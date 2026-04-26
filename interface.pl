% ==============================================================
%  INTERFACE DO SISTEMA ESPECIALISTA DE RECOMENDACAO DE DIETA
%  Disciplina: Introducao a Inteligencia Artificial - UEM
% ==============================================================

:- consult('motor.pl').

% ==============================================================
%  CORES E FORMATACAO ANSI
% ==============================================================

ansi(reset,   '\e[0m').
ansi(negrito, '\e[1m').
ansi(verde,   '\e[32m').
ansi(amarelo, '\e[33m').
ansi(azul,    '\e[34m').
ansi(magenta, '\e[35m').
ansi(ciano,   '\e[36m').
ansi(branco,  '\e[37m').
ansi(vermelho,'\e[31m').
ansi(cinza,   '\e[90m').

% Escreve texto com cor (sem newline)
cor(Cor, Texto) :-
    ansi(Cor, C), ansi(reset, R),
    format("~w~w~w", [C, Texto, R]).

% Escreve texto em negrito (sem newline)
negrito(Texto) :-
    ansi(negrito, B), ansi(reset, R),
    format("~w~w~w", [B, Texto, R]).

% Escreve texto colorido com newline
corln(Cor, Texto) :-
    cor(Cor, Texto), nl.

% ==============================================================
%  SEPARADORES E CABECALHOS
% ==============================================================

largura(62).

linha_solida :-
    largura(L), ansi(cinza, C), ansi(reset, R),
    format("~w", [C]),
    forall(between(1, L, _), write('=')),
    format("~w~n", [R]).

linha_tracejada :-
    largura(L), ansi(cinza, C), ansi(reset, R),
    format("~w", [C]),
    forall(between(1, L, _), write('-')),
    format("~w~n", [R]).

% Cabecalho de secao com destaque
secao(Titulo) :-
    nl, linha_solida,
    ansi(negrito, B), ansi(azul, Az), ansi(reset, R),
    format("~w~w  ~w~w~n", [B, Az, Titulo, R]),
    linha_tracejada.

% Cabecalho menor para subsecoes
subsecao(Titulo) :-
    nl,
    ansi(negrito, B), ansi(ciano, C), ansi(reset, R),
    format("~w~w  ~w~w~n", [B, C, Titulo, R]),
    linha_tracejada.

% ==============================================================
%  BARRA DE PROGRESSO E PROBABILIDADE
% ==============================================================

% Escolhe a cor pelo nivel de probabilidade
cor_probabilidade(P, verde)   :- P >= 85, !.
cor_probabilidade(P, amarelo) :- P >= 70, !.
cor_probabilidade(_, vermelho).

% Barra de progresso visual com # e . (ASCII compativel)
barra_progresso(Percentual) :-
    TotalBlocos = 20,
    Cheios is round(Percentual * TotalBlocos / 100),
    Vazios is TotalBlocos - Cheios,
    cor_probabilidade(Percentual, Cor),
    ansi(Cor, C), ansi(cinza, Cz), ansi(reset, R),
    format("~w[", [C]),
    forall(between(1, Cheios, _), write('#')),
    format("~w", [Cz]),
    forall(between(1, Vazios, _), write('.')),
    format("~w] ", [C]),
    write(Percentual), write('%'),
    write(R).

mostrar_probabilidade(Prob) :-
    Pct is round(Prob * 100),
    write("  Probabilidade: "),
    barra_progresso(Pct), nl.

% ==============================================================
%  TEXTOS DAS PERGUNTAS AO USUARIO
% ==============================================================

% --- Objetivos ---
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

% --- Condicoes de saude ---
pergunta(tem_diabetes_tipo2,
    'Voce possui diagnostico de diabetes tipo 2 ou pre-diabetes?').
pergunta(pressao_arterial_alta,
    'Voce possui pressao arterial alta (hipertensao) diagnosticada?').
pergunta(pressao_arterial_normal,
    'Sua pressao arterial esta dentro da faixa normal (menor que 120/80 mmHg)?').
pergunta(colesterol_alto,
    'Voce possui colesterol total elevado (acima de 200 mg/dL) ou LDL alto?').
pergunta(tem_condicao_inflamatoria,
    'Voce possui condicao inflamatoria cronica (artrite, doenca de Crohn, lupus ou similar)?').
pergunta(diagnosticado_celiaco_ou_sensivel_gluten,
    'Voce possui diagnostico de doenca celiaca ou sensibilidade nao celiaca ao gluten?').
pergunta(sintomas_gastrointestinais_cronicos,
    'Voce apresenta sintomas gastrointestinais cronicos (inchaco, dor abdominal, diarreia)?').
