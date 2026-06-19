# =====================================================================
# 05_arima_sarima_models.R  —  Modelos univariados
#   Modelo 1: ARIMA  (sem componente sazonal)
#   Modelo 2: SARIMA (com componente sazonal, s = 12)
# Estimados para AS DUAS variáveis dependentes: IPCA cheio e núcleo.
# Inclui diagnóstico de resíduos (Ljung-Box) do modelo final.
# Saída: data/processed/result_univariados.rds  +  figuras de resíduos.
# =====================================================================

if (!exists("config"))        source("config.R")
if (!exists("rodar_modelo"))  source("R/utils.R")

suppressPackageStartupMessages({
  library(readr); library(forecast); library(Metrics)
})

base <- readr::read_csv("data/processed/base_mensal.csv", show_col_types = FALSE)
base$mes <- as.Date(base$mes)

# diagnóstico de resíduos -> salva figura e devolve p-valor de Ljung-Box
diagnosticar <- function(res, tag) {
  png(sprintf("output/figures/resid_%s.png", tag), width = 900, height = 600)
  forecast::checkresiduals(res$mod_full)
  dev.off()
  lb <- forecast::checkresiduals(res$mod_full, plot = FALSE)
  data.frame(Modelo = res$nome,
             LjungBox_pvalor = round(lb$p.value, 4),
             stringsAsFactors = FALSE)
}

resultados <- list()
diagnosticos <- list()

for (alvo in c("ipca", "nucleo")) {
  rotulo <- ifelse(alvo == "ipca", "IPCA cheio", "Núcleo")
  am <- montar_amostra(base, alvo)            # sem regressoras

  # Modelo 1 — ARIMA (seasonal = FALSE)
  m1 <- rodar_modelo(paste0("M1 ARIMA — ", rotulo),
                     am$y, seasonal = FALSE, n_test = config$n_test)
  # Modelo 2 — SARIMA (seasonal = TRUE)
  m2 <- rodar_modelo(paste0("M2 SARIMA — ", rotulo),
                     am$y, seasonal = TRUE, n_test = config$n_test)

  resultados[[paste0(alvo, "_m1")]] <- m1
  resultados[[paste0(alvo, "_m2")]] <- m2

  diagnosticos[[paste0(alvo, "_m1")]] <- diagnosticar(m1, paste0(alvo, "_m1"))
  diagnosticos[[paste0(alvo, "_m2")]] <- diagnosticar(m2, paste0(alvo, "_m2"))

  message(sprintf(">> [05] %s | M1 %s (AIC=%.1f, RMSE=%.3f) | M2 %s (AIC=%.1f, RMSE=%.3f)",
                  rotulo, ordem_texto(m1$ordem_full), m1$aic, m1$rmse,
                  ordem_texto(m2$ordem_full), m2$aic, m2$rmse))
}

saveRDS(resultados, "data/processed/result_univariados.rds")
diag_df <- do.call(rbind, diagnosticos)
write.csv(diag_df, "output/tables/ljungbox_univariados.csv", row.names = FALSE)
message(">> [05] Modelos univariados estimados e salvos.")
