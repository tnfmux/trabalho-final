# =====================================================================
# 01_download_data.R  —  Coleta das séries via API do Banco Central
# Fontes:
#   - SGS (API JSON direta): IPCA, núcleo, IGP-M, Selic meta, câmbio
#   - Expectativas Focus (rbcb): IPCA mensal
# Saída: arquivos brutos em data/raw/
# =====================================================================

if (!exists("config"))       source("config.R")
if (!exists("construir_ts")) source("R/utils.R")

suppressPackageStartupMessages({
  library(httr); library(jsonlite); library(rbcb)
  library(dplyr); library(readr); library(lubridate)
})

di   <- as.Date(config$data_inicio)
dfim <- as.Date(config$data_fim)

# --- busca um trecho da série (uma requisição), com retry --------------
buscar_trecho <- function(codigo, d0, d1, max_tentativas = 3) {
  url <- sprintf(
    "https://api.bcb.gov.br/dados/serie/bcdata.sgs.%d/dados?formato=json&dataInicial=%s&dataFinal=%s",
    codigo, format(d0, "%d/%m/%Y"), format(d1, "%d/%m/%Y")
  )
  for (tentativa in seq_len(max_tentativas)) {
    resp <- tryCatch(httr::GET(url, httr::timeout(30)),
                     error = function(e) NULL)
    if (!is.null(resp) && httr::status_code(resp) == 200) {
      json <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
      if (length(json) == 0) return(data.frame())  # trecho sem dados
      return(data.frame(
        data  = as.Date(json$data, format = "%d/%m/%Y"),
        valor = as.numeric(json$valor),
        stringsAsFactors = FALSE
      ))
    }
    if (tentativa < max_tentativas) {
      message("     HTTP ", if (!is.null(resp)) httr::status_code(resp) else "timeout",
              " — tentativa ", tentativa, "/", max_tentativas, ", esperando 5s...")
      Sys.sleep(5)
    }
  }
  stop("falha após ", max_tentativas, " tentativas em ",
       format(d0, "%Y"), "-", format(d1, "%Y"))
}

# --- baixa série do SGS via API JSON direta -----------------------------
# Séries DIÁRIAS (Selic 432, câmbio 1) têm limite de ~10 anos por
# requisição no BCB; por isso quebramos o período em janelas de 9 anos
# e concatenamos. Séries mensais aceitam o range completo numa só chamada.
baixar_sgs <- function(codigo, nome) {
  cache <- file.path("data/raw", paste0(nome, ".rds"))
  message("   - ", nome, " (SGS ", codigo, ")")

  res <- tryCatch({
    cortes <- seq(di, dfim, by = "9 years")
    if (utils::tail(cortes, 1) < dfim) cortes <- c(cortes, dfim)

    partes <- list()
    for (i in seq_len(length(cortes) - 1)) {
      d0 <- if (i == 1) cortes[i] else cortes[i] + 1
      partes[[i]] <- buscar_trecho(codigo, d0, cortes[i + 1])
      if (i < length(cortes) - 1) Sys.sleep(3)  # evita rate limit do BCB
    }
    out <- do.call(rbind, partes)
    out <- out[!duplicated(out$data), , drop = FALSE]
    out$serie <- nome
    saveRDS(out, cache)
    out
  }, error = function(e) {
    if (file.exists(cache)) {
      warning("API falhou para ", nome, " — usando cache local. Erro: ", e$message)
      readRDS(cache)
    } else {
      stop("API falhou para ", nome, " e não há cache. Erro: ", e$message)
    }
  })
  res
}

message(">> [01] Baixando séries do SGS ...")
ipca   <- baixar_sgs(config$sgs$ipca,   "ipca")
Sys.sleep(2)
nucleo <- baixar_sgs(config$sgs$nucleo, "nucleo")
Sys.sleep(2)
igpm   <- baixar_sgs(config$sgs$igpm,   "igpm")
Sys.sleep(2)
selic  <- baixar_sgs(config$sgs$selic,  "selic")
Sys.sleep(2)
cambio <- baixar_sgs(config$sgs$cambio, "cambio")

# --- Expectativas Focus: IPCA mensal -----------------------------------
message(">> [01] Baixando expectativas Focus (IPCA mensal) ...")
focus_cache <- "data/raw/focus_ipca.rds"
focus_ipca <- tryCatch({
  res <- rbcb::get_market_expectations(
    type       = "monthly",
    indic      = "IPCA",
    start_date = config$data_inicio
  )
  saveRDS(res, focus_cache)
  res
}, error = function(e) {
  if (file.exists(focus_cache)) {
    warning("API Focus falhou — usando cache local. Erro: ", e$message)
    readRDS(focus_cache)
  } else {
    stop("API Focus falhou e não há cache. Erro: ", e$message)
  }
})

# cópia "legível" das séries mensais já em formato longo
readr::write_csv(bind_rows(ipca, nucleo, igpm),
                 "data/raw/series_mensais_long.csv")

message(">> [01] Concluído. Dados brutos salvos em data/raw/")
