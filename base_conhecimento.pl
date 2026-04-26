:- set_prolog_flag(encoding, utf8).

% ==============================================================
%  BASE DE CONHECIMENTO — Sistema Especialista de Dietas
%  Disciplina: Introducao a Inteligencia Artificial — UEM
%
%  Modelo de Probabilidade:
%    Score = min(0.99, ProbBase + soma(pesos dos suportes satisfeitos))
%
%    - ProbBase: probabilidade a priori de cada dieta (0.0-1.0)
%    - Pesos em suporta/4: contribuicao de cada fato do usuario
%    - Teto em 0.99 para evitar certeza absoluta
%    - Convertido para porcentagem inteira na exibicao (round * 100)
% ==============================================================

% DIETAS -------------------------------------------------------
% dieta(Id, NomeExibicao, ProbabilidadeBase).
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

% DESCRICOES ---------------------------------------------------
:- dynamic descricao_dieta/2.

descricao_dieta(low_carb,
    'Reducao de carboidratos priorizando proteinas, vegetais e gorduras saudaveis. Eficaz para perda de peso e controle glicemico.').
descricao_dieta(vegetariana,
    'Baseada em vegetais. Exclui carnes, mas permite laticinios e ovos. Rica em fibras e antioxidantes.').
descricao_dieta(vegana,
    'Estritamente baseada em plantas. Exclui qualquer produto de origem animal, exige suplementacao de B12 e proteina planejada.').
descricao_dieta(mediterranea,
    'Focada em alimentos frescos, azeite, peixes, oleaginosas e graos integrais. Fortemente associada a saude cardiovascular.').
descricao_dieta(hiperproteica,
    'Alta ingestao de proteinas (1.6-2.2g/kg). Focada na manutencao e hipertrofia muscular, ideal para atletas e praticantes de musculacao.').
descricao_dieta(low_fat,
    'Reducao drastica de gorduras totais. Indicada para controle de colesterol e saude cardiovascular em perfis sedentarios a leve.').
descricao_dieta(sem_gluten,
    'Exclusao total de trigo, centeio e cevada. Obrigatoria para celiacos e indicada para sensibilidade nao celiaca ao gluten.').
descricao_dieta(dash,
    'Desenvolvida para reduzir a pressao arterial. Enfatiza potassio, magnesio e restricao severa de sodio.').
descricao_dieta(cetogenica,
    'Altissima ingestao de gorduras e carboidratos quase zerados (< 50g/dia). Induz cetose, potente para perda de peso e controle glicemico tipo 2.').
descricao_dieta(paleolitica,
    'Inspirada na alimentacao pre-agricola: carnes, sementes e raizes. Exclui graos, laticinios e alimentos processados.').
descricao_dieta(flexitariana,
    'Majoritariamente vegetariana, com consumo esporadico e flexivel de carnes. Equilibra saude, sustentabilidade e praticidade.').

% PERGUNTAS ----------------------------------------------------
% pergunta(Atributo, Tipo, TextoPergunta, Opcoes, Justificativa).
%
% Tipo = base                         → sempre exibida
% Tipo = depende(AttrPai, ValEsper)   → exibida so se AttrPai=ValEsper
%
:- dynamic pergunta/5.

% --- Perguntas base -------------------------------------------

pergunta(objetivo, base,
    'Qual e o seu principal objetivo com a dieta?',
    [perda_peso, ganho_massa, saude_geral, controle_cronicas, performance_atletica],
    'O objetivo e a diretriz central que orienta todo o perfil nutricional recomendado.').

pergunta(nivel_atividade, base,
    'Qual e o seu nivel de atividade fisica semanal?',
    [sedentario, leve, moderado, intenso],
    'O nivel de atividade determina a demanda calorica, proteica e a tolerancia a diferentes padroes alimentares.').

