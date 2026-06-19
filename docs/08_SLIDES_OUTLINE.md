# Parte 8 — Estrutura dos slides finais

Apresentação de **14 slides**, montada em cima da rubrica do **Tema 3** (cada slide
indica o critério que atende e os pontos). Para cada slide: **título**, **conteúdo**,
**visual** (arquivo gerado pelo pipeline) e uma **fala curta** para a defesa oral.
Os números já estão preenchidos a partir dos CSVs de `output/`.

> Deck pronto: `Previsao_Inflacao_Brasileira.pptx`. As falas curtas de cada slide também
> estão nas **notas do apresentador** do arquivo (Modo Apresentador), em versão mais longa,
> servindo como o relatório detalhado de análise, tratamento e interpretação.

Mapa rubrica → slides: **Análise exploratória (1,5)** S3–S4 · **Transformações e
estacionariedade (1,5)** S5 · **Modelagem (2,0)** S6–S7 · **Variáveis externas (1,0)** S8 ·
**Avaliação fora da amostra (2,0)** S9–S11 · **Comparação (1,5)** S12 (+ S13) ·
**Qualidade do código (0,5)** S14.

---

### Slide 1 — Título e integrantes
- **Conteúdo:** "Previsão da Inflação Brasileira"; subtítulo ARIMA → SARIMA → SARIMAX,
  cheio × núcleo; disciplina (Programação e Resolução de Problemas — FGV); integrantes:
  Hector Sabadell, Rafael Machado, Theodoro Mota, Thiago Barbosa.
- **Visual:** capa escura com motivo gráfico.
- **Fala:** "Prevemos a inflação brasileira comparando o IPCA cheio e o núcleo por médias
  aparadas, com modelos econométricos de séries temporais em R."

### Slide 2 — Pergunta de pesquisa e dados
- **Conteúdo:** pergunta (regressoras macro melhoram a previsão vs. modelos só
  autorregressivos? o ganho difere entre cheio e núcleo?); amostra mensal jan/2004–mai/2025
  (257 obs.); holdout de 24 meses; fontes SGS/BCB via `rbcb` (IPCA 433, núcleo 4466, câmbio 1,
  Selic 432, IGP-M 189, Focus). Nota metodológica do código do núcleo (4466, não 11427/EX0).
- **Visual:** card da pergunta + tabela de fontes.
- **Fala:** "Queremos saber se câmbio, Selic, IGP-M e Focus melhoram a previsão — e se isso
  vale igualmente para o índice cheio e para o núcleo. Todos os dados são públicos e por API."

### Slide 3 — Análise exploratória das séries  · Critério 1 (1,5)
- **Conteúdo:** descritivas — média ≈ 0,46% (cheio) e 0,45% (núcleo); desvio-padrão 0,33 vs
  0,18; o cheio é ~2× mais volátil. Choques de alimentos, energia e administrados inflam a
  variância do cheio; o núcleo, mais suave, antecipa a tendência.
- **Visual:** `output/figures/01_series_inflacao.png` + cards de estatística.
- **Fala:** "O cheio oscila muito mais que o núcleo (DP 0,33 vs 0,18) — primeira pista de que
  o núcleo deve ser mais previsível."

### Slide 4 — Autocorrelação e sazonalidade  · Critério 1 (1,5)
- **Conteúdo:** diagnóstico técnico — PACF corta após o 1º lag (AR de ordem baixa); ACF com
  picos a cada 12 meses → termo sazonal do SARIMA. Leitura econômica — sazonalidade vem do
  calendário de preços (mensalidades escolares, safra/entressafra, reajustes de serviços); a
  persistência do 1º lag é a inércia inflacionária (indexação de contratos e salários).
- **Visual:** `03_acf_pacf_ipca.png` + `05_sazonalidade_ipca.png`.
- **Fala:** "A sazonalidade não é acidente: é o calendário de preços do Brasil. E a
  persistência é a inércia inflacionária, ligada à indexação."

