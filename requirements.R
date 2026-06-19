# =====================================================================
# requirements.R  —  Instala e carrega os pacotes necessários
# Rode este arquivo UMA vez antes do main.R (ou ele é chamado por main.R).
# =====================================================================

pacotes <- c(
  "rbcb",       # API do Banco Central (SGS + Expectativas Focus)
  "tidyverse",  # dplyr, ggplot2, tidyr, readr, etc.
  "lubridate",  # manipulação de datas
  "zoo",        # na.locf (preenchimento da Selic) e utilidades de séries
  "forecast",   # auto.arima, Arima, forecast (motor econométrico)
  "tseries",    # testes ADF e KPSS
  "urca",       # testes de raiz unitária (versão detalhada)
  "Metrics",    # rmse, mae
  "httr",       # chamadas HTTP diretas à API do BCB
  "jsonlite"    # parse de JSON da API do BCB
)

faltando <- pacotes[!pacotes %in% rownames(installed.packages())]
if (length(faltando) > 0) {
  message("Instalando pacotes ausentes: ", paste(faltando, collapse = ", "))
  install.packages(faltando, repos = "https://cloud.r-project.org")
}

ok <- sapply(pacotes, function(p)
  suppressPackageStartupMessages(require(p, character.only = TRUE)))
if (any(!ok))
  stop("Pacotes não carregados: ", paste(names(ok)[!ok], collapse = ", "))

message("Pacotes carregados com sucesso.")
