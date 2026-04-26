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
  table { font-size: 0.8em; width: 100%; }
  td, th { padding: 2px 4px; font-size: 0.75em; }

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
* **Alunos:** Caetano Vendrame Mantovani, Lorenzo Henrique Zanetti, Vitor da Rocha Machado
* **Linguagem:** Prolog (SWI-Prolog)

---

# O Problema

<div class="card">

**Como recomendar uma dieta alimentar adequada a um usuário**, considerando seus objetivos, condições de saúde, restrições alimentares, tempo de preparo e orçamento, de forma explicável?

</div>

### Por que usar um Sistema Especialista?

* Várias dietas podem ser plausíveis para o mesmo perfil.
* Algumas condições apresentam **contraindicações**.
* Outras condições fornecem apenas **peso adicional** para a recomendação.
* A entrevista pode ser eficiente, com perguntas condicionais quando necessário.
* Ajuda o usuário a ter um norte naquilo que precisa, mas lembrando-o de consultar um especialista.

---

# Fundamentação Teórica

* Sistemas especialistas aplicam conhecimento explícito em forma de fatos e regras.
* Prolog é adequado porque unifica, consulta fatos e calcula inferências naturalmente.
* A recomendação é feita por um modelo híbrido:
  * regras booleanas para contraindicações
  * heurísticas numéricas para evidências
* Explicabilidade é oferecida por predicados que retornam as razões de escolha.

---

# Arquitetura do Sistema

```
sistema-especialista-dieta/
├── base_conhecimento.pl   ← dietas, perguntas, descrições, evidências e contraindicações
├── motor_inferencia.pl    ← contexto, inferência, recomendações, explicações
├── interface.py           ← menu, integração Python/Prolog, CRUD de base
├── testes_unitarios.pl    ← validações automatizadas com plunit
└── slides.md              ← apresentação do trabalho
```

---

# Base de Conhecimento: dietas e descrições

* São declaradas 11 dietas com probabilidade base.
* Cada dieta possui uma descrição textual para apresentação.
* Exemplo real:

```prolog
dieta(low_carb, 'Low Carb', 0.50).
descricao_dieta(low_carb, 'Reducao de carboidratos priorizando proteinas, 
vegetais e gorduras saudaveis. Eficaz para perda de peso e controle glicemico.').
```

---

# Tabela de Dietas

| ID | Nome | Probabilidade Base | Descrição |
|----|------|---------------------|-----------|
| low_carb | Low Carb | 0.50 | Redução de carboidratos priorizando proteínas, vegetais e gorduras saudáveis. Eficaz para perda de peso e controle glicêmico. |
| vegetariana | Vegetariana | 0.50 | Baseada em vegetais. Exclui carnes, mas permite laticínios e ovos. Rica em fibras e antioxidantes. |
| vegana | Vegana | 0.45 | Estritamente baseada em plantas. Exclui qualquer produto de origem animal, exige suplementação de B12 e proteína planejada. |
| mediterranea | Mediterrânea | 0.55 | Focada em alimentos frescos, azeite, peixes, oleaginosas e grãos integrais. Fortemente associada à saúde cardiovascular. |
| hiperproteica | Hiperproteica | 0.50 | Alta ingestão de proteínas (1.6-2.2g/kg). Focada na manutenção e hipertrofia muscular, ideal para atletas e praticantes de musculação. |

---

# Tabela de Dietas

| ID | Nome | Probabilidade Base | Descrição |
|----|------|---------------------|-----------|
| low_fat | Low Fat | 0.45 | Redução drástica de gorduras totais. Indicada para controle de colesterol e saúde cardiovascular em perfis sedentários a leve. |
| sem_gluten | Sem Gluten | 0.40 | Exclusão total de trigo, centeio e cevada. Obrigatória para celíacos e indicada para sensibilidade não celíaca ao glúten. |
| dash | DASH | 0.45 | Desenvolvida para reduzir a pressão arterial. Enfatiza potássio, magnésio e restrição severa de sódio. |
| cetogenica | Cetogênica | 0.40 | Altíssima ingestão de gorduras e carboidratos quase zerados (< 50g/dia). Induz cetose, potente para perda de peso e controle glicêmico tipo 2. |
| paleolitica | Paleolítica | 0.45 | Inspirada na alimentação pré-agricola: carnes, sementes e raízes. Exclui grãos, laticínios e alimentos processados. |
| flexitariana | Flexitariana | 0.55 | Majoritariamente vegetariana, com consumo esporádico e flexível de carnes. Equilibra saúde, sustentabilidade e praticidade. |

