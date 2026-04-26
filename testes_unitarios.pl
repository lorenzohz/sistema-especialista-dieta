%  TESTES UNITARIOS — Sistema Especialista de Dietas
%  Arquivo: testes_unitarios.pl
%
%  Utiliza PLUnit (nativo SWI-Prolog).
%  Pode ser executado:
%    - Diretamente: swipl -g "run_tests" testes_unitarios.pl
%    - Via interface Python (opcao 3 do menu principal)
%
%  Suites cobertas:
%    1. calculo_score           - Score com modelo de probabilidade
%    2. regras_exclusao         - Exclusao de dietas incompativeis
%    3. recomendacoes           - Ordenacao e filtragem do resultado
%    4. perguntas_condicionais  - Ativacao dinamica de perguntas
%    5. crud_dietas             - CRUD da entidade Dieta
%    6. crud_suportes           - CRUD das regras de suporte/peso
%    7. crud_exclusoes          - CRUD das regras de exclusao
%    8. explicabilidade         - Fatos confirmados / faltantes / razoes

:- set_prolog_flag(encoding, utf8).
:- use_module(library(plunit)).
:- consult('motor_inferencia.pl').

% HELPERS ------------------------------------------------------

limpar_fatos :-
    retractall(user:user_fact(_, _)).

assert_fatos([]).
assert_fatos([Attr-Val | Resto]) :-
    assertz(user:user_fact(Attr, Val)),
    assert_fatos(Resto).

% Perfil tipico de perda de peso sem comorbidades
perfil_perda_peso :-
    assert_fatos([
        objetivo              - perda_peso,
        nivel_atividade       - sedentario,
        faixa_etaria          - adulto,
        imc_faixa             - sobrepeso,
        tem_diabetes          - nao,
        tem_hipertensao       - nao,
        tem_colesterol_alto   - nao,
        tem_problemas_renais  - nao,
        tem_doenca_cardiaca   - nao,
        restricao_carne       - nao,
        alergia_lactose       - nao,
        restricao_gluten      - nao,
        tempo_preparo         - media,
        orcamento             - flexivel,
        disposicao_restricao  - nao
    ]).

% Perfil vegetariano sem restricao a laticinios
perfil_vegetariano :-
    assert_fatos([
        objetivo              - saude_geral,
        nivel_atividade       - moderado,
        faixa_etaria          - adulto,
        imc_faixa             - normal,
        tem_diabetes          - nao,
        tem_hipertensao       - nao,
        tem_colesterol_alto   - nao,
        tem_problemas_renais  - nao,
        tem_doenca_cardiaca   - nao,
        restricao_carne       - sim,
        restricao_laticinios  - nao,
        alergia_lactose       - nao,
        restricao_gluten      - nao,
        tempo_preparo         - media,
        orcamento             - flexivel
    ]).

% Perfil com hipertensao e colesterol alto — idoso
perfil_cardiovascular :-
    assert_fatos([
        objetivo              - controle_cronicas,
        nivel_atividade       - leve,
        faixa_etaria          - idoso,
        imc_faixa             - sobrepeso,
        tem_diabetes          - nao,
        tem_hipertensao       - sim,
        tem_colesterol_alto   - sim,
        tem_problemas_renais  - nao,
        tem_doenca_cardiaca   - nao,
        restricao_carne       - nao,
        alergia_lactose       - nao,
        restricao_gluten      - nao,
        tempo_preparo         - media,
        orcamento             - flexivel
    ]).


% SUITE 1 — Calculo de Score -----------------------------------

:- begin_tests(calculo_score).

% Sem nenhum fato, score == probabilidade a priori
test(score_base_sem_fatos,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    dieta(low_carb, _, ProbBase),
    calcular_score(low_carb, S),
    S =:= ProbBase.

% Um fato suportado deve aumentar o score
test(score_cresce_com_fato_suportado,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, perda_peso)))),
      cleanup(limpar_fatos) ]) :-
    dieta(low_carb, _, ProbBase),
    calcular_score(low_carb, S),
    S > ProbBase.

% Fato irrelevante para a dieta nao altera o score
test(score_inalterado_por_fato_irrelevante,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, ganho_massa)))),
      cleanup(limpar_fatos) ]) :-
    dieta(low_carb, _, ProbBase),
    calcular_score(low_carb, S),
    S =:= ProbBase.

