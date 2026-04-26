---
marp: true
theme: default
paginate: true
style: |
  /* @theme rose-pine-dawn */
  /*
  Rosé Pine theme create by RAINBOWFLESH
  > www.rosepinetheme.com
  MIT License https://github.com/rainbowflesh/Rose-Pine-For-Marp/blob/master/license

  palette in :root
  */

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
  /* Common style */
  h1 {
      color: var(--rose);
      padding-bottom: 2mm;
      margin-bottom: 12mm;
  }
  h2 {
      color: var(--rose);
  }
  h3 {
      color: var(--rose);
  }
  h4 {
      color: var(--rose);
  }
  h5 {
      color: var(--rose);
  }
  h6 {
      color: var(--rose);
  }
  a {
      color: var(--iris);
  }
  p {
      font-size: 20pt;
      font-weight: 600;
      color: var(--text);
  }
  code {
      color: var(--text);
      background-color: var(--highlight-muted);
  }
  text {
      color: var(--text);
  }
  ul {
      color: var(--subtle);
  }
  li {
      color: var(--subtle);
  }
  img {
      background-color: var(--highlight-low);
  }
  strong {
      color: var(--text);
      font-weight: inherit;
      font-weight: 800;
  }
  mjx-container {
      color: var(--text);
  }
  marp-pre {
      background-color: var(--overlay);
      border-color: var(--highlight-high);
  }

  /* Code blok */
  .hljs-comment { color: var(--muted); }
  .hljs-attr { color: var(--foam); }
  .hljs-punctuation { color: var(--subtle); }
  .hljs-string { color: var(--gold); }
  .hljs-title { color: var(--foam); }
  .hljs-keyword { color: var(--pine); }
  .hljs-variable { color: var(--text); }
  .hljs-literal { color: var(--rose); }
  .hljs-type { color: var(--love); }
  .hljs-number { color: var(--gold); }
  .hljs-built_in { color: var(--love); }
  .hljs-params { color: var(--iris); }
  .hljs-symbol { color: var(--foam); }
  .hljs-meta { color: var(--subtle); }
---

# Trabalho Prático - Sistemas Especialistas 
## Introdução à Inteligência Artificial 

**Universidade Estadual de Maringá** **Departamento de Informática** * **Professor:** Wagner Igarashi 
* **Alunos:** [Nome 1], [Nome 2], [Nome 3] 
* **Tema:** [Inserir o tema escolhido do Anexo A ou outro tema previamente informado ao professor] 

---

# Introdução e Modelagem do Problema 

* **Objetivo:** Desenvolver um sistema especialista em linguagem lógica, aplicando conceitos de representação de conhecimento, raciocínio lógico, explicabilidade e probabilidade.
* **O Problema:** [Descreva brevemente o problema que o seu sistema resolve dentro do tema escolhido]
* **Entidades Principais:** [Liste as principais entidades que serão controladas, ex: pacientes, veículos, culturas]

---

# Fundamentação Teórica 

* **Sistemas Especialistas:** Modelagem baseada nos conceitos de Russell & Norvig.
* **Representação de Conhecimento:** [Explique brevemente como o conhecimento da sua área escolhida foi estruturado]
* **Probabilidade:** [Explique a teoria base usada para lidar com a incerteza nos diagnósticos ou recomendações] 

---

# Materiais e Métodos 

* **Base de Conhecimento:** Construção de uma base contendo fatos e regras, com as hipóteses possuindo probabilidades associadas.
* **Controle de Entidades:** Implementação de CRUD (consulta, inclusão, alteração, exclusão) executado em tempo real.
* **Interface (IHC):** Interação via console onde o usuário informa condições e recebe os resultados ordenados.

---

# Desenvolvimento 

* **Cálculo de Probabilidade:** O sistema ordena os diagnósticos de forma decrescente. O critério utilizado foi: [Explicar o critério matemático ou lógico utilizado no código].
* **Testes Unitários:** Foram implementados testes focados em validar diagnóstico, explicabilidade, CRUD e cálculo de probabilidades.
* **Explicabilidade (Rastreio):** O sistema consegue informar quais regras foram ativadas e justificar por que uma hipótese foi ou não diagnosticada.

---

# Demonstração Prática 

> **Aviso Importante do Sistema:**
> "Este protótipo é apenas informativo. Consulte um especialista para diagnóstico ou recomendação correta e precisa." 

*Apresentação ao vivo dos tipos de consultas possíveis, demonstrando a interação via console.* ---

# Conclusões 

* **Resultados Alcançados:** [Relatar se a base de dados ficou completa e se o sistema teve um comportamento correto].
* **Qualidade da Interface:** [Comentar sobre a usabilidade da interação via console].
* **Dificuldades Encontradas:** [Listar desafios na implementação do CRUD, testes unitários ou explicabilidade].

---

# Referências Bibliográficas 

* RUSSELL, S.; NORVIG, P. *Inteligência Artificial*. 
* [Inserir outras referências bibliográficas utilizadas para a fundamentação teórica ou construção da base de dados do tema]