pergunta(faixa_etaria, base,
    'Qual e a sua faixa etaria?',
    [jovem, adulto, idoso],
    'A faixa etaria influencia as necessidades nutricionais, especialmente de proteinas, calcio e sodio.').

pergunta(imc_faixa, base,
    'Como voce classificaria seu peso corporal atual?',
    [abaixo_peso, normal, sobrepeso, obesidade],
    'O IMC orienta a intensidade da restricao ou suplementacao calorica necessaria na dieta.').

pergunta(tem_diabetes, base,
    'Voce possui diagnostico de diabetes (qualquer tipo) ou pre-diabetes?',
    [sim, nao],
    'O diabetes exige controle rigoroso do indice glicemico dos alimentos e pode tornar certas dietas mais ou menos adequadas.').

pergunta(tem_hipertensao, base,
    'Voce possui pressao arterial alta (hipertensao) diagnosticada?',
    [sim, nao],
    'A hipertensao indica necessidade de reducao de sodio e aumento de potassio, priorizando dietas com esse perfil.').

pergunta(tem_colesterol_alto, base,
    'Voce possui colesterol total elevado ou LDL alto diagnosticado?',
    [sim, nao],
    'Colesterol elevado orienta a preferencia por dietas com baixo teor de gordura saturada e ricas em fibras e gorduras insaturadas.').

pergunta(tem_problemas_renais, base,
    'Voce possui doenca renal cronica ou insuficiencia renal diagnosticada?',
    [sim, nao],
    'Problemas renais contraindicam dietas com alta carga proteica, pois sobrecarregam os rins.').

pergunta(tem_doenca_cardiaca, base,
    'Voce possui doenca cardiaca diagnosticada (insuficiencia, arritmia, historico de infarto)?',
    [sim, nao],
    'Doencas cardiacas tornam dietas de alto teor de gordura saturada de alto risco e priorizam padroes cardioprotetores.').

pergunta(restricao_carne, base,
    'Voce possui restricao ao consumo de carnes (bovina, frango, peixe)?',
    [sim, nao],
    'A restricao a carne elimina dietas baseadas em proteinas animais e direciona para perfis vegetarianos ou veganos.').

pergunta(alergia_lactose, base,
    'Voce possui intolerancia a lactose ou alergia a proteinas do leite?',
    [sim, nao],
    'A intolerancia a lactose afeta a adequacao de dietas que dependem de laticinios como fonte proteica principal.').

pergunta(restricao_gluten, base,
    'Voce possui doenca celiaca ou sensibilidade ao gluten (confirmada ou suspeita)?',
    [sim, nao],
    'A sensibilidade ao gluten exige adaptacao dietetica especifica independentemente de outras condicoes de saude.').

pergunta(tempo_preparo, base,
    'Como e a sua disponibilidade de tempo para preparar refeicoes?',
    [baixa, media, alta],
    'Dietas com alimentos frescos, integrais e proteinas variadas exigem maior tempo de cozinha e planejamento semanal.').

pergunta(orcamento, base,
    'Como e o seu orcamento mensal para alimentacao?',
    [baixo, flexivel, alto],
    'Algumas dietas exigem ingredientes frescos, organicos ou proteinas de alto valor biologico com custo elevado.').

% --- Perguntas condicionais -----------------------------------

pergunta(frequencia_carne, depende(restricao_carne, nao),
    'Voce consome carne, com qual frequencia semanal?',
    [diariamente, ocasionalmente, raramente],
    'Distingue o perfil flexitariano (consumo esporadico) do onivoro tradicional, influenciando saude e sustentabilidade.').

pergunta(restricao_laticinios, depende(restricao_carne, sim),
    'Ja que voce nao consome carne, possui restricao a laticinios e ovos tambem?',
    [sim, nao],
    'A restricao a laticinios e ovos distingue o perfil vegetariano do vegano, com impacto direto nas fontes proteicas.').

