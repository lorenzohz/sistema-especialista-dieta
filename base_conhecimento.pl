:- dynamic plano/5.
:- dynamic recomendacao/3.
:- dynamic criterio_obrigatorio/2.
:- dynamic criterio_opcional/2.

% Formato:
%% plano(+Id, +Nome, +Categoria, +Probabilidade, +Descricao)
%%
%% A probabilidade base varia de 0.0 a 1.0.
%% O calculo final e: ProbBase * (1 + Score * 0.20), onde
%% Score = opcionais_confirmados / total_criterios_opcionais.
%% Isso significa que os criterios opcionais podem
%% aumentar a ProbBase em ate 20% de forma proporcional.

% ==============================================================
% CATEGORIA: Emagrecimento
% ==============================================================

plano(dieta_low_carb,
    'Dieta Low-Carb / Cetogenica',
    emagrecimento,
    0.88,
    'Restricao de carboidratos para induzir cetose ou reducao calorica significativa. Indicada para perda de peso rapida e controle glicemico.'
).

plano(dieta_emagrecimento_moderado,
    'Dieta Hipocalorica Equilibrada',
    emagrecimento,
    0.85,
    'Reducao moderada de calorias mantendo todos os grupos alimentares. Perda de peso gradual e sustentavel, ideal para a maioria dos perfis.'
).

% ==============================================================
% CATEGORIA: Saude Cardiovascular
% ==============================================================

plano(dieta_mediterranea,
    'Dieta Mediterranea',
    saude_cardiovascular,
    0.90,
    'Rica em azeite, frutas, verduras, peixes e graos integrais. Amplamente reconhecida por reduzir riscos cardiovasculares e inflamacao sistemica.'
).

plano(dieta_dash,
    'Dieta DASH (Controle da Hipertensao)',
    saude_cardiovascular,
    0.92,
    'Desenvolvida especificamente para controle da pressao arterial. Enfatiza frutas, vegetais, laticinios com baixo teor de gordura e restricao de sodio.'
).

% ==============================================================
% CATEGORIA: Controle Metabolico
% ==============================================================

plano(dieta_diabeticos,
    'Dieta para Controle do Diabetes Tipo 2',
    controle_metabolico,
    0.91,
    'Controle rigoroso do indice glicemico dos alimentos. Prioriza fibras, proteinas magras e gorduras saudaveis para estabilizacao da glicemia.'
).

plano(dieta_anti_inflamatoria,
    'Dieta Anti-Inflamatoria',
    controle_metabolico,
    0.83,
    'Foca em alimentos que combatem inflamacao cronica: peixes gordurosos, frutas vermelhas, nozes, azeite e especiarias como acafrao e gengibre.'
).

% ==============================================================
% CATEGORIA: Ganho de Massa / Performance
% ==============================================================

plano(dieta_hiperproteica,
    'Dieta Hiperproteica para Ganho Muscular',
    ganho_massa,
    0.89,
    'Elevada ingestao de proteinas (1.6-2.2g por kg de peso corporal) para suportar hipertrofia muscular. Combinada com treinamento de forca.'
).

plano(dieta_ganho_peso_saudavel,
    'Dieta Hipercalorica Saudavel',
    ganho_massa,
    0.84,
    'Aumento calorico com alimentos nutritivos para ganho de peso em pessoas abaixo do peso ideal. Evita calorias vazias e gorduras saturadas.'
).

% ==============================================================
% CATEGORIA: Restricoes Alimentares
% ==============================================================

plano(dieta_vegetariana,
    'Dieta Vegetariana / Vegana',
    restricao_alimentar,
    0.87,
    'Exclusao de carnes (vegetariana) ou de todos os produtos de origem animal (vegana). Requer planejamento cuidadoso para suprir proteinas, B12, ferro e omega-3.'
).

plano(dieta_sem_gluten,
    'Dieta Isenta de Gluten',
    restricao_alimentar,
    0.95,
    'Eliminacao completa de gluten (trigo, cevada, centeio). Obrigatoria para celiacos e recomendada para sensibilidade nao celiaca ao gluten.'
).

