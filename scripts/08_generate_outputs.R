# =====================================================================
# 08_generate_outputs.R  —  Consolidação dos resultados finais
#   - tabela mestra (todos os modelos, IPCA e núcleo lado a lado);
#   - comparação quantitativa IPCA cheio x núcleo (volatilidade,
#     persistência, previsibilidade, valor marginal das regressoras);
#   - coeficientes do melhor modelo de cada série.
# Tudo CALCULADO a partir dos resultados (nada é inventado).
# Saídas em output/tables/.
# =====================================================================

if (!exists("config")) source("config.R")
if (!exists("ts_para_datas")) source("R/utils.R")

suppressPackageStartupMessages({ library(readr); library(forecast) })

base  <- readr::read_csv("data/processed/base_mensal.csv", show_col_types = FALSE)
aval  <- readRDS("data/processed/avaliacao.rds")

# ---- 1) tabela mestra: RMSE/MAE de cada modelo, IPCA x núcleo ----------
mestra <- data.frame(
  Modelo     = sub(" —.*$", "", aval$ipca$tabela$Modelo),  # rótulo curto
  RMSE_IPCA  = aval$ipca$tabela$RMSE,
  MAE_IPCA   = aval$ipca$tabela$MAE,
  RMSE_Nucleo= aval$nucleo$tabela$RMSE,
  MAE_Nucleo = aval$nucleo$tabela$MAE,
  stringsAsFactors = FALSE
)
write.csv(mestra, "output/tables/tabela_mestra_rmse_mae.csv", row.names = FALSE)
message(">> [08] Tabela mestra (RMSE/MAE — IPCA x núcleo):")
print(mestra)

# ---- 2) comparação estrutural IPCA cheio x núcleo ---------------------
# Persistência aproximada por autocorrelação de 1ª ordem (ACF lag 1).
acf1 <- function(x) { x <- x[!is.na(x)]; acf(x, lag.max = 1, plot = FALSE)$acf[2, 1, 1] }

# valor marginal das regressoras = redução de RMSE do M2 (SARIMA) ao M6
rmse_m2_ipca <- aval$ipca$tabela$RMSE[2];  rmse_m6_ipca <- aval$ipca$tabela$RMSE[6]
rmse_m2_nuc  <- aval$nucleo$tabela$RMSE[2]; rmse_m6_nuc  <- aval$nucleo$tabela$RMSE[6]

comparacao <- data.frame(
  Dimensao = c("Desvio-padrão (volatilidade)",
               "Persistência (ACF lag 1)",
               "Melhor RMSE fora da amostra",
               "Melhor modelo",
               "RMSE SARIMA (M2)",
               "RMSE SARIMAX completo (M6)",
               "Ganho com regressoras (M2->M6, %)"),
  IPCA_cheio = c(
    round(sd(base$ipca, na.rm = TRUE), 3),
    round(acf1(base$ipca), 3),
    round(min(aval$ipca$tabela$RMSE), 4),
    aval$ipca$melhor,
    round(rmse_m2_ipca, 4),
    round(rmse_m6_ipca, 4),
    round(100 * (rmse_m2_ipca - rmse_m6_ipca) / rmse_m2_ipca, 1)
  ),
  Nucleo = c(
    round(sd(base$nucleo, na.rm = TRUE), 3),
    round(acf1(base$nucleo), 3),
    round(min(aval$nucleo$tabela$RMSE), 4),
    aval$nucleo$melhor,
    round(rmse_m2_nuc, 4),
    round(rmse_m6_nuc, 4),
    round(100 * (rmse_m2_nuc - rmse_m6_nuc) / rmse_m2_nuc, 1)
  ),
  stringsAsFactors = FALSE
)
write.csv(comparacao, "output/tables/comparacao_cheio_vs_nucleo.csv", row.names = FALSE)
message(">> [08] Comparação IPCA cheio x núcleo:")
print(comparacao)

# ---- 3) coeficientes do melhor modelo de cada série -------------------
exportar_coef <- function(res, arquivo) {
  m  <- res$melhor_res$mod_full
  co <- coef(m)
  se <- sqrt(diag(m$var.coef))
  df <- data.frame(Termo = names(co),
                   Coeficiente = round(as.numeric(co), 4),
                   ErroPadrao  = round(as.numeric(se), 4),
                   stringsAsFactors = FALSE)
  df$Estatistica_t <- round(df$Coeficiente / df$ErroPadrao, 2)
  gl <- m$nobs - length(co)
  df$p_valor <- round(2 * pt(-abs(df$Estatistica_t), df = gl), 4)
  write.csv(df, file.path("output/tables", arquivo), row.names = FALSE)
  df
}
co_ipca <- exportar_coef(aval$ipca,   "coeficientes_melhor_ipca.csv")
co_nuc  <- exportar_coef(aval$nucleo, "coeficientes_melhor_nucleo.csv")
message(">> [08] Coeficientes do melhor modelo (IPCA):"); print(co_ipca)
message(">> [08] Coeficientes do melhor modelo (núcleo):"); print(co_nuc)

message("\n>> [08] Consolidação concluída. Veja output/tables/ para todas as tabelas.")
