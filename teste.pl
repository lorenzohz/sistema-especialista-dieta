% ==============================================================
%  TESTES UNITARIOS - Sistema Especialista de Recomendacao de Dieta
%  Disciplina: Introducao a Inteligencia Artificial - UEM
%
%  Para executar: swipl -g "consult('teste.pl'), executar_todos_testes, halt."
% ==============================================================

:- consult('interface.pl').

% --------------------------------------------------------------
% Utilitarios de Teste
% --------------------------------------------------------------

:- dynamic testes_passados/1.
:- dynamic testes_falhos/1.
testes_passados(0).
testes_falhos(0).

assert_verdadeiro(Descricao, Goal) :-
    (call(Goal) ->
        retract(testes_passados(N)),
        N1 is N + 1,
        assertz(testes_passados(N1)),
        write('[PASSOU] '), writeln(Descricao)
    ;
        retract(testes_falhos(N)),
        N1 is N + 1,
        assertz(testes_falhos(N1)),
        write('[FALHOU] '), writeln(Descricao)
    ).

assert_falso(Descricao, Goal) :-
    (call(Goal) ->
        retract(testes_falhos(N)),
        N1 is N + 1,
        assertz(testes_falhos(N1)),
        write('[FALHOU] '), writeln(Descricao)
    ;
        retract(testes_passados(N)),
        N1 is N + 1,
        assertz(testes_passados(N1)),
        write('[PASSOU] '), writeln(Descricao)
    ).

limpar_respostas :-
    retractall(resposta(_, _)).

% --------------------------------------------------------------
% GRUPO 1: Testes da base de conhecimento
% --------------------------------------------------------------

test_base_conhecimento :-
    nl,
    writeln('=== GRUPO 1: Base de Conhecimento ==='),

    assert_verdadeiro(
        'Hipotese dieta_low_carb existe na base',
        hipotese(dieta_low_carb, _, _, _, _)
    ),

    assert_verdadeiro(
        'Hipotese dieta_mediterranea existe na base',
        hipotese(dieta_mediterranea, _, _, _, _)
    ),

    assert_verdadeiro(
        'Hipotese dieta_dash existe na base',
        hipotese(dieta_dash, _, _, _, _)
    ),

    assert_verdadeiro(
        'Hipotese dieta_diabeticos existe na base',
        hipotese(dieta_diabeticos, _, _, _, _)
    ),

    assert_verdadeiro(
        'Hipotese dieta_vegetariana existe na base',
        hipotese(dieta_vegetariana, _, _, _, _)
    ),

    assert_verdadeiro(
        'Hipotese dieta_sem_gluten existe na base',
        hipotese(dieta_sem_gluten, _, _, _, _)
    ),

    assert_verdadeiro(
        'dieta_low_carb possui sintoma obrigatorio objetivo_emagrecer',
        sintoma_obrigatorio(dieta_low_carb, objetivo_emagrecer)
    ),

    assert_verdadeiro(
        'dieta_dash possui sintoma obrigatorio pressao_arterial_alta',
        sintoma_obrigatorio(dieta_dash, pressao_arterial_alta)
    ),

    assert_verdadeiro(
        'dieta_vegetariana possui sintoma obrigatorio nao_consome_carne',
        sintoma_obrigatorio(dieta_vegetariana, nao_consome_carne)
    ),

    assert_verdadeiro(
        'dieta_low_carb possui pelo menos 1 sintoma opcional',
        sintoma_opcional(dieta_low_carb, _)
    ),

    assert_verdadeiro(
        'dieta_low_carb possui recomendacao na posicao 1',
        recomendacao(dieta_low_carb, 1, _)
    ),

    assert_verdadeiro(
        'dieta_dash possui recomendacao na posicao 1',
        recomendacao(dieta_dash, 1, _)
    ),

    assert_verdadeiro(
        'Probabilidade base de dieta_sem_gluten esta entre 0 e 1',
        (hipotese(dieta_sem_gluten, _, _, P, _), P > 0.0, P =< 1.0)
    ),

    assert_verdadeiro(
        'Probabilidade base de dieta_dash esta entre 0 e 1',
        (hipotese(dieta_dash, _, _, P, _), P > 0.0, P =< 1.0)
    ).