% ==============================================================
% CATEGORIA: Manutencao / Bem-estar Geral
% ==============================================================

plano(dieta_equilibrada_manutencao,
    'Dieta Equilibrada para Manutencao do Peso',
    manutencao,
    0.82,
    'Alimentacao balanceada seguindo as proporcoes dos grupos alimentares para manter peso e saude sem restricoes extremas.'
).


% ==============================================================
%
%  SINTOMAS OBRIGATORIOS (condicoes que DEVEM estar presentes)
%
% ==============================================================

% -- Dieta Low-Carb --
criterio_obrigatorio(dieta_low_carb, objetivo_emagrecer).
criterio_obrigatorio(dieta_low_carb, aceita_reducao_carboidratos).

% -- Dieta Hipocalorica --
criterio_obrigatorio(dieta_emagrecimento_moderado, objetivo_emagrecer).
criterio_obrigatorio(dieta_emagrecimento_moderado, sem_restricao_gluten).

% -- Dieta Mediterranea --
criterio_obrigatorio(dieta_mediterranea, objetivo_saude_cardiovascular).
criterio_obrigatorio(dieta_mediterranea, consome_peixe_ou_frutos_mar).

% -- Dieta DASH --
criterio_obrigatorio(dieta_dash, pressao_arterial_alta).

% -- Dieta Diabeticos --
criterio_obrigatorio(dieta_diabeticos, tem_diabetes_tipo2).

% -- Dieta Anti-Inflamatoria --
criterio_obrigatorio(dieta_anti_inflamatoria, tem_condicao_inflamatoria).

% -- Dieta Hiperproteica --
criterio_obrigatorio(dieta_hiperproteica, objetivo_ganho_muscular).
criterio_obrigatorio(dieta_hiperproteica, pratica_musculacao_ou_esporte).

% -- Dieta Ganho de Peso --
criterio_obrigatorio(dieta_ganho_peso_saudavel, objetivo_ganhar_peso).

% -- Dieta Vegetariana --
criterio_obrigatorio(dieta_vegetariana, nao_consome_carne).

% -- Dieta Sem Gluten --
criterio_obrigatorio(dieta_sem_gluten, diagnosticado_celiaco_ou_sensivel_gluten).

% -- Dieta Manutencao --
criterio_obrigatorio(dieta_equilibrada_manutencao, objetivo_manutencao_peso).
criterio_obrigatorio(dieta_equilibrada_manutencao, sem_condicao_medica_especifica).


% ==============================================================
%
%  SINTOMAS OPCIONAIS (aumentam a probabilidade se confirmados)
%
% ==============================================================

% -- Dieta Low-Carb --
criterio_opcional(dieta_low_carb, tem_diabetes_tipo2).
criterio_opcional(dieta_low_carb, nivel_atividade_sedentario_ou_leve).
criterio_opcional(dieta_low_carb, colesterol_alto).
criterio_opcional(dieta_low_carb, ja_tentou_dietas_sem_sucesso).
criterio_opcional(dieta_low_carb, muito_acima_peso).

% -- Dieta Hipocalorica --
criterio_opcional(dieta_emagrecimento_moderado, nivel_atividade_moderada).
criterio_opcional(dieta_emagrecimento_moderado, historico_de_dietas_yo_yo).
criterio_opcional(dieta_emagrecimento_moderado, prefere_variedade_alimentar).
criterio_opcional(dieta_emagrecimento_moderado, sem_condicao_medica_especifica).
criterio_opcional(dieta_emagrecimento_moderado, pouco_acima_peso).

% -- Dieta Mediterranea --
criterio_opcional(dieta_mediterranea, colesterol_alto).
criterio_opcional(dieta_mediterranea, nivel_atividade_moderada).
criterio_opcional(dieta_mediterranea, nao_tem_diabetes_tipo2).
criterio_opcional(dieta_mediterranea, pressao_arterial_normal).
criterio_opcional(dieta_mediterranea, prefere_variedade_alimentar).

