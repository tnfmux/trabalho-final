# Parte 10 — Checklist final de entrega

Marque cada item **depois de rodar o pipeline** na sua máquina. O checklist segue a
ordem natural de execução e verificação.

## Checklist de itens

- [ ] **Código executa do zero** — `Rscript main.R` roda sem erro num ambiente limpo.
- [ ] **APIs funcionando** — `rbcb::get_series` (SGS) e `get_market_expectations` (Focus)
      retornaram dados (precisa de internet; o BCB não exige chave).
- [ ] **Dados brutos salvos** — arquivos `.rds` em `data/raw/`.
- [ ] **Dados tratados salvos** — `data/processed/base_mensal.csv` existe e tem as colunas
      `mes, ipca, nucleo, igpm, cambio_med, selic_fim, focus, dcambio` (a coluna de data
      chama-se `mes`, com o 1º dia de cada mês).
- [ ] **Gráficos gerados** — 5 figuras em `output/figures/` (séries, regressoras, ACF/PACF
      ×2, sazonalidade) + `forecast_ipca.png` e `forecast_nucleo.png`.
- [ ] **Tabelas de modelos geradas** — `comparacao_ipca.csv`, `comparacao_nucleo.csv`,
      `tabela_mestra_rmse_mae.csv` em `output/tables/`.
- [ ] **Previsões salvas** — `output/forecasts/forecast_ipca.csv` e `forecast_nucleo.csv`.
- [ ] **RMSE e MAE calculados** — presentes nas tabelas de comparação.
- [ ] **Slides completos** — 14 slides montados a partir de `slides_outline.md`, com os
      números preenchidos a partir dos CSVs.
- [ ] **README com instruções** — `README.md` na raiz.
- [ ] **Pacotes listados** — `requirements.R` instala/carrega todas as dependências.
- [ ] **Fontes citadas** — BCB/SGS e códigos das séries no `docs/01_PLANO.md` e no README.
- [ ] **Limitações declaradas** — `docs/09_INTERPRETACAO.md` (seção 9.6) e slide 13.
- [ ] **Interpretação econômica incluída** — `docs/04_MODELOS.md`, `07_COMPARACAO.md`,
      `09_INTERPRETACAO.md`.

---

## Instruções finais

### 1. Quais arquivos criar/conferir primeiro
A ordem de **dependência** é:
1. `requirements.R` (instala pacotes).
2. `config.R` (parâmetros — confira datas e o código do núcleo).
3. `R/utils.R` (funções de apoio).
4. `main.R` (orquestrador).
5. Os `scripts/01..08` rodam **nessa ordem** automaticamente via `main.R`.

Você não precisa criar nada à mão: tudo já está no projeto. Só **abra `config.R`** e
ajuste, se quiser, `n_test`, `data_inicio` ou o código do núcleo.

### 2. Qual comando rodar no terminal
Na raiz do projeto (`trabalho_previsao_inflacao/`):
```bash
Rscript main.R
```
Na primeira execução, a instalação dos pacotes pode demorar alguns minutos.
Para rodar um passo isolado depois, por exemplo só os outputs:
```bash
Rscript scripts/08_generate_outputs.R
```

### 3. Como abrir e executar no VSCode
1. Instale o **R** (≥ 4.x) e, no VSCode, a extensão **"R" (REditorSupport)**.
2. (Recomendado) no R: `install.packages("languageserver")` para autocompletar/lint.
3. `File → Open Folder…` e selecione `trabalho_previsao_inflacao/`.
4. Abra `main.R`. Use o **terminal integrado** (`Ctrl+`` ) e rode `Rscript main.R`,
   ou abra um terminal R interativo e execute `source("main.R")`.
5. Para rodar linha a linha, posicione o cursor e use `Ctrl+Enter` (envia ao terminal R).

### 4. Como verificar se tudo funcionou
- O terminal deve terminar **sem mensagens de erro** (avisos/`Warning` de pacote são ok).
- Confira que existem arquivos novos em `data/raw/`, `data/processed/`,
  `output/figures/`, `output/tables/` e `output/forecasts/`.
- Abra `output/tables/tabela_mestra_rmse_mae.csv`: deve ter linhas para M1–M6 e colunas
  de RMSE/MAE para IPCA e núcleo, **com números preenchidos** (sem `NA` em toda a coluna).
- Abra uma figura `forecast_*.png` e veja se a linha prevista acompanha a observada.

### 5. Quais resultados olhar antes de montar os slides
Nesta ordem:
1. `output/tables/tabela_mestra_rmse_mae.csv` — **quem prevê melhor** (slide 11).
2. `output/tables/comparacao_ipca.csv` e `comparacao_nucleo.csv` — melhor modelo de
   cada série e seus AIC/BIC/RMSE/MAE (slides 9 e 10).
3. `output/tables/comparacao_cheio_vs_nucleo.csv` — volatilidade, persistência,
   previsibilidade, ganho das regressoras (slide 12).
4. `output/tables/coeficientes_melhor_ipca.csv` / `coeficientes_melhor_nucleo.csv` —
   sinais e significância das regressoras (apoio aos slides 9, 10 e 12).
5. `output/figures/forecast_ipca.png` e `forecast_nucleo.png` — gráficos previsão ×
   observado (slides 9 e 10).
6. `output/tables/ljungbox_univariados.csv` — validação dos resíduos (apoio ao slide 8).

Com esses arquivos abertos, preencha as lacunas `[___]` de `slides_outline.md` e de
`docs/09_INTERPRETACAO.md`.
