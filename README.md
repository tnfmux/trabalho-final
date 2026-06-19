# Previsão da Inflação Brasileira — IPCA Cheio vs. Núcleo

Trabalho final da disciplina **Programação e Resolução de Problemas** — Tema 3:
*Previsão da inflação brasileira com modelos econométricos*.

Projeto em **R**, totalmente reprodutível, que coleta dados públicos do Banco Central
por API, trata as séries, estima modelos **ARIMA → SARIMA → SARIMAX** e avalia a
previsão **fora da amostra** por **RMSE** e **MAE**, comparando o **IPCA cheio (headline)**
com o **núcleo por médias aparadas**.

---

## Pergunta de pesquisa

> Modelos econométricos com regressoras macroeconômicas melhoram a previsão da inflação
> brasileira em relação a modelos puramente autorregressivos? Esse ganho é diferente para
> o IPCA cheio e para o núcleo de inflação?

---

## Como rodar (resumo)

```bash
# na raiz do projeto
Rscript main.R
```

Isso instala os pacotes (1ª vez), baixa os dados por API, trata as séries, roda os
testes e os modelos e gera todas as figuras e tabelas em `output/`. Precisa de **internet**
(APIs do BCB) e **R ≥ 4.x**.

> Passos detalhados (terminal, VSCode, verificação) estão em `docs/10_CHECKLIST.md`.

---

## Estrutura do projeto

```
trabalho_previsao_inflacao/
├── data/
│   ├── raw/              # séries brutas baixadas por API (.rds)
│   └── processed/        # base_mensal.csv + objetos de resultado (.rds)
├── output/
│   ├── figures/          # gráficos (.png)
│   ├── tables/           # tabelas de resultado (.csv)
│   └── forecasts/        # previsões fora da amostra (.csv)
├── scripts/
│   ├── 01_download_data.R      # coleta SGS (rbcb) + Focus
│   ├── 02_prepare_data.R       # tratamento e alinhamento mensal
│   ├── 03_exploratory_analysis.R # gráficos, descritivas, ACF/PACF
│   ├── 04_stationarity_tests.R   # ADF + KPSS
│   ├── 05_arima_sarima_models.R  # M1 (ARIMA) e M2 (SARIMA)
│   ├── 06_sarimax_models.R       # M3–M6 (SARIMAX cumulativos)
│   ├── 07_forecast_evaluation.R  # RMSE/MAE, melhor modelo, gráficos
│   └── 08_generate_outputs.R     # tabelas mestras + comparação + coeficientes
├── R/
│   └── utils.R           # funções de apoio (motor de estimação/avaliação)
├── docs/                 # textos do relatório (Partes 1,2,4,5,7,9,10)
├── config.R              # parâmetros globais (datas, códigos SGS, n_test)
├── requirements.R        # pacotes necessários
├── main.R                # orquestrador: roda 01→08 em sequência
├── slides_outline.md     # estrutura dos 14 slides (Parte 8)
└── README.md
```

---

## Dados e fontes (todas públicas — SGS/BCB via `rbcb`)

| Série | Código SGS | Frequência | Tratamento |
|---|---|---|---|
| IPCA cheio (headline), var % mensal | **433** | mensal | usado direto |
| Núcleo IPCA — médias aparadas c/ suavização, var % | **4466** | mensal | usado direto |
| Meta Selic (Copom), % a.a. | **432** | em datas de reunião | valor de **fim de mês** |
| Câmbio R$/US$ (venda) | **1** | diária | **média mensal → variação %** |
| IGP-M (FGV), var % mensal | **189** | mensal | usado direto |
| Expectativa Focus (IPCA) | API de expectativas de mercado | diária | **mediana ex-ante** mensal |

> **Observação metodológica importante (núcleo):** o enunciado citava o código **11427**
> como "núcleo por médias aparadas". Conferindo o Portal de Dados Abertos do BCB, **11427
> é, na verdade, o núcleo por EXCLUSÃO (IPCA-EX0)**, não por médias aparadas. O núcleo por
> **médias aparadas com suavização** corresponde ao código **4466**, que adotamos por
> coerência com a metodologia declarada. Para reproduzir com EX0, basta alterar
> `nucleo = 11427` em `config.R`.

---

## Modelos estimados (para IPCA cheio e para núcleo)

| Modelo | Especificação |
|---|---|
| M1 | ARIMA univariado |
| M2 | SARIMA (com componente sazonal) |
| M3 | SARIMAX + câmbio |
| M4 | SARIMAX + câmbio + Selic |
| M5 | SARIMAX + câmbio + Selic + IGP-M |
| M6 | SARIMAX + câmbio + Selic + IGP-M + Focus |

Avaliação: **holdout** dos últimos `n_test = 24` meses; ordens escolhidas por `auto.arima`
(minimiza AICc); critério de seleção final = **menor RMSE fora da amostra**.

---

## Pacotes (ver `requirements.R`)

`rbcb`, `tidyverse`, `lubridate`, `zoo`, `forecast`, `tseries`, `urca`, `Metrics`,
`tsibble`, `feasts`, `fable`.

---

## Documentação (pasta `docs/`)

- `01_PLANO.md` — plano completo (pergunta, motivação, hipóteses, metodologia).
- `02_ESTRATEGIA_DADOS.md` — coleta e tratamento das séries.
- `04_MODELOS.md` — explicação de ARIMA/SARIMA/SARIMAX e dos canais econômicos.
- `05_DIAGNOSTICOS.md` — testes e diagnósticos (ADF, KPSS, ACF/PACF, Ljung-Box, RMSE/MAE).
- `07_COMPARACAO.md` — comparação IPCA cheio × núcleo.
- `09_INTERPRETACAO.md` — texto interpretativo acadêmico (parágrafos prontos).
- `10_CHECKLIST.md` — checklist de entrega + instruções finais.

---

## Limitações principais

Previsão condicional do SARIMAX (regressoras realizadas no teste, exceto Focus);
holdout fixo (sem *rolling origin*); quebras estruturais no período (2008, 2015–16,
pandemia); linearidade dos modelos; escolha automática de ordens; sensibilidade à
definição de núcleo. Detalhes em `docs/09_INTERPRETACAO.md` (seção 9.6).

---

## Reprodutibilidade

Todos os dados são baixados por API a cada execução; nenhum número é "chumbado" no
código. Para fixar uma versão dos dados, salve os `.rds` de `data/raw/` junto ao projeto.
