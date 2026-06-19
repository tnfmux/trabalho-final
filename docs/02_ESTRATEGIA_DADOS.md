# Parte 2 — Estratégia de dados

## 2.1 Coleta via API
Toda a coleta usa o pacote **`rbcb`**, que conversa com os web services do Banco Central.

### Séries do SGS
```r
rbcb::get_series(c(ipca = 433), start_date = "2004-01-01")
```
`get_series` aceita um vetor nomeado `c(nome = codigo)` e devolve um *tibble* com `date` e a
série. No projeto, a função `baixar_sgs()` (script 01) padroniza tudo para colunas
`data`, `valor`.

### Expectativas Focus
```r
rbcb::get_market_expectations(type = "monthly", indic = "IPCA",
                              start_date = "2004-01-01")
```
Retorna, para cada **data de pesquisa** e cada **mês de referência** (`DataReferencia`,
formato `"MM/AAAA"`), as estatísticas do Focus: `Media`, `Mediana`, `DesvioPadrao`,
`Minimo`, `Maximo`, `numeroRespondentes`, `baseCalculo`. Usamos a **mediana**, mais robusta
a outliers do que a média.

## 2.2 Tratamento por frequência
O desafio central é alinhar séries de frequências diferentes numa **base mensal única**,
com âncora no 1º dia de cada mês (`lubridate::floor_date(data, "month")`).

| Série | Regra de agregação | Justificativa econômica |
|---|---|---|
| Câmbio (diário) | **Média mensal** | A média captura melhor o nível cambial "sentido" pelos preços ao longo do mês; depois usamos a **variação % mensal** (repasse cambial). |
| Selic meta | **Valor vigente no fim do mês** | A meta muda em datas discretas do Copom; o relevante é a postura de política em vigor ao fim do mês. |
| IPCA, núcleo, IGP-M | **Mantidos mensais** | Já são variações % mensais. |
| Focus | **Última leitura ex-ante** | Mediana da pesquisa mais recente divulgada **antes** do início do mês de referência → regressora genuinamente *forward-looking*. |

### Câmbio: por que média mensal e depois variação
O nível do câmbio é não-estacionário (tende a I(1)). Por isso, além da média mensal,
calculamos a **variação cambial mensal** `dcambio = 100*(log(câmbio_t) − log(câmbio_{t−1}))`.
Essa transformação (i) torna a série estacionária e (ii) corresponde diretamente ao
conceito de *pass-through*: o que pressiona preços é a **variação** cambial, não o nível.

### Selic: LOCF (last observation carried forward)
A série 432 só registra observações nas datas em que a meta muda. Para obter o valor de fim
de mês:
1. cria-se uma **grade diária** completa;
2. preenche-se "para frente" com `zoo::na.locf` (cada dia herda a última meta definida);
3. toma-se o **último dia de cada mês**.

### Focus: regra reprodutível e ex-ante
Para o mês de referência *t*:
1. filtra-se `data_survey < primeiro_dia_de_t` (só leituras anteriores ao mês previsto);
2. ordena-se por `data_survey` e `baseCalculo`;
3. toma-se a **última** mediana (a leitura mais recente e mais "fresca").

Isso evita *look-ahead*: a expectativa usada para prever a inflação de *t* já estava
disponível antes de *t* começar.

## 2.3 Cuidados com datas, ausentes e alinhamento
- **Datas**: tudo é convertido para `Date` e ancorado no 1º dia do mês, evitando
  divergências de calendário entre fontes.
- **Valores ausentes (NA)**: o script 02 imprime a contagem de NAs por coluna. As séries de
  inflação (IPCA, núcleo, IGP-M) tendem a ser completas desde 2004; o **Focus mensal** pode
  começar mais tarde — por isso a função `montar_amostra()` usa, para cada modelo, a maior
  janela contígua **sem NA** nas colunas efetivamente utilizadas.
- **Alinhamento temporal**: o *merge* é feito por mês. Como diferentes modelos usam
  diferentes regressoras, o conjunto de **teste** (últimos `n_test` meses) é o mesmo para
  todos (o fim da amostra é comum), o que **mantém o RMSE/MAE comparáveis**; apenas o início
  do **treino** varia conforme a disponibilidade da regressora.
- **Saída**: a base tratada é gravada em `data/processed/base_mensal.csv`, e os dados brutos
  em `data/raw/` (formato `.rds`), garantindo reprodutibilidade e rastreabilidade.
