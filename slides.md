---
marp: true
theme: default
paginate: true
style: |
  @import "default";

  :root {
      --base: #faf4ed;
      --surface: #fffaf3;
      --overlay: #f2e9e1;
      --muted: #9893a5;
      --subtle: #797593;
      --text: #575279;
      --love: #b4637a;
      --gold: #ea9d34;
      --rose: #d7827e;
      --pine: #286983;
      --foam: #56949f;
      --iris: #907aa9;
      --highlight-low: #f4ede8;
      --highlight-muted: #dfdad9;
      --highlight-high: #cecacd;

      font-family: Pier Sans, ui-sans-serif, system-ui, -apple-system,
          BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, Noto Sans,
          sans-serif, "Apple Color Emoji", "Segoe UI Emoji", Segoe UI Symbol,
          "Noto Color Emoji";
      font-weight: initial;
      background-color: var(--base);
  }
  h1 { color: var(--rose); padding-bottom: 2mm; margin-bottom: 10mm; }
  h2 { color: var(--rose); }
  h3 { color: var(--pine); font-size: 18pt; margin-top: 4mm; margin-bottom: 2mm; }
  a  { color: var(--iris); }
  p  { font-size: 18pt; font-weight: 600; color: var(--text); }
  code { color: var(--text); background-color: var(--highlight-muted); }
  ul { color: var(--subtle); }
  li { color: var(--subtle); font-size: 17pt; }
  strong { color: var(--text); font-weight: 800; }
  mjx-container { color: var(--text); }
  marp-pre { background-color: var(--overlay); border-color: var(--highlight-high); }
  .hljs-comment  { color: var(--muted); }
  .hljs-attr     { color: var(--foam); }
  .hljs-string   { color: var(--gold); }
  .hljs-keyword  { color: var(--pine); }
  .hljs-literal  { color: var(--rose); }
  .hljs-number   { color: var(--gold); }
  .hljs-built_in { color: var(--love); }
  .hljs-params   { color: var(--iris); }

  /* Layout helpers */
  .cols { display: flex; gap: 24px; }
  .col  { flex: 1; }
  .tag  {
      display: inline-block;
      background: var(--highlight-muted);
      color: var(--pine);
      border-radius: 6px;
      padding: 2px 10px;
      font-size: 14pt;
      font-weight: 700;
      margin: 3px 2px;
  }
  .card {
      background: var(--overlay);
      border-left: 4px solid var(--rose);
      border-radius: 6px;
      padding: 10px 16px;
      margin: 6px 0;
  }
  .card p, .card li { font-size: 15pt; }
  .note {
      background: var(--highlight-low);
      border-radius: 6px;
      padding: 8px 14px;
      font-size: 14pt;
      color: var(--subtle);
  }
---

# Sistema Especialista de Recomendação de Dieta
## Introdução à Inteligência Artificial

**Universidade Estadual de Maringá** — Departamento de Informática

* **Professor:** Wagner Igarashi
* **Alunos:** [Nome 1], [Nome 2], [Nome 3]
* **Linguagem:** Prolog (SWI-Prolog)

---

# O Problema

<div class="card">

**Como recomendar um plano alimentar adequado a um usuário**, considerando seus objetivos, condições de saúde, restrições alimentares e hábitos de vida, de forma transparente e justificável?

</div>

### Por que usar um Sistema Especialista?

* O domínio nutricional é **rico em regras** e **conhecimento especializado**
* Recomendações dependem de múltiplos fatores **combinados**
* O usuário precisa entender **por que** aquela dieta foi sugerida
* Incerteza é inerente: nem toda condição é obrigatória para uma recomendação

---

# Domínio Modelado

<div class="cols">
<div class="col">

### Categorias de Planos

<span class="tag">Emagrecimento</span>
<span class="tag">Saúde Cardiovascular</span>
<span class="tag">Controle Metabólico</span>
<span class="tag">Ganho de Massa</span>
<span class="tag">Restrições Alimentares</span>
<span class="tag">Manutenção</span>

</div>
<div class="col">

### 11 Planos de Dieta