---

# Base de Conhecimento: perguntas e perfil

* O sistema pergunta atributos do usuário com o predicado `pergunta/5`.
* Existem perguntas:
  * base: sempre ativas
  * condicionais: ativadas por resposta anterior
* Exemplos:

```prolog
pergunta(objetivo, base, 'Qual e o seu principal objetivo com a dieta?', 
[perda_peso, ganho_massa, saude_geral, controle_cronicas, performance_atletica], 
'O objetivo orienta o perfil nutricional recomendado.').
```

```prolog
pergunta(tipo_diabetes, depende(tem_diabetes, sim), 'Qual e o tipo do seu diabetes?', 
[tipo_1, tipo_2, pre_diabetes], 'Tipo clinico altera seguranca e conduta nutricional.').
```

---

# Tabela de Perguntas Base

| Atributo | Texto da Pergunta | Opções | Justificativa |
|----------|-------------------|--------|---------------|
| objetivo | Qual é o seu principal objetivo com a dieta? | perda_peso, ganho_massa, saude_geral, controle_cronicas, performance_atletica | O objetivo orienta o perfil nutricional recomendado. |
| nivel_atividade | Qual é o seu nível de atividade física semanal? | sedentario, leve, moderado, intenso | O nível de atividade altera demanda calórica e proteica. |
| faixa_etaria | Qual é a sua faixa etária? | jovem, adulto, idoso | A faixa etária afeta necessidades nutricionais e segurança clínica. |
| imc_faixa | Como você classificaria seu peso corporal atual? | abaixo_peso, normal, sobrepeso, obesidade | O IMC orienta a intensidade de ajuste energético da dieta. |
| tem_diabetes | Você possui diabetes ou pré-diabetes? | sim, nao | Diabetes exige controle de glicemia e carboidratos. |
| tem_hipertensao | Você possui hipertensão diagnosticada? | sim, nao | Hipertensão prioriza dietas com controle de sódio e perfil cardioprotetor. |
| tem_colesterol_alto | Você possui colesterol elevado? | sim, nao | Colesterol elevado favorece padrões com menor gordura saturada. |

---

# Tabela de Perguntas Base

| Atributo | Texto da Pergunta | Opções | Justificativa |
|----------|-------------------|--------|---------------|
| tem_problemas_renais | Você possui doença renal crônica ou insuficiência renal? | sim, nao | Doença renal restringe dietas com alta carga proteica. |
| tem_doenca_cardiaca | Você possui doença cardíaca diagnosticada? | sim, nao | Doença cardíaca restringe dietas de alto risco cardiovascular. |
| restricao_carne | Você possui restrição ao consumo de carnes? | sim, nao | Restrição de carne direciona para perfis vegetarianos ou veganos. |
| alergia_lactose | Você possui intolerância a lactose ou alergia à proteína do leite? | sim, nao | A restrição a lactose altera fontes proteicas e planejamento alimentar. |
| restricao_gluten | Você possui doença celíaca ou sensibilidade ao glúten? | sim, nao | A restrição ao glúten exige adaptações específicas. |
| tempo_preparo | Como é sua disponibilidade de tempo para preparar refeições? | baixa, media, alta | Algumas dietas exigem maior preparo e planejamento. |
| orcamento | Como é seu orçamento mensal para alimentação? | baixo, flexivel, alto | O custo de ingredientes pode inviabilizar certos padrões alimentares. |

---

# Tabela de Perguntas Condicionais

