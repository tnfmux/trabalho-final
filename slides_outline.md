# Parte 8 — Estrutura dos slides finais

Apresentação de **14 slides**. Para cada um: **título**, **bullets objetivos**,
**gráfico/tabela sugerida** (com o arquivo exato gerado pelo pipeline) e uma **fala
curta** para a defesa oral. Onde houver número empírico, há lacuna `[___]` a preencher
com o resultado do código.

> Dica: monte os slides **só depois** de rodar `Rscript main.R` e abrir os CSVs/figuras
> de `output/`. Veja a ordem de leitura em `docs/10_CHECKLIST.md`.

---

### Slide 1 — Título e integrantes
- **Bullets:** Título do trabalho; disciplina (Programação e Resolução de Problemas);
  nomes dos integrantes; data.
- **Visual:** capa limpa, talvez um recorte da figura `01_series_inflacao.png` ao fundo.
- **Fala:** "Nosso trabalho prevê a inflação brasileira comparando o IPCA cheio e o núcleo
  por médias aparadas, usando modelos econométricos de séries temporais em R."

### Slide 2 — Pergunta de pesquisa
- **Bullets:**
  - Regressoras macroeconômicas melhoram a previsão da inflação vs. modelos só autorregressivos?
  - Esse ganho é diferente para o IPCA cheio e para o núcleo?
- **Visual:** a pergunta em destaque, sem gráfico.
- **Fala:** "Queremos saber se adicionar câmbio, Selic, IGP-M e expectativas Focus melhora
  a previsão — e se isso vale igualmente para o índice cheio e para o núcleo."

### Slide 3 — Motivação macroeconômica
- **Bullets:** regime de metas desde ~2004; previsão guia a Selic; headline tem ruído de
  alimentos/energia; núcleo isola a tendência persistente.
- **Visual:** `output/figures/01_series_inflacao.png` (cheio × núcleo).
- **Fala:** "Prever inflação tem custo real: erra a previsão, erra a política de juros.
  Por isso separar o ruído transitório da tendência é tão importante."

### Slide 4 — Dados e fontes
- **Bullets:** SGS/BCB via pacote `rbcb`; IPCA 433; núcleo médias aparadas 4466; Selic 432;
  câmbio 1; IGP-M 189; Focus via API de expectativas de mercado. Amostra: jan/2004 → hoje.
- **Visual:** tabela de fontes (a do `docs/01_PLANO.md`).
- **Fala:** "Todos os dados são públicos e baixados por API, o que garante reprodutibilidade
  total." *(Mencionar a correção do código do núcleo — ver slide 13/observação.)*

### Slide 5 — Tratamento das séries
- **Bullets:** câmbio diário → variação % da média mensal (*pass-through*); Selic → fim de mês;
  IGP-M/IPCA/núcleo → mensais; Focus → mediana ex-ante (última antes do mês de referência);
  alinhamento mensal e tratamento de NA.
- **Visual:** `output/figures/02_regressoras.png`.
- **Fala:** "Cada série recebe o tratamento coerente com sua natureza econômica e frequência,
  com regras explícitas e reprodutíveis."

### Slide 6 — Metodologia: ARIMA, SARIMA e SARIMAX
- **Bullets:** ARIMA (p,d,q) capta inércia; SARIMA acrescenta sazonalidade (P,D,Q)[12];
  SARIMAX adiciona regressoras externas; 6 modelos por série (M1→M6).
- **Visual:** diagrama simples ARIMA → SARIMA → SARIMAX (pode ser texto/esquema).
- **Fala:** "Partimos do mais simples — só o passado da série — e vamos acrescentando
  sazonalidade e, depois, informação macroeconômica, modelo a modelo."

### Slide 7 — Análise exploratória
- **Bullets:** estatísticas descritivas (média, desvio-padrão, persistência); cheio mais
  volátil que núcleo *(confirmar)*.
- **Visual:** `output/tables/estatisticas_descritivas.csv` (transcrita) + ACF/PACF
  (`03_acf_pacf_ipca.png`).
- **Fala:** "Já na exploração vemos que o cheio oscila mais e o núcleo é mais suave —
  primeira pista de que o núcleo deve ser mais previsível."

### Slide 8 — Estacionariedade e transformações
- **Bullets:** ADF (H0: raiz unitária) + KPSS (H0: estacionária); séries de inflação já são
  variações % → `d = 0`; regressoras de nível transformadas para estacionariedade.
