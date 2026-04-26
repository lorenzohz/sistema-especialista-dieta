:- set_prolog_flag(encoding, utf8).
:- use_module(library(lists)).

:- consult('base_conhecimento.pl').

:- dynamic paciente_atual/1.
paciente_atual(usuario_atual).

% CONTEXTO DO INDIVIDUO ---------------------------------------------------------

definir_individuo_atual(X) :-
    retractall(paciente_atual(_)),
    assertz(paciente_atual(X)),
    (paciente(X) -> true ; assertz(paciente(X))).

individuo_atual(X) :-
    paciente_atual(X).

limpar_sessao_atual :-
    individuo_atual(X),
    limpar_respostas(X).

% INFERENCIA --------------------------------------------------------------------
% Score = min(0.99, ProbBase + soma das evidencias satisfeitas)

calcular_score(Dieta, X, Score) :-
    dieta(Dieta, _, ProbBase),
    findall(Peso, evidencia(Dieta, X, Peso), Pesos),
    sum_list(Pesos, Soma),
    Score is min(0.99, ProbBase + Soma).

calcular_score(Dieta, Score) :-
    individuo_atual(X),
    calcular_score(Dieta, X, Score).

nao_contraindicada(Dieta, X) :-
    \+ contraindicada(Dieta, X).

nao_excluida(Dieta) :-
    individuo_atual(X),
    nao_contraindicada(Dieta, X).

recomendar(X, Lista) :-
    findall(Score-Dieta-Nome, (
        dieta(Dieta, Nome, _),
        nao_contraindicada(Dieta, X),
        calcular_score(Dieta, X, Score)
    ), Unsorted),
    msort(Unsorted, Sorted),
    reverse(Sorted, Lista).

recomendar(Lista) :-
    individuo_atual(X),
    recomendar(X, Lista).

% EXPLICABILIDADE ----------------------------------------------------------------

fatos_confirmados(Dieta, X, Pesos) :-
    findall(Peso, evidencia(Dieta, X, Peso), Pesos).

fatos_confirmados(Dieta, Pesos) :-
    individuo_atual(X),
    fatos_confirmados(Dieta, X, Pesos).

razoes_exclusao(Dieta, X, Razoes) :-
    findall(true, contraindicada(Dieta, X), Razoes).

razoes_exclusao(Dieta, Razoes) :-
    individuo_atual(X),
    razoes_exclusao(Dieta, X, Razoes).

% INTERFACE DE PERGUNTAS ---------------------------------------------------------

listar_perguntas_base(Lista) :-
    findall(Attr, pergunta(Attr, base, _, _, _), Lista).

listar_perguntas_condicionais_ativas(X, Lista) :-
    findall(Attr, (
        pergunta(Attr, depende(AttrPai, ValEsperado), _, _, _),
        resposta_usuario(X, AttrPai, ValEsperado),
        \+ resposta_usuario(X, Attr, _)
    ), Lista).

listar_perguntas_condicionais_ativas(Lista) :-
    individuo_atual(X),
    listar_perguntas_condicionais_ativas(X, Lista).

detalhes_pergunta(Attr, Texto, Opcoes, Justificativa) :-
    pergunta(Attr, _, Texto, Opcoes, Justificativa).

gatilho_pergunta(Attr, AttrPai, Val) :-
    pergunta(Attr, depende(AttrPai, Val), _, _, _).
