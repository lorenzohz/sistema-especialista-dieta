% TESTES UNITARIOS - Sistema Especialista de Dietas (Modelo LPO)
% Executar:
%   swipl -q -g "executar_testes_sistema" -t halt testes_unitarios.pl

:- set_prolog_flag(encoding, utf8).
:- use_module(library(plunit)).
:- consult('motor_inferencia.pl').

% HELPERS -----------------------------------------------------------------------

individuo_teste(usuario_teste).

limpar_fatos :-
    individuo_teste(X),
    definir_individuo_atual(X),
    limpar_respostas(X).

registrar_lista(_, []).
registrar_lista(X, [Attr-Val | Resto]) :-
    registrar_resposta(X, Attr, Val),
    registrar_lista(X, Resto).

assert_respostas(Pares) :-
    individuo_teste(X),
    registrar_lista(X, Pares).

perfil_perda_peso :-
    assert_respostas([
        objetivo-perda_peso,
        nivel_atividade-sedentario,
        faixa_etaria-adulto,
        imc_faixa-sobrepeso,
        tem_diabetes-nao,
        tem_hipertensao-nao,
        tem_colesterol_alto-nao,
        tem_problemas_renais-nao,
        tem_doenca_cardiaca-nao,
        restricao_carne-nao,
        alergia_lactose-nao,
        restricao_gluten-nao,
        tempo_preparo-media,
        orcamento-flexivel,
        disposicao_restricao-nao
    ]).

perfil_vegetariano :-
    assert_respostas([
        objetivo-saude_geral,
        nivel_atividade-moderado,
        faixa_etaria-adulto,
        imc_faixa-normal,
        tem_diabetes-nao,
        tem_hipertensao-nao,
        tem_colesterol_alto-nao,
        tem_problemas_renais-nao,
        tem_doenca_cardiaca-nao,
        restricao_carne-sim,
        restricao_laticinios-nao,
        alergia_lactose-nao,
        restricao_gluten-nao,
        tempo_preparo-media,
        orcamento-flexivel
    ]).

perfil_cardiovascular :-
    assert_respostas([
        objetivo-controle_cronicas,
        nivel_atividade-leve,
        faixa_etaria-idoso,
        imc_faixa-sobrepeso,
        tem_diabetes-nao,
        tem_hipertensao-sim,
        tem_colesterol_alto-sim,
        tem_problemas_renais-nao,
        tem_doenca_cardiaca-nao,
        restricao_carne-nao,
        alergia_lactose-nao,
        restricao_gluten-nao,
        tempo_preparo-media,
        orcamento-flexivel
    ]).

% SUITE 1 - Calculo de Score ----------------------------------------------------

:- begin_tests(calculo_score_lpo).