- **Visual:** `output/tables/testes_estacionariedade.csv`.
- **Fala:** "Os testes confirmam que podemos modelar as séries em variação, sem
  diferenciação adicional na maioria dos casos."

### Slide 9 — Resultados para o IPCA cheio
- **Bullets:** tabela M1–M6 com AIC, BIC, RMSE, MAE; melhor modelo = `[___]`;
  RMSE = `[___]`, MAE = `[___]`.
- **Visual:** `output/figures/forecast_ipca.png` + `output/tables/comparacao_ipca.csv`.
- **Fala:** "Para o cheio, o melhor desempenho fora da amostra foi do modelo `[___]`,
  o que sugere que `[regressoras ajudaram / a dinâmica autorregressiva bastou]`."

### Slide 10 — Resultados para o núcleo
- **Bullets:** tabela M1–M6; melhor modelo = `[___]`; RMSE = `[___]`, MAE = `[___]`.
- **Visual:** `output/figures/forecast_nucleo.png` + `output/tables/comparacao_nucleo.csv`.
- **Fala:** "No núcleo, o melhor modelo foi `[___]`. Como esperado, o erro de previsão
  tende a ser menor que o do cheio."

### Slide 11 — Comparação dos modelos por RMSE e MAE
- **Bullets:** tabela mestra lado a lado (cheio × núcleo, M1–M6); RMSE penaliza erros
  grandes; MAE em p.p. de inflação; menor é melhor.
- **Visual:** `output/tables/tabela_mestra_rmse_mae.csv`.
- **Fala:** "Esta tabela é o coração do trabalho: ela mostra, modelo a modelo, quem prevê
  melhor — e o critério de decisão é o RMSE fora da amostra."

### Slide 12 — Comparação IPCA cheio versus núcleo
- **Bullets:** volatilidade; persistência; previsibilidade; onde as regressoras ajudam mais;
  núcleo com menor erro *(confirmar)*; cheio mais sensível a câmbio/IGP-M *(confirmar)*.
- **Visual:** `output/tables/comparacao_cheio_vs_nucleo.csv`.
- **Fala:** "O núcleo é mais suave, mais persistente e mais previsível; o cheio é mais
  volátil e mais dependente de informação externa. Isso confirma a ideia de separar
  choque transitório de componente persistente."

### Slide 13 — Limitações
- **Bullets:** SARIMAX usa regressoras realizadas no teste (previsão condicional/ex-post,
  exceto Focus); holdout fixo (sem rolling); quebras estruturais (2008/2016/pandemia);
  linearidade; escolha automática de ordens; definição de núcleo (4466 vs 11427/EX0).
- **Visual:** lista; opcionalmente destacar a nota do código do núcleo.
- **Fala:** "Somos transparentes quanto aos limites: o ganho do SARIMAX é, em parte,
  otimista, e há choques no período que desafiam qualquer modelo linear."

### Slide 14 — Conclusão
- **Bullets:** resposta à pergunta de pesquisa (regressoras `[ajudaram/não ajudaram]`,
  `[mais/menos]` no cheio); núcleo mais previsível *(confirmar)*; implicação de política;
  reprodutibilidade total (código + API).
- **Visual:** síntese / recados finais.
- **Fala:** "Concluímos que `[síntese conforme os números]`. O componente persistente da
  inflação é bem capturado por modelos autorregressivos, enquanto o componente transitório
  do índice cheio se beneficia mais da informação macroeconômica externa."

---

## Resumo dos arquivos a usar nos slides

| Slide | Arquivo principal |
|---|---|
| 3 | `output/figures/01_series_inflacao.png` |
| 5 | `output/figures/02_regressoras.png` |
| 7 | `output/tables/estatisticas_descritivas.csv`, `output/figures/03_acf_pacf_ipca.png` |
| 8 | `output/tables/testes_estacionariedade.csv` |
| 9 | `output/figures/forecast_ipca.png`, `output/tables/comparacao_ipca.csv` |
| 10 | `output/figures/forecast_nucleo.png`, `output/tables/comparacao_nucleo.csv` |
| 11 | `output/tables/tabela_mestra_rmse_mae.csv` |
| 12 | `output/tables/comparacao_cheio_vs_nucleo.csv` |
