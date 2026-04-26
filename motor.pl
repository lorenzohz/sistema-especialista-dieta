:- consult('base_conhecimento.pl').

:- dynamic resposta/2.

%
% Verifica se todos os sintomas/condicoes obrigatorios de uma hipotese foram confirmados
%

obrigatorios_confirmados(Hipotese) :-
    forall(
        sintoma_obrigatorio(Hipotese, Sintoma),
        resposta(Sintoma, sim)
    ).

%
% Verifica se uma hipotese foi descartada (algum obrigatorio negado)
%

hipotese_descartada(Hipotese) :-
    sintoma_obrigatorio(Hipotese, Sintoma),
    resposta(Sintoma, nao).

%
% Retorna quais condicoes obrigatorias descartaram uma hipotese
%

sintoma_que_descartou(Hipotese, Sintoma) :-
    sintoma_obrigatorio(Hipotese, Sintoma),
    resposta(Sintoma, nao).

%
% Conta quantas condicoes opcionais foram confirmadas
%

contar_opcionais_confirmados(Hipotese, Quantidade) :-
    findall(
        Sintoma,
        (
            sintoma_opcional(Hipotese, Sintoma),
            resposta(Sintoma, sim)
        ),
        Lista
    ),
    length(Lista, Quantidade).

%
% Conta o total de condicoes opcionais da hipotese
%

total_opcionais(Hipotese, Total) :-
    findall(
        Sintoma,
        sintoma_opcional(Hipotese, Sintoma),
        Lista
    ),
    length(Lista, Total).

%
% Hipotese ainda possivel:
% nao pode ter nenhuma condicao obrigatoria respondida como nao
%

hipotese_possivel(Hipotese) :-
    hipotese(Hipotese, _, _, _, _),
    \+ hipotese_descartada(Hipotese).

%
% Condicao obrigatoria ainda nao perguntada
%

sintoma_obrigatorio_nao_respondido(Sintoma) :-
    sintoma_obrigatorio(_, Sintoma),
    \+ resposta(Sintoma, _).

%
% Condicao opcional relevante:
% pertence a uma hipotese ainda possivel
% e ainda nao foi respondida
%

sintoma_opcional_relevante(Sintoma) :-
    hipotese_possivel(Hipotese),
    sintoma_opcional(Hipotese, Sintoma),
    \+ resposta(Sintoma, _).

%
% Calcula a probabilidade final da hipotese
% Formula: ProbBase + Bonus
% Bonus = (opcionais_confirmados / total_opcionais) * 0.10
% Isso permite que condicoes opcionais somem ate 10% a mais na probabilidade
%

probabilidade_final(Hipotese, ProbFinal) :-
    hipotese(Hipotese, _, _, ProbBase, _),
    obrigatorios_confirmados(Hipotese),
    contar_opcionais_confirmados(Hipotese, Confirmados),
    total_opcionais(Hipotese, Total),
    (
        Total =:= 0 ->
        Bonus = 0
    ;
        Bonus is (Confirmados / Total) * 0.10
    ),
    ProbFinalTemp is ProbBase + Bonus,
    ProbFinal is min(1.0, ProbFinalTemp).

%
% Gera lista de diagnosticos possiveis ordenados por probabilidade decrescente
%

diagnostico(ResultadosOrdenados) :-
    findall(
        Prob-Hipotese,
        probabilidade_final(Hipotese, Prob),
        Resultados
    ),
    sort(1, @>=, Resultados, ResultadosOrdenados).

%
% Explicabilidade: lista condicoes que confirmaram a hipotese
%

explicar_hipotese(Hipotese) :-
    hipotese(Hipotese, _, _, _, _),

    nl,

    writeln('Condicoes obrigatorias confirmadas:'),
    forall(
        sintoma_obrigatorio(Hipotese, S),
        (
            resposta(S, sim),
            pergunta(S, Texto),
            write('  [OK] '), writeln(Texto)
        )
    ),

    nl,

    writeln('Condicoes opcionais confirmadas:'),
    (
        (sintoma_opcional(Hipotese, S2), resposta(S2, sim)) ->
            forall(
                (sintoma_opcional(Hipotese, S3), resposta(S3, sim)),
                (
                    pergunta(S3, Texto3),
                    write('  [+] '), writeln(Texto3)
                )
            )
    ;
        writeln('  Nenhuma.')
    ).

%
% Explicabilidade: explica por que uma hipotese foi descartada
%

explicar_descarte(Hipotese) :-
    hipotese(Hipotese, Nome, _, _, _),
    hipotese_descartada(Hipotese),

    nl,
    write('Hipotese descartada: '), writeln(Nome),

    writeln('Motivo: a(s) seguinte(s) condicao(oes) foram negadas:'),

    forall(
        sintoma_que_descartou(Hipotese, S),
        (
            pergunta(S, Texto),
            write('  [X] '), writeln(Texto)
        )
    ).

%
% Explicabilidade: explica por que uma pergunta foi feita
%

explicar_pergunta(Sintoma) :-
    pergunta(Sintoma, Texto),

    nl,
    write('Pergunta: '), writeln(Texto),

    findall(
        Nome,
        (
            (sintoma_obrigatorio(H, Sintoma)
            ;
             sintoma_opcional(H, Sintoma)),
            hipotese(H, Nome, _, _, _)
        ),
        Lista
    ),

    (
        Lista \= [] ->
            writeln('Essa pergunta foi feita porque esta relacionada com as seguintes hipoteses:'),
            forall(
                member(Nome, Lista),
                (
                    write('  - '), writeln(Nome)
                )
            )
    ;
        writeln('Nenhuma hipotese relacionada encontrada.')
    ).
