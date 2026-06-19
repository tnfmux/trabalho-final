# =====================================================================
# 07_forecast_evaluation.R  —  Avaliação e comparação dos modelos
#   - junta os 6 modelos por variável dependente;
#   - monta a tabela comparativa (AIC, BIC, RMSE, MAE);
#   - identifica o melhor modelo (menor RMSE fora da amostra);
#   - gera gráficos previsto x observado;
#   - exporta previsões e tabelas.
# Saídas: output/tables/*.csv, output/figures/forecast_*.png,
#         output/forecasts/*.csv
# =====================================================================

if (!exists("config"))             source("config.R")
if (!exists("tabela_comparacao"))  source("R/utils.R")

suppressPackageStartupMessages({ library(ggplot2) })

univ   <- readRDS("data/processed/result_univariados.rds")
sarmx  <- readRDS("data/processed/result_sarimax.rds")

avaliar_alvo <- function(alvo, rotulo) {
  res_list <- list(
    univ[[paste0(alvo, "_m1")]],  # M1 ARIMA
    univ[[paste0(alvo, "_m2")]],  # M2 SARIMA
    sarmx[[paste0(alvo, "_m3")]], # M3 SARIMAX + câmbio
    sarmx[[paste0(alvo, "_m4")]], # M4 + Selic
    sarmx[[paste0(alvo, "_m5")]], # M5 + IGP-M
    sarmx[[paste0(alvo, "_m6")]]  # M6 + Focus
  )

  tab <- tabela_comparacao(res_list)
  write.csv(tab, sprintf("output/tables/comparacao_%s.csv", alvo),
            row.names = FALSE)

  message(sprintf("\n=== Comparação de modelos — %s ===", rotulo))
  print(tab)

  melhor_i   <- which.min(tab$RMSE)
  melhor_res <- res_list[[melhor_i]]
  message(sprintf(">> Melhor modelo (menor RMSE) para %s: %s",
                  rotulo, tab$Modelo[melhor_i]))

  # gráfico previsto x observado do melhor modelo
  g <- grafico_previsao(melhor_res,
                        sprintf("Previsão fora da amostra — %s\n(%s)",
                                rotulo, tab$Modelo[melhor_i]))
  ggsave(sprintf("output/figures/forecast_%s.png", alvo), g,
         width = 9, height = 4.5, dpi = 150)

  # exporta a previsão do melhor modelo
  prev_df <- data.frame(
    data      = ts_para_datas(melhor_res$y_test),
    observado = as.numeric(melhor_res$y_test),
    previsto  = as.numeric(melhor_res$pred)
  )
  write.csv(prev_df, sprintf("output/forecasts/forecast_%s.csv", alvo),
            row.names = FALSE)

  list(tabela = tab, melhor = tab$Modelo[melhor_i],
       melhor_res = melhor_res, todos = res_list)
}

aval_ipca   <- avaliar_alvo("ipca",   "IPCA cheio")
aval_nucleo <- avaliar_alvo("nucleo", "Núcleo")

saveRDS(list(ipca = aval_ipca, nucleo = aval_nucleo),
        "data/processed/avaliacao.rds")
message("\n>> [07] Avaliação concluída. Tabelas, previsões e gráficos salvos.")
