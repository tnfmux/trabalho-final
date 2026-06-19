# Parte 4 — Explicação dos modelos

## ARIMA, SARIMA e SARIMAX em uma frase
- **ARIMA**: usa o **passado da própria série** (e dos erros passados) para prever o futuro.
- **SARIMA**: ARIMA **+ sazonalidade** (padrões que se repetem a cada 12 meses).
- **SARIMAX**: SARIMA **+ variáveis externas** (regressoras) que ajudam a explicar a série.

## O que é ARIMA (p, d, q)
ARIMA = *AutoRegressive Integrated Moving Average*. Combina três ideias:
- **AR(p)** — *autorregressivo*: a inflação de hoje depende de suas próprias defasagens
  (p termos passados). Captura **inércia/persistência**.
- **I(d)** — *integrado*: número de **diferenciações** necessárias para tornar a série
  estacionária. `d = 1` significa modelar a variação da série, não o nível.
- **MA(q)** — *média móvel*: a inflação de hoje depende dos **choques (erros) passados**
  (q termos). Captura efeitos transitórios.

Notação: **ARIMA(p, d, q)**. Exemplo: ARIMA(1,0,1) = um termo AR, sem diferenciação, um
termo MA.

## O que é SARIMA — componente sazonal (P, D, Q)[s]
Inflação mensal tem **sazonalidade**: certos meses sobem por motivos de calendário
(ex.: mensalidades escolares no início do ano, vestuário, alimentos sazonais). O SARIMA
acrescenta uma estrutura **sazonal** análoga à não-sazonal, mas operando a cada `s` períodos
(aqui `s = 12`):
- **P** — termos autorregressivos sazonais (relação com o mesmo mês de anos anteriores);
- **D** — diferenciação sazonal (subtrai o valor de 12 meses atrás);
- **Q** — médias móveis sazonais (choques no mesmo mês de anos anteriores).

Notação: **SARIMA(p,d,q)(P,D,Q)[s]**. Ignorar a sazonalidade joga padrões previsíveis para
dentro do resíduo, piorando a previsão; modelá-la melhora o ajuste e a previsão.

## O que é SARIMAX — regressoras externas (o "X")
O **X** vem de *eXogenous*: variáveis explicativas externas (`xreg`). O modelo passa a ser
uma **regressão com erros (S)ARIMA**:
> inflação_t = β·(regressoras_t) + ruído(S)ARIMA_t

Ou seja, parte da inflação é explicada pelas regressoras macroeconômicas; o que sobra
(o resíduo) ainda tem estrutura temporal modelada pelo SARIMA. As regressoras usadas:
câmbio, Selic, IGP-M e expectativas Focus.

## Por que cada regressora pode ajudar a prever a inflação

### Câmbio → inflação (repasse cambial / *pass-through*)
Uma desvalorização do real encarece importados e insumos dolarizados; produtores repassam o
custo aos preços. O efeito é mais forte sobre **bens comercializáveis** e tende a aparecer
mais no **IPCA cheio** do que no núcleo. Usamos a **variação cambial mensal**.

### Selic → inflação (canal da política monetária)
Juros mais altos encarecem crédito, esfriam consumo e investimento e tendem a apreciar o
câmbio — tudo reduzindo pressão inflacionária. O efeito é **defasado** (alguns trimestres),
o que o (S)ARIMA acomoda via estrutura dinâmica dos erros.

### IGP-M → IPCA (indicador antecedente de custos)
O IGP-M tem forte peso de **preços no atacado (IPA)** e do câmbio. Pressões de custo
costumam aparecer **primeiro** no atacado e só depois chegam ao **varejo** (IPCA). Assim, o
IGP-M corrente carrega informação útil para antecipar o IPCA.

### Expectativas Focus → inflação (canal forward-looking)
Na Curva de Phillips novo-keynesiana, a inflação corrente depende da **inflação esperada**.
Empresas e trabalhadores formam preços e salários olhando para a frente. Se as expectativas
sobem, a inflação tende a subir, mesmo antes de a demanda mudar. O Focus é a melhor proxy
pública dessas expectativas e é **conhecido ex-ante**, o que o torna uma regressora legítima
para previsão.

## Por que o núcleo pode ser mais previsível que o IPCA cheio
O IPCA cheio embute itens muito **voláteis** (alimentos in natura, combustíveis, energia),
sujeitos a choques de oferta difíceis de antecipar (clima, geopolítica, decisões
regulatórias). O **núcleo por médias aparadas** remove essas caudas a cada mês, ficando com
um sinal mais **suave e persistente**. Séries mais persistentes e menos ruidosas são, em
geral, **mais fáceis de prever** — o que sugere menor RMSE para o núcleo. Por outro lado,
como o núcleo já filtra choques de câmbio/alimentos, o **ganho marginal** de incluir câmbio
e IGP-M tende a ser **menor** no núcleo do que no cheio. Estas são hipóteses verificadas
empiricamente pelos números do projeto.