* Low-Carb / Cetogênica
* Hipocalórica Equilibrada
* Mediterrânea
* DASH (Hipertensão)
* Controle do Diabetes Tipo 2
* Anti-Inflamatória
* Hiperproteica (Ganho Muscular)
* Ganho de Peso Saudável
* Vegetariana / Plant-Based
* Sem Glúten (Celíacos)
* Equilibrada de Manutenção

</div>
</div>

---

# Arquitetura do Sistema

```
diet-expert-system/
├── base_conhecimento.pl   ← Fatos: planos, critérios, recomendações
├── motor.pl               ← Inferência, probabilidade, explicabilidade
├── interface.pl           ← IHC: entrevista, CRUD, menus
├── teste.pl               ← Testes unitários (5 grupos)
└── main.pl                ← Ponto de entrada
```

<div class="cols" style="margin-top:10px">
<div class="col">
<div class="card">

**Base de Conhecimento**
16 critérios obrigatórios
48 critérios opcionais
58 recomendações práticas
39 perguntas ao usuário

</div>
</div>
<div class="col">
<div class="card">

**Motor de Inferência**
Encadeamento para frente
Filtro por critérios obrigatórios
Pontuação por critérios opcionais
Ordenação decrescente por probabilidade

</div>
</div>
</div>

---

# Representação do Conhecimento

### Estrutura de um Plano

```prolog
plano(dieta_dash,
    'Dieta DASH (Controle da Hipertensão)',
    saude_cardiovascular,
    0.92,   % probabilidade base
    'Desenvolvida para controle da pressão arterial. Enfatiza frutas,
     vegetais, laticínios com baixo teor de gordura e restrição de sódio.'
).

criterio_obrigatorio(dieta_dash, pressao_arterial_alta).

criterio_opcional(dieta_dash, objetivo_emagrecer).
criterio_opcional(dieta_dash, consome_muito_sodio_atualmente).
criterio_opcional(dieta_dash, historico_familiar_doenca_cardiaca).
```

<div class="note">

Critérios **obrigatórios** eliminam o plano se negados. Critérios **opcionais** ajustam a probabilidade final.

</div>

---

# Cálculo de Probabilidade

### Fórmula Aplicada

$$P_{final} = P_{base} + \frac{C_{confirmados}}{C_{total}} \times 0{,}10$$

Onde:
* **P_base** — probabilidade intrínseca do plano (entre 0,0 e 1,0)
* **C_confirmados** — critérios opcionais respondidos como *sim*
* **C_total** — total de critérios opcionais do plano
* O bônus máximo é **+10%**, limitando P_final a 1,0

### Implementação em Prolog

```prolog
probabilidade_final(Plano, ProbFinal) :-
    plano(Plano, _, _, ProbBase, _),
    criterios_obrigatorios_confirmados(Plano),
    contar_criterios_opcionais(Plano, Confirmados),
    total_criterios_opcionais(Plano, Total),
    Bonus is (Confirmados / Total) * 0.10,
    ProbFinal is min(1.0, ProbBase + Bonus).
```

---

# Fluxo da Entrevista

### 1 — Seleção do Objetivo (nova etapa inicial)

```
------------------------------------------------------------
 Qual é o seu principal objetivo?
------------------------------------------------------------
  1. Perder peso (emagrecer)
  2. Ganhar massa muscular
  3. Ganhar peso (estou abaixo do peso desejado)
  4. Manter o peso atual
  5. Melhorar a saúde do coração e sistema cardiovascular
  6. Melhorar a saúde e bem-estar geral
>> Digite o número correspondente: _
```

### 2 — Perguntas de Perfil (sim / não)

O motor consulta apenas os critérios ainda **pendentes e relevantes** para os planos compatíveis com o objetivo escolhido, evitando perguntas desnecessárias.

---

# Explicabilidade

O sistema justifica cada resultado de três formas:

<div class="cols">
<div class="col">
<div class="card">

### Por que foi recomendado?

Lista todos os critérios obrigatórios e opcionais **confirmados** pelo usuário para aquele plano.

```prolog
explicar_plano(Plano)
```

</div>
</div>
<div class="col">
<div class="card">

### Por que foi descartado?

Indica qual critério obrigatório foi **negado**, eliminando o plano da lista.

