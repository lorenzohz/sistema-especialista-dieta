:- set_prolog_flag(encoding, utf8).

% DIETAS -------------------------------------------------------------------------------------------------------
% dieta(Id, NomeExibicao, ProbabilidadeBase).
%
% ProbabilidadeBase: probabilidade a priori (0.0-1.0)
% Representa o quanto a dieta e adequada "por padrao", antes de qualquer fato do usuario ser considerado.
:- dynamic dieta/3.

dieta(low_carb,      'Low Carb',       0.50).
dieta(vegetariana,   'Vegetariana',    0.50).
dieta(vegana,        'Vegana',         0.45).
dieta(mediterranea,  'Mediterranea',   0.55).
dieta(hiperproteica, 'Hiperproteica',  0.50).
dieta(low_fat,       'Low Fat',        0.45).
dieta(sem_gluten,    'Sem Gluten',     0.40).
dieta(dash,          'DASH',           0.45).
dieta(cetogenica,    'Cetogenica',     0.40).
dieta(paleolitica,   'Paleolitica',    0.45).
dieta(flexitariana,  'Flexitariana',   0.55).

% DESCRIÇÕES ---------------------------------------------------------------------------------------------------
:- dynamic descricao_dieta/2.

descricao_dieta(low_carb,      'Reducao de carboidratos, focando em proteinas, vegetais e gorduras boas.').
descricao_dieta(vegetariana,   'Baseada em vegetais. Exclui carnes, mas permite laticinios e ovos.').
descricao_dieta(vegana,        'Estritamente baseada em plantas. Exclui qualquer produto de origem animal.').
descricao_dieta(mediterranea,  'Focada em alimentos frescos, azeite, peixes, oleaginosas e graos integrais.').
descricao_dieta(hiperproteica, 'Alta ingestao de proteinas, focada na manutencao e construcao muscular.').
descricao_dieta(low_fat,       'Reducao drastica de gorduras, priorizando carboidratos complexos e proteinas magras.').
descricao_dieta(sem_gluten,    'Exclusao total de trigo, centeio e cevada. Focada em celíacos ou intolerantes.').
descricao_dieta(dash,          'Focada em reduzir a pressao arterial, sendo rica em potassio e baixissima em sodio.').
descricao_dieta(cetogenica,    'Altissima ingestao de gorduras e carboidratos quase zerados (induz cetose).').
descricao_dieta(paleolitica,   'Foca em alimentos nao processados (carnes, sementes) e exclui graos e laticinios.').
descricao_dieta(flexitariana,  'Maioritariamente vegetariana, com consumo esporadico e flexivel de carnes.').

% PERGUNTAS ----------------------------------------------------------------------------------------------------
% pergunta(Atributo, Tipo, TextoPergunta, Opcoes, Justificativa).
%
% Atributo: identificador interno do fato
% Tipo pode ser 'base' ou 'depende(AtributoPai, ValorEsperado)'.
% Opcoes: valores possiveis para o atributo
% Justificativa: razao pela qual essa pergunta e feita

% PERGUNTAS BASE
pergunta(objetivo, base,
    'Qual e o seu principal objetivo com a dieta?',
    [perda_peso, ganho_massa, saude_geral, controle_diabetes, controle_pressao],
    'O objetivo e a diretriz central para selecionar o perfil nutricional adequado.').

pergunta(nivel_atividade, base,
    'Qual e o seu nivel de atividade fisica?',
    [sedentario, moderado, intenso],
    'O nivel de atividade determina a demanda calorica e proteica da dieta.').

pergunta(condicao_saude, base,
    'Voce possui alguma condicao de saude especifica?',
    [nenhuma, diabetes, hipertensao, colesterol_alto, problemas_renais],
    'Certas condicoes de saude tornam dietas especificas mais indicadas ou absolutamente contraindicadas.').

pergunta(tempo_preparo, base,
    'Como e a sua disponibilidade de tempo para preparar refeicoes?',
    [baixa, media, alta],
    'Dietas com alimentos sempre frescos ou integrais exigem maior tempo de cozinha e planejamento.').

pergunta(restricao_carne, base,
    'Voce possui restricao ao consumo de carnes?',
    [sim, nao],
    'Restricoes a carne eliminam dietas incompativeis com a escolha alimentar.').

pergunta(orcamento, base,
    'Como e o seu orcamento para alimentacao?',
    [baixo, flexivel, alto],
    'Algumas dietas exigem ingredientes frescos ou especificos que podem ter custo elevado.').

% PERGUNTAS CONDICIONAIS
pergunta(frequencia_carne, depende(restricao_carne, nao),
    'Com qual frequencia voce consome carne na semana?',
    [diariamente, ocasionalmente, raramente],
    'Ajuda a distinguir se um perfil flexitariano ou tradicional e mais adequado.').

pergunta(restricao_laticinios, depende(restricao_carne, sim),
    'Como voce nao consome carne, possui restricao ao consumo de laticinios e ovos?',
    [sim, nao],
    'A restricao a laticinios distingue os perfis vegetariano e vegano.').

pergunta(disposicao_restricao, depende(objetivo, perda_peso),
    'Voce esta disposto(a) a cortar drasticamente grupos alimentares (como carboidratos)?',
    [sim, nao],
    'Dietas de choque ou cetogenicas exigem alta restricao e disciplina.').

pergunta(restricao_gluten, depende(condicao_saude, nenhuma),
    'Apesar de nao ter condicoes cronicas, voce possui sensibilidade ao gluten?',
    [sim, nao],
    'A sensibilidade ao gluten exige adaptacao dietetica especifica, mesmo em pessoas saudaveis.').