pergunta(nao_tem_problema_renal,
    'Voce NAO possui doenca renal cronica ou insuficiencia renal?').
pergunta(sem_condicao_medica_especifica,
    'Voce NAO possui nenhuma condicao medica especifica (diabetes, hipertensao, etc.)?').
pergunta(nao_tem_diabetes_tipo2,
    'Voce NAO possui diabetes tipo 2 nem pre-diabetes?').
pergunta(historico_familiar_doenca_cardiaca,
    'Ha historico de doenca cardiaca na sua familia (pais ou irmaos)?').
pergunta(historico_familiar_diabetes,
    'Ha historico de diabetes tipo 2 na sua familia?').

% --- Habitos alimentares e restricoes ---
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
    'Sua motivacao para nao comer carne inclui questoes eticas ou ambientais?').

% --- Nivel de atividade fisica ---
pergunta(nivel_atividade_sedentario_ou_leve,
    'Seu nivel de atividade fisica e sedentario ou leve (menos de 2x por semana)?').
pergunta(nivel_atividade_moderada,
    'Seu nivel de atividade fisica e moderado (academia ou esporte 3-4x por semana)?').
pergunta(nivel_atividade_alta,
    'Seu nivel de atividade fisica e alto (treinos intensos 5+ vezes por semana ou atleta)?').
pergunta(pratica_musculacao_ou_esporte,
    'Voce pratica musculacao ou esporte de alta intensidade regularmente (pelo menos 3x/semana)?').

% --- Peso e composicao corporal ---
pergunta(muito_acima_peso,
    'Voce esta muito acima do peso (IMC acima de 30, obesidade)?').
pergunta(pouco_acima_peso,
    'Voce esta levemente acima do peso (IMC entre 25-29.9, sobrepeso)?').
pergunta(metabolismo_acelerado_ou_dificuldade_ganho,
    'Voce tem dificuldade em ganhar peso mesmo comendo bastante (metabolismo acelerado)?').
pergunta(historico_de_dietas_yo_yo,
    'Voce ja fez varias dietas sem sucesso a longo prazo (efeito sanfona)?').
pergunta(ja_tentou_dietas_sem_sucesso,
    'Voce ja tentou dietas convencionais e nao obteve resultado satisfatorio?').

% ==============================================================
%  AUXILIARES DE LEITURA
% ==============================================================

ler_opcao(N) :-
    read_line_to_string(user_input, Linha),
    (number_string(N, Linha) -> true ; N = -1).

ler_sim_nao(Resp) :-
    read_line_to_string(user_input, Linha),
    string_lower(Linha, Lower),
    (   Lower = "sim" -> Resp = sim
    ;   Lower = "nao" -> Resp = nao
    ;   Resp = invalido
    ).

ler_atom(Atom) :-
    read_line_to_string(user_input, Linha),
    atom_string(Atom, Linha).

ler_numero(N) :-
    read_line_to_string(user_input, Linha),
    (number_string(N, Linha) -> true ; N = invalido).

% ==============================================================
%  MENU DE OBJETIVOS
% ==============================================================

objetivo_opcao(1, objetivo_emagrecer,            'Perder peso (emagrecer)').
objetivo_opcao(2, objetivo_ganho_muscular,       'Ganhar massa muscular').
objetivo_opcao(3, objetivo_ganhar_peso,          'Ganhar peso (abaixo do peso desejado)').
objetivo_opcao(4, objetivo_manutencao_peso,      'Manter o peso atual').
objetivo_opcao(5, objetivo_saude_cardiovascular, 'Melhorar a saude cardiovascular').
objetivo_opcao(6, objetivo_saude_geral,          'Melhorar saude e bem-estar geral').

perguntar_objetivo :-
    secao('QUAL E O SEU OBJETIVO PRINCIPAL?'),
    forall(
        objetivo_opcao(N, _, Desc),
        (
            ansi(negrito, B), ansi(reset, R),
            format("  ~w~w~w. ~w~n", [B, N, R, Desc])
        )
    ),
    nl,
    cor(ciano, '>> '), write('Numero da opcao: '),
    ler_numero(Escolha),
    (
        (integer(Escolha), objetivo_opcao(Escolha, IdEscolhido, DescEscolhida)) ->
            nl,
            write('  Objetivo: '), corln(verde, DescEscolhida),
            assertz(resposta(IdEscolhido, sim)),
            forall(
                (objetivo_opcao(_, IdOutro, _), IdOutro \= IdEscolhido),
                assertz(resposta(IdOutro, nao))
            )
        ;
            corln(vermelho, '  [ERRO] Opcao invalida. Tente novamente.'),
            perguntar_objetivo
    ).