% --------------------------------------------------------------
% GRUPO 2: Testes do Motor de Inferencia (diagnostico)
% --------------------------------------------------------------

test_diagnostico :-
    nl,
    writeln('=== GRUPO 2: Motor de Inferencia e Diagnostico ==='),

    % --- Cenario 1: usuario quer emagrecer e aceita reducao de carboidratos ---
    limpar_respostas,
    assertz(resposta(objetivo_emagrecer, sim)),
    assertz(resposta(aceita_reducao_carboidratos, sim)),
    assertz(resposta(objetivo_manutencao_peso, nao)),
    assertz(resposta(objetivo_ganho_muscular, nao)),
    assertz(resposta(objetivo_ganhar_peso, nao)),
    assertz(resposta(objetivo_saude_cardiovascular, nao)),
    assertz(resposta(pressao_arterial_alta, nao)),
    assertz(resposta(tem_diabetes_tipo2, nao)),
    assertz(resposta(tem_condicao_inflamatoria, nao)),
    assertz(resposta(diagnosticado_celiaco_ou_sensivel_gluten, nao)),
    assertz(resposta(nao_consome_carne, nao)),
    assertz(resposta(pratica_musculacao_ou_esporte, nao)),
    assertz(resposta(sem_restricao_gluten, sim)),
    assertz(resposta(sem_condicao_medica_especifica, nao)),
    assertz(resposta(consome_peixe_ou_frutos_mar, nao)),

    assert_verdadeiro(
        'Cenario 1: dieta_low_carb e diagnosticada quando usuario quer emagrecer e aceita corte de carbo',
        (diagnostico(R), member(_-dieta_low_carb, R))
    ),

    % --- Cenario 2: usuario tem hipertensao ---
    limpar_respostas,
    assertz(resposta(pressao_arterial_alta, sim)),
    assertz(resposta(objetivo_emagrecer, nao)),
    assertz(resposta(objetivo_manutencao_peso, nao)),
    assertz(resposta(objetivo_ganho_muscular, nao)),
    assertz(resposta(objetivo_ganhar_peso, nao)),
    assertz(resposta(objetivo_saude_cardiovascular, nao)),
    assertz(resposta(tem_diabetes_tipo2, nao)),
    assertz(resposta(tem_condicao_inflamatoria, nao)),
    assertz(resposta(diagnosticado_celiaco_ou_sensivel_gluten, nao)),
    assertz(resposta(nao_consome_carne, nao)),
    assertz(resposta(pratica_musculacao_ou_esporte, nao)),

    assert_verdadeiro(
        'Cenario 2: dieta_dash e diagnosticada para usuario com hipertensao',
        (diagnostico(R), member(_-dieta_dash, R))
    ),

    % --- Cenario 3: usuario tem doenca celiaca ---
    limpar_respostas,
    assertz(resposta(diagnosticado_celiaco_ou_sensivel_gluten, sim)),
    assertz(resposta(objetivo_emagrecer, nao)),
    assertz(resposta(objetivo_manutencao_peso, nao)),
    assertz(resposta(objetivo_ganho_muscular, nao)),
    assertz(resposta(objetivo_ganhar_peso, nao)),
    assertz(resposta(objetivo_saude_cardiovascular, nao)),
    assertz(resposta(pressao_arterial_alta, nao)),
    assertz(resposta(tem_diabetes_tipo2, nao)),
    assertz(resposta(tem_condicao_inflamatoria, nao)),
    assertz(resposta(nao_consome_carne, nao)),
    assertz(resposta(pratica_musculacao_ou_esporte, nao)),

    assert_verdadeiro(
        'Cenario 3: dieta_sem_gluten e diagnosticada para celiaco',
        (diagnostico(R), member(_-dieta_sem_gluten, R))
    ),

    % --- Cenario 4: usuario vegetariano ---
    limpar_respostas,
    assertz(resposta(nao_consome_carne, sim)),
    assertz(resposta(objetivo_emagrecer, nao)),
    assertz(resposta(objetivo_manutencao_peso, nao)),
    assertz(resposta(objetivo_ganho_muscular, nao)),
    assertz(resposta(objetivo_ganhar_peso, nao)),
    assertz(resposta(objetivo_saude_cardiovascular, nao)),
    assertz(resposta(pressao_arterial_alta, nao)),
    assertz(resposta(tem_diabetes_tipo2, nao)),
    assertz(resposta(tem_condicao_inflamatoria, nao)),
    assertz(resposta(diagnosticado_celiaco_ou_sensivel_gluten, nao)),
    assertz(resposta(pratica_musculacao_ou_esporte, nao)),

    assert_verdadeiro(
        'Cenario 4: dieta_vegetariana e diagnosticada para vegetariano',
        (diagnostico(R), member(_-dieta_vegetariana, R))
    ),

    % --- Cenario 5: Sem nenhuma condicao ativa -> nenhum resultado esperado ---
    limpar_respostas,
    assertz(resposta(objetivo_emagrecer, nao)),
    assertz(resposta(objetivo_manutencao_peso, nao)),
    assertz(resposta(objetivo_ganho_muscular, nao)),
    assertz(resposta(objetivo_ganhar_peso, nao)),
    assertz(resposta(objetivo_saude_cardiovascular, nao)),
    assertz(resposta(pressao_arterial_alta, nao)),
    assertz(resposta(tem_diabetes_tipo2, nao)),
    assertz(resposta(tem_condicao_inflamatoria, nao)),
    assertz(resposta(diagnosticado_celiaco_ou_sensivel_gluten, nao)),
    assertz(resposta(nao_consome_carne, nao)),
    assertz(resposta(pratica_musculacao_ou_esporte, nao)),
    assertz(resposta(sem_condicao_medica_especifica, nao)),
    assertz(resposta(sem_restricao_gluten, nao)),
    assertz(resposta(consome_peixe_ou_frutos_mar, nao)),

    assert_verdadeiro(
        'Cenario 5: Nenhum resultado quando todas condicoes negadas',
        (diagnostico(R), R = [])
    ).

