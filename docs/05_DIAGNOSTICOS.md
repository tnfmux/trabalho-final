# Parte 5 — Diagnósticos e testes

Esta parte descreve **todos os procedimentos de diagnóstico** do projeto, indicando
em qual script cada um é executado e qual arquivo de saída ele gera. A filosofia
é: *nenhum número é inventado* — cada estatística citada nos slides ou no relatório
sai de um arquivo produzido pelo pipeline.

---

## 1. Gráfico das séries em nível

- **Onde:** `scripts/03_exploratory_analysis.R`
- **Saídas:**
  - `output/figures/01_series_inflacao.png` — IPCA cheio e núcleo (médias aparadas) sobrepostos.
  - `output/figures/02_regressoras.png` — câmbio (variação mensal), Selic (fim de mês), IGP-M, Focus.
- **O que olhar:** nível e amplitude das oscilações, presença de picos (2008, 2015–2016, 2021–2022),
  e a impressão visual de que o núcleo é **mais suave** que o cheio.

## 2. Séries transformadas (quando necessário)

As séries de inflação (IPCA, núcleo, IGP-M) **já são variações percentuais mensais**,
portanto não recebem log nem diferenciação prévia — são tipicamente estacionárias em
nível ou exigem no máximo `d = 0`. As transformações ocorrem apenas nas regressoras
de **nível** para torná-las comparáveis e estacionárias (ver `scripts/02_prepare_data.R`):

- **Câmbio:** convertido em **variação percentual mensal** da média do mês
  (`dcambio = 100 · Δlog`), que é a forma econômica do *pass-through* cambial.
- **Selic:** mantida em **nível de fim de mês** (variável de política, muda em datas discretas).
- **IGP-M:** mantido como **variação % mensal** (já estacionário).
- **Focus:** mediana **ex-ante** (última leitura antes do mês de referência).

A justificativa formal de cada transformação está em `docs/02_ESTRATEGIA_DADOS.md`.

## 3. Estatísticas descritivas

- **Onde:** `scripts/03_exploratory_analysis.R`
- **Saída:** `output/tables/estatisticas_descritivas.csv`
- **Conteúdo:** média, desvio-padrão, mínimo, máximo, e autocorrelação de ordem 1 (`acf1`)
  de cada série. O **desvio-padrão** mede volatilidade; o **acf1** mede persistência.
  Esses dois números alimentam diretamente a comparação cheio × núcleo (Parte 7).

## 4. Teste ADF (Augmented Dickey-Fuller)

- **Onde:** `scripts/04_stationarity_tests.R` (`tseries::adf.test`)
- **Hipótese nula:** a série **tem raiz unitária** (é não estacionária).
- **Leitura:** p-valor **baixo** (< 0,05) ⟹ **rejeita** H0 ⟹ série estacionária.
- **Saída:** `output/tables/testes_estacionariedade.csv`.

## 5. Teste KPSS

- **Onde:** `scripts/04_stationarity_tests.R` (`tseries::kpss.test`, `null = "Level"`)
- **Hipótese nula:** a série **é estacionária** (em torno de um nível) — *é o oposto do ADF*.
- **Leitura:** p-valor **baixo** ⟹ **rejeita** estacionariedade.
- **Por que os dois juntos:** ADF e KPSS têm hipóteses nulas invertidas. Quando
  **ADF rejeita** e **KPSS não rejeita**, há evidência robusta de estacionariedade.
  Resultados conflitantes sinalizam fronteira (raiz quase unitária) e justificam cautela.
- **Saída:** mesma tabela (`testes_estacionariedade.csv`), com coluna de conclusão prática.

## 6. Autocorrelação (ACF) e autocorrelação parcial (PACF)

- **Onde:** `scripts/03_exploratory_analysis.R`
- **Saídas:**
  - `output/figures/03_acf_pacf_ipca.png`
  - `output/figures/04_acf_pacf_nucleo.png`
