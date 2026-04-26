:- set_prolog_flag(encoding, utf8).

% Garante que os predicados sejam manipuláveis em tempo de execução
:- dynamic dieta/3.
:- dynamic descricao_dieta/2.
:- dynamic suporta/4.
:- dynamic exclui/3.
:- dynamic pergunta/5.

% DIETAS -------------------------------------------------------------------------------------------------------
incluir_dieta(Id, Nome, Prob, Desc) :-
    \+ dieta(Id, _, _),
    assertz(dieta(Id, Nome, Prob)),
    assertz(descricao_dieta(Id, Desc)).

alterar_dieta(Id, Nome, Prob, Desc) :-
    dieta(Id, _, _),
    retractall(dieta(Id, _, _)),
    retractall(descricao_dieta(Id, _)),
    assertz(dieta(Id, Nome, Prob)),
    assertz(descricao_dieta(Id, Desc)).

excluir_dieta(Id) :-
    retractall(dieta(Id, _, _)),
    retractall(descricao_dieta(Id, _)),
    retractall(suporta(Id, _, _, _)),
    retractall(exclui(Id, _, _)).

% PERGUNTAS ----------------------------------------------------------------------------------------------------
incluir_pergunta(Attr, Tipo, Texto, Ops, Just) :-
    \+ pergunta(Attr, _, _, _, _),
    assertz(pergunta(Attr, Tipo, Texto, Ops, Just)).

alterar_pergunta(Attr, Tipo, Texto, Ops, Just) :-
    pergunta(Attr, _, _, _, _),
    retractall(pergunta(Attr, _, _, _, _)),
    assertz(pergunta(Attr, Tipo, Texto, Ops, Just)).

excluir_pergunta(Attr) :-
    retractall(pergunta(Attr, _, _, _, _)),
    retractall(suporta(_, Attr, _, _)),
    retractall(exclui(_, Attr, _)).

% SUPORTES -----------------------------------------------------------------------------------------------------
incluir_suporte(DietaId, Attr, Val, Peso) :-
    assertz(suporta(DietaId, Attr, Val, Peso)).

alterar_suporte(DietaId, Attr, Val, NovoPeso) :-
    retractall(suporta(DietaId, Attr, Val, _)),
    assertz(suporta(DietaId, Attr, Val, NovoPeso)).

excluir_suporte(DietaId, Attr, Val) :-
    retractall(suporta(DietaId, Attr, Val, _)).

% EXCLUSÕES ----------------------------------------------------------------------------------------------------
incluir_exclusao(DietaId, Attr, Val) :-
    assertz(exclui(DietaId, Attr, Val)).

alterar_exclusao(DietaId, AttrAntigo, ValAntigo, NovoAttr, NovoVal) :-
    retractall(exclui(DietaId, AttrAntigo, ValAntigo)),
    assertz(exclui(DietaId, NovoAttr, NovoVal)).

excluir_exclusao(DietaId, Attr, Val) :-
    retractall(exclui(DietaId, Attr, Val)).