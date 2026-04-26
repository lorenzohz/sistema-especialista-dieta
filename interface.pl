% ==============================================================
%  INTERFACE DO SISTEMA ESPECIALISTA DE RECOMENDACAO DE DIETA
%  Disciplina: Introducao a Inteligencia Artificial - UEM
% ==============================================================

% Textos das perguntas ao usuario
% pergunta(+Id, +TextoDaPergunta)

% --------------------------------------------------------------
% Objetivos do usuario
% --------------------------------------------------------------

pergunta(objetivo_emagrecer,
    'Seu principal objetivo e perder peso (emagrecer)?').

pergunta(objetivo_ganho_muscular,
    'Seu principal objetivo e ganhar massa muscular?').

pergunta(objetivo_manutencao_peso,
    'Seu principal objetivo e manter o peso atual?').

pergunta(objetivo_ganhar_peso,
    'Seu objetivo e ganhar peso (voce esta abaixo do peso desejado)?').

pergunta(objetivo_saude_cardiovascular,
    'Seu objetivo prioritario e melhorar a saude do coracao e sistema cardiovascular?').

pergunta(objetivo_saude_geral,
    'Seu objetivo e melhorar a saude e bem-estar geral, sem objetivo especifico de peso?').

% --------------------------------------------------------------
% Condicoes de saude
% --------------------------------------------------------------

pergunta(tem_diabetes_tipo2,
    'Voce possui diagnostico de diabetes tipo 2 ou pre-diabetes?').

pergunta(pressao_arterial_alta,
    'Voce possui pressao arterial alta (hipertensao) diagnosticada?').

pergunta(pressao_arterial_normal,
    'Sua pressao arterial esta dentro da faixa normal (menor que 120/80 mmHg)?').

pergunta(colesterol_alto,
    'Voce possui colesterol total elevado (acima de 200 mg/dL) ou LDL alto?').

pergunta(tem_condicao_inflamatoria,
    'Voce possui condicao inflamatoria cronica (artrite, artrose, doenca de Crohn, lupus ou similar)?').

pergunta(diagnosticado_celiaco_ou_sensivel_gluten,
    'Voce possui diagnostico de doenca celiaca ou sensibilidade nao celiaca ao gluten?').

pergunta(sintomas_gastrointestinais_cronicos,
    'Voce apresenta sintomas gastrointestinais cronicos (inchaco, dor abdominal, diarreia) sem diagnostico definido?').

pergunta(nao_tem_problema_renal,
    'Voce NAO possui doenca renal cronica ou insuficiencia renal?').

pergunta(sem_condicao_medica_especifica,
    'Voce NAO possui nenhuma condicao medica especifica (diabetes, hipertensao, doenca cardiaca, etc.)?').

pergunta(nao_tem_diabetes_tipo2,
    'Voce NAO possui diabetes tipo 2 nem pre-diabetes?').

pergunta(historico_familiar_doenca_cardiaca,
    'Ha historico de doenca cardiaca na sua familia (pais ou irmaos)?').

pergunta(historico_familiar_diabetes,
    'Ha historico de diabetes tipo 2 na sua familia?').

% --------------------------------------------------------------
% Habitos alimentares e restricoes
% --------------------------------------------------------------

pergunta(nao_consome_carne,
    'Voce nao consome carnes (bovina, suina, frango, peixe) por escolha ou necessidade?').

pergunta(consome_peixe_ou_frutos_mar,
    'Voce consome peixe e/ou frutos do mar regularmente (ao menos 1-2 vezes por semana)?').

pergunta(consome_carne_e_ovos,
    'Voce consome carne e ovos regularmente sem restricoes?').

pergunta(aceita_reducao_carboidratos,
    'Voce aceita reduzir significativamente o consumo de carboidratos (pao, arroz, massa, acucar)?').

pergunta(sem_restricao_gluten,
    'Voce nao possui restricao ao gluten (pode consumir trigo, aveia, cevada normalmente)?').

