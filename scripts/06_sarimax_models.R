# =====================================================================
# 06_sarimax_models.R  —  Modelos com regressoras externas (SARIMAX)
#   Modelo 3: SARIMAX + câmbio
#   Modelo 4: SARIMAX + câmbio + Selic
#   Modelo 5: SARIMAX + câmbio + Selic + IGP-M
#   Modelo 6: SARIMAX + câmbio + Selic + IGP-M + Focus
# Estimados para IPCA cheio e núcleo. Todos com componente sazonal.
# Saída: data/processed/result_sarimax.rds
# =====================================================================

if (!exists("config"))       source("config.R")
if (!exists("rodar_modelo")) source("R/utils.R")

suppressPackageStartupMessages({
  library(readr); library(forecast); library(Metrics)
})

base <- readr::read_csv("data/processed/base_mensal.csv", show_col_types = FALSE)
base$mes <- as.Date(base$mes)

# conjuntos cumulativos de regressoras (colunas da base tratada)
specs <- list(
  M3 = c("dcambio"),
  M4 = c("dcambio", "selic_fim"),
  M5 = c("dcambio", "selic_fim", "igpm"),
  M6 = c("dcambio", "selic_fim", "igpm", "focus")
)
rotulos <- list(M3 = "+ câmbio",
                M4 = "+ câmbio + Selic",
                M5 = "+ câmbio + Selic + IGP-M",
                M6 = "+ câmbio + Selic + IGP-M + Focus")

resultados <- list()
diagnosticos_sarimax <- list()

for (alvo in c("ipca", "nucleo")) {
  rotulo_alvo <- ifelse(alvo == "ipca", "IPCA cheio", "Núcleo")

  # janela comum: usa M6 (todas as regressoras) para achar o menor período
  am_m6 <- montar_amostra(base, alvo, specs[["M6"]])
  base_comum <- am_m6$dados

  for (m in names(specs)) {
    am <- montar_amostra(base_comum, alvo, specs[[m]])
    nome <- sprintf("%s SARIMAX %s — %s", m, rotulos[[m]], rotulo_alvo)
    res <- rodar_modelo(nome, am$y, xreg_full = am$xreg,
                        seasonal = TRUE, n_test = config$n_test)
    chave <- paste0(alvo, "_", tolower(m))
    resultados[[chave]] <- res

    tag <- paste0(alvo, "_", tolower(m))
    png(sprintf("output/figures/resid_%s.png", tag), width = 900, height = 600)
    forecast::checkresiduals(res$mod_full)
    dev.off()
    lb <- forecast::checkresiduals(res$mod_full, plot = FALSE)
    diagnosticos_sarimax[[tag]] <- data.frame(
      Modelo = nome, LjungBox_pvalor = round(lb$p.value, 4),
      stringsAsFactors = FALSE
    )

    message(sprintf(">> [06] %-9s %-28s | %s | AIC=%.1f RMSE=%.3f MAE=%.3f",
                    rotulo_alvo, rotulos[[m]], ordem_texto(res$ordem_full),
                    res$aic, res$rmse, res$mae))
  }
  message(sprintf(">> [06] Janela comum %s: %s a %s (%d obs)",
                  rotulo_alvo, base_comum$mes[1],
                  base_comum$mes[nrow(base_comum)], nrow(base_comum)))
}

diag_sx <- do.call(rbind, diagnosticos_sarimax)
write.csv(diag_sx, "output/tables/ljungbox_sarimax.csv", row.names = FALSE)

saveRDS(resultados, "data/processed/result_sarimax.rds")
message(">> [06] Modelos SARIMAX estimados e salvos (com diagnóstico de resíduos).")