| Atributo | Dependência | Texto da Pergunta | Opções | Justificativa |
|----------|-------------|-------------------|--------|---------------|
| frequencia_carne | depende(restricao_carne, nao) | Você consome carne com qual frequência semanal? | diariamente, ocasionalmente, raramente | Distingue perfis onívoros e flexitarianos. |
| restricao_laticinios | depende(restricao_carne, sim) | Já que você não consome carne, também restringe laticínios e ovos? | sim, nao | Distingue perfil vegetariano de vegano. |
| disposicao_restricao | depende(objetivo, perda_peso) | Para perder peso, você aceita cortar grupos alimentares de forma intensa? | sim, nao | Dietas muito restritivas exigem alta adesão. |
| tipo_diabetes | depende(tem_diabetes, sim) | Qual é o tipo do seu diabetes? | tipo_1, tipo_2, pre_diabetes | Tipo clínico altera segurança e conduta nutricional. |

---

# Modelagem do perfil do usuário

* As respostas são armazenadas dinamicamente com predicados:
  * `tem_objetivo/2`, `tem_nivel_atividade/2`, `tem_faixa_etaria/2`, etc.
  * `tem_doenca/2`, `nao_tem_doenca/2`
  * `tem_restricao/2`, `nao_tem_restricao/2`
* O paciente atual é controlado por `paciente_atual/1` e `definir_individuo_atual/1`.
* `limpar_respostas/1` reseta o perfil entre sessões.

---

# Regras de evidência

* Cada dieta possui fatos `evidencia(Dieta, X, Peso)`.
* O peso representa quanto a condição favorece a dieta.
* Exemplo:

```prolog
evidencia(low_carb, X, 0.25) :- tem_objetivo(X, perda_peso).
evidencia(vegana, X, 0.30) :- tem_restricao(X, laticinios).
evidencia(sem_gluten, X, 0.50) :- tem_restricao(X, gluten).
```

* Isso permite diferenciar dietas por perfil clínico e restrições.

---

# Regras de contraindicação

* `contraindicada(Dieta, X)` define exclusões estritas.
* Apenas dietas não contraindicadas são consideradas.
* Exemplo de lógica presente no código:
  * `cetogenica` pode ser contraindicada para diabetes tipo 1 ou doença cardíaca
  * `hiperproteica` pode ser contraindicada para problemas renais

---

# Tabela de Contraindicações

| Dieta | Condição | Atributo Relacionado | Justificativa |
|-------|----------|----------------------|---------------|
| cetogenica | tem_disposicao_restricao(X, nao) | disposicao_restricao | Muito restritiva, exige alta adesão. |
| cetogenica | tem_doenca(X, colesterol_alto) | tem_colesterol_alto | Incompatível com altíssima gordura. |
| cetogenica | tem_doenca(X, doenca_cardiaca) | tem_doenca_cardiaca | Risco cardiovascular elevado. |
| cetogenica | tem_tipo_diabetes(X, tipo_1) | tipo_diabetes | Requer controle glicêmico estável. |
| hiperproteica | tem_restricao(X, carne) | restricao_carne | Baseia-se fundamentalmente em carnes. |
| hiperproteica | tem_doenca(X, problemas_renais) | tem_problemas_renais | Sobrecarrega rins. |
| vegetariana | tem_restricao(X, laticinios) | restricao_laticinios | Permite laticínios; inviável com restrição. |

---

# Tabela de Contraindicações

| Dieta | Condição | Atributo Relacionado | Justificativa |
|-------|----------|----------------------|---------------|
| vegana | tem_tempo_preparo(X, baixa) | tempo_preparo | Planejamento de proteínas é essencial. |
| mediterranea | tem_tempo_preparo(X, baixa) | tempo_preparo | Requer preparo de refeições frescas. |
| mediterranea | tem_orcamento(X, baixo) | orcamento | Ingredientes frescos são caros. |
| paleolitica | tem_tempo_preparo(X, baixa) | tempo_preparo | Carnes e alimentos não processados exigem preparo. |
| paleolitica | tem_orcamento(X, baixo) | orcamento | Carnes e sementes são custosos. |
| paleolitica | tem_doenca(X, problemas_renais) | tem_problemas_renais | Alta proteína sobrecarrega rins. |
| low_fat | tem_objetivo(X, ganho_massa) | objetivo | Impede ganho muscular efetivo. |
| sem_gluten | tem_objetivo(X, ganho_massa) | objetivo | Muito restritiva para ganho muscular. |

---

# Motor de inferência

