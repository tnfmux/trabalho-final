# =====================================================================
# 03_exploratory_analysis.R  —  Análise exploratória e descritiva
# Gera:
#   - gráfico das séries em nível (IPCA cheio vs. núcleo);
#   - gráfico das regressoras;
#   - tabela de estatísticas descritivas;
#   - ACF e PACF das duas séries de inflação;
#   - gráfico sazonal (subséries por mês).
# Saídas em output/figures e output/tables.
# =====================================================================

if (!exists("config"))       source("config.R")
if (!exists("construir_ts")) source("R/utils.R")

suppressPackageStartupMessages({
  library(dplyr); library(ggplot2); library(readr); library(tidyr); library(forecast)
})

base <- readr::read_csv("data/processed/base_mensal.csv", show_col_types = FALSE)
base$mes <- as.Date(base$mes)

ano0 <- as.integer(format(min(base$mes), "%Y"))
mes0 <- as.integer(format(min(base$mes), "%m"))
ipca_ts   <- construir_ts(base$ipca,   ano0, mes0)
nucleo_ts <- construir_ts(base$nucleo, ano0, mes0)

# ---- 1) séries de inflação em nível -----------------------------------
g1 <- base %>%
  select(mes, ipca, nucleo) %>%
  pivot_longer(-mes, names_to = "serie", values_to = "valor") %>%
  mutate(serie = recode(serie, ipca = "IPCA cheio", nucleo = "Núcleo (médias aparadas)")) %>%
  ggplot(aes(mes, valor, colour = serie)) +
  geom_line(linewidth = 0.6) +
  labs(title = "Inflação mensal: IPCA cheio vs. núcleo",
       x = NULL, y = "Variação mensal (%)", colour = NULL) +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom")
ggsave("output/figures/01_series_inflacao.png", g1, width = 9, height = 4.5, dpi = 150)

# ---- 2) regressoras ---------------------------------------------------
g2 <- base %>%
  select(mes, dcambio, selic_fim, igpm, focus) %>%
  pivot_longer(-mes, names_to = "serie", values_to = "valor") %>%
  mutate(serie = recode(serie,
                        dcambio   = "Variação cambial (%)",
                        selic_fim = "Selic meta (% a.a.)",
                        igpm      = "IGP-M (% mês)",
                        focus     = "Expectativa Focus IPCA (% mês)")) %>%
  ggplot(aes(mes, valor)) +
  geom_line(linewidth = 0.5, colour = "#2c3e50") +
  facet_wrap(~serie, scales = "free_y") +
  labs(title = "Regressoras macroeconômicas", x = NULL, y = NULL) +
  theme_minimal(base_size = 11)
ggsave("output/figures/02_regressoras.png", g2, width = 9, height = 5, dpi = 150)

# ---- 3) estatísticas descritivas --------------------------------------
descritivas <- function(x, nome) {
  x <- x[!is.na(x)]
  data.frame(
    Serie    = nome,
    N        = length(x),
    Media    = round(mean(x), 3),
    Mediana  = round(median(x), 3),
    DesvPad  = round(sd(x), 3),
    Min      = round(min(x), 3),
    Max      = round(max(x), 3),
    Assimetria = round(mean((x - mean(x))^3) / sd(x)^3, 3),
    stringsAsFactors = FALSE
  )
}
tab_desc <- rbind(
  descritivas(base$ipca,   "IPCA cheio"),
  descritivas(base$nucleo, "Núcleo"),
  descritivas(base$igpm,   "IGP-M"),
  descritivas(base$dcambio,"Variação cambial"),
  descritivas(base$selic_fim,"Selic meta"),
  descritivas(base$focus,  "Focus IPCA")
)
write.csv(tab_desc, "output/tables/estatisticas_descritivas.csv", row.names = FALSE)
message(">> [03] Estatísticas descritivas:")
print(tab_desc)

# ---- 4) ACF e PACF ----------------------------------------------------
png("output/figures/03_acf_pacf_ipca.png", width = 900, height = 400)
par(mfrow = c(1, 2)); Acf(ipca_ts, main = "ACF — IPCA cheio")
Pacf(ipca_ts, main = "PACF — IPCA cheio"); dev.off()

png("output/figures/04_acf_pacf_nucleo.png", width = 900, height = 400)
par(mfrow = c(1, 2)); Acf(nucleo_ts, main = "ACF — Núcleo")
Pacf(nucleo_ts, main = "PACF — Núcleo"); dev.off()

# ---- 5) gráfico sazonal (subséries por mês) ---------------------------
g5 <- forecast::ggseasonplot(ipca_ts, year.labels = FALSE) +
  ggplot2::labs(title = "Padrão sazonal — IPCA cheio",
                y = "Variação mensal (%)") +
  ggplot2::theme_minimal(base_size = 11)
ggsave("output/figures/05_sazonalidade_ipca.png", g5, width = 9, height = 4.5, dpi = 150)

message(">> [03] Figuras e tabelas exploratórias salvas.")