pergunta(prefere_variedade_alimentar,
    'Voce prefere uma dieta variada, sem eliminar grupos alimentares inteiros?').

pergunta(consome_muito_sodio_atualmente,
    'Voce consume muitos alimentos ricos em sodio (sal, embutidos, enlatados, fast food)?').

pergunta(motivacao_etica_ou_ambiental,
    'Sua motivacao para nao comer carne inclui questoes eticas (bem-estar animal) ou ambientais?').

% --------------------------------------------------------------
% Nivel de atividade fisica
% --------------------------------------------------------------

pergunta(nivel_atividade_sedentario_ou_leve,
    'Seu nivel de atividade fisica e sedentario ou leve (menos de 2x por semana ou apenas caminhadas curtas)?').

pergunta(nivel_atividade_moderada,
    'Seu nivel de atividade fisica e moderado (ex: academia ou esporte 3-4x por semana, 45-60 min)?').

pergunta(nivel_atividade_alta,
    'Seu nivel de atividade fisica e alto (treinos intensos 5+ vezes por semana ou atleta)?').

pergunta(pratica_musculacao_ou_esporte,
    'Voce pratica musculacao ou esporte de alta intensidade com regularidade (pelo menos 3x por semana)?').

% --------------------------------------------------------------
% Peso e composicao corporal
% --------------------------------------------------------------

pergunta(muito_acima_peso,
    'Voce esta muito acima do peso (IMC acima de 30, obesidade)?').

pergunta(pouco_acima_peso,
    'Voce esta levemente acima do peso (IMC entre 25-29.9, sobrepeso)?').

pergunta(metabolismo_acelerado_ou_dificuldade_ganho,
    'Voce tem dificuldade em ganhar peso mesmo comendo bastante (metabolismo acelerado)?').

pergunta(historico_de_dietas_yo_yo,
    'Voce ja fez varias dietas sem sucesso a longo prazo (efeito sanfona)?').

pergunta(ja_tentou_dietas_sem_sucesso,
    'Voce ja tentou dietas convencionais (hipocalorica, etc.) e nao obteve resultado satisfatorio?').

:- consult('motor.pl').

% ==============================================================
%  AUXILIARES DE LEITURA DE LINHA
%  Substituem read/1 para que o usuario nao precise digitar '.'
% ==============================================================

% Le uma linha e converte para inteiro (para opcoes de menu)
ler_opcao(N) :-
    read_line_to_string(user_input, Linha),
    (number_string(N, Linha) -> true ; N = -1).

% Le uma linha e devolve sim ou nao (com loop de validacao)
ler_sim_nao(Resp) :-
    read_line_to_string(user_input, Linha),
    string_lower(Linha, Lower),
    (   Lower = "sim" -> Resp = sim
    ;   Lower = "nao" -> Resp = nao
    ;   Resp = invalido
    ).

% Le uma linha e devolve um atom (para IDs, nomes, categorias)
ler_atom(Atom) :-
    read_line_to_string(user_input, Linha),
    atom_string(Atom, Linha).

% Le uma linha e devolve numero (inteiro ou float)
ler_numero(N) :-
    read_line_to_string(user_input, Linha),
    (number_string(N, Linha) -> true ; N = invalido).

% ==============================================================
%  NUCLEO DA ENTREVISTA
% ==============================================================

% Todos os objetivos possiveis, em ordem de exibicao
objetivo_opcao(1, objetivo_emagrecer,             'Perder peso (emagrecer)').
objetivo_opcao(2, objetivo_ganho_muscular,        'Ganhar massa muscular').
objetivo_opcao(3, objetivo_ganhar_peso,           'Ganhar peso (estou abaixo do peso desejado)').
objetivo_opcao(4, objetivo_manutencao_peso,       'Manter o peso atual').
objetivo_opcao(5, objetivo_saude_cardiovascular,  'Melhorar a saude do coracao e sistema cardiovascular').
objetivo_opcao(6, objetivo_saude_geral,           'Melhorar a saude e bem-estar geral, sem objetivo especifico de peso').