% -- Dieta DASH --
criterio_opcional(dieta_dash, colesterol_alto).
criterio_opcional(dieta_dash, objetivo_emagrecer).
criterio_opcional(dieta_dash, consome_muito_sodio_atualmente).
criterio_opcional(dieta_dash, historico_familiar_doenca_cardiaca).
criterio_opcional(dieta_dash, nivel_atividade_sedentario_ou_leve).

% -- Dieta Diabeticos --
criterio_opcional(dieta_diabeticos, objetivo_emagrecer).
criterio_opcional(dieta_diabeticos, nivel_atividade_sedentario_ou_leve).
criterio_opcional(dieta_diabeticos, colesterol_alto).
criterio_opcional(dieta_diabeticos, pressao_arterial_alta).
criterio_opcional(dieta_diabeticos, historico_familiar_diabetes).

% -- Dieta Anti-Inflamatoria --
criterio_opcional(dieta_anti_inflamatoria, consome_peixe_ou_frutos_mar).
criterio_opcional(dieta_anti_inflamatoria, colesterol_alto).
criterio_opcional(dieta_anti_inflamatoria, objetivo_saude_cardiovascular).
criterio_opcional(dieta_anti_inflamatoria, tem_diabetes_tipo2).

% -- Dieta Hiperproteica --
criterio_opcional(dieta_hiperproteica, nivel_atividade_alta).
criterio_opcional(dieta_hiperproteica, nao_tem_problema_renal).
criterio_opcional(dieta_hiperproteica, objetivo_emagrecer).
criterio_opcional(dieta_hiperproteica, consome_carne_e_ovos).

% -- Dieta Ganho de Peso --
criterio_opcional(dieta_ganho_peso_saudavel, pratica_musculacao_ou_esporte).
criterio_opcional(dieta_ganho_peso_saudavel, nivel_atividade_alta).
criterio_opcional(dieta_ganho_peso_saudavel, metabolismo_acelerado_ou_dificuldade_ganho).
criterio_opcional(dieta_ganho_peso_saudavel, objetivo_ganho_muscular).

% -- Dieta Vegetariana --
criterio_opcional(dieta_vegetariana, motivacao_etica_ou_ambiental).
criterio_opcional(dieta_vegetariana, objetivo_saude_cardiovascular).
criterio_opcional(dieta_vegetariana, sem_restricao_gluten).
criterio_opcional(dieta_vegetariana, objetivo_emagrecer).

% -- Dieta Sem Gluten --
criterio_opcional(dieta_sem_gluten, tem_condicao_inflamatoria).
criterio_opcional(dieta_sem_gluten, sintomas_gastrointestinais_cronicos).
criterio_opcional(dieta_sem_gluten, objetivo_saude_geral).

% -- Dieta Manutencao --
criterio_opcional(dieta_equilibrada_manutencao, nivel_atividade_moderada).
criterio_opcional(dieta_equilibrada_manutencao, prefere_variedade_alimentar).
criterio_opcional(dieta_equilibrada_manutencao, sem_restricao_gluten).
criterio_opcional(dieta_equilibrada_manutencao, objetivo_saude_geral).


% ==============================================================
%
%  RECOMENDACOES PRATICAS
%
% ==============================================================

% -- Dieta Low-Carb / Cetogenica --
recomendacao(dieta_low_carb, 1, 'Limite carboidratos a 20-50g por dia (cetogenica) ou 100-150g (low-carb moderada).').
recomendacao(dieta_low_carb, 2, 'Priorize carnes magras, ovos, queijos, abacate, azeite e vegetais nao amilaceos.').
recomendacao(dieta_low_carb, 3, 'Evite: arroz, pao, massas, batata, acucar, refrigerantes e frutas de alto IG.').
recomendacao(dieta_low_carb, 4, 'Monitore glicemia regularmente se for diabetico. Consulte seu medico.').
recomendacao(dieta_low_carb, 5, 'Hidrate-se bem (2.5 a 3L de agua por dia) para evitar a "gripe cetogenica".').

