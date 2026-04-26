% MODELO DE PROBABILIDADE:
%   Score = min(0.99,  ProbBase + sum(Pesos dos suportes satisfeitos))
%
%   - ProbBase: probabilidade a priori de cada dieta
%   - Pesos: cada regra suporta/4 define quanto um fato confirmado contribui para o score da dieta
%   - Limitado a 0.99 para nao atingir certeza absoluta
%   - Convertido para porcentagem inteira para exibicao (round * 100)

:- set_prolog_flag(encoding, utf8).
:- use_module(library(lists)).

:- consult('base_conhecimento.pl').
:- consult('crud_bc.pl').
:- (exists_file('kb_dinamico.pl') -> consult('kb_dinamico.pl') ; true).

% Fatos do usuario - assertados dinamicamente via arquivo de sessao
:- dynamic user_fact/2.

% INFERÊNCIA ---------------------------------------------------------------------------------------------------

% calcular_score(+Dieta, -Score)
% Score = min(0.99, ProbBase + soma dos pesos das regras satisfeitas)
calcular_score(Dieta, Score) :-
    dieta(Dieta, _, ProbBase),
    findall(W, (suporta(Dieta, Attr, Val, W), user_fact(Attr, Val)), Ws),
    sum_list(Ws, SumW),
    Score is min(0.99, ProbBase + SumW).

% nao_excluida(+Dieta)
% Verdadeiro se nenhuma regra de exclusao foi ativada para a dieta
nao_excluida(Dieta) :-
    \+ (exclui(Dieta, Attr, Val), user_fact(Attr, Val)).

% recomendar(-Lista)
% Lista = [Score-Id-Nome, ...] ordenada por score decrescente
recomendar(Lista) :-
    findall(Score-Dieta-Nome, (
        dieta(Dieta, Nome, _),
        nao_excluida(Dieta),
        calcular_score(Dieta, Score)
    ), Unsorted),
    msort(Unsorted, Sorted),
    reverse(Sorted, Lista).

% EXPLICABILIDADE ----------------------------------------------------------------------------------------------

% fatos_confirmados(+Dieta, -Fatos)
% Fatos do usuario que suportam a dieta e suas contribuicoes
fatos_confirmados(Dieta, Fatos) :-
    findall(Attr-Val-W, (
        suporta(Dieta, Attr, Val, W),
        user_fact(Attr, Val)
    ), Fatos).

% fatos_faltantes(+Dieta, -Fatos)
% Fatos que poderiam ter aumentado o score mas nao foram satisfeitos
fatos_faltantes(Dieta, Fatos) :-
    findall(Attr-Val-W, (
        suporta(Dieta, Attr, Val, W),
        \+ user_fact(Attr, Val)
    ), Fatos).

% razoes_exclusao(+Dieta, -Razoes)
% Condicoes do usuario que causaram a exclusao da dieta
razoes_exclusao(Dieta, Razoes) :-
    findall(Attr-Val, (
        exclui(Dieta, Attr, Val),
        user_fact(Attr, Val)
    ), Razoes).

% SAIDA ESTRUTURADA --------------------------------------------------------------------------------------------

% Recomendacoes ordenadas
print_recomendacoes :-
    recomendar(Lista),
    forall(member(Score-Dieta-Nome, Lista), (
        Pct is round(Score * 100),
        format("DIETA|~w|~w|~w~n", [Dieta, Nome, Pct])
    )).

% Fatos que confirmaram uma dieta
print_fatos_confirmados(Dieta) :-
    fatos_confirmados(Dieta, Fatos),
    forall(member(Attr-Val-W, Fatos), (
        Pct is round(W * 100),
        format("CONFIRMADO|~w|~w|~w~n", [Attr, Val, Pct])
    )).

% Razoes de exclusao de uma dieta
print_razoes_exclusao(Dieta) :-
    razoes_exclusao(Dieta, Razoes),
    forall(member(Attr-Val, Razoes), (
        format("EXCLUIDO|~w|~w~n", [Attr, Val])
    )).

% Fatos que faltaram para uma dieta pontuar mais
print_fatos_faltantes(Dieta) :-
    fatos_faltantes(Dieta, Fatos),
    forall(member(Attr-Val-W, Fatos), (
        Pct is round(W * 100),
        format("FALTANTE|~w|~w|~w~n", [Attr, Val, Pct])
    )).

% Justificativa de uma pergunta
print_justificativa_pergunta(Attr) :-
    (pergunta(Attr, _, _, _, Just) ->
        format("JUSTIFICATIVA|~w~n", [Just])
    ;
        format("JUSTIFICATIVA|Justificativa nao encontrada na base.~n", [])
    ).

% Todas as dietas da BC (incluindo dinamicas)
print_todas_dietas :-
    findall(Id-Nome-Prob, dieta(Id, Nome, Prob), Lista),
    forall(member(Id-Nome-Prob, Lista), (
        ProbPct is round(Prob * 100),
        format("DIETA_KB|~w|~w|~w~n", [Id, Nome, ProbPct])
    )).

% Regras de suporte de uma dieta especifica
print_suportes_dieta(Dieta) :-
    findall(Attr-Val-W, suporta(Dieta, Attr, Val, W), Lista),
    forall(member(Attr-Val-W, Lista), (
        format("SUPORTE_KB|~w|~w|~w~n", [Attr, Val, W])
    )).

% Verifica se uma dieta existe na BC
print_dieta_existe(Id) :-
    (dieta(Id, _, _) -> format("EXISTE|sim~n", []) ; format("EXISTE|nao~n", [])).

% INTERFACE E FLUXO DE PERGUNTAS -------------------------------------------------------------------------------

% Retorna apenas os atributos das perguntas que sao a base (obrigatorias)
listar_perguntas_base(Lista) :-
    findall(Attr, pergunta(Attr, base, _, _, _), Lista).

% Retorna atributos de perguntas condicionais cujo pre-requisito ja foi respondido pelo usuario
listar_perguntas_condicionais_ativas(Lista) :-
    findall(Attr, (
        pergunta(Attr, depende(AttrPai, ValEsperado), _, _, _),
        user_fact(AttrPai, ValEsperado),
        \+ user_fact(Attr, _) % Garante que nao retorna se o usuario ja respondeu
    ), Lista).

% Busca os detalhes de uma pergunta especifica para exibir na interface Python
detalhes_pergunta(Attr, Texto, Opcoes, Justificativa) :-
    pergunta(Attr, _, Texto, Opcoes, Justificativa).

% Extrai a lógica de dependência definida na BC
gatilho_pergunta(Attr, AttrPai, Val) :-
    pergunta(Attr, depende(AttrPai, Val), _, _, _).