% --------------------------------------------------------------
% GRUPO 3: Testes de Probabilidade
% --------------------------------------------------------------

test_probabilidade :-
    nl,
    writeln('=== GRUPO 3: Calculo de Probabilidade ==='),

    % Cenario: apenas obrigatorios confirmados (sem opcionais) -> prob = ProbBase
    limpar_respostas,
    assertz(resposta(pressao_arterial_alta, sim)),

    assert_verdadeiro(
        'Prob. de dieta_dash com so obrigatorio: deve ser >= 0.92 (prob base)',
        (probabilidade_final(dieta_dash, P), P >= 0.92)
    ),

    % Cenario: obrigatorios + 1 opcional confirmado -> bonus deve elevar a prob
    limpar_respostas,
    assertz(resposta(pressao_arterial_alta, sim)),
    assertz(resposta(colesterol_alto, sim)),  % opcional de dieta_dash

    assert_verdadeiro(
        'Prob. de dieta_dash com 1 opcional confirmado deve ser > 0.92',
        (probabilidade_final(dieta_dash, P), P > 0.92)
    ),

    % Probabilidade nunca deve ultrapassar 1.0
    limpar_respostas,
    assertz(resposta(pressao_arterial_alta, sim)),
    assertz(resposta(colesterol_alto, sim)),
    assertz(resposta(objetivo_emagrecer, sim)),
    assertz(resposta(consome_muito_sodio_atualmente, sim)),
    assertz(resposta(historico_familiar_doenca_cardiaca, sim)),
    assertz(resposta(nivel_atividade_sedentario_ou_leve, sim)),

    assert_verdadeiro(
        'Probabilidade final de dieta_dash nunca deve ultrapassar 1.0',
        (probabilidade_final(dieta_dash, P), P =< 1.0)
    ),

    % Resultados devem estar em ordem decrescente
    limpar_respostas,
    assertz(resposta(pressao_arterial_alta, sim)),
    assertz(resposta(diagnosticado_celiaco_ou_sensivel_gluten, sim)),

    assert_verdadeiro(
        'Resultados do diagnostico devem estar em ordem decrescente de probabilidade',
        (
            diagnostico([P1-_ | Resto]),
            (Resto = [] ; (Resto = [P2-_ | _], P1 >= P2))
        )
    ).

% --------------------------------------------------------------
% GRUPO 4: Testes de Explicabilidade
% --------------------------------------------------------------

