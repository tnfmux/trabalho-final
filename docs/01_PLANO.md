# Parte 1 — Plano completo do trabalho

## Tema
Previsão da inflação brasileira com modelos econométricos, comparando o **IPCA cheio**
(*headline*) com o **núcleo do IPCA por médias aparadas**.

## Pergunta de pesquisa
> Modelos econométricos com regressoras macroeconômicas (câmbio, Selic, IGP-M e
> expectativas Focus) melhoram a previsão da inflação brasileira em relação a modelos
> puramente autorregressivos (ARIMA/SARIMA)? Esse ganho é diferente para o IPCA cheio
> e para o núcleo de inflação?

## Motivação
A inflação é a variável-síntese da política monetária no Brasil. Sob o regime de metas
(em vigor desde 1999 e estabilizado a partir de 2004), o Banco Central calibra a taxa
Selic com base em projeções de inflação. Prever bem a inflação é, portanto, relevante para
política monetária, para decisões de investimento e crédito, para reajustes de contratos e
para o planejamento fiscal. A distinção entre **headline** e **núcleo** é central: o IPCA
cheio responde a choques transitórios de alimentos e energia, ao passo que o núcleo procura
isolar a tendência mais persistente — exatamente o componente que a política monetária
consegue influenciar. Comparar as duas séries em paralelo permite separar o que é "ruído
de choque" do que é "sinal de tendência".

## Hipótese central
1. **H1** — As regressoras macroeconômicas reduzem o erro de previsão fora da amostra
   (menor RMSE/MAE) em relação aos modelos puramente autorregressivos, principalmente para
   o **IPCA cheio**, mais sensível a câmbio e a preços por atacado (IGP-M).
2. **H2** — O **núcleo** é mais previsível (menor erro) do que o IPCA cheio mesmo nos
   modelos univariados, por ser menos volátil e mais persistente; o ganho marginal das
   regressoras externas tende a ser **menor** no núcleo do que no cheio.

> As hipóteses são confirmadas ou rejeitadas **pelos números gerados pelo código**, não a
> priori. O relatório deve ler a tabela `output/tables/comparacao_cheio_vs_nucleo.csv`.

## Justificativa econômica das escolhas
- **IPCA cheio**: índice oficial de metas; é o que a sociedade observa e o que indexa
  contratos. É a referência natural de "inflação".
- **Núcleo por médias aparadas**: remove, a cada mês, os itens nas caudas da distribuição
  de variações (os 20% mais altos e os 20% mais baixos), atenuando choques pontuais. Capta
  a **tendência inflacionária**, mais ligada a demanda agregada e inércia.
- **Câmbio (R$/US$)**: o repasse cambial (*pass-through*) transmite desvalorizações aos
  preços de bens comercializáveis e insumos importados.
- **Selic**: instrumento de política monetária; juros mais altos esfriam demanda e
  expectativas, com efeito defasado sobre a inflação.
- **IGP-M**: índice de preços no atacado (forte peso do IPA); funciona como **indicador
  antecedente** de pressões de custo que depois chegam ao varejo (IPCA).
- **Expectativas Focus**: variável **forward-looking**; numa Curva de Phillips
  novo-keynesiana, a inflação corrente depende da inflação esperada. Expectativas
  ancoradas ajudam a prever a inflação efetiva.

## Dados utilizados
| Série | Fonte | Código SGS | Frequência original | Tratamento |
|---|---|---|---|---|
| IPCA cheio (var % mês) | IBGE/BCB | 433 | Mensal | — |
| Núcleo médias aparadas c/ suavização (var % mês) | BCB | 4466 | Mensal | — |
| Meta Selic (% a.a.) | BCB/Copom | 432 | Datas do Copom | Fim do mês (LOCF) |
| Câmbio R$/US$ venda | BCB | 1 | Diária | Média mensal → variação % |
| IGP-M (var % mês) | FGV/BCB | 189 | Mensal | — |
| Expectativa Focus IPCA (mediana) | BCB (Expectativas) | — (API) | Por pesquisa | Última leitura ex-ante |

> **Correção importante sobre o núcleo:** o enunciado citava o código **11427** como núcleo
> por médias aparadas. Conferindo o Portal de Dados Abertos do BCB, **11427 é o núcleo por
> EXCLUSÃO EX0** (exclui monitorados e alimentos no domicílio), e **não** um núcleo por
> médias aparadas. A medida por médias aparadas com suavização (clássica do BCB, com série
> longa) é o código **4466**, adotado aqui. Para reproduzir com EX0, troque `nucleo` em
> `config.R`.

## Metodologia (visão geral)
1. Coleta por API (SGS + Focus) e tratamento/alinhamento mensal.
2. Exploração: gráficos, estatísticas descritivas, ACF/PACF, sazonalidade.
3. Estacionariedade: ADF + KPSS; justificativa de (não) transformações.
4. Estimação progressiva: ARIMA → SARIMA → SARIMAX (regressoras cumulativas).
5. Separação treino/teste (holdout dos últimos `n_test` meses).
6. Previsão fora da amostra; avaliação por **RMSE** e **MAE**.
7. Comparação entre modelos e entre **IPCA cheio** e **núcleo**.
8. Interpretação macroeconômica e limitações.

## Estrutura final do trabalho
Código reprodutível em R (pasta `scripts/`, orquestrado por `main.R`), saídas automáticas
em `output/` (figuras, tabelas, previsões), documentação em `docs/` e apresentação a partir
de `slides_outline.md`.
