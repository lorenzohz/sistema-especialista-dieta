%  TESTES UNITÁRIOS — Sistema Especialista de Dietas
%  Arquivo: testes_unitarios.pl
%
%  Utiliza PLUnit (nativo SWI-Prolog).
%  Pode ser executado:
%    - Diretamente: swipl -g "run_tests" testes_unitarios.pl
%    - Via interface Python (opção 3 do menu principal)
%
%  Suites cobertas:
%    1. calculo_score           - Score bayesiano simples
%    2. regras_exclusao         - Exclusão de dietas incompatíveis
%    3. recomendacoes           - Ordenação e filtragem do resultado
%    4. perguntas_condicionais  - Ativação dinâmica de perguntas
%    5. crud_dietas             - CRUD da entidade Dieta
%    6. crud_suportes           - CRUD das regras de suporte/peso
%    7. crud_exclusoes          - CRUD das regras de exclusão
%    8. explicabilidade         - Fatos confirmados / faltantes / razões

:- set_prolog_flag(encoding, utf8).
:- use_module(library(plunit)).

% Carrega o motor (que já carrega base_conhecimento e crud_bc)
:- consult('motor_inferencia.pl').

%  Helpers reutilizados pelos testes

%% limpar_fatos/0 — remove todos os fatos de sessão do usuário
limpar_fatos :-
    retractall(user:user_fact(_, _)).

%% assert_fatos(+Lista) — ativa fatos Attr-Val em massa
assert_fatos([]).
assert_fatos([Attr-Val | Resto]) :-
    assertz(user:user_fact(Attr, Val)),
    assert_fatos(Resto).

%% perfil_perda_peso/0 — perfil representativo para perda de peso
perfil_perda_peso :-
    assert_fatos([
        objetivo          - perda_peso,
        nivel_atividade   - sedentario,
        condicao_saude    - nenhuma,
        restricao_carne   - nao,
        orcamento         - flexivel,
        tempo_preparo     - media,
        disposicao_restricao - nao
    ]).

%% perfil_vegetariano/0 — perfil vegetariano sem laticínios
perfil_vegetariano :-
    assert_fatos([
        objetivo           - saude_geral,
        nivel_atividade    - moderado,
        condicao_saude     - nenhuma,
        restricao_carne    - sim,
        restricao_laticinios - nao,
        orcamento          - flexivel,
        tempo_preparo      - media
    ]).


%  SUITE 1 — Cálculo de Score
%  Fórmula: Score = min(0.99, ProbBase + soma(pesos satisfeitos))

:- begin_tests(calculo_score).

%% Sem nenhum fato do usuário, score == probabilidade a priori
test(score_base_sem_fatos,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    dieta(low_carb, _, ProbBase),
    calcular_score(low_carb, S),
    S =:= ProbBase.

%% Um fato suportado deve aumentar o score
test(score_cresce_com_fato_suportado,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, perda_peso)))),
      cleanup(limpar_fatos) ]) :-
    dieta(low_carb, _, ProbBase),
    calcular_score(low_carb, S),
    S > ProbBase.

%% Fatos não suportados pela dieta não mudam o score
test(score_inalterado_por_fato_irrelevante,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, ganho_massa)))),
      cleanup(limpar_fatos) ]) :-
    dieta(low_carb, _, ProbBase),
    calcular_score(low_carb, S),
    S =:= ProbBase.

%% Teto de 0.99 deve ser respeitado mesmo com muitos fatos favoráveis
test(score_limitado_a_0_99,
    [ setup((limpar_fatos,
             assert_fatos([objetivo-perda_peso,
                           nivel_atividade-sedentario,
                           condicao_saude-diabetes,
                           restricao_carne-nao]))),
      cleanup(limpar_fatos) ]) :-
    calcular_score(low_carb, S),
    S =< 0.99.

