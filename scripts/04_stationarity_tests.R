# =====================================================================
# 04_stationarity_tests.R  —  Estacionariedade
# Roda ADF (H0: tem raiz unitária / não-estacionária) e
# KPSS (H0: estacionária) para as séries de inflação e regressoras.
# A leitura conjunta dos dois testes é mais robusta:
#   - ADF rejeita H0  E  KPSS NÃO rejeita H0  -> evidência de estacionariedade.
# Saída: output/tables/testes_estacionariedade.csv
# =====================================================================

if (!exists("config"))       source("config.R")
if (!exists("construir_ts")) source("R/utils.R")

suppressPackageStartupMessages({
  library(readr); library(tseries); library(dplyr)
})

base <- readr::read_csv("data/processed/base_mensal.csv", show_col_types = FALSE)
base$mes <- as.Date(base$mes)

testar <- function(x, nome) {
  x <- x[!is.na(x)]
  adf  <- suppressWarnings(tseries::adf.test(x))      # H0: raiz unitária
  kpss <- suppressWarnings(tseries::kpss.test(x, null = "Level"))  # H0: estacionária
  data.frame(
    Serie       = nome,
    ADF_estat   = round(unname(adf$statistic), 3),
    ADF_pvalor  = round(adf$p.value, 4),
    KPSS_estat  = round(unname(kpss$statistic), 3),
    KPSS_pvalor = round(kpss$p.value, 4),
    Conclusao   = dplyr::case_when(
      adf$p.value < 0.05 & kpss$p.value > 0.05  ~ "Estacionária",
      adf$p.value >= 0.05 & kpss$p.value <= 0.05 ~ "Não-estacionária",
      adf$p.value < 0.05 & kpss$p.value <= 0.05  ~ "Conflito (ADF rejeita RU, KPSS rejeita estac.)",
      TRUE ~ "Inconclusivo (nenhum teste rejeita H0)"
    ),
    stringsAsFactors = FALSE
  )
}

tab <- rbind(
  testar(base$ipca,      "IPCA cheio"),
  testar(base$nucleo,    "Núcleo"),
  testar(base$igpm,      "IGP-M"),
  testar(base$dcambio,   "Variação cambial"),
  testar(base$selic_fim, "Selic meta (nível)"),
  testar(base$focus,     "Focus IPCA")
)

write.csv(tab, "output/tables/testes_estacionariedade.csv", row.names = FALSE)
message(">> [04] Testes de estacionariedade:")
print(tab)
message("   Obs.: como modelamos a VARIAÇÃO mensal (não o índice em nível),")
message("   as séries de inflação tendem a já ser estacionárias (d provável = 0).")
message("   O auto.arima confirmará a ordem de diferenciação via testes (KPSS).")
