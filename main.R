# =====================================================================
# main.R  —  Orquestra todo o pipeline de ponta a ponta
# Rode este arquivo para reproduzir o trabalho do zero:
#   Rscript main.R      (no terminal)   ou   source("main.R")  (no R/RStudio)
# =====================================================================

cat("\n========================================================\n")
cat(" PREVISÃO DA INFLAÇÃO BRASILEIRA — IPCA cheio vs. Núcleo\n")
cat("========================================================\n\n")

# 0) ambiente -----------------------------------------------------------
options(stringsAsFactors = FALSE, error = NULL)
Sys.setlocale("LC_TIME", "pt_BR.UTF-8")   # nomes de meses em PT (se disponível)

source("requirements.R")   # instala/carrega pacotes
source("config.R")         # parâmetros globais
source("R/utils.R")        # funções utilitárias
criar_estrutura_pastas()   # garante as pastas

# 1) pipeline -----------------------------------------------------------
etapas <- c(
  "scripts/01_download_data.R",
  "scripts/02_prepare_data.R",
  "scripts/03_exploratory_analysis.R",
  "scripts/04_stationarity_tests.R",
  "scripts/05_arima_sarima_models.R",
  "scripts/06_sarimax_models.R",
  "scripts/07_forecast_evaluation.R",
  "scripts/08_generate_outputs.R"
)

for (e in etapas) {
  cat("\n----------------------------------------------------------\n")
  cat(">>> Executando:", e, "\n")
  cat("----------------------------------------------------------\n")
  source(e, echo = FALSE)
}

writeLines(capture.output(sessionInfo()), "output/sessioninfo.txt")

cat("\n========================================================\n")
cat(" PIPELINE CONCLUÍDO.\n")
cat(" Resultados em: output/figures, output/tables, output/forecasts\n")
cat("========================================================\n")