%
% Exibe menu numerado de objetivos, le a escolha do usuario
% e registra sim para o escolhido e nao para todos os demais.
%
perguntar_objetivo :-
    nl,
    writeln('------------------------------------------------------------'),
    writeln(' Qual e o seu principal objetivo?'),
    writeln('------------------------------------------------------------'),
    forall(
        objetivo_opcao(N, _, Descricao),
        (write('  '), write(N), write('. '), writeln(Descricao))
    ),
    nl,
    write('>> Digite o numero correspondente: '),
    ler_numero(Escolha),
    (
        (integer(Escolha), objetivo_opcao(Escolha, IdEscolhido, _)) ->
            assertz(resposta(IdEscolhido, sim)),
            forall(
                (objetivo_opcao(_, IdOutro, _), IdOutro \= IdEscolhido),
                assertz(resposta(IdOutro, nao))
            )
        ;
            writeln('   Opcao invalida. Tente novamente.'),
            perguntar_objetivo
    ).

realizar_entrevista :-
    perguntar_objetivo,
    perguntar_criterios_obrigatorios,
    perguntar_criterios_opcionais_relevantes.

perguntar_criterios_obrigatorios :-
    forall(
        criterio_obrigatorio_pendente(Sintoma),
        (
            pergunta(Sintoma, Texto),
            perguntar_criterio(Sintoma, Texto)
        )
    ).

perguntar_criterios_opcionais_relevantes :-
    forall(
        criterio_opcional_relevante(Sintoma),
        (
            pergunta(Sintoma, Texto),
            perguntar_criterio(Sintoma, Texto)
        )
    ).

perguntar_criterio(Sintoma, Texto) :-
    nl,
    write('>> '), writeln(Texto),
    writeln('   Digite: sim ou nao'),
    ler_sim_nao(Resposta),
    (
        (Resposta = sim ; Resposta = nao) ->
            assertz(resposta(Sintoma, Resposta))
    ;
        writeln('   Resposta invalida. Digite sim. ou nao.'),
        perguntar_criterio(Sintoma, Texto)
    ).

% ==============================================================
%  INICIO E EXIBICAO DO DIAGNOSTICO
% ==============================================================

iniciar_consulta :-
    nl,
    writeln('============================================================'),
    writeln(' SISTEMA ESPECIALISTA DE RECOMENDACAO DE DIETA'),
    writeln('============================================================'),
    writeln(' AVISO: Este prototipo e apenas informativo.'),
    writeln(' Consulte um nutricionista ou medico para diagnostico'),
    writeln(' ou recomendacao correta e precisa.'),
    writeln('============================================================'),
    nl,
    writeln('Primeiro escolha seu objetivo principal; em seguida'),
    writeln('responda as perguntas sobre seu perfil de saude e habitos.'),
    retractall(resposta(_, _)),
    realizar_entrevista,
    diagnostico(Resultados),
    mostrar_resultados(Resultados),
    menu_explicacoes.

mostrar_resultados([]) :-
    nl,
    writeln('============================================================'),
    writeln(' Nenhuma dieta foi recomendada com base nas informacoes.'),
    writeln(' Verifique suas respostas ou consulte um especialista.'),
    writeln('============================================================').

mostrar_resultados(Resultados) :-
    nl,
    writeln('============================================================'),
    writeln(' RESULTADOS - RECOMENDACOES POR PROBABILIDADE'),
    writeln('============================================================'),
    mostrar_lista_resultados(Resultados).

mostrar_lista_resultados([]).

