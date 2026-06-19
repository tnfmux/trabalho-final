# =====================================================================
# R/utils.R  —  Funções utilitárias compartilhadas
# Concentra o "motor" do projeto: construção de séries temporais,
# estimação dos modelos com avaliação fora da amostra, montagem de
# tabelas comparativas e gráficos. Mantê-las aqui evita repetição.
# =====================================================================

# ---------------------------------------------------------------------
# Cria a estrutura de pastas do projeto (idempotente).
# ---------------------------------------------------------------------
criar_estrutura_pastas <- function(base = ".") {
  pastas <- c("data/raw", "data/processed",
              "output/figures", "output/tables", "output/forecasts")
  for (p in pastas) dir.create(file.path(base, p), recursive = TRUE,
                               showWarnings = FALSE)
  invisible(TRUE)
}

# ---------------------------------------------------------------------
# Constrói um objeto ts mensal (frequência 12).
# ---------------------------------------------------------------------
construir_ts <- function(x, ano_inicio, mes_inicio = 1, freq = 12) {
  stats::ts(x, start = c(ano_inicio, mes_inicio), frequency = freq)
}

# ---------------------------------------------------------------------
# Converte os tempos de um ts mensal em datas (1º dia do mês).
# Evita dependência extra só para o eixo dos gráficos.
# ---------------------------------------------------------------------
ts_para_datas <- function(x) {
  anos  <- floor(stats::time(x) + 1e-8)
  meses <- stats::cycle(x)
  as.Date(sprintf("%04d-%02d-01", anos, meses))
}

# ---------------------------------------------------------------------
# Monta a amostra de modelagem para uma variável dependente e um
# conjunto (possivelmente vazio) de regressoras.
#   - seleciona as colunas necessárias;
#   - descarta linhas com NA (regressoras como o Focus começam depois);
#   - usa a maior janela contígua disponível;
#   - devolve y (ts), xreg (matriz alinhada) e a data de início.
# ---------------------------------------------------------------------
montar_amostra <- function(base, y_col, x_cols = character(0)) {
  cols <- c(y_col, x_cols)
  ok   <- stats::complete.cases(base[, cols, drop = FALSE])
  if (!any(ok)) stop("Sem observações completas para: ", y_col,
                     " ~ ", paste(x_cols, collapse = " + "))
  i1 <- which(ok)[1]
  i2 <- utils::tail(which(ok), 1)
  if (any(!ok[i1:i2]))
    warning("Há NAs internos em ", y_col, " com regressoras [",
            paste(x_cols, collapse = ", "),
            "]. Verifique a base antes de interpretar.")
  sub  <- base[i1:i2, ]
  ano0 <- as.integer(format(sub$mes[1], "%Y"))
  mes0 <- as.integer(format(sub$mes[1], "%m"))
  y    <- construir_ts(sub[[y_col]], ano0, mes0)
  X    <- if (length(x_cols)) {
    M <- as.matrix(sub[, x_cols, drop = FALSE]); colnames(M) <- x_cols; M
  } else NULL
  list(y = y, xreg = X, inicio = c(ano0, mes0), dados = sub)
}