### Slide 5 — Transformações e estacionariedade  · Critério 2 (1,5)
- **Conteúdo:** ADF (H₀: raiz unitária) + KPSS (H₀: estacionária). IPCA já é variação % →
  estacionário em nível, `d = 0` (diferenciar introduziria ruído); câmbio diário → média
  mensal → variação %; Selic não-estacionária em nível, usada como **regressora exógena**, não
  diferenciada. Por que importa: estacionariedade do IPCA é coerente com o regime de metas
  (reverte à meta); Selic segue ciclos longos de política monetária.
- **Visual:** `output/tables/testes_estacionariedade.csv` (transcrita) + box econômico.
- **Fala:** "Os testes confirmam modelar em variação, sem diferenciação extra na maioria dos
  casos. A estacionariedade do IPCA é o que se espera sob metas de inflação críveis."

### Slide 6 — Estratégia de modelagem  · Critério 3 (2,0)
- **Conteúdo:** seis modelos aninhados, ordens por `auto.arima` (mínimo AICc).
  M1 ARIMA · M2 SARIMA (sazonal) · M3 +câmbio (repasse) · M4 +Selic (política monetária) ·
  M5 +IGP-M (custos) · M6 +Focus (expectativas). Ordens: cheio (1,0,0)(0,0,1)[12];
  núcleo (1,0,1)(2,0,0)[12]. Seleção final = menor RMSE fora da amostra.
- **Visual:** grade de 6 cards M1–M6.
- **Fala:** "Partimos do passado da série e acrescentamos sazonalidade e, depois, informação
  macro, uma regressora por vez."

### Slide 7 — Diagnóstico de resíduos (Ljung-Box)  · Critério 3 (2,0)
- **Conteúdo:** H₀ = resíduos sem autocorrelação. ARIMA puro do núcleo falha (p=0,0002) →
  SARIMA corrige (p=0,104); modelos do cheio passam (M2 p=0,382; M6 p=0,475). Leitura
  econômica: resíduos sem padrão = modelo captou o sistemático (inércia, sazonalidade, drivers
  macro); o que resta são choques imprevisíveis.
- **Visual:** `resid_ipca_m6.png` + lista de p-valores.
- **Fala:** "Quando os resíduos viram ruído branco, extraímos toda a parte previsível; o resto
  são surpresas que nenhum modelo anteciparia."

### Slide 8 — Regressoras: sinais e significância  · Critério 4 (1,0)
- **Conteúdo:** coeficientes do melhor modelo de cada série.
  Cheio (M6): Focus +1,12 (p<0,001), IGP-M +0,11 (p<0,001), Selic −0,006 (p=0,019),
  Δcâmbio −0,004 (n.s.). Núcleo (M5): IGP-M +0,028 (p=0,001), Selic +0,021 (p=0,007),
  Δcâmbio −0,001 (n.s.), AR(1) +0,90. Leitura: Focus domina o cheio (repasse ≈ 1-para-1);
  no núcleo a inércia é o motor; câmbio não significativo em nenhum.
- **Visual:** dois cards de coeficientes (cheio × núcleo).
- **Fala:** "No cheio, a expectativa Focus é a regressora mais forte. No núcleo, domina a
  inércia (AR≈0,9). O câmbio não foi significativo."

### Slide 9 — Avaliação fora da amostra  · Critério 5 (2,0)
- **Conteúdo:** RMSE no holdout dos últimos 24 meses (previsão condicional às regressoras
  realizadas). Queda do RMSE M2→M6: cheio −53%, núcleo −10%.
- **Visual:** gráfico de barras nativo (RMSE M1–M6, cheio × núcleo) + cards 53% / 10%.
- **Fala:** "No cheio, o erro despenca no M6 — as regressoras cortam o RMSE pela metade. No
  núcleo, o melhor é o M5, e o ganho é modesto."

### Slide 10 — Resultados: IPCA cheio  · Critério 5 (2,0)
- **Conteúdo:** melhor modelo = M6 (SARIMAX completo); RMSE 0,125; MAE 0,099. A expectativa
  Focus carrega informação prospectiva que o passado do IPCA não tem.
- **Visual:** `output/figures/forecast_ipca.png` + cards RMSE/MAE.
- **Fala:** "Para o cheio, o melhor desempenho foi do M6, com RMSE 0,125. A previsão acompanha
  bem o observado; o ganho vem da Focus."

