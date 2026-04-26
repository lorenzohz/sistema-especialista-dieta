:- consult('base_conhecimento.pl').

:- dynamic resposta/2.

%
% Verifica se todos os criterios obrigatorios de um plano foram confirmados
%

criterios_obrigatorios_confirmados(Plano) :-
    forall(
        criterio_obrigatorio(Plano, Criterio),
        resposta(Criterio, sim)
    ).

%
% Verifica se um plano foi descartado (algum criterio obrigatorio negado)
%

plano_descartado(Plano) :-
    criterio_obrigatorio(Plano, Criterio),
    resposta(Criterio, nao).

%
% Retorna quais criterios obrigatorios descartaram um plano
%

criterio_que_descartou(Plano, Criterio) :-
    criterio_obrigatorio(Plano, Criterio),
    resposta(Criterio, nao).

%
% Conta quantas condicoes opcionais foram confirmadas
%

contar_criterios_opcionais(Plano, Quantidade) :-
    findall(
        Criterio,
        (
            criterio_opcional(Plano, Criterio),
            resposta(Criterio, sim)
        ),
        Lista
    ),
    length(Lista, Quantidade).

%
% Conta o total de criterios opcionais do plano
%

total_criterios_opcionais(Plano, Total) :-
    findall(
        Criterio,
        criterio_opcional(Plano, Criterio),
        Lista
    ),
    length(Lista, Total).

%
% Plano ainda possivel:
% nao pode ter nenhuma condicao obrigatoria respondida como nao
%

plano_possivel(Plano) :-
    plano(Plano, _, _, _, _),
    \+ plano_descartado(Plano).

%
% Condicao obrigatoria ainda nao perguntada
%

criterio_obrigatorio_pendente(Criterio) :-
    criterio_obrigatorio(_, Criterio),
    \+ resposta(Criterio, _).

%
% Condicao opcional relevante:
% pertence a um plano ainda possivel
% e ainda nao foi respondida
%

criterio_opcional_relevante(Criterio) :-
    plano_possivel(Plano),
    criterio_opcional(Plano, Criterio),
    \+ resposta(Criterio, _).

%
% Calcula a probabilidade final do plano
% Formula: ProbBase * (1 + Score * 0.20)
%   onde Score = opcionais_confirmados / total_criterios_opcionais
%
% Diferente da formula aditiva (+ bonus fixo), aqui o bonus e
% PROPORCIONAL a probabilidade base: quanto maior a ProbBase do plano,
% maior e o crescimento absoluto causado pelos criterios opcionais.
% O bonus maximo e de 20% relativo sobre a ProbBase (ex: 0.80 -> 0.96).
%

probabilidade_final(Plano, ProbFinal) :-
    plano(Plano, _, _, ProbBase, _),
    criterios_obrigatorios_confirmados(Plano),
    contar_criterios_opcionais(Plano, Confirmados),
    total_criterios_opcionais(Plano, Total),
    (
        Total =:= 0
    ->  ProbFinal = ProbBase
    ;
        Score is Confirmados / Total,
        ProbFinalTemp is ProbBase * (1.0 + Score * 0.20),
        ProbFinal is min(1.0, ProbFinalTemp)
    ).

%
% Gera lista de diagnosticos possiveis ordenados por probabilidade decrescente
%

diagnostico(ResultadosOrdenados) :-
    findall(
        Prob-Plano,
        probabilidade_final(Plano, Prob),
        Resultados
    ),
    sort(1, @>=, Resultados, ResultadosOrdenados).

%
% Explicabilidade: lista criterios que confirmaram o plano
%

explicar_plano(Plano) :-
    plano(Plano, _, _, _, _),

    nl,

    writeln('Condicoes obrigatorias confirmadas:'),
    forall(
        criterio_obrigatorio(Plano, C),
        (
            resposta(C, sim),
            pergunta(C, Texto),
            write('  [OK] '), writeln(Texto)
        )
    ),

    nl,

    writeln('Condicoes opcionais confirmadas:'),
    (
        (criterio_opcional(Plano, C2), resposta(C2, sim)) ->
            forall(
                (criterio_opcional(Plano, C3), resposta(C3, sim)),
                (
                    pergunta(C3, Texto3),
                    write('  [+] '), writeln(Texto3)
                )
            )
    ;
        writeln('  Nenhuma.')
    ).

%
% Explicabilidade: explica por que um plano foi descartado
%

explicar_descarte(Plano) :-
    plano(Plano, Nome, _, _, _),
    plano_descartado(Plano),

    nl,
    write('Plano descartado: '), writeln(Nome),

    writeln('Motivo: a(s) seguinte(s) condicao(oes) foram negadas:'),

    forall(
        criterio_que_descartou(Plano, C),
        (
            pergunta(C, Texto),
            write('  [X] '), writeln(Texto)
        )
    ).

%
% Explicabilidade: explica por que uma pergunta foi feita
%

explicar_pergunta(Criterio) :-
    pergunta(Criterio, Texto),

    nl,
    write('Pergunta: '), writeln(Texto),

    findall(
        Nome,
        (
            (criterio_obrigatorio(H, Criterio)
            ;
             criterio_opcional(H, Criterio)),
            plano(H, Nome, _, _, _)
        ),
        Lista
    ),

    (
        Lista \= [] ->
            writeln('Essa pergunta foi feita porque esta relacionada com os seguintes planos de dieta:'),
            forall(
                member(Nome, Lista),
                (
                    write('  - '), writeln(Nome)
                )
            )
    ;
        writeln('Nenhum plano relacionado encontrado.')
    ).
