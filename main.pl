% ==============================================================
%  MAIN - Sistema Especialista de Recomendacao de Dieta
%  Disciplina: Introducao a Inteligencia Artificial - UEM
%  Prof. Wagner Igarashi
%
%  Como executar:
%    swipl main.pl
%
%  Para rodar os testes unitarios:
%    swipl -g "consult('teste.pl'), executar_todos_testes, halt."
% ==============================================================

:- consult('interface.pl').

% --------------------------------------------------------------
%  Inicializacao automatica ao carregar o arquivo
% --------------------------------------------------------------

:- initialization(main, main).

main :-
    menu.