### Slide 11 — Resultados: Núcleo  · Critério 5 (2,0)
- **Conteúdo:** melhor modelo = M5 (sem Focus); RMSE 0,125; MAE 0,100. Alta persistência
  (AR≈0,9) faz o próprio passado explicar quase tudo. (M6 tem AIC menor, mas o critério é
  menor RMSE fora da amostra → M5.)
- **Visual:** `output/figures/forecast_nucleo.png` + cards RMSE/MAE.
- **Fala:** "No núcleo, o melhor é o M5. A série é muito inercial, então acrescentar Focus não
  melhora a previsão."

### Slide 12 — Comparação: cheio × núcleo  · Critério 6 (1,5)
- **Conteúdo:** volatilidade 0,328 vs 0,179; persistência (ACF lag 1) 0,551 vs 0,822;
  melhor RMSE 0,1248 vs 0,1253; ganho com regressoras 53,1% vs 10,1%. Insight: regressoras
  agregam mais quando a série é volátil e sensível a choques (cheio); quando é suave e
  inercial (núcleo), o autorregressivo já esgota o sinal.
- **Visual:** `output/tables/comparacao_cheio_vs_nucleo.csv` + card "O que separa os dois".
- **Fala:** "O cheio é mais volátil e menos persistente, e ganha 53% com regressoras; o núcleo
  ganha só 10%. A condição que separa os dois é a volatilidade."

### Slide 13 — Conclusões
- **Conteúdo:** (1) regressoras agregam, sobretudo no cheio (M6, −53%, Focus decisiva);
  (2) no núcleo a inércia domina (M5, ganho ~10%); (3) a resposta depende da natureza da
  série. Faixa "Objetivos do trabalho — cumpridos": tratamento & estacionariedade; modelagem
  ARIMA·SARIMA·SARIMAX; avaliação RMSE/MAE; discussão do melhor modelo.
- **Visual:** três cards + faixa de objetivos.
- **Fala:** "Respondendo à pergunta: as regressoras melhoram a previsão, principalmente no
  cheio. O valor da informação macro depende de quão volátil é a série."

### Slide 14 — Limitações e reprodutibilidade  · Critério 7 (0,5)
- **Conteúdo:** limitações — previsão condicional (regressoras realizadas no teste, exceto
  Focus); holdout fixo (sem rolling origin); quebras estruturais (2008, 2015–16, pandemia);
  modelos lineares; ordens automáticas; definição de núcleo (4466 vs 11427/EX0).
  Reprodutibilidade — `Rscript main.R` roda 01→08; dados por API (nada fixado no código);
  estrutura modular; fallback de cache local.
- **Visual:** dois cards (limitações × reprodutibilidade).
- **Fala:** "Somos transparentes: o ganho do SARIMAX é em parte otimista, e há choques que
  desafiam qualquer modelo linear. Mas o trabalho roda inteiro com um comando."

---

## Resumo dos arquivos usados nos slides

| Slide | Critério | Arquivo principal |
|---|---|---|
| 3 | 1 | `output/figures/01_series_inflacao.png`, `estatisticas_descritivas.csv` |
| 4 | 1 | `output/figures/03_acf_pacf_ipca.png`, `05_sazonalidade_ipca.png` |
| 5 | 2 | `output/tables/testes_estacionariedade.csv` |
| 6 | 3 | `comparacao_ipca.csv`, `comparacao_nucleo.csv` (ordens) |
| 7 | 3 | `output/figures/resid_ipca_m6.png`, `ljungbox_*.csv` |
| 8 | 4 | `coeficientes_melhor_ipca.csv`, `coeficientes_melhor_nucleo.csv` |
| 9 | 5 | `output/tables/tabela_mestra_rmse_mae.csv` (gráfico de barras) |
| 10 | 5 | `output/figures/forecast_ipca.png`, `comparacao_ipca.csv` |
| 11 | 5 | `output/figures/forecast_nucleo.png`, `comparacao_nucleo.csv` |
| 12 | 6 | `output/tables/comparacao_cheio_vs_nucleo.csv` |
| 13 | — | síntese (conclusões + objetivos cumpridos) |
| 14 | 7 | lista (limitações + reprodutibilidade) |