pergunta(disposicao_restricao, depende(objetivo, perda_peso),
    'Para perder peso, voce esta disposto(a) a cortar drasticamente grupos alimentares como carboidratos?',
    [sim, nao],
    'Dietas cetogenica e low carb intenso exigem alta restricao e disciplina; sem essa disposicao, sao contraindicadas.').

pergunta(tipo_diabetes, depende(tem_diabetes, sim),
    'Qual e o tipo do seu diabetes?',
    [tipo_1, tipo_2, pre_diabetes],
    'Tipo 1 exige gestao insulinica precisa; tipo 2 e pre-diabetes respondem bem a restricao de carboidratos e cetose.').

% REGRAS DE SUPORTE --------------------------------------------
% suporta(Dieta, Atributo, Valor, Peso).
%
% Peso: quanto esse fato contribui ao score final da dieta.
% Score = min(0.99, ProbBase + sum(pesos satisfeitos))
:- dynamic suporta/4.

% --- Low Carb -------------------------------------------------
suporta(low_carb, objetivo,            perda_peso,    0.25).
suporta(low_carb, objetivo,            controle_cronicas, 0.10).
suporta(low_carb, tem_diabetes,        sim,           0.15).
suporta(low_carb, tipo_diabetes,       tipo_2,        0.10).
suporta(low_carb, tipo_diabetes,       pre_diabetes,  0.08).
suporta(low_carb, nivel_atividade,     sedentario,    0.05).
suporta(low_carb, nivel_atividade,     leve,          0.05).
suporta(low_carb, imc_faixa,          sobrepeso,     0.08).
suporta(low_carb, imc_faixa,          obesidade,     0.12).
suporta(low_carb, restricao_carne,    nao,           0.05).
suporta(low_carb, disposicao_restricao, sim,         0.08).
suporta(low_carb, tem_colesterol_alto, sim,           0.05).

% --- Vegetariana ----------------------------------------------
suporta(vegetariana, restricao_carne,      sim,             0.30).
suporta(vegetariana, restricao_laticinios, nao,             0.10).
suporta(vegetariana, objetivo,             saude_geral,     0.10).
suporta(vegetariana, tem_colesterol_alto,  sim,             0.08).
suporta(vegetariana, nivel_atividade,      moderado,        0.05).
suporta(vegetariana, alergia_lactose,      nao,             0.05).
suporta(vegetariana, faixa_etaria,         jovem,           0.05).
suporta(vegetariana, faixa_etaria,         adulto,          0.05).
suporta(vegetariana, orcamento,            flexivel,        0.05).

% --- Vegana ---------------------------------------------------
suporta(vegana, restricao_carne,      sim,             0.20).
suporta(vegana, restricao_laticinios, sim,             0.30).
suporta(vegana, alergia_lactose,      sim,             0.10).
suporta(vegana, objetivo,             saude_geral,     0.08).
suporta(vegana, tem_colesterol_alto,  sim,             0.08).
suporta(vegana, faixa_etaria,         jovem,           0.05).

% --- Mediterranea ---------------------------------------------
suporta(mediterranea, objetivo,           saude_geral,        0.15).
suporta(mediterranea, objetivo,           controle_cronicas,  0.12).
suporta(mediterranea, objetivo,           performance_atletica, 0.05).
suporta(mediterranea, restricao_carne,    nao,                0.05).
suporta(mediterranea, tem_colesterol_alto, sim,               0.12).
suporta(mediterranea, tem_hipertensao,    sim,                0.08).
suporta(mediterranea, tem_doenca_cardiaca, sim,               0.12).
suporta(mediterranea, nivel_atividade,    moderado,           0.05).
suporta(mediterranea, nivel_atividade,    intenso,            0.05).
suporta(mediterranea, orcamento,          flexivel,           0.05).
suporta(mediterranea, orcamento,          alto,               0.08).
suporta(mediterranea, faixa_etaria,       idoso,              0.08).
suporta(mediterranea, faixa_etaria,       adulto,             0.05).