- **Para que serve:** a ACF sugere a ordem **MA (q)** e a PACF sugere a ordem **AR (p)**.
  Picos nas defasagens **12, 24** indicam **sazonalidade** anual, motivando o salto de
  ARIMA para SARIMA. (A escolha final das ordens, porém, é feita pelo `auto.arima`,
  que minimiza AICc; a inspeção gráfica é confirmatória.)
- **Sazonalidade visual:** `output/figures/05_sazonalidade_ipca.png` (seasonal plot).

## 7. Diagnóstico dos resíduos + Ljung-Box

- **Onde:** `scripts/05_arima_sarima_models.R`, função `diagnosticar()` com
  `forecast::checkresiduals`.
- **Saídas:**
  - Figuras `output/figures/resid_<serie>_<modelo>.png` (resíduo, ACF do resíduo, histograma).
  - Tabela `output/tables/ljungbox_univariados.csv` com o p-valor do **teste de Ljung-Box**.
- **Teste de Ljung-Box** — H0: os resíduos **não têm autocorrelação** (são ruído branco).
  - p-valor **alto** (> 0,05) ⟹ **não rejeita** ⟹ resíduos "limpos" ⟹ modelo bem especificado.
  - p-valor **baixo** ⟹ ainda há estrutura não capturada ⟹ revisar ordens.

## 8. Comparação de AIC e BIC

- **Onde:** o motor `rodar_modelo()` (em `R/utils.R`) guarda `aic` e `bic` de **cada** modelo;
  consolidados em `scripts/07_forecast_evaluation.R` e exportados via Parte 8.
- **Leitura:** menor AIC/BIC ⟹ melhor compromisso ajuste × parcimônia **dentro da amostra**.
  AIC/BIC são critérios **in-sample** e servem para escolher entre especificações próximas,
  mas **não substituem** a avaliação fora da amostra.

## 9. Avaliação fora da amostra — RMSE e MAE

- **Onde:** motor `rodar_modelo()` + `scripts/07_forecast_evaluation.R`.
- **Mecânica anti-look-ahead:**
  1. `mod_full` = `auto.arima` na **amostra completa** → fornece coeficientes, AIC, BIC.
  2. `mod_train` = `auto.arima` **somente no treino** (tudo menos os últimos `n_test = 24` meses).
  3. Previsão dos 24 meses de teste com `mod_train` → comparada ao **observado**.
- **RMSE** (Root Mean Squared Error): penaliza mais os **erros grandes** (eleva ao quadrado).
- **MAE** (Mean Absolute Error): erro médio absoluto, em **pontos percentuais de inflação**,
  interpretação direta.
- **Saídas:** `output/tables/comparacao_ipca.csv`, `output/tables/comparacao_nucleo.csv`
  e a tabela mestra `output/tables/tabela_mestra_rmse_mae.csv`.
- **Nota sobre SARIMAX:** no teste, as regressoras de câmbio, Selic e IGP-M usam o valor
  **realizado** (previsão condicional / *ex-post*) — isso é uma **limitação** declarada,
  pois na prática esses valores não seriam conhecidos. A exceção é o **Focus**, que é
  genuinamente **ex-ante** (expectativa formada antes do mês).

---

### Resumo: qual diagnóstico responde a qual pergunta

| Pergunta | Diagnóstico | Arquivo |
|---|---|---|
| A série é estacionária? | ADF + KPSS | `testes_estacionariedade.csv` |
| Quais ordens (p, q)? | ACF / PACF + `auto.arima` | figuras 03/04 |
| Há sazonalidade? | seasonal plot + lags 12/24 | figura 05 |
| O modelo está bem especificado? | Ljung-Box nos resíduos | `ljungbox_univariados.csv` |
| Qual ajuste in-sample é melhor? | AIC / BIC | tabela mestra |
| Qual prevê melhor fora da amostra? | RMSE / MAE | `comparacao_*.csv` |