% Teto de 0.99 deve ser respeitado mesmo com muitos fatos favoraveis
test(score_limitado_a_0_99,
    [ setup((limpar_fatos,
             assert_fatos([objetivo-perda_peso,
                           nivel_atividade-sedentario,
                           tem_diabetes-sim,
                           imc_faixa-obesidade,
                           restricao_carne-nao,
                           disposicao_restricao-sim]))),
      cleanup(limpar_fatos) ]) :-
    calcular_score(low_carb, S),
    S =< 0.99.

% Score e numerico (float), nunca unificado com atomo
test(score_retorna_numero,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    calcular_score(mediterranea, S),
    number(S).

% Hiperproteica deve superar low_fat no perfil de ganho de massa
test(score_hiperproteica_supera_low_fat_em_ganho_massa,
    [ setup((limpar_fatos,
             assert_fatos([objetivo-ganho_massa,
                           nivel_atividade-intenso,
                           restricao_carne-nao]))),
      cleanup(limpar_fatos) ]) :-
    calcular_score(hiperproteica, SH),
    calcular_score(low_fat, SL),
    SH > SL.

% DASH deve pontuar alto com hipertensao
test(score_dash_alto_com_hipertensao,
    [ setup((limpar_fatos,
             assert_fatos([tem_hipertensao-sim,
                           objetivo-controle_cronicas]))),
      cleanup(limpar_fatos) ]) :-
    dieta(dash, _, ProbBase),
    calcular_score(dash, S),
    S > ProbBase + 0.30.

% Cetogenica deve pontuar alto com diabetes tipo 2 e disposicao a restricao
test(score_cetogenica_alto_com_diabetes_t2,
    [ setup((limpar_fatos,
             assert_fatos([tem_diabetes-sim,
                           tipo_diabetes-tipo_2,
                           disposicao_restricao-sim,
                           objetivo-perda_peso]))),
      cleanup(limpar_fatos) ]) :-
    dieta(cetogenica, _, ProbBase),
    calcular_score(cetogenica, S),
    S > ProbBase + 0.40.

% Sem gluten pontua alto quando restricao_gluten=sim
test(score_sem_gluten_alto_com_restricao_gluten,
    [ setup((limpar_fatos,
             assertz(user:user_fact(restricao_gluten, sim)))),
      cleanup(limpar_fatos) ]) :-
    dieta(sem_gluten, _, ProbBase),
    calcular_score(sem_gluten, S),
    S > ProbBase + 0.40.

% DASH deve superar hiperproteica para perfil cardiovascular
test(score_dash_supera_hiperproteica_para_cardiovascular,
    [ setup((limpar_fatos, perfil_cardiovascular)),
      cleanup(limpar_fatos) ]) :-
    calcular_score(dash, SD),
    calcular_score(hiperproteica, SH),
    SD > SH.

:- end_tests(calculo_score).


% SUITE 2 — Regras de Exclusao ---------------------------------

:- begin_tests(regras_exclusao).

% Sem fatos conflitantes, low_carb nao e excluida
test(low_carb_nao_excluida_sem_conflito,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    nao_excluida(low_carb).

% Vegetariano nao pode seguir hiperproteica baseada em carne
test(hiperproteica_excluida_para_vegetariano,
    [ setup((limpar_fatos, assertz(user:user_fact(restricao_carne, sim)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(hiperproteica).

% Sem disposicao para cortar carboidratos → cetogenica excluida
test(cetogenica_excluida_sem_disposicao,
    [ setup((limpar_fatos, assertz(user:user_fact(disposicao_restricao, nao)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(cetogenica).

% Pouco tempo de preparo → mediterranea excluida
test(mediterranea_excluida_por_tempo_baixo,
    [ setup((limpar_fatos, assertz(user:user_fact(tempo_preparo, baixa)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(mediterranea).

% Problemas renais → hiperproteica excluida (sobrecarga renal)
test(hiperproteica_excluida_por_problema_renal,
    [ setup((limpar_fatos, assertz(user:user_fact(tem_problemas_renais, sim)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(hiperproteica).

% Colesterol alto → cetogenica excluida (alto consumo de gordura saturada)
test(cetogenica_excluida_por_colesterol_alto,
    [ setup((limpar_fatos, assertz(user:user_fact(tem_colesterol_alto, sim)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(cetogenica).

% Doenca cardiaca → cetogenica excluida (risco cardiovascular)
test(cetogenica_excluida_por_doenca_cardiaca,
    [ setup((limpar_fatos, assertz(user:user_fact(tem_doenca_cardiaca, sim)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(cetogenica).

% Diabetes tipo 1 → cetogenica excluida (risco sem supervisao medica)
test(cetogenica_excluida_por_diabetes_tipo1,
    [ setup((limpar_fatos,
             assert_fatos([tem_diabetes-sim, tipo_diabetes-tipo_1]))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(cetogenica).

% Objetivo ganho de massa → low_fat excluida
test(low_fat_excluida_para_ganho_massa,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, ganho_massa)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(low_fat).

% Orcamento baixo → mediterranea excluida
test(mediterranea_excluida_por_orcamento_baixo,
    [ setup((limpar_fatos, assertz(user:user_fact(orcamento, baixo)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(mediterranea).

% Vegana excluida com pouco tempo (requer planejamento rigoroso)
test(vegana_excluida_por_tempo_baixo,
    [ setup((limpar_fatos, assertz(user:user_fact(tempo_preparo, baixa)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(vegana).

% Problemas renais → paleolitica excluida (alto consumo de proteina animal)
test(paleolitica_excluida_por_problema_renal,
    [ setup((limpar_fatos, assertz(user:user_fact(tem_problemas_renais, sim)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(paleolitica).

:- end_tests(regras_exclusao).


% SUITE 3 — Recomendacoes --------------------------------------

:- begin_tests(recomendacoes).

% Retorna lista nao-vazia para perfil valido
test(retorna_lista_nao_vazia,
    [ setup((limpar_fatos, perfil_perda_peso)),
      cleanup(limpar_fatos) ]) :-
    recomendar(Lista),
    Lista \= [].

% Lista ordenada por score decrescente
test(lista_ordenada_decrescente,
    [ setup((limpar_fatos, perfil_perda_peso)),
      cleanup(limpar_fatos) ]) :-
    recomendar(Lista),
    verificar_ordem_decrescente(Lista).

verificar_ordem_decrescente([]) :- !.
verificar_ordem_decrescente([_]) :- !.
verificar_ordem_decrescente([S1-_-_ | Resto]) :-
    Resto = [S2-_-_ | _],
    S1 >= S2,
    verificar_ordem_decrescente(Resto).

% Hiperproteica nao aparece para vegetariano (excluida)
test(hiperproteica_ausente_para_vegetariano,
    [ setup((limpar_fatos, perfil_vegetariano)),
      cleanup(limpar_fatos) ]) :-
    recomendar(Lista),
    \+ member(_-hiperproteica-_, Lista).

% Vegetariana aparece para vegetariano (sem restricao a laticinios)
test(vegetariana_presente_para_vegetariano,
    [ setup((limpar_fatos, perfil_vegetariano)),
      cleanup(limpar_fatos) ]) :-
    recomendar(Lista),
    once(member(_-vegetariana-_, Lista)).

% Todos os scores estao no intervalo [0, 0.99]
test(todos_scores_no_intervalo_valido,
    [ setup((limpar_fatos, perfil_perda_peso)),
      cleanup(limpar_fatos) ]) :-
    recomendar(Lista),
    forall(member(S-_-_, Lista), (S >= 0, S =< 0.99)).

% DASH deve estar no top 3 para perfil cardiovascular
test(dash_top3_para_perfil_cardiovascular,
    [ setup((limpar_fatos, perfil_cardiovascular)),
      cleanup(limpar_fatos) ]) :-
    recomendar(Lista),
    once(nth1(Pos, Lista, _-dash-_)),
    Pos =< 3.

% Cetogenica nao aparece para quem tem colesterol alto (exclusao)
test(cetogenica_ausente_com_colesterol_alto,
    [ setup((limpar_fatos,
             assert_fatos([tem_colesterol_alto-sim,
                           disposicao_restricao-sim,
                           objetivo-perda_peso]))),
      cleanup(limpar_fatos) ]) :-
    recomendar(Lista),
    \+ member(_-cetogenica-_, Lista).

:- end_tests(recomendacoes).


% SUITE 4 — Perguntas Condicionais -----------------------------

:- begin_tests(perguntas_condicionais).

% Sem fatos, nenhuma pergunta condicional ativa
test(sem_fatos_nenhuma_condicional,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    listar_perguntas_condicionais_ativas(L),
    L = [].

% restricao_carne=sim deve ativar a pergunta sobre laticinios
test(sim_carne_ativa_pergunta_laticinios,
    [ setup((limpar_fatos, assertz(user:user_fact(restricao_carne, sim)))),
      cleanup(limpar_fatos) ]) :-
    listar_perguntas_condicionais_ativas(L),
    member(restricao_laticinios, L).

% restricao_carne=nao deve ativar a pergunta sobre frequencia de consumo
test(nao_carne_ativa_frequencia,
    [ setup((limpar_fatos, assertz(user:user_fact(restricao_carne, nao)))),
      cleanup(limpar_fatos) ]) :-
    listar_perguntas_condicionais_ativas(L),
    member(frequencia_carne, L).

% objetivo=perda_peso deve ativar a pergunta sobre disposicao de restricao
test(perda_peso_ativa_disposicao,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, perda_peso)))),
      cleanup(limpar_fatos) ]) :-
    listar_perguntas_condicionais_ativas(L),
    member(disposicao_restricao, L).

% tem_diabetes=sim deve ativar a pergunta sobre tipo de diabetes
test(diabetes_ativa_tipo_diabetes,
    [ setup((limpar_fatos, assertz(user:user_fact(tem_diabetes, sim)))),
      cleanup(limpar_fatos) ]) :-
    listar_perguntas_condicionais_ativas(L),
    member(tipo_diabetes, L).

% Pergunta condicional nao e repetida apos ser respondida
test(condicional_nao_repete_se_ja_respondida,
    [ setup((limpar_fatos,
             assertz(user:user_fact(restricao_carne, sim)),
             assertz(user:user_fact(restricao_laticinios, nao)))),
      cleanup(limpar_fatos) ]) :-
    listar_perguntas_condicionais_ativas(L),
    \+ member(restricao_laticinios, L).

% tipo_diabetes nao ativa se tem_diabetes=nao
test(tipo_diabetes_nao_ativa_sem_diabetes,
    [ setup((limpar_fatos, assertz(user:user_fact(tem_diabetes, nao)))),
      cleanup(limpar_fatos) ]) :-
    listar_perguntas_condicionais_ativas(L),
    \+ member(tipo_diabetes, L).

:- end_tests(perguntas_condicionais).


% SUITE 5 — CRUD Dietas ----------------------------------------

:- begin_tests(crud_dietas).

cleanup_dieta_crud :-
    retractall(user:dieta(dieta_crud_teste, _, _)),
    retractall(user:descricao_dieta(dieta_crud_teste, _)),
    retractall(user:suporta(dieta_crud_teste, _, _, _)),
    retractall(user:exclui(dieta_crud_teste, _, _)).

% Inclusao cria os predicados dieta/3 e descricao_dieta/2
test(incluir_nova_dieta,
    [ setup(cleanup_dieta_crud), cleanup(cleanup_dieta_crud) ]) :-
    incluir_dieta(dieta_crud_teste, 'Dieta Teste', 0.50, 'Descricao de teste'),
    dieta(dieta_crud_teste, 'Dieta Teste', 0.50),
    descricao_dieta(dieta_crud_teste, 'Descricao de teste').

% Nao permite incluir dieta com ID ja existente
test(incluir_dieta_duplicada_falha,
    [ setup((cleanup_dieta_crud,
             incluir_dieta(dieta_crud_teste, 'Orig', 0.50, 'Desc'))),
      cleanup(cleanup_dieta_crud) ]) :-
    \+ incluir_dieta(dieta_crud_teste, 'Dup', 0.60, 'Desc2').

% Alteracao atualiza nome, probabilidade e descricao
test(alterar_dieta_existente,
    [ setup((cleanup_dieta_crud,
             incluir_dieta(dieta_crud_teste, 'Velha', 0.30, 'Desc velha'))),
      cleanup(cleanup_dieta_crud) ]) :-
    alterar_dieta(dieta_crud_teste, 'Nova', 0.75, 'Desc nova'),
    dieta(dieta_crud_teste, 'Nova', 0.75),
    descricao_dieta(dieta_crud_teste, 'Desc nova').

% Exclusao remove dieta e todos os fatos associados
test(excluir_dieta_remove_tudo,
    [ setup((cleanup_dieta_crud,
             incluir_dieta(dieta_crud_teste, 'Del', 0.50, 'Desc'),
             assertz(user:suporta(dieta_crud_teste, objetivo, saude_geral, 0.10)),
             assertz(user:exclui(dieta_crud_teste, orcamento, baixo)))),
      cleanup(cleanup_dieta_crud) ]) :-
    excluir_dieta(dieta_crud_teste),
    \+ dieta(dieta_crud_teste, _, _),
    \+ descricao_dieta(dieta_crud_teste, _),
    \+ suporta(dieta_crud_teste, _, _, _),
    \+ exclui(dieta_crud_teste, _, _).

:- end_tests(crud_dietas).


% SUITE 6 — CRUD Suportes (Pesos) ------------------------------

:- begin_tests(crud_suportes).

cleanup_suporte_crud :-
    retractall(user:suporta(low_carb, nivel_atividade, val_crud_teste, _)).

% Inclusao de suporte persiste na base
test(incluir_suporte,
    [ setup(cleanup_suporte_crud), cleanup(cleanup_suporte_crud) ]) :-
    incluir_suporte(low_carb, nivel_atividade, val_crud_teste, 0.15),
    suporta(low_carb, nivel_atividade, val_crud_teste, 0.15).

% Alteracao de peso atualiza o registro corretamente
test(alterar_peso_suporte,
    [ setup((cleanup_suporte_crud,
             assertz(user:suporta(low_carb, nivel_atividade, val_crud_teste, 0.10)))),
      cleanup(cleanup_suporte_crud) ]) :-
    alterar_suporte(low_carb, nivel_atividade, val_crud_teste, 0.22),
    suporta(low_carb, nivel_atividade, val_crud_teste, 0.22),
    \+ suporta(low_carb, nivel_atividade, val_crud_teste, 0.10).

% Exclusao de suporte remove o registro
test(excluir_suporte,
    [ setup((cleanup_suporte_crud,
             assertz(user:suporta(low_carb, nivel_atividade, val_crud_teste, 0.10)))),
      cleanup(cleanup_suporte_crud) ]) :-
    excluir_suporte(low_carb, nivel_atividade, val_crud_teste),
    \+ suporta(low_carb, nivel_atividade, val_crud_teste, _).

% Novo suporte afeta o score calculado
test(suporte_novo_impacta_score,
    [ setup((limpar_fatos,
             assertz(user:user_fact(objetivo, saude_geral)),
             retractall(user:suporta(low_carb, objetivo, saude_geral, _)))),
      cleanup((limpar_fatos,
               retractall(user:suporta(low_carb, objetivo, saude_geral, _)))) ]) :-
    dieta(low_carb, _, ProbBase),
    calcular_score(low_carb, S0),
    S0 =:= ProbBase,
    incluir_suporte(low_carb, objetivo, saude_geral, 0.20),
    calcular_score(low_carb, S1),
    S1 > S0.

:- end_tests(crud_suportes).


% SUITE 7 — CRUD Exclusoes (Bloqueios) -------------------------

:- begin_tests(crud_exclusoes).

cleanup_excl_crud :-
    retractall(user:exclui(low_carb, attr_crud_excl, val_crud_excl)).

% Inclusao de exclusao persiste
test(incluir_exclusao,
    [ setup(cleanup_excl_crud), cleanup(cleanup_excl_crud) ]) :-
    incluir_exclusao(low_carb, attr_crud_excl, val_crud_excl),
    exclui(low_carb, attr_crud_excl, val_crud_excl).

% Exclusao de uma regra de bloqueio a remove
test(excluir_exclusao,
    [ setup((cleanup_excl_crud,
             assertz(user:exclui(low_carb, attr_crud_excl, val_crud_excl)))),
      cleanup(cleanup_excl_crud) ]) :-
    excluir_exclusao(low_carb, attr_crud_excl, val_crud_excl),
    \+ exclui(low_carb, attr_crud_excl, val_crud_excl).

% Nova exclusao impede a dieta de aparecer quando o fato estiver ativo
test(nova_exclusao_bloqueia_dieta,
    [ setup((limpar_fatos,
             assertz(user:user_fact(objetivo, saude_geral)))),
      cleanup((limpar_fatos,
               retractall(user:exclui(low_carb, objetivo, saude_geral)))) ]) :-
    nao_excluida(low_carb),
    incluir_exclusao(low_carb, objetivo, saude_geral),
    \+ nao_excluida(low_carb).

:- end_tests(crud_exclusoes).


% SUITE 8 — Explicabilidade ------------------------------------

:- begin_tests(explicabilidade).

% fatos_confirmados lista pares corretos para o perfil
test(fatos_confirmados_retorna_fatos_ativos,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, perda_peso)))),
      cleanup(limpar_fatos) ]) :-
    fatos_confirmados(low_carb, Fatos),
    member(objetivo-perda_peso-0.25, Fatos).

% fatos_confirmados deve estar vazio sem fatos ativos
test(fatos_confirmados_vazio_sem_fatos,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    fatos_confirmados(low_carb, Fatos),
    Fatos = [].

% fatos_faltantes lista suportes nao satisfeitos
test(fatos_faltantes_sem_fatos_traz_todos,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    fatos_faltantes(low_carb, Fatos),
    Fatos \= [].

% fatos_faltantes exclui o que ja foi satisfeito
test(fatos_faltantes_exclui_satisfeitos,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, perda_peso)))),
      cleanup(limpar_fatos) ]) :-
    fatos_faltantes(low_carb, Fatos),
    \+ member(objetivo-perda_peso-_, Fatos).

% razoes_exclusao retorna o atributo que causou a exclusao
test(razoes_exclusao_hiperproteica_vegetariano,
    [ setup((limpar_fatos, assertz(user:user_fact(restricao_carne, sim)))),
      cleanup(limpar_fatos) ]) :-
    razoes_exclusao(hiperproteica, Razoes),
    member(restricao_carne-sim, Razoes).

% razoes_exclusao retorna tem_problemas_renais como causa de exclusao da hiperproteica
test(razoes_exclusao_hiperproteica_renal,
    [ setup((limpar_fatos, assertz(user:user_fact(tem_problemas_renais, sim)))),
      cleanup(limpar_fatos) ]) :-
    razoes_exclusao(hiperproteica, Razoes),
    member(tem_problemas_renais-sim, Razoes).

% razoes_exclusao vazia quando nao ha conflito
test(razoes_exclusao_vazia_sem_conflito,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, perda_peso)))),
      cleanup(limpar_fatos) ]) :-
    razoes_exclusao(low_carb, Razoes),
    Razoes = [].

% detalhes_pergunta retorna os campos corretos para atributo base
test(detalhes_pergunta_retorna_estrutura_correta) :-
    detalhes_pergunta(objetivo, Texto, Opcoes, Justificativa),
    string_length(Texto, TLen), TLen > 5,
    is_list(Opcoes), Opcoes \= [],
    string_length(Justificativa, JLen), JLen > 5.

% detalhes_pergunta funciona para novos atributos de saude
test(detalhes_pergunta_tem_hipertensao) :-
    detalhes_pergunta(tem_hipertensao, Texto, Opcoes, _),
    string_length(Texto, TLen), TLen > 5,
    memberchk(sim, Opcoes),
    memberchk(nao, Opcoes).

% detalhes_pergunta para tipo_diabetes (condicional)
test(detalhes_pergunta_tipo_diabetes) :-
    detalhes_pergunta(tipo_diabetes, _, Opcoes, _),
    memberchk(tipo_2, Opcoes),
    memberchk(pre_diabetes, Opcoes).

% gatilho_pergunta identifica a dependencia de restricao_laticinios
test(gatilho_pergunta_restricao_carne_sim) :-
    gatilho_pergunta(restricao_laticinios, restricao_carne, sim).

% gatilho_pergunta identifica a dependencia de tipo_diabetes
test(gatilho_pergunta_tipo_diabetes) :-
    gatilho_pergunta(tipo_diabetes, tem_diabetes, sim).

% gatilho_pergunta identifica a dependencia de disposicao_restricao
test(gatilho_pergunta_disposicao_restricao) :-
    gatilho_pergunta(disposicao_restricao, objetivo, perda_peso).

:- end_tests(explicabilidade).


% PREDICADO AUXILIAR — chamado pela interface Python
% executar_testes_sistema/0

executar_testes_sistema :-
    set_test_options([format(log), output(always)]),
    run_tests.