test(score_base_sem_fatos,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    dieta(low_carb, _, ProbBase),
    calcular_score(low_carb, X, S),
    S =:= ProbBase.

test(score_cresce_com_evidencia,
    [ setup((limpar_fatos, assert_respostas([objetivo-perda_peso]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    dieta(low_carb, _, ProbBase),
    calcular_score(low_carb, X, S),
    S > ProbBase.

test(score_inalterado_por_fato_irrelevante,
    [ setup((limpar_fatos, assert_respostas([objetivo-ganho_massa]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    dieta(low_carb, _, ProbBase),
    calcular_score(low_carb, X, S),
    S =:= ProbBase.

test(score_limitado_a_0_99,
    [ setup((limpar_fatos,
             assert_respostas([
                 objetivo-perda_peso,
                 nivel_atividade-sedentario,
                 tem_diabetes-sim,
                 tipo_diabetes-tipo_2,
                 imc_faixa-obesidade,
                 restricao_carne-nao,
                 disposicao_restricao-sim
             ]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    calcular_score(low_carb, X, S),
    S =< 0.99.

test(score_dash_supera_hiperproteica_no_perfil_cardiovascular,
    [ setup((limpar_fatos, perfil_cardiovascular)),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    calcular_score(dash, X, SD),
    calcular_score(hiperproteica, X, SH),
    SD > SH.

test(score_cetogenica_alto_com_t2,
    [ setup((limpar_fatos,
             assert_respostas([
                 tem_diabetes-sim,
                 tipo_diabetes-tipo_2,
                 disposicao_restricao-sim,
                 objetivo-perda_peso
             ]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    dieta(cetogenica, _, ProbBase),
    calcular_score(cetogenica, X, S),
    S > ProbBase + 0.40.

test(score_sem_gluten_alto_com_restricao_gluten,
    [ setup((limpar_fatos, assert_respostas([restricao_gluten-sim]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    dieta(sem_gluten, _, ProbBase),
    calcular_score(sem_gluten, X, S),
    S > ProbBase + 0.40.

test(calcular_score_2_respeita_individuo_atual,
    [ setup((limpar_fatos, assert_respostas([objetivo-perda_peso]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    definir_individuo_atual(X),
    calcular_score(low_carb, X, SX),
    calcular_score(low_carb, SAtual),
    SX =:= SAtual.

:- end_tests(calculo_score_lpo).

% SUITE 2 - Contraindicacoes ----------------------------------------------------

:- begin_tests(contraindicacoes_lpo).

test(cetogenica_contraindicada_por_doenca_cardiaca,
    [ setup((limpar_fatos, assert_respostas([tem_doenca_cardiaca-sim]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    once(contraindicada(cetogenica, X)).

test(cetogenica_contraindicada_sem_disposicao,
    [ setup((limpar_fatos, assert_respostas([disposicao_restricao-nao]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    once(contraindicada(cetogenica, X)).

test(cetogenica_contraindicada_por_tipo_1,
    [ setup((limpar_fatos, assert_respostas([tem_diabetes-sim, tipo_diabetes-tipo_1]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    contraindicada(cetogenica, X).

test(hiperproteica_contraindicada_em_renal,
    [ setup((limpar_fatos, assert_respostas([tem_problemas_renais-sim]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    contraindicada(hiperproteica, X).

test(hiperproteica_contraindicada_para_restricao_carne,
    [ setup((limpar_fatos, assert_respostas([restricao_carne-sim]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    once(contraindicada(hiperproteica, X)).

test(mediterranea_contraindicada_tempo_baixo,
    [ setup((limpar_fatos, assert_respostas([tempo_preparo-baixa]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    once(contraindicada(mediterranea, X)).

test(mediterranea_contraindicada_orcamento_baixo,
    [ setup((limpar_fatos, assert_respostas([orcamento-baixo]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    once(contraindicada(mediterranea, X)).

test(paleolitica_contraindicada_orcamento_baixo,
    [ setup((limpar_fatos, assert_respostas([orcamento-baixo]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    once(contraindicada(paleolitica, X)).

test(low_fat_contraindicada_para_ganho_massa,
    [ setup((limpar_fatos, assert_respostas([objetivo-ganho_massa]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    once(contraindicada(low_fat, X)).

test(low_carb_nao_contraindicada_sem_conflitos,
    [ setup((limpar_fatos, perfil_perda_peso)),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    nao_contraindicada(low_carb, X).

:- end_tests(contraindicacoes_lpo).

% SUITE 3 - Recomendacoes -------------------------------------------------------

:- begin_tests(recomendacoes_lpo).

test(retorna_lista_nao_vazia,
    [ setup((limpar_fatos, perfil_perda_peso)),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    recomendar(X, Lista),
    Lista \= [].

test(lista_ordenada_decrescente,
    [ setup((limpar_fatos, perfil_perda_peso)),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    recomendar(X, Lista),
    verificar_ordem_decrescente(Lista).

verificar_ordem_decrescente([]) :- !.
verificar_ordem_decrescente([_]) :- !.
verificar_ordem_decrescente([S1-_-_ | Resto]) :-
    Resto = [S2-_-_ | _],
    S1 >= S2,
    verificar_ordem_decrescente(Resto).

test(hiperproteica_ausente_para_vegetariano,
    [ setup((limpar_fatos, perfil_vegetariano)),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    recomendar(X, Lista),
    \+ member(_-hiperproteica-_, Lista).

test(vegetariana_presente_para_vegetariano,
    [ setup((limpar_fatos, perfil_vegetariano)),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    recomendar(X, Lista),
    once(member(_-vegetariana-_, Lista)).

test(dash_top3_para_perfil_cardiovascular,
    [ setup((limpar_fatos, perfil_cardiovascular)),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    recomendar(X, Lista),
    once(nth1(Pos, Lista, _-dash-_)),
    Pos =< 3.

test(cetogenica_ausente_quando_colesterol_alto,
    [ setup((limpar_fatos,
             assert_respostas([
                 tem_colesterol_alto-sim,
                 objetivo-perda_peso,
                 disposicao_restricao-sim
             ]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    recomendar(X, Lista),
    \+ member(_-cetogenica-_, Lista).

test(recomendar_2_respeita_individuo_atual,
    [ setup((limpar_fatos, perfil_perda_peso)),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    definir_individuo_atual(X),
    recomendar(X, ListaX),
    recomendar(ListaAtual),
    ListaX = ListaAtual.

test(low_fat_ausente_em_ganho_massa,
    [ setup((limpar_fatos,
             assert_respostas([
                 objetivo-ganho_massa,
                 nivel_atividade-intenso,
                 restricao_carne-nao
             ]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    recomendar(X, Lista),
    \+ member(_-low_fat-_, Lista).

:- end_tests(recomendacoes_lpo).

% SUITE 4 - Perguntas condicionais ----------------------------------------------

:- begin_tests(perguntas_condicionais_lpo).

test(sem_fatos_nenhuma_condicional,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    listar_perguntas_condicionais_ativas(X, L),
    L = [].

test(sim_carne_ativa_pergunta_laticinios,
    [ setup((limpar_fatos, assert_respostas([restricao_carne-sim]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    listar_perguntas_condicionais_ativas(X, L),
    member(restricao_laticinios, L).

test(nao_carne_ativa_frequencia,
    [ setup((limpar_fatos, assert_respostas([restricao_carne-nao]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    listar_perguntas_condicionais_ativas(X, L),
    member(frequencia_carne, L).

test(perda_peso_ativa_disposicao,
    [ setup((limpar_fatos, assert_respostas([objetivo-perda_peso]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    listar_perguntas_condicionais_ativas(X, L),
    member(disposicao_restricao, L).

test(diabetes_ativa_tipo_diabetes,
    [ setup((limpar_fatos, assert_respostas([tem_diabetes-sim]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    listar_perguntas_condicionais_ativas(X, L),
    member(tipo_diabetes, L).

test(condicional_nao_repete_apos_resposta,
    [ setup((limpar_fatos,
             assert_respostas([restricao_carne-sim, restricao_laticinios-nao]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    listar_perguntas_condicionais_ativas(X, L),
    \+ member(restricao_laticinios, L).

test(tipo_diabetes_nao_ativa_quando_sem_diabetes,
    [ setup((limpar_fatos, assert_respostas([tem_diabetes-nao]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    listar_perguntas_condicionais_ativas(X, L),
    \+ member(tipo_diabetes, L).

:- end_tests(perguntas_condicionais_lpo).

% SUITE 5 - Modelo relacional ---------------------------------------------------

:- begin_tests(modelo_relacional_lpo).

test(registro_relacao_doenca_sim,
    [ setup((limpar_fatos, assert_respostas([tem_diabetes-sim]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    tem_doenca(X, diabetes),
    once(resposta_usuario(X, tem_diabetes, sim)).

test(registro_relacao_doenca_nao,
    [ setup((limpar_fatos, assert_respostas([tem_diabetes-nao]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    nao_tem_doenca(X, diabetes),
    once(resposta_usuario(X, tem_diabetes, nao)).

test(registro_relacao_restricao,
    [ setup((limpar_fatos, assert_respostas([restricao_gluten-sim]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    tem_restricao(X, gluten),
    once(resposta_usuario(X, restricao_gluten, sim)).

test(evidencia_dispara_com_relacao,
    [ setup((limpar_fatos, assert_respostas([objetivo-perda_peso]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    evidencia(low_carb, X, 0.25).

test(contraindicacao_estrita_sem_peso,
    [ setup((limpar_fatos, assert_respostas([tem_doenca_cardiaca-sim]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    once(contraindicada(cetogenica, X)).

test(tem_diabetes_nao_limpa_tipo_diabetes,
    [ setup((limpar_fatos,
             assert_respostas([tem_diabetes-sim, tipo_diabetes-tipo_2, tem_diabetes-nao]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    \+ tem_tipo_diabetes(X, _),
    once(resposta_usuario(X, tem_diabetes, nao)).

test(definir_individuo_atual_garante_paciente,
    [ setup(limpar_fatos),
      cleanup((retractall(paciente(usuario_extra_teste)), limpar_fatos)) ]) :-
    definir_individuo_atual(usuario_extra_teste),
    paciente(usuario_extra_teste).

:- end_tests(modelo_relacional_lpo).

% SUITE 6 - Explicabilidade -----------------------------------------------------

:- begin_tests(explicabilidade_lpo).

test(fatos_confirmados_tem_pesos_ativos,
    [ setup((limpar_fatos, assert_respostas([objetivo-perda_peso]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    fatos_confirmados(low_carb, X, Pesos),
    member(0.25, Pesos).

test(razoes_exclusao_nao_vazia_em_conflito,
    [ setup((limpar_fatos, assert_respostas([tem_colesterol_alto-sim]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    razoes_exclusao(cetogenica, X, Razoes),
    Razoes \= [].

test(razoes_exclusao_vazia_sem_conflito,
    [ setup((limpar_fatos, assert_respostas([objetivo-perda_peso]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    razoes_exclusao(low_carb, X, Razoes),
    Razoes = [].

test(razoes_exclusao_multiplas_para_cetogenica,
    [ setup((limpar_fatos,
             assert_respostas([tem_colesterol_alto-sim, tem_doenca_cardiaca-sim]))),
      cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    razoes_exclusao(cetogenica, X, Razoes),
    length(Razoes, N),
    N >= 2.

test(fatos_confirmados_vazio_sem_evidencias,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    individuo_teste(X),
    fatos_confirmados(low_carb, X, Pesos),
    Pesos = [].

test(detalhes_pergunta_retorna_estrutura_correta) :-
    detalhes_pergunta(objetivo, Texto, Opcoes, Justificativa),
    string_length(Texto, TLen), TLen > 5,
    is_list(Opcoes), Opcoes \= [],
    string_length(Justificativa, JLen), JLen > 5.

test(gatilho_pergunta_tipo_diabetes) :-
    gatilho_pergunta(tipo_diabetes, tem_diabetes, sim).

:- end_tests(explicabilidade_lpo).

% Auxiliar para interface Python ------------------------------------------------

executar_testes_sistema :-
    set_test_options([format(log), output(always)]),
    run_tests.