# ---------------------------------------------------------------------
# Estima um modelo (S)ARIMA(X) e avalia fora da amostra.
#
#   nome      : rótulo do modelo (entra nas tabelas)
#   y_full    : ts da variável dependente (amostra completa)
#   xreg_full : matriz de regressoras alinhada a y_full (ou NULL)
#   n_test    : nº de observações no conjunto de teste (holdout final)
#   seasonal  : TRUE permite componente sazonal (SARIMA/SARIMAX)
#
# Estratégia:
#   - mod_full  -> auto.arima na amostra COMPLETA, usado para reportar
#                  coeficientes, AIC e BIC do modelo final;
#   - mod_train -> auto.arima SÓ no treino, usado para prever o teste
#                  (evita "look-ahead" na avaliação preditiva);
#   - nos SARIMAX, a previsão do teste usa os valores REALIZADOS das
#     regressoras (previsão condicional / ex-post). Isso isola o valor
#     informativo das regressoras. Ver limitações no relatório.
# ---------------------------------------------------------------------
rodar_modelo <- function(nome, y_full, xreg_full = NULL,
                         n_test = 24, seasonal = TRUE) {

  n <- length(y_full)
  if (n_test >= n) stop("n_test (", n_test, ") >= tamanho da série (", n, ").")

  t_all     <- stats::time(y_full)
  idx_corte <- n - n_test

  y_train <- stats::window(y_full, end   = t_all[idx_corte])
  y_test  <- stats::window(y_full, start = t_all[idx_corte + 1])

  tem_xreg <- !is.null(xreg_full)
  if (tem_xreg) {
    xreg_full  <- as.matrix(xreg_full)
    xr_train   <- xreg_full[1:idx_corte, , drop = FALSE]
    xr_test    <- xreg_full[(idx_corte + 1):n, , drop = FALSE]
  }

  # 1) modelo final (amostra completa) -> AIC/BIC/coeficientes
  # 2) modelo de treino -> previsão fora da amostra
  # Nota: auto.arima captura o call e re-avalia por nome internamente,
  # por isso não passamos xreg=NULL — omitimos o argumento.
  if (tem_xreg) {
    mod_full  <- forecast::auto.arima(y_full,  xreg = xreg_full, seasonal = seasonal)
    mod_train <- forecast::auto.arima(y_train, xreg = xr_train,  seasonal = seasonal)
    fc        <- forecast::forecast(mod_train, h = n_test, xreg = xr_test)
  } else {
    mod_full  <- forecast::auto.arima(y_full,  seasonal = seasonal)
    mod_train <- forecast::auto.arima(y_train, seasonal = seasonal)
    fc        <- forecast::forecast(mod_train, h = n_test)
  }

  # 3) métricas no teste
  obs  <- as.numeric(y_test)
  pred <- as.numeric(fc$mean)

  list(
    nome        = nome,
    ordem_full  = forecast::arimaorder(mod_full),
    ordem_train = forecast::arimaorder(mod_train),
    mod_full    = mod_full,
    mod_train   = mod_train,
    fc          = fc,
    aic         = stats::AIC(mod_full),
    bic         = stats::BIC(mod_full),
    rmse        = Metrics::rmse(obs, pred),
    mae         = Metrics::mae(obs, pred),
    y_test      = y_test,
    pred        = stats::ts(pred, start = stats::start(y_test),
                            frequency = stats::frequency(y_full))
  )
}

# ---------------------------------------------------------------------
# Formata a ordem (p,d,q)(P,D,Q)[s] como texto legível.
# ---------------------------------------------------------------------
ordem_texto <- function(ord) {
  if (length(ord) == 7) {
    sprintf("(%d,%d,%d)(%d,%d,%d)[%d]",
            ord[1], ord[2], ord[3], ord[4], ord[5], ord[6], ord[7])
  } else {
    sprintf("(%d,%d,%d)", ord[1], ord[2], ord[3])
  }
}

# ---------------------------------------------------------------------
# Constrói a tabela comparativa a partir de uma lista de resultados.
# ---------------------------------------------------------------------
tabela_comparacao <- function(resultados) {
  do.call(rbind, lapply(resultados, function(r) {
    data.frame(
      Modelo        = r$nome,
      Especificacao = ordem_texto(r$ordem_full),
      AIC           = round(r$aic, 2),
      BIC           = round(r$bic, 2),
      RMSE          = round(r$rmse, 4),
      MAE           = round(r$mae, 4),
      stringsAsFactors = FALSE
    )
  }))
}

# ---------------------------------------------------------------------
# Gráfico previsto x observado no conjunto de teste.
# ---------------------------------------------------------------------
grafico_previsao <- function(res, titulo) {
  df <- data.frame(
    data      = ts_para_datas(res$y_test),
    Observado = as.numeric(res$y_test),
    Previsto  = as.numeric(res$pred)
  )
  ggplot2::ggplot(df, ggplot2::aes(x = data)) +
    ggplot2::geom_line(ggplot2::aes(y = Observado, colour = "Observado"),
                       linewidth = 0.8) +
    ggplot2::geom_line(ggplot2::aes(y = Previsto,  colour = "Previsto"),
                       linewidth = 0.8, linetype = "dashed") +
    ggplot2::scale_colour_manual(values = c(Observado = "#1b1b1b",
                                            Previsto  = "#c0392b")) +
    ggplot2::labs(title = titulo, x = NULL,
                  y = "Variação mensal (%)", colour = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom")
}

# ---------------------------------------------------------------------
# Salva um data.frame como CSV em output/tables (atalho).
# ---------------------------------------------------------------------
salvar_tabela <- function(df, arquivo) {
  utils::write.csv(df, file.path("output/tables", arquivo),
                   row.names = FALSE)
  invisible(df)
}