%% Score é numérico (float) e não unificado com átomo
test(score_retorna_numero,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    calcular_score(mediterranea, S),
    number(S).

%% Dieta com múltiplos pesos satisfeitos supera dieta com menos
test(score_hiperproteica_supera_sem_fatos_com_perfil_ganho,
    [ setup((limpar_fatos,
             assert_fatos([objetivo-ganho_massa,
                           nivel_atividade-intenso,
                           restricao_carne-nao]))),
      cleanup(limpar_fatos) ]) :-
    calcular_score(hiperproteica, SH),
    calcular_score(low_fat, SL),
    SH > SL.

%% Dieta DASH deve pontuar alto com hipertensão
test(score_dash_alto_com_hipertensao,
    [ setup((limpar_fatos,
             assert_fatos([condicao_saude-hipertensao,
                           objetivo-controle_pressao]))),
      cleanup(limpar_fatos) ]) :-
    dieta(dash, _, ProbBase),
    calcular_score(dash, S),
    S > ProbBase + 0.30.  % deve ganhar pelo menos 30 pp

:- end_tests(calculo_score).


%  SUITE 2 — Regras de Exclusão
%  nao_excluida/1 deve falhar quando um fato conflitante estiver ativo

:- begin_tests(regras_exclusao).

%% Sem fatos conflitantes, dieta não é excluída
test(low_carb_nao_excluida_sem_conflito,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    nao_excluida(low_carb).

%% Vegetariano não pode fazer dieta hiperproteica (baseada em carne)
test(hiperproteica_excluida_para_vegetariano,
    [ setup((limpar_fatos, assertz(user:user_fact(restricao_carne, sim)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(hiperproteica).

%% Sem disposição para cortar carboidratos → cetogênica excluída
test(cetogenica_excluida_sem_disposicao,
    [ setup((limpar_fatos, assertz(user:user_fact(disposicao_restricao, nao)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(cetogenica).

%% Pouco tempo de preparo → mediterrânea excluída
test(mediterranea_excluida_por_tempo_baixo,
    [ setup((limpar_fatos, assertz(user:user_fact(tempo_preparo, baixa)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(mediterranea).

%% Problemas renais → hiperproteica excluída (sobrecarga renal)
test(hiperproteica_excluida_por_problema_renal,
    [ setup((limpar_fatos, assertz(user:user_fact(condicao_saude, problemas_renais)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(hiperproteica).

%% Colesterol alto → cetogênica excluída (alto consumo de gordura saturada)
test(cetogenica_excluida_por_colesterol_alto,
    [ setup((limpar_fatos, assertz(user:user_fact(condicao_saude, colesterol_alto)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(cetogenica).

%% Objetivo ganho de massa → low fat excluída
test(low_fat_excluida_para_ganho_massa,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, ganho_massa)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(low_fat).

%% Orçamento baixo → mediterrânea excluída
test(mediterranea_excluida_por_orcamento_baixo,
    [ setup((limpar_fatos, assertz(user:user_fact(orcamento, baixo)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(mediterranea).

%% Vegana excluída com pouco tempo (requer planejamento rigoroso)
test(vegana_excluida_por_tempo_baixo,
    [ setup((limpar_fatos, assertz(user:user_fact(tempo_preparo, baixa)))),
      cleanup(limpar_fatos) ]) :-
    \+ nao_excluida(vegana).

:- end_tests(regras_exclusao).



%  SUITE 3 — Recomendações (recomendar/1)
%  Lista deve ser não-vazia, ordenada decrescente e sem excluídas

:- begin_tests(recomendacoes).

%% Retorna lista não-vazia para perfil válido
test(retorna_lista_nao_vazia,
    [ setup((limpar_fatos, perfil_perda_peso)),
      cleanup(limpar_fatos) ]) :-
    recomendar(Lista),
    Lista \= [].

%% Lista ordenada por score decrescente
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

%% Hiperproteica não aparece para vegetariano (excluída)
test(hiperproteica_ausente_para_vegetariano,
    [ setup((limpar_fatos, perfil_vegetariano)),
      cleanup(limpar_fatos) ]) :-
    recomendar(Lista),
    \+ member(_-hiperproteica-_, Lista).

%% Vegetariana aparece para vegetariano (sem restrição de laticínios)
test(vegetariana_presente_para_vegetariano,
    [ setup((limpar_fatos, perfil_vegetariano)),
      cleanup(limpar_fatos) ]) :-
    recomendar(Lista),
        once(member(_-vegetariana-_, Lista)).

%% Todos os scores estão no intervalo [0, 0.99]
test(todos_scores_no_intervalo_valido,
    [ setup((limpar_fatos, perfil_perda_peso)),
      cleanup(limpar_fatos) ]) :-
    recomendar(Lista),
    forall(member(S-_-_, Lista), (S >= 0, S =< 0.99)).

%% DASH deve estar bem posicionada para perfil de hipertensão
test(dash_top3_para_hipertensao,
    [ setup((limpar_fatos,
             assert_fatos([objetivo-controle_pressao,
                           condicao_saude-hipertensao,
                           nivel_atividade-moderado,
                           restricao_carne-nao,
                           orcamento-flexivel,
                           tempo_preparo-media]))),
      cleanup(limpar_fatos) ]) :-
    recomendar(Lista),
        once(nth1(Pos, Lista, _-dash-_)),
    Pos =< 3.

:- end_tests(recomendacoes).



%  SUITE 4 — Perguntas Condicionais
%  listar_perguntas_condicionais_ativas/1 deve ativar/omitir corretamente

:- begin_tests(perguntas_condicionais).

%% Sem fatos, nenhuma pergunta condicional ativa
test(sem_fatos_nenhuma_condicional,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    listar_perguntas_condicionais_ativas(L),
    L = [].

%% restricao_carne=sim deve ativar a pergunta sobre laticínios
test(sim_carne_ativa_pergunta_laticinios,
    [ setup((limpar_fatos, assertz(user:user_fact(restricao_carne, sim)))),
      cleanup(limpar_fatos) ]) :-
    listar_perguntas_condicionais_ativas(L),
    member(restricao_laticinios, L).

%% restricao_carne=nao deve ativar a pergunta sobre frequência de consumo
test(nao_carne_ativa_frequencia,
    [ setup((limpar_fatos, assertz(user:user_fact(restricao_carne, nao)))),
      cleanup(limpar_fatos) ]) :-
    listar_perguntas_condicionais_ativas(L),
    member(frequencia_carne, L).

%% objetivo=perda_peso deve ativar a pergunta sobre disposição de restrição
test(perda_peso_ativa_disposicao,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, perda_peso)))),
      cleanup(limpar_fatos) ]) :-
    listar_perguntas_condicionais_ativas(L),
    member(disposicao_restricao, L).

%% Pergunta condicional não é repetida após ser respondida
test(condicional_nao_repete_se_ja_respondida,
    [ setup((limpar_fatos,
             assertz(user:user_fact(restricao_carne, sim)),
             assertz(user:user_fact(restricao_laticinios, sim)))),
      cleanup(limpar_fatos) ]) :-
    listar_perguntas_condicionais_ativas(L),
    \+ member(restricao_laticinios, L).

%% condicao_saude=nenhuma deve ativar pergunta de sensibilidade ao glúten
test(nenhuma_condicao_ativa_gluten,
    [ setup((limpar_fatos, assertz(user:user_fact(condicao_saude, nenhuma)))),
      cleanup(limpar_fatos) ]) :-
    listar_perguntas_condicionais_ativas(L),
    member(restricao_gluten, L).

:- end_tests(perguntas_condicionais).



%  SUITE 5 — CRUD Dietas
%  Verifica incluir / alterar / excluir em tempo de execução

:- begin_tests(crud_dietas).

%% Limpa qualquer resíduo de dieta de teste antes/depois de cada caso
cleanup_dieta_crud :-
    retractall(user:dieta(dieta_crud_teste, _, _)),
    retractall(user:descricao_dieta(dieta_crud_teste, _)),
    retractall(user:suporta(dieta_crud_teste, _, _, _)),
    retractall(user:exclui(dieta_crud_teste, _, _)).

%% Inclusão cria os predicados dieta/3 e descricao_dieta/2
test(incluir_nova_dieta,
    [ setup(cleanup_dieta_crud), cleanup(cleanup_dieta_crud) ]) :-
    incluir_dieta(dieta_crud_teste, 'Dieta Teste', 0.50, 'Descricao de teste'),
    dieta(dieta_crud_teste, 'Dieta Teste', 0.50),
    descricao_dieta(dieta_crud_teste, 'Descricao de teste').

%% Não permite incluir dieta com ID já existente (falha corretamente)
test(incluir_dieta_duplicada_falha,
    [ setup((cleanup_dieta_crud,
             incluir_dieta(dieta_crud_teste, 'Orig', 0.50, 'Desc'))),
      cleanup(cleanup_dieta_crud) ]) :-
    \+ incluir_dieta(dieta_crud_teste, 'Dup', 0.60, 'Desc2').

%% Alteração atualiza nome, probabilidade e descrição
test(alterar_dieta_existente,
    [ setup((cleanup_dieta_crud,
             incluir_dieta(dieta_crud_teste, 'Velha', 0.30, 'Desc velha'))),
      cleanup(cleanup_dieta_crud) ]) :-
    alterar_dieta(dieta_crud_teste, 'Nova', 0.75, 'Desc nova'),
    dieta(dieta_crud_teste, 'Nova', 0.75),
    descricao_dieta(dieta_crud_teste, 'Desc nova').

%% Exclusão remove dieta e todos os fatos associados
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


%  SUITE 6 — CRUD Suportes (Pesos)

:- begin_tests(crud_suportes).

cleanup_suporte_crud :-
    retractall(user:suporta(low_carb, nivel_atividade, val_crud_teste, _)).

%% Inclusão de suporte persiste na base
test(incluir_suporte,
    [ setup(cleanup_suporte_crud), cleanup(cleanup_suporte_crud) ]) :-
    incluir_suporte(low_carb, nivel_atividade, val_crud_teste, 0.15),
    suporta(low_carb, nivel_atividade, val_crud_teste, 0.15).

%% Alteração de peso atualiza o registro corretamente
test(alterar_peso_suporte,
    [ setup((cleanup_suporte_crud,
                         assertz(user:suporta(low_carb, nivel_atividade, val_crud_teste, 0.10)))),
      cleanup(cleanup_suporte_crud) ]) :-
        alterar_suporte(low_carb, nivel_atividade, val_crud_teste, 0.22),
        suporta(low_carb, nivel_atividade, val_crud_teste, 0.22),
        \+ suporta(low_carb, nivel_atividade, val_crud_teste, 0.10).

%% Exclusão de suporte remove o registro
test(excluir_suporte,
    [ setup((cleanup_suporte_crud,
                         assertz(user:suporta(low_carb, nivel_atividade, val_crud_teste, 0.10)))),
      cleanup(cleanup_suporte_crud) ]) :-
        excluir_suporte(low_carb, nivel_atividade, val_crud_teste),
        \+ suporta(low_carb, nivel_atividade, val_crud_teste, _).

%% Novo suporte afeta o score calculado
test(suporte_novo_impacta_score,
    [ setup((limpar_fatos,
                         assertz(user:user_fact(objetivo, saude_geral)),
                         retractall(user:suporta(low_carb, objetivo, saude_geral, _)))),
      cleanup((limpar_fatos,
                             retractall(user:suporta(low_carb, objetivo, saude_geral, _)))) ]) :-
    dieta(low_carb, _, ProbBase),
    calcular_score(low_carb, S0),
    S0 =:= ProbBase,                  % ainda sem suporte para saude_geral
    incluir_suporte(low_carb, objetivo, saude_geral, 0.20),
    calcular_score(low_carb, S1),
    S1 > S0.                          % agora deve ter pontuado

:- end_tests(crud_suportes).



%  SUITE 7 — CRUD Exclusões (Bloqueios)

:- begin_tests(crud_exclusoes).

cleanup_excl_crud :-
    retractall(user:exclui(low_carb, attr_crud_excl, val_crud_excl)).

%% Inclusão de exclusão persiste
test(incluir_exclusao,
    [ setup(cleanup_excl_crud), cleanup(cleanup_excl_crud) ]) :-
    incluir_exclusao(low_carb, attr_crud_excl, val_crud_excl),
    exclui(low_carb, attr_crud_excl, val_crud_excl).

%% Exclusão de uma regra de bloqueio a remove
test(excluir_exclusao,
    [ setup((cleanup_excl_crud,
                         assertz(user:exclui(low_carb, attr_crud_excl, val_crud_excl)))),
      cleanup(cleanup_excl_crud) ]) :-
        excluir_exclusao(low_carb, attr_crud_excl, val_crud_excl),
        \+ exclui(low_carb, attr_crud_excl, val_crud_excl).

%% Nova exclusão impede a dieta de aparecer quando o fato estiver ativo
test(nova_exclusao_bloqueia_dieta_no_score,
    [ setup((limpar_fatos,
                         assertz(user:user_fact(objetivo, saude_geral)))),
      cleanup((limpar_fatos,
                             retractall(user:exclui(low_carb, objetivo, saude_geral)))) ]) :-
    nao_excluida(low_carb),            % ainda não bloqueada
    incluir_exclusao(low_carb, objetivo, saude_geral),
    \+ nao_excluida(low_carb).         % agora bloqueada

:- end_tests(crud_exclusoes).



%  SUITE 8 — Explicabilidade
%  fatos_confirmados/2, fatos_faltantes/2, razoes_exclusao/2

:- begin_tests(explicabilidade).

%% fatos_confirmados lista pares corretos para o perfil
test(fatos_confirmados_retorna_fatos_ativos,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, perda_peso)))),
      cleanup(limpar_fatos) ]) :-
    fatos_confirmados(low_carb, Fatos),
    member(objetivo-perda_peso-0.25, Fatos).

%% fatos_confirmados deve estar vazio sem fatos ativos
test(fatos_confirmados_vazio_sem_fatos,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    fatos_confirmados(low_carb, Fatos),
    Fatos = [].

%% fatos_faltantes lista suportes não satisfeitos
test(fatos_faltantes_sem_fatos_traz_todos,
    [ setup(limpar_fatos), cleanup(limpar_fatos) ]) :-
    fatos_faltantes(low_carb, Fatos),
    Fatos \= [].

%% fatos_faltantes exclui o que já foi satisfeito
test(fatos_faltantes_exclui_satisfeitos,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, perda_peso)))),
      cleanup(limpar_fatos) ]) :-
    fatos_faltantes(low_carb, Fatos),
    \+ member(objetivo-perda_peso-_, Fatos).

%% razoes_exclusao retorna o atributo que causou a exclusão
test(razoes_exclusao_hiperproteica_vegetariano,
    [ setup((limpar_fatos, assertz(user:user_fact(restricao_carne, sim)))),
      cleanup(limpar_fatos) ]) :-
    razoes_exclusao(hiperproteica, Razoes),
    member(restricao_carne-sim, Razoes).

%% razoes_exclusao vazia quando não há conflito
test(razoes_exclusao_vazia_sem_conflito,
    [ setup((limpar_fatos, assertz(user:user_fact(objetivo, perda_peso)))),
      cleanup(limpar_fatos) ]) :-
    razoes_exclusao(low_carb, Razoes),
    Razoes = [].

%% detalhes_pergunta retorna os campos corretos para atributo base
test(detalhes_pergunta_retorna_estrutura_correta) :-
    detalhes_pergunta(objetivo, Texto, Opcoes, Justificativa),
    string_length(Texto, TLen), TLen > 5,
    is_list(Opcoes), Opcoes \= [],
    string_length(Justificativa, JLen), JLen > 5.

%% gatilho_pergunta identifica a dependência corretamente
test(gatilho_pergunta_restricao_carne_sim) :-
    gatilho_pergunta(restricao_laticinios, restricao_carne, sim).

:- end_tests(explicabilidade).



%  PREDICADO AUXILIAR — chamado pela interface Python
%  executar_testes_sistema/0
%  Executa run_tests e retorna ao prompt normalmente.

executar_testes_sistema :-
  set_test_options([format(log), output(always)]),
    run_tests.