% --- Hiperproteica --------------------------------------------
suporta(hiperproteica, objetivo,          ganho_massa,          0.30).
suporta(hiperproteica, objetivo,          performance_atletica, 0.20).
suporta(hiperproteica, nivel_atividade,   intenso,              0.20).
suporta(hiperproteica, nivel_atividade,   moderado,             0.05).
suporta(hiperproteica, restricao_carne,   nao,                  0.08).
suporta(hiperproteica, imc_faixa,         abaixo_peso,          0.08).
suporta(hiperproteica, imc_faixa,         normal,               0.05).
suporta(hiperproteica, faixa_etaria,      jovem,                0.08).
suporta(hiperproteica, faixa_etaria,      adulto,               0.05).
suporta(hiperproteica, frequencia_carne,  diariamente,          0.05).

% --- Low Fat --------------------------------------------------
suporta(low_fat, objetivo,           perda_peso,      0.10).
suporta(low_fat, objetivo,           saude_geral,     0.10).
suporta(low_fat, objetivo,           controle_cronicas, 0.08).
suporta(low_fat, tem_colesterol_alto, sim,            0.20).
suporta(low_fat, tem_hipertensao,    sim,             0.10).
suporta(low_fat, tem_doenca_cardiaca, sim,            0.15).
suporta(low_fat, nivel_atividade,    sedentario,      0.05).
suporta(low_fat, nivel_atividade,    leve,            0.05).
suporta(low_fat, faixa_etaria,       idoso,           0.10).
suporta(low_fat, imc_faixa,          sobrepeso,       0.05).
suporta(low_fat, imc_faixa,          obesidade,       0.08).

% --- Sem Gluten -----------------------------------------------
suporta(sem_gluten, restricao_gluten, sim,         0.50).
suporta(sem_gluten, objetivo,         saude_geral, 0.05).

% --- DASH -----------------------------------------------------
suporta(dash, tem_hipertensao,     sim,               0.30).
suporta(dash, objetivo,            controle_cronicas, 0.20).
suporta(dash, objetivo,            saude_geral,       0.08).
suporta(dash, restricao_carne,     nao,               0.05).
suporta(dash, tem_colesterol_alto, sim,               0.10).
suporta(dash, tem_doenca_cardiaca, sim,               0.12).
suporta(dash, faixa_etaria,        idoso,             0.10).
suporta(dash, faixa_etaria,        adulto,            0.05).
suporta(dash, nivel_atividade,     sedentario,        0.05).
suporta(dash, nivel_atividade,     leve,              0.05).
suporta(dash, orcamento,           flexivel,          0.05).

% --- Cetogenica -----------------------------------------------
suporta(cetogenica, objetivo,             perda_peso,    0.15).
suporta(cetogenica, tem_diabetes,         sim,           0.15).
suporta(cetogenica, tipo_diabetes,        tipo_2,        0.15).
suporta(cetogenica, tipo_diabetes,        pre_diabetes,  0.10).
suporta(cetogenica, disposicao_restricao, sim,           0.28).
suporta(cetogenica, orcamento,            alto,          0.08).
suporta(cetogenica, imc_faixa,           obesidade,     0.12).
suporta(cetogenica, nivel_atividade,      sedentario,    0.05).

% --- Paleolitica ----------------------------------------------
suporta(paleolitica, objetivo,          saude_geral,          0.15).
suporta(paleolitica, objetivo,          performance_atletica, 0.12).
suporta(paleolitica, restricao_gluten,  sim,                  0.15).
suporta(paleolitica, orcamento,         alto,                 0.10).
suporta(paleolitica, orcamento,         flexivel,             0.05).
suporta(paleolitica, nivel_atividade,   intenso,              0.10).
suporta(paleolitica, nivel_atividade,   moderado,             0.05).
suporta(paleolitica, restricao_carne,   nao,                  0.05).
suporta(paleolitica, faixa_etaria,      jovem,                0.08).
suporta(paleolitica, faixa_etaria,      adulto,               0.05).

