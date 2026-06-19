# =====================================================================
# 02_prepare_data.R  —  Tratamento e alinhamento mensal das séries
# Regras (justificadas no relatório):
#   - Câmbio (diário) -> MÉDIA mensal (melhor proxy do repasse cambial).
#   - Selic meta (muda em datas do Copom) -> valor VIGENTE no fim do mês.
#   - IPCA, núcleo, IGP-M -> já mensais (variação % mensal).
#   - Focus -> mediana da última leitura divulgada ATÉ o fim do mês
#              anterior ao mês de referência (regressora forward-looking).
# Saída: data/processed/base_mensal.csv
# =====================================================================

if (!exists("config")) source("config.R")

suppressPackageStartupMessages({
  library(dplyr); library(lubridate); library(tidyr); library(readr); library(zoo)
})

message(">> [02] Tratando e alinhando séries em frequência mensal ...")

ipca       <- readRDS("data/raw/ipca.rds")
nucleo     <- readRDS("data/raw/nucleo.rds")
igpm       <- readRDS("data/raw/igpm.rds")
selic      <- readRDS("data/raw/selic.rds")
cambio     <- readRDS("data/raw/cambio.rds")
focus_raw  <- readRDS("data/raw/focus_ipca.rds")

# âncora mensal: 1º dia do mês
mes <- function(d) lubridate::floor_date(as.Date(d), "month")

# ---- séries já mensais ------------------------------------------------
ipca_m   <- ipca   %>% transmute(mes = mes(data), ipca   = valor)
nucleo_m <- nucleo %>% transmute(mes = mes(data), nucleo = valor)
igpm_m   <- igpm   %>% transmute(mes = mes(data), igpm   = valor)

# ---- câmbio diário -> média mensal ------------------------------------
cambio_m <- cambio %>%
  mutate(mes = mes(data)) %>%
  group_by(mes) %>%
  summarise(cambio_med = mean(valor, na.rm = TRUE), .groups = "drop")

# ---- Selic meta -> valor vigente no fim do mês ------------------------
# A série muda em datas discretas (Copom). Construímos uma grade diária,
# preenchemos "para frente" (LOCF) e tomamos o último valor de cada mês.
grade_selic <- tibble(
    data = seq(min(selic$data), max(c(selic$data, Sys.Date())), by = "day")
  ) %>%
  left_join(selic %>% select(data, valor), by = "data") %>%
  arrange(data) %>%
  mutate(selic_vig = zoo::na.locf(valor, na.rm = FALSE))

selic_m <- grade_selic %>%
  mutate(mes = mes(data)) %>%
  group_by(mes) %>%
  summarise(selic_fim = dplyr::last(selic_vig[!is.na(selic_vig)]),
            .groups = "drop")

# ---- Focus (IPCA mensal) -> regressora forward-looking ----------------
# Para cada mês de referência t, pegamos a MEDIANA da última leitura
# divulgada ANTES do início de t. Assim, a expectativa já é conhecida
# quando a inflação de t se realiza (regressora genuinamente ex-ante).
# Entre leituras da mesma data, baseCalculo = 1 (4 dias úteis) é a mais
# recente; usamos a ordenação por data e baseCalculo para desempatar.
focus_m <- focus_raw %>%
  mutate(
    data_survey = as.Date(Data),
    mes_ref     = lubridate::my(DataReferencia)   # "MM/AAAA" -> 1º dia
  ) %>%
  filter(!is.na(Mediana), data_survey < mes_ref) %>%
  arrange(mes_ref, data_survey, baseCalculo) %>%
  group_by(mes_ref) %>%
  summarise(focus = dplyr::last(Mediana), .groups = "drop") %>%
  rename(mes = mes_ref)

# ---- merge mensal -----------------------------------------------------
base <- ipca_m %>%
  full_join(nucleo_m, by = "mes") %>%
  full_join(igpm_m,   by = "mes") %>%
  full_join(cambio_m, by = "mes") %>%
  full_join(selic_m,  by = "mes") %>%
  full_join(focus_m,  by = "mes") %>%
  arrange(mes) %>%
  filter(mes >= as.Date(config$data_inicio),
         mes <= as.Date(config$data_fim))

# ---- regressora derivada: variação cambial mensal (%) -----------------
# Câmbio em nível é não-estacionário; a variação % mensal é estacionária
# e corresponde diretamente ao conceito de repasse cambial (pass-through).
base <- base %>%
  mutate(dcambio = 100 * (log(cambio_med) - log(dplyr::lag(cambio_med))))

# ---- relatório rápido de qualidade ------------------------------------
n_na <- sapply(base, function(x) sum(is.na(x)))
message("   Observações: ", nrow(base),
        " | período: ", format(min(base$mes)), " a ", format(max(base$mes)))
message("   NAs por coluna:")
print(n_na)

# ---- salva base tratada ----------------------------------------------
readr::write_csv(base, "data/processed/base_mensal.csv")
message(">> [02] Base final salva em data/processed/base_mensal.csv")