% -- Dieta Hipocalorica Equilibrada --
recomendacao(dieta_emagrecimento_moderado, 1, 'Deficits de 300-500 kcal/dia sao suficientes para perda de peso segura (0,5-1kg/semana).').
recomendacao(dieta_emagrecimento_moderado, 2, 'Mantenha todos os grupos alimentares: proteinas, carboidratos complexos, gorduras saudaveis.').
recomendacao(dieta_emagrecimento_moderado, 3, 'Priorize alimentos integrais, frutas, vegetais e proteinas magras (frango, peixe, leguminosas).').
recomendacao(dieta_emagrecimento_moderado, 4, 'Evite ultraprocessados, acucares adicionados e frituras.').
recomendacao(dieta_emagrecimento_moderado, 5, 'Combine com atividade fisica aerobica pelo menos 150 minutos por semana.').

% -- Dieta Mediterranea --
recomendacao(dieta_mediterranea, 1, 'Base: azeite de oliva extra virgem, frutas, verduras, legumes, graos integrais e leguminosas.').
recomendacao(dieta_mediterranea, 2, 'Consuma peixes e frutos do mar pelo menos 2x por semana.').
recomendacao(dieta_mediterranea, 3, 'Consuma carnes vermelhas com moderacao (max. 1-2x por semana).').
recomendacao(dieta_mediterranea, 4, 'Inclua nozes, amendoas e sementes como lanches saudaveis.').
recomendacao(dieta_mediterranea, 5, 'Prefira iogurte natural e queijos frescos a laticinios industrializados.').

% -- Dieta DASH --
recomendacao(dieta_dash, 1, 'Reduza o sodio para menos de 2300mg/dia (ideal: 1500mg/dia para maior controle).').
recomendacao(dieta_dash, 2, 'Aumente ingestao de potassio: banana, batata-doce, espinafre, feijao.').
recomendacao(dieta_dash, 3, 'Consuma 4-5 porcoes de frutas e vegetais por dia.').
recomendacao(dieta_dash, 4, 'Prefira laticinios desnatados ou com baixo teor de gordura.').
recomendacao(dieta_dash, 5, 'Evite embutidos, enlatados, fast food e alimentos industrializados com alto teor de sodio.').
recomendacao(dieta_dash, 6, 'Monitore a pressao arterial diariamente e siga orientacao medica.').

% -- Dieta para Diabeticos --
recomendacao(dieta_diabeticos, 1, 'Prefira carboidratos de baixo indice glicemico: aveia, quinoa, batata-doce, leguminosas.').
recomendacao(dieta_diabeticos, 2, 'Fracione as refeicoes em 5-6 vezes ao dia para evitar picos glicemicos.').
recomendacao(dieta_diabeticos, 3, 'Evite acucar refinado, sucos industrializados, refrigerantes e doces.').
recomendacao(dieta_diabeticos, 4, 'Inclua fibras em todas as refeicoes (veg., leguminosas, cereais integrais).').
recomendacao(dieta_diabeticos, 5, 'Monitore a glicemia antes e apos as refeicoes para identificar alimentos problematicos.').
recomendacao(dieta_diabeticos, 6, 'Consulte endocrinologista e nutricionista para ajuste do plano alimentar com a medicacao.').

% -- Dieta Anti-Inflamatoria --
recomendacao(dieta_anti_inflamatoria, 1, 'Aumente omega-3: salmao, sardinha, atum, linhaça, chia e nozes.').
recomendacao(dieta_anti_inflamatoria, 2, 'Consuma frutas vermelhas (morango, mirtilo, framboesa) ricas em antioxidantes.').
recomendacao(dieta_anti_inflamatoria, 3, 'Use especiarias anti-inflamatorias: acafrao-da-terra (curcuma), gengibre e canela.').
recomendacao(dieta_anti_inflamatoria, 4, 'Elimine ou reduza drasticamente: acucar, farinha branca, gordura trans e alcool.').
recomendacao(dieta_anti_inflamatoria, 5, 'Prefira azeite de oliva extra virgem como gordura de cozinha.').