% REGRAS DE SUPORTE --------------------------------------------------------------------------------------------
% suporta(Dieta, Atributo, Valor, Peso).
%
% Peso: quanto esse fato contribui ao score final da dieta.
% Formula: Score = min(0.99, ProbBase + sum(pesos satisfeitos))
:- dynamic suporta/4.

% Low Carb
suporta(low_carb, objetivo,        perda_peso,        0.25).
suporta(low_carb, objetivo,        controle_diabetes, 0.20).
suporta(low_carb, nivel_atividade, sedentario,        0.10).
suporta(low_carb, nivel_atividade, moderado,          0.05).
suporta(low_carb, condicao_saude,  diabetes,          0.15).
suporta(low_carb, restricao_carne, nao,               0.05).

% Vegetariana
suporta(vegetariana, restricao_carne,      sim,             0.35).
suporta(vegetariana, objetivo,             saude_geral,     0.15).
suporta(vegetariana, condicao_saude,       colesterol_alto, 0.10).
suporta(vegetariana, restricao_laticinios, nao,             0.05).
suporta(vegetariana, nivel_atividade,      moderado,        0.05).

% Vegana
suporta(vegana, restricao_carne,      sim,             0.25).
suporta(vegana, restricao_laticinios, sim,             0.30).
suporta(vegana, objetivo,             saude_geral,     0.10).
suporta(vegana, condicao_saude,       colesterol_alto, 0.10).

% Mediterranea
suporta(mediterranea, objetivo,        saude_geral,      0.20).
suporta(mediterranea, objetivo,        controle_pressao, 0.10).
suporta(mediterranea, restricao_carne, nao,              0.10).
suporta(mediterranea, condicao_saude,  colesterol_alto,  0.15).
suporta(mediterranea, condicao_saude,  hipertensao,      0.10).
suporta(mediterranea, nivel_atividade, moderado,         0.05).
suporta(mediterranea, nivel_atividade, intenso,          0.05).
suporta(mediterranea, orcamento,       flexivel,         0.10).
suporta(mediterranea, orcamento,       alto,             0.15).

% Hiperproteica
suporta(hiperproteica, objetivo,        ganho_massa, 0.35).
suporta(hiperproteica, nivel_atividade, intenso,     0.20).
suporta(hiperproteica, nivel_atividade, moderado,    0.05).
suporta(hiperproteica, restricao_carne, nao,         0.10).

% Low Fat
suporta(low_fat, objetivo,        perda_peso,      0.15).
suporta(low_fat, objetivo,        saude_geral,     0.10).
suporta(low_fat, condicao_saude,  colesterol_alto, 0.20).
suporta(low_fat, condicao_saude,  hipertensao,     0.10).
suporta(low_fat, nivel_atividade, sedentario,      0.05).

% Sem Gluten
suporta(sem_gluten, restricao_gluten, sim,         0.50).
suporta(sem_gluten, objetivo,         saude_geral, 0.05).

% DASH
suporta(dash, condicao_saude,  hipertensao,      0.35).
suporta(dash, objetivo,        controle_pressao, 0.25).
suporta(dash, objetivo,        saude_geral,      0.10).
suporta(dash, restricao_carne, nao,              0.05).
suporta(dash, condicao_saude,  colesterol_alto,  0.10).

% Cetogenica
suporta(cetogenica, objetivo,             perda_peso, 0.20).
suporta(cetogenica, condicao_saude,       diabetes,   0.20).
suporta(cetogenica, disposicao_restricao, sim,        0.30).
suporta(cetogenica, orcamento,            alto,       0.10).

% Paleolitica
suporta(paleolitica, objetivo,         saude_geral, 0.20).
suporta(paleolitica, restricao_gluten, sim,         0.15).
suporta(paleolitica, orcamento,        alto,        0.10).
suporta(paleolitica, orcamento,        flexivel,    0.05).

% Flexitariana
suporta(flexitariana, restricao_carne,  nao,            0.10).
suporta(flexitariana, frequencia_carne, ocasionalmente, 0.30).
suporta(flexitariana, frequencia_carne, raramente,      0.35).
suporta(flexitariana, objetivo,         saude_geral,    0.15).

% REGRAS DE EXCLUSAO -------------------------------------------------------------------------------------------
% exclui(Dieta, Atributo, Valor).
%
% Condicao que torna a dieta INCOMPATIVEL com o usuario.
% Dietas excluidas nao aparecem nas recomendacoes.
:- dynamic exclui/3.

% Vegetariano nao pode seguir dieta hiperproteica baseada em carne
exclui(hiperproteica, restricao_carne, sim).

% Quem nao consome laticinios nao deve seguir dieta vegetariana
% (pois ela depende de laticinios como fonte proteica; vegana e mais adequada)
exclui(vegetariana, restricao_laticinios, sim).

% Quem nao quer cortar carboidrato nao pode fazer keto
exclui(cetogenica, disposicao_restricao, nao).

% Exige preparo de peixes e vegetais frescos
exclui(mediterranea, tempo_preparo, baixa).

% Exige planejamento rigoroso de macros para não haver déficit
exclui(vegana, tempo_preparo, baixa).

% Alimentos processados são proibidos, exige cozinhar tudo
exclui(paleolitica, tempo_preparo, baixa).

% Sobrecarga renal
exclui(hiperproteica, condicao_saude, problemas_renais).

% Alto consumo de gordura saturada contraindicado
exclui(cetogenica, condicao_saude, colesterol_alto).

% Difícil atingir superávit limpo sem gorduras boas
exclui(low_fat, objetivo, ganho_massa).

% Exclusões financeiras
exclui(paleolitica, orcamento, baixo).
exclui(mediterranea, orcamento, baixo).