mostrar_lista_resultados([Prob-Hipotese | Resto]) :-
    plano(Hipotese, Nome, Categoria, _, Descricao),
    Percentual is round(Prob * 100),

    nl,
    writeln('------------------------------------------------------------'),
    write(' Dieta: '), writeln(Nome),
    write(' Categoria: '), writeln(Categoria),
    write(' Probabilidade: '), write(Percentual), writeln('%'),
    nl,
    write(' Descricao: '), writeln(Descricao),

    explicar_plano(Hipotese),

    nl,
    writeln(' Recomendacoes:'),
    mostrar_recomendacoes(Hipotese),

    mostrar_lista_resultados(Resto).

mostrar_recomendacoes(Hipotese) :-
    forall(
        recomendacao(Hipotese, Ordem, Descricao),
        (
            write('  '), write(Ordem), write('. '), writeln(Descricao)
        )
    ).

% ==============================================================
%  MENU DE EXPLICACOES (POS-DIAGNOSTICO)
% ==============================================================

menu_explicacoes :-
    nl,
    writeln('============================================================'),
    writeln(' EXPLICACOES ADICIONAIS'),
    writeln('============================================================'),
    writeln(' (1) Por que uma dieta NAO foi recomendada?'),
    writeln(' (2) Por que uma pergunta foi feita?'),
    writeln(' (3) Voltar ao menu principal'),
    writeln('------------------------------------------------------------'),
    write('Opcao: '), ler_opcao(Opcao),
    executar_explicacao(Opcao).

executar_explicacao(1) :-
    explicar_plano_descartado,
    menu_explicacoes.

executar_explicacao(2) :-
    explicar_sintoma,
    menu_explicacoes.

executar_explicacao(3).

executar_explicacao(_) :-
    writeln('Opcao invalida.'),
    menu_explicacoes.

% --------------------------------------------------------------

explicar_sintoma :-
    nl,
    listar_perguntas_feitas,
    writeln('Digite o ID da pergunta (ex: objetivo_emagrecer):'),
    write('> '), ler_atom(IdPergunta),
    (
        resposta(IdPergunta, _) ->
            explicar_pergunta(IdPergunta)
    ;
        writeln('Essa pergunta nao foi feita durante o diagnostico.')
    ).

explicar_plano_descartado :-
    nl,
    writeln('IDs de planos disponiveis:'),
    listar_ids_planos,
    writeln('Digite o ID do plano (ex: dieta_low_carb):'),
    write('> '), ler_atom(Hipotese),
    (
        plano_descartado(Hipotese) ->
            explicar_descarte(Hipotese)
    ;
        (
            plano(Hipotese, _, _, _, _) ->
                writeln('Esse plano nao foi descartado (pode ter sido recomendado ou nao avaliado).')
        ;
            writeln('ID de plano nao encontrado.')
        )
    ).

listar_ids_planos :-
    forall(
        plano(Id, Nome, _, _, _),
        (
            write('  - '), write(Id), write(' ('), write(Nome), writeln(')')
        )
    ).

listar_perguntas_feitas :-
    findall(Sintoma, resposta(Sintoma, _), Lista),
    sort(Lista, Unicas),
    writeln('Perguntas realizadas durante o diagnostico:'),
    forall(
        member(S, Unicas),
        (
            pergunta(S, Texto),
            write('  - '), write(S), write(' -> '), writeln(Texto)
        )
    ).

% ==============================================================
%  MENU PRINCIPAL
% ==============================================================

menu :-
    nl,
    writeln('============================================================'),
    writeln(' SISTEMA ESPECIALISTA DE RECOMENDACAO DE DIETA'),
    writeln(' Introducao a Inteligencia Artificial - UEM'),
    writeln('============================================================'),
    writeln(' (1) Iniciar avaliacao e obter recomendacao'),
    writeln(' (2) Gerenciar planos de dieta (CRUD)'),
    writeln(' (3) Sair'),
    writeln('------------------------------------------------------------'),
    write('Opcao: '), ler_opcao(Opcao),
    executar_opcao(Opcao).

executar_opcao(1) :-
    iniciar_consulta,
    menu.

executar_opcao(2) :-
    menu_crud.

executar_opcao(3) :-
    writeln('Encerrando o sistema. Ate logo!').