% -- Dieta Hiperproteica --
recomendacao(dieta_hiperproteica, 1, 'Consuma 1.6 a 2.2g de proteina por kg de peso corporal por dia.').
recomendacao(dieta_hiperproteica, 2, 'Fontes proteicas recomendadas: frango, ovo, peixe, carne magra, laticinios, leguminosas.').
recomendacao(dieta_hiperproteica, 3, 'Distribua a proteina em 4-6 refeicoes para maximizar a sintese muscular.').
recomendacao(dieta_hiperproteica, 4, 'Mantenha ingestao calorica total adequada ao objetivo (superavit para ganho de massa).').
recomendacao(dieta_hiperproteica, 5, 'Hidrate-se bem: maior ingestao proteica exige mais agua para metabolismo do nitrogenio.').
recomendacao(dieta_hiperproteica, 6, 'Realize exames de funcao renal periodicamente. Evite suplementacao excessiva sem orientacao.').

% -- Dieta Hipercalorica Saudavel --
recomendacao(dieta_ganho_peso_saudavel, 1, 'Adicione 300-500 kcal/dia acima do seu gasto energetico total.').
recomendacao(dieta_ganho_peso_saudavel, 2, 'Priorize calorias de qualidade: avocado, azeite, amendoim, aveia, batata-doce, frango, ovos.').
recomendacao(dieta_ganho_peso_saudavel, 3, 'Faca de 5 a 6 refeicoes por dia para facilitar o consumo calorico total.').
recomendacao(dieta_ganho_peso_saudavel, 4, 'Combine com treino de resistencia para que o ganho de peso seja em massa magra.').
recomendacao(dieta_ganho_peso_saudavel, 5, 'Evite ganho de peso com ultraprocessados e alimentos ricos em gordura saturada.').

% -- Dieta Vegetariana / Vegana --
recomendacao(dieta_vegetariana, 1, 'Planeje cuidadosamente a ingestao de proteinas completas: combine leguminosas + cereais.').
recomendacao(dieta_vegetariana, 2, 'Suplemente vitamina B12, especialmente se for vegano (100-250mcg/dia ou conforme exame).').
recomendacao(dieta_vegetariana, 3, 'Fontes de ferro vegetal: lentilha, feijao, tofu, espinafre. Consuma com vitamina C para melhor absorcao.').
recomendacao(dieta_vegetariana, 4, 'Omega-3: consuma linhaça, chia, nozes. Considere suplementacao de alga (DHA/EPA vegano).').
recomendacao(dieta_vegetariana, 5, 'Realize exames periodicos (B12, ferro, vitamina D, calcio) para monitorar possiveis deficiencias.').

% -- Dieta Sem Gluten --
recomendacao(dieta_sem_gluten, 1, 'Elimine completamente trigo, cevada, centeio e seus derivados (pao, massa, biscoito, cerveja).').
recomendacao(dieta_sem_gluten, 2, 'Substitua por: arroz, milho, quinoa, amaranto, batata, mandioca e aveia certificada sem gluten.').
recomendacao(dieta_sem_gluten, 3, 'Atencao a contaminacao cruzada: utensilios, frigideiras e superficies compartilhados com gluten.').
recomendacao(dieta_sem_gluten, 4, 'Leia sempre os rotulos dos alimentos industrializados (o gluten pode estar em molhos, embutidos, etc.).').
recomendacao(dieta_sem_gluten, 5, 'Acompanhe com gastroenterologista e realize exames periodicos (anticorpos antitransglutaminase).').

% -- Dieta Equilibrada para Manutencao --
recomendacao(dieta_equilibrada_manutencao, 1, 'Siga o modelo do prato saudavel: 50% vegetais, 25% proteinas magras, 25% carboidratos complexos.').
recomendacao(dieta_equilibrada_manutencao, 2, 'Mantenha horarios regulares de refeicao e evite pular refeicoes.').
recomendacao(dieta_equilibrada_manutencao, 3, 'Hidrate-se: pelo menos 35ml de agua por kg de peso corporal por dia.').
recomendacao(dieta_equilibrada_manutencao, 4, 'Pratique atividade fisica regularmente (150-300 min/semana de intensidade moderada).').
recomendacao(dieta_equilibrada_manutencao, 5, 'Realize consulta anual com nutricionista para ajustes conforme mudancas de rotina e exames.').
