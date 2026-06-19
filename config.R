# =====================================================================
# config.R  —  Parâmetros globais do projeto
# Centraliza datas, códigos SGS e hiperparâmetros de avaliação.
# Altere AQUI (e somente aqui) para reproduzir o trabalho com outras
# escolhas (período, série de núcleo, tamanho do conjunto de teste).
# =====================================================================

config <- list(

  # ---- Período da amostra ----
  data_inicio = "2004-01-01",   # regime de metas já estabilizado
  data_fim    = "2025-05-01",   # último mês com dados completos

  # ---- Avaliação fora da amostra ----
  n_test = 24,                  # nº de meses reservados para teste (holdout)

  # ---- Códigos do SGS (Sistema Gerenciador de Séries Temporais / BCB) ----
  sgs = list(
    ipca   = 433,    # IPCA cheio (headline) - variação % mensal
    nucleo = 4466,   # Núcleo IPCA - MÉDIAS APARADAS COM SUAVIZAÇÃO - var % mensal
    selic  = 432,    # Meta para a taxa Selic definida pelo Copom - % a.a.
    cambio = 1,      # Taxa de câmbio R$/US$ (venda) - DIÁRIA
    igpm   = 189     # IGP-M (FGV) - variação % mensal
  )

  # ------------------------------------------------------------------
  # ATENÇÃO METODOLÓGICA — código do núcleo:
  # O enunciado citava o código 11427 como "núcleo por médias aparadas".
  # Conferindo o Portal de Dados Abertos do BCB, o código 11427 é, na
  # verdade, o "IPCA - Núcleo por EXCLUSÃO - sem monitorados e alimentos
  # no domicílio" (IPCA-EX0), que NÃO é um núcleo por médias aparadas.
  # O núcleo por médias aparadas com suavização (a medida clássica usada
  # pelo BCB e com história longa desde os anos 2000) é o código 4466.
  # Por coerência com a metodologia declarada ("médias aparadas"),
  # usamos 4466. Para reproduzir com EX0, basta trocar nucleo = 11427.
  # Outras opções: 11426 (médias aparadas SEM suavização).
  # ------------------------------------------------------------------
)