% --- Flexitariana ---------------------------------------------
suporta(flexitariana, restricao_carne,    nao,            0.05).
suporta(flexitariana, frequencia_carne,   ocasionalmente, 0.25).
suporta(flexitariana, frequencia_carne,   raramente,      0.30).
suporta(flexitariana, objetivo,           saude_geral,    0.12).
suporta(flexitariana, objetivo,           controle_cronicas, 0.08).
suporta(flexitariana, faixa_etaria,       jovem,          0.05).
suporta(flexitariana, faixa_etaria,       adulto,         0.05).
suporta(flexitariana, nivel_atividade,    moderado,       0.05).
suporta(flexitariana, tem_colesterol_alto, sim,           0.05).
suporta(flexitariana, orcamento,          flexivel,       0.05).
suporta(flexitariana, orcamento,          baixo,          0.05).

% REGRAS DE EXCLUSAO -------------------------------------------
% exclui(Dieta, Atributo, Valor).
%
% Condicao que torna a dieta INCOMPATIVEL com o perfil do usuario.
% Dietas excluidas sao removidas do resultado antes da exibicao.
:- dynamic exclui/3.

% Vegetariano nao pode seguir dieta hiperproteica baseada em carne
exclui(hiperproteica, restricao_carne, sim).

% Doenca renal contraindicada em dietas de alta proteina (sobrecarga glomerular)
exclui(hiperproteica, tem_problemas_renais, sim).

% Quem nao restringe laticinios nao deve seguir dieta vegana pura
% (vegana exige restricao total de produtos animais, incluindo laticinios)
exclui(vegetariana, restricao_laticinios, sim).

% Quem nao aceita cortar carboidratos nao pode seguir a cetogenica
exclui(cetogenica, disposicao_restricao, nao).

% Colesterol alto: cetogenica contraindicada (alto consumo de gorduras saturadas)
exclui(cetogenica, tem_colesterol_alto, sim).

% Doenca cardiaca: cetogenica contraindicada (risco cardiovascular do alto teor de gordura)
exclui(cetogenica, tem_doenca_cardiaca, sim).

% Baixo tempo de preparo: mediterranea exige frescor e variedade diaria
exclui(mediterranea, tempo_preparo, baixa).

% Orcamento baixo: mediterranea exige azeite, peixes e oleaginosas de custo elevado
exclui(mediterranea, orcamento, baixo).

% Baixo tempo de preparo: vegana exige planejamento rigido de proteinas e micronutrientes
exclui(vegana, tempo_preparo, baixa).

% Baixo tempo de preparo: paleolitica exige preparo integral de tudo
exclui(paleolitica, tempo_preparo, baixa).

% Orcamento baixo: paleolitica exige carnes, sementes e alimentos organicos de custo alto
exclui(paleolitica, orcamento, baixo).

% Objetivo ganho de massa: low fat impossibilita superavit calorico limpo
exclui(low_fat, objetivo, ganho_massa).

% Objetivo ganho de massa: sem_gluten sozinha nao atende demanda proteica de ganho
exclui(sem_gluten, objetivo, ganho_massa).

% Doenca cardiaca: low fat e a preferencia; cetogenica ja esta excluida acima
% Problemas renais: excluir tambem dieta paleolitica (alta proteina animal)
exclui(paleolitica, tem_problemas_renais, sim).

% Diabetes tipo 1: cetogenica de alto risco sem supervisao medica intensiva
exclui(cetogenica, tipo_diabetes, tipo_1).

% Idoso sedentario nao deve seguir hiperproteica sem supervisao (excesso pode lesar rins)
% (retirado — excessivamente restritivo para um sistema generico)

% Orcamento baixo: mediterranea ja excluida acima; adicionar paleolitica acima
