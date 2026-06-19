# Parte 7 — Comparação IPCA cheio versus núcleo

Esta é uma das seções centrais do trabalho e responde à segunda metade da pergunta
de pesquisa: *o ganho das regressoras macroeconômicas é diferente para o IPCA cheio
e para o núcleo?*

> **Importante:** os números desta comparação são **gerados pelo código**, não inventados.
> O script `scripts/08_generate_outputs.R` produz `output/tables/comparacao_cheio_vs_nucleo.csv`,
> que consolida todas as dimensões abaixo a partir das estatísticas descritivas
> (`estatisticas_descritivas.csv`) e da avaliação fora da amostra (`avaliacao.rds`).
> Os trechos em *itálico entre colchetes* abaixo são **lacunas a preencher com o número
> do CSV** depois de rodar o pipeline.

---

## Dimensões comparadas

### 1. Qual série é mais volátil?
- **Métrica:** desvio-padrão da variação mensal (coluna `sd` de `estatisticas_descritivas.csv`).
- **Hipótese econômica (H1):** o **IPCA cheio é mais volátil**, porque inclui alimentos
  *in natura* e energia/combustíveis, sujeitos a choques climáticos e internacionais.
- **A preencher:** *sd(IPCA cheio) = [___]  vs  sd(núcleo) = [___]* → confirma/rejeita H1.

### 2. Qual série tem maior persistência?
- **Métrica:** autocorrelação de ordem 1 (`acf1`), e a soma dos coeficientes AR do melhor modelo.
- **Hipótese:** o **núcleo é mais persistente** — por construção ele retém a parte
  inercial/tendencial da inflação (repasses, indexação, expectativas) e remove os
  itens voláteis. Persistência maior ⟹ **mais previsível** a partir do próprio passado.
- **A preencher:** *acf1(núcleo) = [___]  vs  acf1(cheio) = [___]*.

### 3. Qual série é mais previsível?
- **Métrica:** menor **RMSE** fora da amostra entre os 6 modelos (coluna `melhor_rmse`).
- **Hipótese (H2):** o **núcleo tem menor erro de previsão**, por ser mais suave e persistente.
- **A preencher:** *melhor RMSE núcleo = [___]  vs  melhor RMSE cheio = [___]*.

### 4. Em qual série as regressoras externas ajudam mais?
- **Métrica:** ganho percentual de RMSE do **melhor SARIMAX (M3–M6)** sobre o **SARIMA (M2)**
  — no código, `ganho_M2_M6_pct`.
- **Hipótese:** as regressoras (câmbio, IGP-M) tendem a ajudar **mais o IPCA cheio**,
  porque é nele que os choques de oferta (câmbio→tradeables, IGP-M→atacado) se manifestam.
  No núcleo, grande parte do sinal já está no próprio componente autorregressivo.
- **A preencher:** *ganho cheio = [___] %  vs  ganho núcleo = [___] %*.

### 5. O núcleo apresenta menor erro de previsão?
- Resposta direta ao item 3 + item 2. Se confirmado, é a evidência empírica de que
  **separar o componente persistente facilita a previsão**.

### 6. O IPCA cheio reage mais a câmbio e IGP-M?
- **Métrica:** magnitude e significância dos coeficientes das regressoras no melhor modelo
  de cada série (`coeficientes_melhor_ipca.csv` vs `coeficientes_melhor_nucleo.csv`).
- **Hipótese:** coeficientes de **câmbio** e **IGP-M** maiores/mais significativos no **cheio**.

### 7. O que isso sugere sobre choques transitórios vs componente persistente?
- Se o cheio é mais volátil, menos persistente, mais sensível a câmbio/IGP-M e mais
  beneficiado por regressoras de oferta, e o núcleo é mais suave, mais persistente e
  mais previsível pelo próprio passado, então a conclusão econômica é:
  **a inflação brasileira tem um componente inercial bem capturado por modelos
  autorregressivos (visível no núcleo) e um componente de choques transitórios
  (visível no cheio) que demanda informação externa para ser antecipado.**

---

## Como o CSV é montado (referência de código)

`scripts/08_generate_outputs.R` cria um data frame com uma linha por **dimensão** e
duas colunas (`ipca`, `nucleo`), por exemplo:

| dimensao | ipca | nucleo |
|---|---|---|
| volatilidade (sd) | … | … |
| persistencia (acf1) | … | … |
| melhor_rmse | … | … |
| melhor_modelo | … | … |
| ganho_regressoras_pct (M2→melhor) | … | … |

Basta abrir `comparacao_cheio_vs_nucleo.csv` e transcrever para o slide 12.

---

## Texto-modelo para o relatório (preencher números)

> "A análise descritiva confirma a **hipótese H1**: o IPCA cheio apresentou desvio-padrão
> de *[___]* p.p. contra *[___]* p.p. do núcleo, refletindo a maior exposição do índice
> cheio a choques de alimentos e energia. Em termos de persistência, o núcleo exibiu
> autocorrelação de primeira ordem de *[___]*, superior à do cheio (*[___]*), coerente
> com seu caráter mais inercial. Na avaliação fora da amostra, o melhor modelo para o
> núcleo alcançou RMSE de *[___]* contra *[___]* do cheio, **corroborando H2**: o núcleo
> é mais previsível. As regressoras macroeconômicas reduziram o RMSE em *[___]%* no caso
> do cheio e *[___]%* no caso do núcleo, indicando que a informação externa — em especial
> câmbio e IGP-M — é **mais útil para antecipar o componente transitório** presente no
> índice headline do que o componente persistente já capturado pela dinâmica do núcleo."