```prolog
explicar_descarte(Plano)
```

</div>
</div>
<div class="col">
<div class="card">

### Por que essa pergunta foi feita?

Aponta quais planos dependem daquele critério, tornando a entrevista transparente.

```prolog
explicar_pergunta(Criterio)
```

</div>
</div>
</div>

---

# CRUD em Tempo Real

O sistema permite gerenciar a base de conhecimento **durante a execução**, sem reinicializar o Prolog:

| Operação | Predicados Prolog | Efeito |
|---|---|---|
| **Consultar** | `plano/5` | Lista planos com probabilidade e categoria |
| **Incluir** | `assertz/1` | Adiciona novo plano e seus critérios |
| **Alterar** | `retractall/1` + `assertz/1` | Substitui nome, prob. ou categoria |
| **Excluir** | `retractall/1` | Remove plano e **todos** seus critérios |

<div class="note">

A exclusão remove em cascata: `retractall(plano(Id,_,_,_,_))`, `retractall(criterio_obrigatorio(Id,_))` e `retractall(criterio_opcional(Id,_))`.

</div>

---

# Testes Unitários

Organizados em **5 grupos** executados com `rodar_testes/0`:

<div class="cols">
<div class="col">

**Grupo 1 — Base de Conhecimento**
Valida integridade dos fatos: todos os planos possuem critérios e recomendações associadas.

**Grupo 2 — Motor e Diagnóstico**
Verifica se planos corretos são recomendados e descartados para perfis pré-definidos.

**Grupo 3 — Probabilidade**
Confirma que o cálculo de bônus e a ordenação decrescente estão corretos.

</div>
<div class="col">

**Grupo 4 — Explicabilidade**
Garante que `explicar_plano`, `explicar_descarte` e `explicar_pergunta` retornam resultados consistentes.

**Grupo 5 — CRUD**
Testa inclusão, alteração e exclusão de planos em tempo real, verificando persistência e remoção em cascata.

</div>
</div>

---

# Demonstração Prática

> ⚠️ **Aviso do Sistema:**
> *"Este protótipo é apenas informativo. Consulte um nutricionista ou médico para recomendação correta e precisa."*

### Tipos de consulta demonstradas

* **Perfil cardiovascular** — seleciona objetivo cardiovascular → recomenda Mediterrânea e DASH ordenadas por probabilidade
* **Perfil de emagrecimento** — aceita redução de carboidratos → Low-Carb lidera; Hipocalórica como alternativa
* **Rastreio de decisão** — exibe critérios confirmados e descartados para cada plano
* **CRUD ao vivo** — inclusão de novo plano e verificação imediata no diagnóstico

---

# Conclusões

* **Base de conhecimento** com 11 planos, 64 critérios e 58 recomendações práticas cobre os principais perfis nutricionais
* **Probabilidade combinada** (base + bônus opcional) permite ranqueamento refinado sem tornar critérios secundários obrigatórios
* **Explicabilidade em três níveis** torna o sistema auditável e alinhado com boas práticas de IA responsável
* **Seleção de objetivo única** no início da entrevista eliminou redundância e melhorou a experiência de uso
* **Testes unitários em 5 grupos** garantem confiabilidade do motor, da base e do CRUD

---

# Referências Bibliográficas

* RUSSELL, S.; NORVIG, P. *Inteligência Artificial: Uma Abordagem Moderna*. 4. ed. Pearson, 2022.
* BRATKO, I. *Prolog Programming for Artificial Intelligence*. 4. ed. Pearson, 2011.
* CLOCKSIN, W. F.; MELLISH, C. S. *Programming in Prolog*. 5. ed. Springer, 2003.
* SWI-PROLOG. *SWI-Prolog Reference Manual*. Disponível em: https://www.swi-prolog.org/pldoc/. Acesso em: abr. 2026.
* ORNISH, D. et al. *Intensive Lifestyle Changes for Reversal of Coronary Heart Disease*. JAMA, 1998. *(base para dieta cardiovascular)*
* SACKS, F. M. et al. *Effects on Blood Pressure of Reduced Dietary Sodium and the DASH Diet*. NEJM, 2001. *(base para dieta DASH)*
