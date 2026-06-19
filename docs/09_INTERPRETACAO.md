# Parte 9 — Texto interpretativo para o relatório e os slides

Parágrafos prontos, em português acadêmico, para serem colados no relatório ou usados
como roteiro de fala. Onde houver um resultado empírico, deixei **lacunas `[___]`** a
preencher com os números gerados pelo pipeline — em respeito à regra de **não inventar
resultados**. O texto é escrito de forma **condicional**, de modo que continua correto
qualquer que seja o número observado.

---

## 9.1 Por que prever a inflação é relevante

A inflação é uma das variáveis macroeconômicas mais acompanhadas porque organiza
decisões de consumo, poupança, investimento e política monetária. No Brasil, o regime
de metas de inflação — em vigor de forma estabilizada desde meados dos anos 2000 — torna
a previsão do IPCA peça central da condução da taxa Selic pelo Banco Central. Antecipar
a trajetória dos preços permite à autoridade monetária agir de forma tempestiva, às
empresas planejar reajustes e contratos, e às famílias proteger seu poder de compra.
Erros de previsão têm custo real: subestimar a inflação atrasa a resposta de juros e
desancora expectativas; superestimá-la impõe aperto monetário excessivo e sacrifício
desnecessário de atividade. Construir e avaliar modelos de previsão é, portanto, um
exercício com consequências econômicas concretas, e não apenas estatístico.

## 9.2 Por que comparar o IPCA cheio (headline) e o núcleo

O IPCA cheio mede a variação de preços de toda a cesta de consumo, incluindo itens
muito voláteis — alimentos *in natura*, combustíveis e energia — cujos preços respondem
a clima, safras e cotações internacionais. Essas oscilações são frequentemente
**transitórias**: revertem-se nos meses seguintes e dizem pouco sobre a tendência
subjacente da inflação. O **núcleo por médias aparadas** remove sistematicamente os itens
com variações extremas em cada mês, isolando o componente **persistente** — aquele
associado à inércia inflacionária, à indexação de contratos e às expectativas. Modelar
as duas séries em paralelo permite separar o sinal do ruído: se o núcleo for mais
previsível e menos volátil que o cheio, isso evidencia que parte importante da
variabilidade do headline vem de choques temporários, e que a tendência inflacionária
"limpa" é mais bem comportada e mais fácil de antecipar. Essa distinção é exatamente a
que o Banco Central usa para enxergar além do ruído de curto prazo.

## 9.3 Por que usar regressoras macroeconômicas

Modelos puramente autorregressivos (ARIMA/SARIMA) extraem informação apenas do passado
da própria série. Eles capturam bem a **inércia** e a **sazonalidade**, mas são cegos a
informações externas que antecipam mudanças de regime. As regressoras escolhidas têm
canais econômicos bem identificados:

- **Câmbio (variação mensal):** o repasse cambial (*pass-through*) transmite
  depreciações do real aos preços de bens comercializáveis e insumos importados,
  pressionando a inflação com alguma defasagem.
- **Selic (fim de mês):** instrumento de política monetária; juros mais altos esfriam
  demanda e, com defasagem longa, contêm a inflação — sinal antecedente do esforço
  de estabilização.
- **IGP-M (variação mensal):** índice mais sensível a preços no atacado e ao câmbio,
  costuma **liderar** o IPCA em episódios de choque de custos, funcionando como
  indicador antecedente.
- **Expectativa Focus (mediana ex-ante):** resume a visão prospectiva do mercado e é,
  por construção, **forward-looking**; expectativas desancoradas tendem a se realizar
  via formação de preços e reajustes.

A hipótese é que essas variáveis acrescentem poder preditivo **acima** do que a própria
história da inflação oferece — sobretudo para o IPCA cheio, mais exposto a choques de oferta.

## 9.4 Como interpretar os resultados

A leitura dos resultados deve combinar **três camadas**:

1. **Estacionariedade** (ADF + KPSS): confirma que as séries podem ser modeladas em
   nível de variação, sem raiz unitária, justificando `d = 0` na maioria dos casos.
2. **Ajuste in-sample** (AIC/BIC + Ljung-Box): o melhor modelo deve ter AIC/BIC baixo
   **e** resíduos sem autocorrelação (p-valor de Ljung-Box alto), sinal de que a
   estrutura temporal foi adequadamente capturada.
3. **Desempenho out-of-sample** (RMSE/MAE): o critério decisivo. Um modelo pode ajustar
   bem o passado e prever mal o futuro (sobreajuste); por isso a palavra final é dada
   pelo erro nos 24 meses de teste, que o modelo **não viu** ao ser estimado.

Concretamente: *para o IPCA cheio, o melhor modelo foi `[___]`, com RMSE de `[___]` e
MAE de `[___]`; para o núcleo, foi `[___]`, com RMSE de `[___]` e MAE de `[___]`.*
Se as regressoras reduzirem o RMSE em relação ao SARIMA puro, conclui-se que a
informação macroeconômica **agrega** valor preditivo; se não reduzirem, conclui-se que
a dinâmica autorregressiva já esgotava o sinal disponível — um resultado igualmente
informativo e defensável.

## 9.5 Como escolher o melhor modelo

A escolha segue uma hierarquia explícita e reprodutível:

1. **Critério primário — menor RMSE fora da amostra.** É o que mede capacidade
   preditiva real, alinhada ao objetivo do trabalho.
2. **Critério de desempate — menor MAE** e **parcimônia** (AIC/BIC), preferindo o modelo
   mais simples quando o ganho preditivo for marginal (princípio da navalha de Occam).
3. **Validade dos resíduos** — o modelo escolhido precisa passar no Ljung-Box; um modelo
   com RMSE ligeiramente menor mas resíduos autocorrelacionados é menos confiável.
4. **Coerência econômica** — sinais dos coeficientes das regressoras devem ser plausíveis
   (ex.: depreciação cambial com sinal positivo sobre inflação).

Essa hierarquia evita escolher modelos por mero acaso amostral e mantém a interpretação
econômica no centro da decisão.

## 9.6 Limitações metodológicas a reconhecer

Um trabalho honesto declara suas limitações:

1. **Previsão condicional do SARIMAX (ex-post):** na avaliação fora da amostra, as
   regressoras de câmbio, Selic e IGP-M usam valores **realizados** no período de teste,
   que na prática não seriam conhecidos antecipadamente. Logo, o desempenho do SARIMAX é
   um **limite superior** otimista; a exceção é o Focus, genuinamente ex-ante. Uma
   extensão seria prever também as regressoras (VAR) ou usar apenas defasagens.
2. **Janela de teste fixa (holdout de 24 meses):** não há validação cruzada por janelas
   móveis (*rolling origin*), que daria estimativas de erro mais robustas.
3. **Quebras estruturais:** a amostra cobre choques severos (2008, 2015–2016, pandemia
   2020–2022) que podem violar a estabilidade dos parâmetros; não testamos formalmente
   quebras (ex.: Chow, Bai-Perron).
4. **Linearidade:** ARIMA/SARIMAX são lineares e podem não capturar não linearidades
   (efeitos assimétricos de choques cambiais, mudanças de regime).
5. **Escolha automática de ordens:** o `auto.arima` minimiza AICc, mas pode não coincidir
   com a especificação teoricamente ideal; a inspeção de ACF/PACF é confirmatória, não
   substitutiva.
6. **Definição de núcleo:** adotamos o núcleo por **médias aparadas com suavização**
   (SGS 4466). Outras medidas de núcleo (exclusão, dupla ponderação) poderiam produzir
   resultados quantitativamente distintos, ainda que a leitura qualitativa tenda a se manter.

Reconhecer esses pontos não enfraquece o trabalho — ao contrário, demonstra domínio do
método e delimita corretamente o alcance das conclusões.