executar_opcao(_) :-
    writeln('Opcao invalida. Tente novamente.'),
    menu.

% ==============================================================
%  CRUD DE HIPOTESES
% ==============================================================

menu_crud :-
    nl,
    writeln('============================================================'),
    writeln(' GERENCIAMENTO DE HIPOTESES (CRUD)'),
    writeln('============================================================'),
    writeln(' (1) Consultar / Listar planos'),
    writeln(' (2) Incluir novo plano'),
    writeln(' (3) Alterar plano existente'),
    writeln(' (4) Excluir plano'),
    writeln(' (5) Voltar ao menu principal'),
    writeln('------------------------------------------------------------'),
    write('Opcao: '), ler_opcao(Opcao),
    executar_crud(Opcao).

% (1) Consultar
executar_crud(1) :-
    nl,
    writeln('=== LISTA DE HIPOTESES CADASTRADAS ==='),
    findall(
        Id-Nome-Categoria-Prob,
        plano(Id, Nome, Categoria, Prob, _),
        Lista
    ),
    mostrar_planos_numerados(Lista, 1),
    menu_crud.

% (2) Incluir
executar_crud(2) :-
    nl,
    writeln('--- INCLUIR NOVA HIPOTESE ---'),
    write('ID (atom, ex: dieta_nova): '), ler_atom(Id),
    write('Nome: '), ler_atom(Nome),
    write('Categoria: '), ler_atom(Categoria),
    write('Probabilidade base (0.0 a 1.0): '), ler_numero(Prob),
    write('Descricao: '), ler_atom(Desc),
    assertz(plano(Id, Nome, Categoria, Prob, Desc)),
    writeln('Hipotese incluida com sucesso!'),
    menu_crud.

% (3) Alterar
executar_crud(3) :-
    nl,
    writeln('--- ALTERAR HIPOTESE ---'),
    listar_ids_planos,
    write('Digite o ID do plano a alterar: '), ler_atom(Id),
    (
        plano(Id, _, _, _, _) ->
            write('Novo nome: '), ler_atom(NovoNome),
            write('Nova categoria: '), ler_atom(NovaCategoria),
            write('Nova probabilidade (0.0 a 1.0): '), ler_numero(NovaProbabilidade),
            write('Nova descricao: '), ler_atom(NovaDescricao),
            retractall(plano(Id, _, _, _, _)),
            assertz(plano(Id, NovoNome, NovaCategoria, NovaProbabilidade, NovaDescricao)),
            writeln('Hipotese alterada com sucesso!')
    ;
        writeln('Erro: ID nao encontrado.')
    ),
    menu_crud.

% (4) Excluir
executar_crud(4) :-
    nl,
    writeln('--- EXCLUIR HIPOTESE ---'),
    listar_ids_planos,
    write('Digite o ID do plano a excluir: '), ler_atom(Id),
    (
        plano(Id, _, _, _, _) ->
            retractall(plano(Id, _, _, _, _)),
            retractall(criterio_obrigatorio(Id, _)),
            retractall(criterio_opcional(Id, _)),
            retractall(recomendacao(Id, _, _)),
            writeln('Hipotese e seus dados removidos com sucesso!')
    ;
        writeln('Erro: ID nao encontrado.')
    ),
    menu_crud.

% (5) Voltar
executar_crud(5) :-
    menu.

executar_crud(_) :-
    writeln('Opcao invalida.'),
    menu_crud.

% Auxiliar de listagem
mostrar_planos_numerados([], _).
mostrar_planos_numerados([Id-Nome-Categoria-Prob | Resto], N) :-
    Pct is Prob * 100,
    nl,
    write(N), writeln(')'),
    write('   ID: '), writeln(Id),
    write('   Nome: '), writeln(Nome),
    write('   Categoria: '), writeln(Categoria),
    write('   Prob. base: '), write(Pct), writeln('%'),
    N1 is N + 1,
    mostrar_planos_numerados(Resto, N1).