test_explicabilidade :-
    nl,
    writeln('=== GRUPO 4: Explicabilidade ==='),

    limpar_respostas,
    assertz(resposta(objetivo_emagrecer, nao)),
    assertz(resposta(aceita_reducao_carboidratos, nao)),

    assert_verdadeiro(
        'dieta_low_carb e descartada quando obrigatorios negados',
        hipotese_descartada(dieta_low_carb)
    ),

    assert_verdadeiro(
        'sintoma_que_descartou identifica o sintoma correto',
        sintoma_que_descartou(dieta_low_carb, objetivo_emagrecer)
    ),

    limpar_respostas,
    assertz(resposta(pressao_arterial_alta, sim)),

    assert_verdadeiro(
        'dieta_dash nao e descartada quando obrigatorio confirmado',
        \+ hipotese_descartada(dieta_dash)
    ),

    assert_verdadeiro(
        'hipotese_possivel valida hipoteses nao descartadas',
        hipotese_possivel(dieta_dash)
    ),

    assert_verdadeiro(
        'explicar_pergunta retorna info sobre pressao_arterial_alta',
        (
            findall(
                Nome,
                (sintoma_obrigatorio(H, pressao_arterial_alta), hipotese(H, Nome, _, _, _)),
                L
            ),
            L \= []
        )
    ).

% --------------------------------------------------------------
% GRUPO 5: Testes de CRUD
% --------------------------------------------------------------

test_crud :-
    nl,
    writeln('=== GRUPO 5: CRUD de Hipoteses ==='),

    % Incluir
    assertz(hipotese(
        dieta_teste_crud,
        'Dieta de Teste CRUD',
        teste,
        0.75,
        'Hipotese criada durante o teste de CRUD.'
    )),

    assert_verdadeiro(
        'CRUD: Hipotese incluida deve ser encontrada na base',
        hipotese(dieta_teste_crud, 'Dieta de Teste CRUD', teste, 0.75, _)
    ),

    % Alterar
    retractall(hipotese(dieta_teste_crud, _, _, _, _)),
    assertz(hipotese(dieta_teste_crud, 'Dieta Teste Alterada', teste_alt, 0.80, 'Descricao alterada.')),

    assert_verdadeiro(
        'CRUD: Hipotese alterada deve refletir novo nome',
        hipotese(dieta_teste_crud, 'Dieta Teste Alterada', _, _, _)
    ),

    assert_verdadeiro(
        'CRUD: Hipotese alterada deve refletir nova probabilidade',
        hipotese(dieta_teste_crud, _, _, 0.80, _)
    ),

    assert_falso(
        'CRUD: Hipotese alterada nao deve mais ter nome antigo',
        hipotese(dieta_teste_crud, 'Dieta de Teste CRUD', _, _, _)
    ),

    % Excluir
    retractall(hipotese(dieta_teste_crud, _, _, _, _)),
    retractall(sintoma_obrigatorio(dieta_teste_crud, _)),
    retractall(sintoma_opcional(dieta_teste_crud, _)),
    retractall(recomendacao(dieta_teste_crud, _, _)),

    assert_falso(
        'CRUD: Hipotese excluida nao deve mais existir na base',
        hipotese(dieta_teste_crud, _, _, _, _)
    ).

% --------------------------------------------------------------
% RUNNER PRINCIPAL
% --------------------------------------------------------------

executar_todos_testes :-
    nl,
    writeln('############################################################'),
    writeln('  EXECUCAO DOS TESTES UNITARIOS'),
    writeln('  Sistema Especialista de Recomendacao de Dieta - UEM'),
    writeln('############################################################'),

    test_base_conhecimento,
    test_diagnostico,
    test_probabilidade,
    test_explicabilidade,
    test_crud,

    nl,
    writeln('############################################################'),
    writeln('  RESUMO DOS TESTES'),
    writeln('############################################################'),
    testes_passados(P),
    testes_falhos(F),
    Total is P + F,
    write('  Total de testes: '), writeln(Total),
    write('  Passaram: '), writeln(P),
    write('  Falharam: '), writeln(F),
    writeln('############################################################'),
    nl.

:- initialization(executar_todos_testes, main).