% ==============================================================
%  NUCLEO DA ENTREVISTA  -- encadeamento pra frente
%  Os fatos (respostas) sao inseridos via assertz conforme o
%  usuario responde, e cada nova resposta pode habilitar novas
%  perguntas (criterios opcionais de planos ainda possiveis).
% ==============================================================

realizar_entrevista :-
    perguntar_objetivo,
    perguntar_criterios_obrigatorios,
    perguntar_criterios_opcionais_relevantes.

perguntar_criterios_obrigatorios :-
    forall(
        criterio_obrigatorio_pendente(Sintoma),
        (
            pergunta(Sintoma, Texto),
            perguntar_criterio(Sintoma, Texto, obrigatorio)
        )
    ).

perguntar_criterios_opcionais_relevantes :-
    findall(C, criterio_opcional_relevante(C), Lista),
    sort(Lista, Unicas),
    length(Unicas, Total),
    (   Total > 0 ->
        nl,
        ansi(cinza, Cz), ansi(reset, R),
        format("~w  (~w pergunta(s) adicional(is) para refinar o resultado)~w~n", [Cz, Total, R]),
        forall(
            member(S, Unicas),
            (pergunta(S, Texto), perguntar_criterio(S, Texto, opcional))
        )
    ;   true
    ).

perguntar_criterio(Sintoma, Texto, Tipo) :-
    nl,
    (   Tipo = obrigatorio ->
        cor(amarelo, '  [?] ')
    ;
        cor(cinza, '  [+] ')
    ),
    write(Texto), nl,
    cor(ciano, '      Resposta (sim/nao): '),
    ler_sim_nao(Resposta),
    (
        Resposta = sim ->
            cor(verde, '      -> sim'), nl,
            assertz(resposta(Sintoma, sim))
    ;   Resposta = nao ->
            cor(cinza, '      -> nao'), nl,
            assertz(resposta(Sintoma, nao))
    ;
        corln(vermelho, '      [ERRO] Digite "sim" ou "nao".'),
        perguntar_criterio(Sintoma, Texto, Tipo)
    ).

% ==============================================================
%  INICIO E EXIBICAO DO DIAGNOSTICO
% ==============================================================

iniciar_consulta :-
    secao('SISTEMA ESPECIALISTA DE RECOMENDACAO DE DIETA'),
    ansi(amarelo, Am), ansi(negrito, B), ansi(reset, R),
    format("~w~w  AVISO: Este prototipo e apenas informativo.~w~n", [B, Am, R]),
    format("  Consulte um nutricionista ou medico para orientacao~n"),
    format("  correta e personalizada ao seu caso.~n"),
    linha_tracejada,
    format("  Responda as perguntas para obter sua recomendacao.~n"),
    retractall(resposta(_, _)),
    realizar_entrevista,
    nl,
    corln(ciano, '  Calculando recomendacoes...'),
    diagnostico(Resultados),
    mostrar_resultados(Resultados),
    menu_explicacoes.

mostrar_resultados([]) :-
    secao('RESULTADO'),
    corln(vermelho, '  Nenhuma dieta foi recomendada com base nas informacoes.'),
    format("  Verifique suas respostas ou consulte um especialista.~n").

mostrar_resultados(Resultados) :-
    secao('RECOMENDACOES POR PROBABILIDADE'),
    length(Resultados, N),
    ansi(cinza, Cz), ansi(reset, R),
    format("~w  ~w dieta(s) encontrada(s) para o seu perfil:~w~n~n", [Cz, N, R]),
    mostrar_lista_resultados(Resultados, 1).

mostrar_lista_resultados([], _).
mostrar_lista_resultados([Prob-Hipotese | Resto], Pos) :-
    plano(Hipotese, Nome, Categoria, _, Descricao),
    linha_tracejada,
    ansi(negrito, B), ansi(reset, R),
    format("~w  #~w  ~w~w~n", [B, Pos, Nome, R]),
    write("  Categoria: "), cor_categoria(Categoria), nl,
    mostrar_probabilidade(Prob),
    nl,
    ansi(cinza, Cz),
    format("~w  ~w~w~n", [Cz, Descricao, R]),
    nl,
    mostrar_criterios_resultado(Hipotese),
    nl,
    negrito('  Recomendacoes praticas:'), nl,
    mostrar_recomendacoes(Hipotese),
    Pos1 is Pos + 1,
    mostrar_lista_resultados(Resto, Pos1).

