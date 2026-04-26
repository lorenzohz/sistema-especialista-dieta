# Sistema Especialista de Recomendação de Dieta
## Disciplina: Introdução à Inteligência Artificial - UEM
## Prof. Wagner Igarashi

---

## Como Executar

### Pré-requisito
SWI-Prolog instalado: https://www.swi-prolog.org/Download.html

### Executar o Sistema Principal
```bash
swipl main.pl
```
Ou dentro do interpretador:
```prolog
?- consult('interface.pl').
?- menu.
```

### Executar os Testes Unitários
```bash
swipl -g "consult('teste.pl'), executar_todos_testes, halt."
```

---

## Estrutura dos Arquivos

| Arquivo | Descrição |
|---|---|
| `base_conhecimento.pl` | Base de fatos: hipóteses, sintomas obrigatórios/opcionais e recomendações |
| `motor.pl` | Motor de inferência: cálculo de probabilidade, diagnóstico e explicabilidade |
| `interface.pl` | Interface humano-computador: perguntas, menus e CRUD |
| `teste.pl` | Testes unitários: base de conhecimento, diagnóstico, probabilidade, CRUD |

---

## Hipóteses Implementadas (11 dietas)

| ID | Nome | Categoria | Prob. Base |
|---|---|---|---|
| dieta_low_carb | Low-Carb / Cetogênica | emagrecimento | 88% |
| dieta_emagrecimento_moderado | Hipocalórica Equilibrada | emagrecimento | 85% |
| dieta_mediterranea | Mediterrânea | saude_cardiovascular | 90% |
| dieta_dash | DASH (Hipertensão) | saude_cardiovascular | 92% |
| dieta_diabeticos | Controle Diabetes Tipo 2 | controle_metabolico | 91% |
| dieta_anti_inflamatoria | Anti-Inflamatória | controle_metabolico | 83% |
| dieta_hiperproteica | Hiperproteica / Ganho Muscular | ganho_massa | 89% |
| dieta_ganho_peso_saudavel | Hipercalórica Saudável | ganho_massa | 84% |
| dieta_vegetariana | Vegetariana / Vegana | restricao_alimentar | 87% |
| dieta_sem_gluten | Isenta de Glúten | restricao_alimentar | 95% |
| dieta_equilibrada_manutencao | Equilibrada para Manutenção | manutencao | 82% |

---

## Cálculo de Probabilidade

```
Prob_Final = min(1.0, Prob_Base + Bonus)
Bonus = (opcionais_confirmados / total_opcionais) * 0.10
```

Os sintomas/condições opcionais confirmados contribuem com até **+10%** na probabilidade final. Os resultados são exibidos em ordem decrescente de probabilidade.

---

## Funcionalidades

- ✅ Base de conhecimento com 11 dietas, 16 condições obrigatórias, 48 opcionais
- ✅ Diagnóstico com probabilidades ordenadas de forma decrescente
- ✅ CRUD em tempo de execução (consultar, incluir, alterar, excluir hipóteses)
- ✅ Explicabilidade: por que uma dieta foi recomendada?
- ✅ Explicabilidade: por que uma dieta NÃO foi recomendada?
- ✅ Explicabilidade: por que uma pergunta foi feita?
- ✅ Aviso informativo (protótipo não substitui especialista)
- ✅ 25+ testes unitários (base de conhecimento, diagnóstico, probabilidade, explicabilidade, CRUD)

---

## Aviso

> **Este protótipo é apenas informativo. Consulte um nutricionista ou médico para diagnóstico ou recomendação correta e precisa.**