* `calcular_score/3` determina o score de cada dieta:
  * base + soma das evidências satisfeitas
  * limite em `0.99`
* `nao_contraindicada/2` garante exclusão de dietas perigosas.
* `recomendar/2` produz uma lista ordenada de `Score-Dieta-Nome`.

---

# Fluxo de recomendação

* O motor busca:
  * todas as dietas definidas em `dieta/3`
  * somente dietas não contraindicadas
  * score de cada dieta com evidências aplicáveis
* Em seguida, ordena resultados em ordem decrescente de score.
* Essa lista é a base para a recomendação final.

---

# Perguntas condicionais

* `listar_perguntas_base/1` retorna perguntas iniciais.
* `listar_perguntas_condicionais_ativas/2` ativa perguntas quando uma resposta específica já existe.
* Exemplo de condição:
  * se `restricao_carne = sim`, então pergunta `restricao_laticinios`
  * se `tem_diabetes = sim`, então pergunta `tipo_diabetes`

---

# Interface Python e integração

* `interface.py` usa `pyswip` para rodar SWI-Prolog dentro do Python.
* No `__init__`, carrega:
  * `motor_inferencia.pl`
  * `base_conhecimento.pl`
* O menu do Python trata:
  * questionário interativo
  * explicações de recomendações
  * operações de CRUD no arquivo Prolog
  * execução de testes unitários

---

# Gestão da base de conhecimento

* O Python parseia `base_conhecimento.pl` com expressões regulares.
* Permite:
  * incluir dieta e descrição
  * alterar probabilidade, nome e descrição
  * incluir/alterar/excluir regras de `evidencia/3`
  * incluir/alterar/excluir regras de `contraindicada/2`
* Após qualquer modificação, o Prolog é recarregado para refletir a mudança.

---

# Materiais e Métodos

* Ambiente: Windows, Python 3, SWI-Prolog.
* Dependência principal: `pyswip`.
* Execução principal: `python interface.py`.
* Testes: `swipl -q -g "executar_testes_sistema" -t halt testes_unitarios.pl`.
* Arquivos principais:
  * `base_conhecimento.pl`
  * `motor_inferencia.pl`
  * `interface.py`
  * `testes_unitarios.pl`

---

# Testes Unitários

* `testes_unitarios.pl` usa `plunit` para validação automatizada.
* Estrutura de testes:
  * score e crescimento por evidências
  * contraindicações específicas
  * ordenação de recomendações
  * ativação de perguntas condicionais
  * consistência do modelo relacional
  * explicabilidade de fatos e exclusões

---

# Demonstração Prática

* Fluxo típico:
  1. iniciar `python interface.py`
  2. responder perguntas do questionário
  3. receber lista ordenada de dietas
  4. visualizar justificativas de escolha
  5. revisar dietas descartadas por contraindicação

* A interface também permite testar CRUD em tempo real e rodar os testes.

---

# Conclusões

* O sistema integra **conhecimento declarativo** e **inferência heurística**.
* A modelagem de perfil é robusta para objetivos, doenças e restrições.
* A explicabilidade ajuda a avaliar e justificar cada recomendação.
* A interface Python torna o protótipo utilizável e extensível.
* Os testes garantem qualidade para diferentes perfis e condições.

---

# Referências Bibliográficas

* RUSSELL, S.; NORVIG, P. *Inteligência Artificial: Uma Abordagem Moderna*. 4. ed. Pearson, 2022.
* BRATKO, I. *Prolog Programming for Artificial Intelligence*. 4. ed. Pearson, 2011.
* CLOCKSIN, W. F.; MELLISH, C. S. *Programming in Prolog*. 5. ed. Springer, 2003.
* SWI-PROLOG. *SWI-Prolog Reference Manual*. Disponível em: https://www.swi-prolog.org/pldoc/. Acesso em: abr. 2026.
* ORNISH, D. et al. *Intensive Lifestyle Changes for Reversal of Coronary Heart Disease*. JAMA, 1998. *(base para dieta cardiovascular)*
* SACKS, F. M. et al. *Effects on Blood Pressure of Reduced Dietary Sodium and the DASH Diet*. NEJM, 2001. *(base para dieta DASH)*