% Cor por categoria
cor_categoria(emagrecimento)        :- cor(amarelo,  'Emagrecimento').
cor_categoria(saude_cardiovascular) :- cor(vermelho, 'Saude Cardiovascular').
cor_categoria(controle_metabolico)  :- cor(ciano,    'Controle Metabolico').
cor_categoria(ganho_massa)          :- cor(verde,    'Ganho de Massa / Performance').
cor_categoria(restricao_alimentar)  :- cor(magenta,  'Restricoes Alimentares').
cor_categoria(manutencao)           :- cor(azul,     'Manutencao / Bem-estar').
cor_categoria(Outro)                :- write(Outro).

% Criterios confirmados do resultado
mostrar_criterios_resultado(Plano) :-
    negrito('  Condicoes obrigatorias confirmadas:'), nl,
    forall(
        (criterio_obrigatorio(Plano, C), resposta(C, sim)),
        (pergunta(C, T), cor(verde, '    [OK] '), write(T), nl)
    ),
    findall(C2, (criterio_opcional(Plano, C2), resposta(C2, sim)), Opts),
    (   Opts \= [] ->
        nl,
        negrito('  Condicoes opcionais confirmadas:'), nl,
        forall(
            member(C3, Opts),
            (pergunta(C3, T3), cor(ciano, '    [+] '), write(T3), nl)
        )
    ;   true
    ).

mostrar_recomendacoes(Hipotese) :-
    forall(
        recomendacao(Hipotese, Ordem, Desc),
        (
            ansi(cinza, Cz), ansi(reset, R),
            format("~w    ~w.~w ~w~n", [Cz, Ordem, R, Desc])
        )
    ).

% ==============================================================
%  MENU DE EXPLICACOES (POS-DIAGNOSTICO)
% ==============================================================

menu_explicacoes :-
    secao('EXPLICACOES ADICIONAIS'),
    format("  (1) Por que uma dieta NAO foi recomendada?~n"),
    format("  (2) Por que uma pergunta foi feita?~n"),
    format("  (3) Voltar ao menu principal~n"),
    linha_tracejada,
    cor(ciano, 'Opcao: '), ler_opcao(Opcao),
    executar_explicacao(Opcao).

executar_explicacao(1) :-
    explicar_plano_descartado,
    menu_explicacoes.
executar_explicacao(2) :-
    explicar_sintoma,
    menu_explicacoes.
executar_explicacao(3).
executar_explicacao(_) :-
    corln(vermelho, '  Opcao invalida.'),
    menu_explicacoes.

explicar_plano_descartado :-
    nl,
    negrito('  IDs de planos disponiveis:'), nl,
    listar_ids_planos,
    nl, cor(ciano, '  ID do plano: '), ler_atom(Hipotese),
    (
        plano_descartado(Hipotese) ->
            explicar_descarte(Hipotese)
    ;
        (plano(Hipotese, _, _, _, _) ->
            corln(amarelo, '  Esse plano nao foi descartado.')
        ;
            corln(vermelho, '  ID de plano nao encontrado.')
        )
    ).

explicar_sintoma :-
    nl,
    negrito('  Perguntas realizadas:'), nl,
    listar_perguntas_feitas,
    nl, cor(ciano, '  ID da pergunta: '), ler_atom(Id),
    (
        resposta(Id, _) ->
            explicar_pergunta(Id)
    ;
        corln(vermelho, '  Essa pergunta nao foi feita durante o diagnostico.')
    ).

listar_ids_planos :-
    forall(
        plano(Id, Nome, _, _, _),
        (
            ansi(cinza, Cz), ansi(reset, R),
            format("~w    ~w~w  (~w)~n", [Cz, Id, R, Nome])
        )
    ).

listar_perguntas_feitas :-
    findall(S, resposta(S, _), Lista),
    sort(Lista, Unicas),
    forall(
        member(S, Unicas),
        (
            pergunta(S, Texto),
            ansi(cinza, Cz), ansi(reset, R),
            format("~w    ~w~w~n      ~w~w~n", [Cz, S, R, Cz, Texto, R])
        )
    ).

% ==============================================================
%  MENU PRINCIPAL
% ==============================================================

menu :-
    secao('SISTEMA ESPECIALISTA DE RECOMENDACAO DE DIETA'),
    ansi(cinza, Cz), ansi(reset, R),
    format("~w  Introducao a Inteligencia Artificial - UEM~w~n~n", [Cz, R]),
    format("  (1) Iniciar avaliacao e obter recomendacao~n"),
    format("  (2) Gerenciar planos de dieta (CRUD)~n"),
    format("  (3) Sair~n"),
    linha_tracejada,
    cor(ciano, 'Opcao: '), ler_opcao(Opcao),
    executar_opcao(Opcao).

executar_opcao(1) :-
    iniciar_consulta,
    menu.
executar_opcao(2) :-
    menu_crud.
executar_opcao(3) :-
    nl, corln(ciano, '  Encerrando o sistema. Ate logo!'), nl.
executar_opcao(_) :-
    corln(vermelho, '  Opcao invalida. Tente novamente.'),
    menu.

% ==============================================================
%  CRUD DE PLANOS
% ==============================================================

menu_crud :-
    secao('GERENCIAMENTO DE PLANOS (CRUD)'),
    format("  (1) Consultar / Listar planos~n"),
    format("  (2) Incluir novo plano~n"),
    format("  (3) Alterar plano existente~n"),
    format("  (4) Excluir plano~n"),
    format("  (5) Voltar ao menu principal~n"),
    linha_tracejada,
    cor(ciano, 'Opcao: '), ler_opcao(Opcao),
    executar_crud(Opcao).

executar_crud(1) :-
    subsecao('PLANOS CADASTRADOS'),
    findall(Id-Nome-Cat-Prob, plano(Id, Nome, Cat, Prob, _), Lista),
    length(Lista, N),
    ansi(cinza, Cz), ansi(reset, R),
    format("~w  ~w plano(s)~w~n~n", [Cz, N, R]),
    mostrar_planos_numerados(Lista, 1),
    menu_crud.

executar_crud(2) :-
    subsecao('INCLUIR NOVO PLANO'),
    cor(ciano, '  ID (ex: dieta_nova): '),     ler_atom(Id),
    cor(ciano, '  Nome: '),                     ler_atom(Nome),
    cor(ciano, '  Categoria: '),                ler_atom(Cat),
    cor(ciano, '  Probabilidade base (0-1): '), ler_numero(Prob),
    cor(ciano, '  Descricao: '),                ler_atom(Desc),
    assertz(plano(Id, Nome, Cat, Prob, Desc)),
    corln(verde, '  [OK] Plano incluido com sucesso!'),
    menu_crud.

executar_crud(3) :-
    subsecao('ALTERAR PLANO'),
    listar_ids_planos,
    nl, cor(ciano, '  ID do plano a alterar: '), ler_atom(Id),
    (
        plano(Id, _, _, _, _) ->
            cor(ciano, '  Novo nome: '),           ler_atom(NovoNome),
            cor(ciano, '  Nova categoria: '),      ler_atom(NovaCat),
            cor(ciano, '  Nova probabilidade: '),  ler_numero(NovaProb),
            cor(ciano, '  Nova descricao: '),      ler_atom(NovaDesc),
            retractall(plano(Id, _, _, _, _)),
            assertz(plano(Id, NovoNome, NovaCat, NovaProb, NovaDesc)),
            corln(verde, '  [OK] Plano alterado com sucesso!')
    ;
        corln(vermelho, '  [ERRO] ID nao encontrado.')
    ),
    menu_crud.

executar_crud(4) :-
    subsecao('EXCLUIR PLANO'),
    listar_ids_planos,
    nl, cor(ciano, '  ID do plano a excluir: '), ler_atom(Id),
    (
        plano(Id, _, _, _, _) ->
            retractall(plano(Id, _, _, _, _)),
            retractall(criterio_obrigatorio(Id, _)),
            retractall(criterio_opcional(Id, _)),
            retractall(recomendacao(Id, _, _)),
            corln(verde, '  [OK] Plano e dados removidos com sucesso!')
    ;
        corln(vermelho, '  [ERRO] ID nao encontrado.')
    ),
    menu_crud.

executar_crud(5) :- menu.
executar_crud(_) :-
    corln(vermelho, '  Opcao invalida.'),
    menu_crud.

% Listagem numerada
mostrar_planos_numerados([], _).
mostrar_planos_numerados([Id-Nome-Cat-Prob | Resto], N) :-
    Pct is round(Prob * 100),
    ansi(negrito, B), ansi(reset, R), ansi(cinza, Cz),
    format("  ~w~w. ~w~w~n", [B, N, Nome, R]),
    format("~w     ID: ~w  |  Categoria: ~w  |  Prob. base: ~w%~w~n",
           [Cz, Id, Cat, Pct, R]),
    N1 is N + 1,
    mostrar_planos_numerados(Resto, N1).
