:- set_prolog_flag(encoding, utf8).

% ==============================================================================
% BASE DE CONHECIMENTO - Sistema Especialista de Dietas
% Modelo LPO: Individuos + relacoes
%
% Inferencia probabilistica (heuristica):
%   Score = min(0.99, ProbBase + soma(evidencias satisfeitas))
%
% Regras clinicas fundamentais:
%   contraindicada/2 e estritamente booleana (verdadeiro/falso)
% ==============================================================================

% ENTIDADES ---------------------------------------------------------------------

:- dynamic dieta/3.
:- dynamic descricao_dieta/2.
:- dynamic pergunta/5.
:- dynamic paciente/1.

% PERFIL DO INDIVIDUO -----------------------------------------------------------

:- dynamic tem_objetivo/2.
:- dynamic tem_nivel_atividade/2.
:- dynamic tem_faixa_etaria/2.
:- dynamic tem_imc_faixa/2.
:- dynamic tem_tempo_preparo/2.
:- dynamic tem_orcamento/2.
:- dynamic tem_tipo_diabetes/2.
:- dynamic tem_frequencia_carne/2.
:- dynamic tem_disposicao_restricao/2.

:- dynamic tem_doenca/2.
:- dynamic nao_tem_doenca/2.
:- dynamic tem_restricao/2.
:- dynamic nao_tem_restricao/2.

:- dynamic evidencia/3.
:- dynamic contraindicada/2.

paciente(usuario_atual).

% DIETAS ------------------------------------------------------------------------
% dieta(Id, NomeExibicao, ProbabilidadeBase).

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

% DESCRICOES --------------------------------------------------------------------

descricao_dieta(low_carb, 'Reducao de carboidratos priorizando proteinas, vegetais e gorduras saudaveis. Eficaz para perda de peso e controle glicemico.').
descricao_dieta(vegetariana, 'Baseada em vegetais. Exclui carnes, mas permite laticinios e ovos. Rica em fibras e antioxidantes.').
descricao_dieta(vegana, 'Estritamente baseada em plantas. Exclui qualquer produto de origem animal, exige suplementacao de B12 e proteina planejada.').
descricao_dieta(mediterranea, 'Focada em alimentos frescos, azeite, peixes, oleaginosas e graos integrais. Fortemente associada a saude cardiovascular.').
descricao_dieta(hiperproteica, 'Alta ingestao de proteinas (1.6-2.2g/kg). Focada na manutencao e hipertrofia muscular, ideal para atletas e praticantes de musculacao.').
descricao_dieta(low_fat, 'Reducao drastica de gorduras totais. Indicada para controle de colesterol e saude cardiovascular em perfis sedentarios a leve.').
descricao_dieta(sem_gluten, 'Exclusao total de trigo, centeio e cevada. Obrigatoria para celiacos e indicada para sensibilidade nao celiaca ao gluten.').
descricao_dieta(dash, 'Desenvolvida para reduzir a pressao arterial. Enfatiza potassio, magnesio e restricao severa de sodio.').
descricao_dieta(cetogenica, 'Altissima ingestao de gorduras e carboidratos quase zerados (< 50g/dia). Induz cetose, potente para perda de peso e controle glicemico tipo 2.').
descricao_dieta(paleolitica, 'Inspirada na alimentacao pre-agricola: carnes, sementes e raizes. Exclui graos, laticinios e alimentos processados.').
descricao_dieta(flexitariana, 'Majoritariamente vegetariana, com consumo esporadico e flexivel de carnes. Equilibra saude, sustentabilidade e praticidade.').

% PERGUNTAS ---------------------------------------------------------------------
% pergunta(Atributo, Tipo, Texto, Opcoes, Justificativa).
% Tipo = base | depende(AttrPai, ValEsperado)

pergunta(objetivo, base,
    'Qual e o seu principal objetivo com a dieta?',
    [perda_peso, ganho_massa, saude_geral, controle_cronicas, performance_atletica],
    'O objetivo orienta o perfil nutricional recomendado.').

pergunta(nivel_atividade, base,
    'Qual e o seu nivel de atividade fisica semanal?',
    [sedentario, leve, moderado, intenso],
    'O nivel de atividade altera demanda calorica e proteica.').

pergunta(faixa_etaria, base,
    'Qual e a sua faixa etaria?',
    [jovem, adulto, idoso],
    'A faixa etaria afeta necessidades nutricionais e seguranca clinica.').

pergunta(imc_faixa, base,
    'Como voce classificaria seu peso corporal atual?',
    [abaixo_peso, normal, sobrepeso, obesidade],
    'O IMC orienta a intensidade de ajuste energetico da dieta.').

pergunta(tem_diabetes, base,
    'Voce possui diabetes ou pre-diabetes?',
    [sim, nao],
    'Diabetes exige controle de glicemia e carboidratos.').

pergunta(tem_hipertensao, base,
    'Voce possui hipertensao diagnosticada?',
    [sim, nao],
    'Hipertensao prioriza dietas com controle de sodio e perfil cardioprotetor.').

pergunta(tem_colesterol_alto, base,
    'Voce possui colesterol elevado?',
    [sim, nao],
    'Colesterol elevado favorece padroes com menor gordura saturada.').

pergunta(tem_problemas_renais, base,
    'Voce possui doenca renal cronica ou insuficiencia renal?',
    [sim, nao],
    'Doenca renal restringe dietas com alta carga proteica.').

pergunta(tem_doenca_cardiaca, base,
    'Voce possui doenca cardiaca diagnosticada?',
    [sim, nao],
    'Doenca cardiaca restringe dietas de alto risco cardiovascular.').

pergunta(restricao_carne, base,
    'Voce possui restricao ao consumo de carnes?',
    [sim, nao],
    'Restricao de carne direciona para perfis vegetarianos ou veganos.').

pergunta(alergia_lactose, base,
    'Voce possui intolerancia a lactose ou alergia a proteina do leite?',
    [sim, nao],
    'A restricao a lactose altera fontes proteicas e planejamento alimentar.').

pergunta(restricao_gluten, base,
    'Voce possui doenca celiaca ou sensibilidade ao gluten?',
    [sim, nao],
    'A restricao ao gluten exige adaptacoes especificas.').

pergunta(tempo_preparo, base,
    'Como e sua disponibilidade de tempo para preparar refeicoes?',
    [baixa, media, alta],
    'Algumas dietas exigem maior preparo e planejamento.').

pergunta(orcamento, base,
    'Como e seu orcamento mensal para alimentacao?',
    [baixo, flexivel, alto],
    'O custo de ingredientes pode inviabilizar certos padroes alimentares.').

pergunta(frequencia_carne, depende(restricao_carne, nao),
    'Voce consome carne com qual frequencia semanal?',
    [diariamente, ocasionalmente, raramente],
    'Distingue perfis onivoros e flexitarianos.').

pergunta(restricao_laticinios, depende(restricao_carne, sim),
    'Ja que voce nao consome carne, tambem restringe laticinios e ovos?',
    [sim, nao],
    'Distingue perfil vegetariano de vegano.').

pergunta(disposicao_restricao, depende(objetivo, perda_peso),
    'Para perder peso, voce aceita cortar grupos alimentares de forma intensa?',
    [sim, nao],
    'Dietas muito restritivas exigem alta adesao.').

pergunta(tipo_diabetes, depende(tem_diabetes, sim),
    'Qual e o tipo do seu diabetes?',
    [tipo_1, tipo_2, pre_diabetes],
    'Tipo clinico altera seguranca e conduta nutricional.').

% MAPEAMENTO DE RESPOSTAS -------------------------------------------------------
% resposta_usuario(+Individuo, +Atributo, ?Valor)

resposta_usuario(X, objetivo, Valor)            :- tem_objetivo(X, Valor).
resposta_usuario(X, nivel_atividade, Valor)     :- tem_nivel_atividade(X, Valor).
resposta_usuario(X, faixa_etaria, Valor)        :- tem_faixa_etaria(X, Valor).
resposta_usuario(X, imc_faixa, Valor)           :- tem_imc_faixa(X, Valor).
resposta_usuario(X, tempo_preparo, Valor)       :- tem_tempo_preparo(X, Valor).
resposta_usuario(X, orcamento, Valor)           :- tem_orcamento(X, Valor).
resposta_usuario(X, tipo_diabetes, Valor)       :- tem_tipo_diabetes(X, Valor).
resposta_usuario(X, frequencia_carne, Valor)    :- tem_frequencia_carne(X, Valor).
resposta_usuario(X, disposicao_restricao, Valor):- tem_disposicao_restricao(X, Valor).

resposta_usuario(X, tem_diabetes, sim)          :- tem_doenca(X, diabetes).
resposta_usuario(X, tem_diabetes, nao)          :- nao_tem_doenca(X, diabetes).
resposta_usuario(X, tem_hipertensao, sim)       :- tem_doenca(X, hipertensao).
resposta_usuario(X, tem_hipertensao, nao)       :- nao_tem_doenca(X, hipertensao).
resposta_usuario(X, tem_colesterol_alto, sim)   :- tem_doenca(X, colesterol_alto).
resposta_usuario(X, tem_colesterol_alto, nao)   :- nao_tem_doenca(X, colesterol_alto).
resposta_usuario(X, tem_problemas_renais, sim)  :- tem_doenca(X, problemas_renais).
resposta_usuario(X, tem_problemas_renais, nao)  :- nao_tem_doenca(X, problemas_renais).
resposta_usuario(X, tem_doenca_cardiaca, sim)   :- tem_doenca(X, doenca_cardiaca).
resposta_usuario(X, tem_doenca_cardiaca, nao)   :- nao_tem_doenca(X, doenca_cardiaca).

resposta_usuario(X, restricao_carne, sim)       :- tem_restricao(X, carne).
resposta_usuario(X, restricao_carne, nao)       :- nao_tem_restricao(X, carne).
resposta_usuario(X, alergia_lactose, sim)       :- tem_restricao(X, lactose).
resposta_usuario(X, alergia_lactose, nao)       :- nao_tem_restricao(X, lactose).
resposta_usuario(X, restricao_gluten, sim)      :- tem_restricao(X, gluten).
resposta_usuario(X, restricao_gluten, nao)      :- nao_tem_restricao(X, gluten).
resposta_usuario(X, restricao_laticinios, sim)  :- tem_restricao(X, laticinios).
resposta_usuario(X, restricao_laticinios, nao)  :- nao_tem_restricao(X, laticinios).

% REGISTRO DE RESPOSTA ----------------------------------------------------------
% registrar_resposta(+Individuo, +Atributo, +Valor)

registrar_resposta(X, objetivo, Valor) :-
    retractall(tem_objetivo(X, _)),
    assertz(tem_objetivo(X, Valor)).
registrar_resposta(X, nivel_atividade, Valor) :-
    retractall(tem_nivel_atividade(X, _)),
    assertz(tem_nivel_atividade(X, Valor)).
registrar_resposta(X, faixa_etaria, Valor) :-
    retractall(tem_faixa_etaria(X, _)),
    assertz(tem_faixa_etaria(X, Valor)).
registrar_resposta(X, imc_faixa, Valor) :-
    retractall(tem_imc_faixa(X, _)),
    assertz(tem_imc_faixa(X, Valor)).
registrar_resposta(X, tempo_preparo, Valor) :-
    retractall(tem_tempo_preparo(X, _)),
    assertz(tem_tempo_preparo(X, Valor)).
registrar_resposta(X, orcamento, Valor) :-
    retractall(tem_orcamento(X, _)),
    assertz(tem_orcamento(X, Valor)).
registrar_resposta(X, tipo_diabetes, Valor) :-
    retractall(tem_tipo_diabetes(X, _)),
    assertz(tem_tipo_diabetes(X, Valor)).
registrar_resposta(X, frequencia_carne, Valor) :-
    retractall(tem_frequencia_carne(X, _)),
    assertz(tem_frequencia_carne(X, Valor)).
registrar_resposta(X, disposicao_restricao, Valor) :-
    retractall(tem_disposicao_restricao(X, _)),
    assertz(tem_disposicao_restricao(X, Valor)).

registrar_resposta(X, tem_diabetes, sim) :-
    retractall(tem_doenca(X, diabetes)),
    retractall(nao_tem_doenca(X, diabetes)),
    assertz(tem_doenca(X, diabetes)).
registrar_resposta(X, tem_diabetes, nao) :-
    retractall(tem_doenca(X, diabetes)),
    retractall(nao_tem_doenca(X, diabetes)),
    retractall(tem_tipo_diabetes(X, _)),
    assertz(nao_tem_doenca(X, diabetes)).

registrar_resposta(X, tem_hipertensao, sim) :-
    retractall(tem_doenca(X, hipertensao)),
    retractall(nao_tem_doenca(X, hipertensao)),
    assertz(tem_doenca(X, hipertensao)).
registrar_resposta(X, tem_hipertensao, nao) :-
    retractall(tem_doenca(X, hipertensao)),
    retractall(nao_tem_doenca(X, hipertensao)),
    assertz(nao_tem_doenca(X, hipertensao)).

registrar_resposta(X, tem_colesterol_alto, sim) :-
    retractall(tem_doenca(X, colesterol_alto)),
    retractall(nao_tem_doenca(X, colesterol_alto)),
    assertz(tem_doenca(X, colesterol_alto)).
registrar_resposta(X, tem_colesterol_alto, nao) :-
    retractall(tem_doenca(X, colesterol_alto)),
    retractall(nao_tem_doenca(X, colesterol_alto)),
    assertz(nao_tem_doenca(X, colesterol_alto)).

registrar_resposta(X, tem_problemas_renais, sim) :-
    retractall(tem_doenca(X, problemas_renais)),
    retractall(nao_tem_doenca(X, problemas_renais)),
    assertz(tem_doenca(X, problemas_renais)).
registrar_resposta(X, tem_problemas_renais, nao) :-
    retractall(tem_doenca(X, problemas_renais)),
    retractall(nao_tem_doenca(X, problemas_renais)),
    assertz(nao_tem_doenca(X, problemas_renais)).

registrar_resposta(X, tem_doenca_cardiaca, sim) :-
    retractall(tem_doenca(X, doenca_cardiaca)),
    retractall(nao_tem_doenca(X, doenca_cardiaca)),
    assertz(tem_doenca(X, doenca_cardiaca)).

registrar_resposta(X, tem_doenca_cardiaca, nao) :-
    retractall(tem_doenca(X, doenca_cardiaca)),
    retractall(nao_tem_doenca(X, doenca_cardiaca)),
    assertz(nao_tem_doenca(X, doenca_cardiaca)).

registrar_resposta(X, restricao_carne, sim) :-
    retractall(tem_restricao(X, carne)),
    retractall(nao_tem_restricao(X, carne)),
    assertz(tem_restricao(X, carne)).
registrar_resposta(X, restricao_carne, nao) :-
    retractall(tem_restricao(X, carne)),
    retractall(nao_tem_restricao(X, carne)),
    retractall(tem_frequencia_carne(X, _)),
    assertz(nao_tem_restricao(X, carne)).

registrar_resposta(X, alergia_lactose, sim) :-
    retractall(tem_restricao(X, lactose)),
    retractall(nao_tem_restricao(X, lactose)),
    assertz(tem_restricao(X, lactose)).
registrar_resposta(X, alergia_lactose, nao) :-
    retractall(tem_restricao(X, lactose)),
    retractall(nao_tem_restricao(X, lactose)),
    assertz(nao_tem_restricao(X, lactose)).

registrar_resposta(X, restricao_gluten, sim) :-
    retractall(tem_restricao(X, gluten)),
    retractall(nao_tem_restricao(X, gluten)),
    assertz(tem_restricao(X, gluten)).
registrar_resposta(X, restricao_gluten, nao) :-
    retractall(tem_restricao(X, gluten)),
    retractall(nao_tem_restricao(X, gluten)),
    assertz(nao_tem_restricao(X, gluten)).

registrar_resposta(X, restricao_laticinios, sim) :-
    retractall(tem_restricao(X, laticinios)),
    retractall(nao_tem_restricao(X, laticinios)),
    assertz(tem_restricao(X, laticinios)).
registrar_resposta(X, restricao_laticinios, nao) :-
    retractall(tem_restricao(X, laticinios)),
    retractall(nao_tem_restricao(X, laticinios)),
    assertz(nao_tem_restricao(X, laticinios)).

% LIMPEZA DE PERFIL --------------------------------------------------------------

limpar_respostas(X) :-
    retractall(tem_objetivo(X, _)),
    retractall(tem_nivel_atividade(X, _)),
    retractall(tem_faixa_etaria(X, _)),
    retractall(tem_imc_faixa(X, _)),
    retractall(tem_tempo_preparo(X, _)),
    retractall(tem_orcamento(X, _)),
    retractall(tem_tipo_diabetes(X, _)),
    retractall(tem_frequencia_carne(X, _)),
    retractall(tem_disposicao_restricao(X, _)),
    retractall(tem_doenca(X, _)),
    retractall(nao_tem_doenca(X, _)),
    retractall(tem_restricao(X, _)),
    retractall(nao_tem_restricao(X, _)).

% EVIDENCIAS HEURISTICAS ---------------------------------------------------------
% evidencia(Dieta, X, Peso) :- Condicao(X, Valor).

evidencia(low_carb, X, 0.25) :- tem_objetivo(X, perda_peso).
evidencia(low_carb, X, 0.10) :- tem_objetivo(X, controle_cronicas).
evidencia(low_carb, X, 0.15) :- tem_doenca(X, diabetes).
evidencia(low_carb, X, 0.10) :- tem_tipo_diabetes(X, tipo_2).
evidencia(low_carb, X, 0.08) :- tem_tipo_diabetes(X, pre_diabetes).
evidencia(low_carb, X, 0.05) :- tem_nivel_atividade(X, sedentario).
evidencia(low_carb, X, 0.05) :- tem_nivel_atividade(X, leve).
evidencia(low_carb, X, 0.08) :- tem_imc_faixa(X, sobrepeso).
evidencia(low_carb, X, 0.12) :- tem_imc_faixa(X, obesidade).
evidencia(low_carb, X, 0.05) :- nao_tem_restricao(X, carne).
evidencia(low_carb, X, 0.08) :- tem_disposicao_restricao(X, sim).
evidencia(low_carb, X, 0.05) :- tem_doenca(X, colesterol_alto).

evidencia(vegetariana, X, 0.30) :- tem_restricao(X, carne).
evidencia(vegetariana, X, 0.10) :- nao_tem_restricao(X, laticinios).
evidencia(vegetariana, X, 0.10) :- tem_objetivo(X, saude_geral).
evidencia(vegetariana, X, 0.08) :- tem_doenca(X, colesterol_alto).
evidencia(vegetariana, X, 0.05) :- tem_nivel_atividade(X, moderado).
evidencia(vegetariana, X, 0.05) :- nao_tem_restricao(X, lactose).
evidencia(vegetariana, X, 0.05) :- tem_faixa_etaria(X, jovem).
evidencia(vegetariana, X, 0.05) :- tem_faixa_etaria(X, adulto).
evidencia(vegetariana, X, 0.05) :- tem_orcamento(X, flexivel).

evidencia(vegana, X, 0.20) :- tem_restricao(X, carne).
evidencia(vegana, X, 0.30) :- tem_restricao(X, laticinios).
evidencia(vegana, X, 0.10) :- tem_restricao(X, lactose).
evidencia(vegana, X, 0.08) :- tem_objetivo(X, saude_geral).
evidencia(vegana, X, 0.08) :- tem_doenca(X, colesterol_alto).
evidencia(vegana, X, 0.05) :- tem_faixa_etaria(X, jovem).

evidencia(mediterranea, X, 0.15) :- tem_objetivo(X, saude_geral).
evidencia(mediterranea, X, 0.12) :- tem_objetivo(X, controle_cronicas).
evidencia(mediterranea, X, 0.05) :- tem_objetivo(X, performance_atletica).
evidencia(mediterranea, X, 0.05) :- nao_tem_restricao(X, carne).
evidencia(mediterranea, X, 0.12) :- tem_doenca(X, colesterol_alto).
evidencia(mediterranea, X, 0.08) :- tem_doenca(X, hipertensao).
evidencia(mediterranea, X, 0.12) :- tem_doenca(X, doenca_cardiaca).
evidencia(mediterranea, X, 0.05) :- tem_nivel_atividade(X, moderado).
evidencia(mediterranea, X, 0.05) :- tem_nivel_atividade(X, intenso).
evidencia(mediterranea, X, 0.05) :- tem_orcamento(X, flexivel).
evidencia(mediterranea, X, 0.08) :- tem_orcamento(X, alto).
evidencia(mediterranea, X, 0.08) :- tem_faixa_etaria(X, idoso).
evidencia(mediterranea, X, 0.05) :- tem_faixa_etaria(X, adulto).

evidencia(hiperproteica, X, 0.30) :- tem_objetivo(X, ganho_massa).
evidencia(hiperproteica, X, 0.20) :- tem_objetivo(X, performance_atletica).
evidencia(hiperproteica, X, 0.20) :- tem_nivel_atividade(X, intenso).
evidencia(hiperproteica, X, 0.05) :- tem_nivel_atividade(X, moderado).
evidencia(hiperproteica, X, 0.08) :- nao_tem_restricao(X, carne).
evidencia(hiperproteica, X, 0.08) :- tem_imc_faixa(X, abaixo_peso).
evidencia(hiperproteica, X, 0.05) :- tem_imc_faixa(X, normal).
evidencia(hiperproteica, X, 0.08) :- tem_faixa_etaria(X, jovem).
evidencia(hiperproteica, X, 0.05) :- tem_faixa_etaria(X, adulto).
evidencia(hiperproteica, X, 0.05) :- tem_frequencia_carne(X, diariamente).

evidencia(low_fat, X, 0.10) :- tem_objetivo(X, perda_peso).
evidencia(low_fat, X, 0.10) :- tem_objetivo(X, saude_geral).
evidencia(low_fat, X, 0.08) :- tem_objetivo(X, controle_cronicas).
evidencia(low_fat, X, 0.20) :- tem_doenca(X, colesterol_alto).
evidencia(low_fat, X, 0.10) :- tem_doenca(X, hipertensao).
evidencia(low_fat, X, 0.15) :- tem_doenca(X, doenca_cardiaca).
evidencia(low_fat, X, 0.05) :- tem_nivel_atividade(X, sedentario).
evidencia(low_fat, X, 0.05) :- tem_nivel_atividade(X, leve).
evidencia(low_fat, X, 0.10) :- tem_faixa_etaria(X, idoso).
evidencia(low_fat, X, 0.05) :- tem_imc_faixa(X, sobrepeso).
evidencia(low_fat, X, 0.08) :- tem_imc_faixa(X, obesidade).

evidencia(sem_gluten, X, 0.50) :- tem_restricao(X, gluten).
evidencia(sem_gluten, X, 0.05) :- tem_objetivo(X, saude_geral).

evidencia(dash, X, 0.30) :- tem_doenca(X, hipertensao).
evidencia(dash, X, 0.20) :- tem_objetivo(X, controle_cronicas).
evidencia(dash, X, 0.08) :- tem_objetivo(X, saude_geral).
evidencia(dash, X, 0.05) :- nao_tem_restricao(X, carne).
evidencia(dash, X, 0.10) :- tem_doenca(X, colesterol_alto).
evidencia(dash, X, 0.12) :- tem_doenca(X, doenca_cardiaca).
evidencia(dash, X, 0.10) :- tem_faixa_etaria(X, idoso).
evidencia(dash, X, 0.05) :- tem_faixa_etaria(X, adulto).
evidencia(dash, X, 0.05) :- tem_nivel_atividade(X, sedentario).
evidencia(dash, X, 0.05) :- tem_nivel_atividade(X, leve).
evidencia(dash, X, 0.05) :- tem_orcamento(X, flexivel).

evidencia(cetogenica, X, 0.15) :- tem_objetivo(X, perda_peso).
evidencia(cetogenica, X, 0.15) :- tem_doenca(X, diabetes).
evidencia(cetogenica, X, 0.15) :- tem_tipo_diabetes(X, tipo_2).
evidencia(cetogenica, X, 0.10) :- tem_tipo_diabetes(X, pre_diabetes).
evidencia(cetogenica, X, 0.28) :- tem_disposicao_restricao(X, sim).
evidencia(cetogenica, X, 0.08) :- tem_orcamento(X, alto).
evidencia(cetogenica, X, 0.12) :- tem_imc_faixa(X, obesidade).
evidencia(cetogenica, X, 0.05) :- tem_nivel_atividade(X, sedentario).

evidencia(paleolitica, X, 0.15) :- tem_objetivo(X, saude_geral).
evidencia(paleolitica, X, 0.12) :- tem_objetivo(X, performance_atletica).
evidencia(paleolitica, X, 0.15) :- tem_restricao(X, gluten).
evidencia(paleolitica, X, 0.10) :- tem_orcamento(X, alto).
evidencia(paleolitica, X, 0.05) :- tem_orcamento(X, flexivel).
evidencia(paleolitica, X, 0.10) :- tem_nivel_atividade(X, intenso).
evidencia(paleolitica, X, 0.05) :- tem_nivel_atividade(X, moderado).
evidencia(paleolitica, X, 0.05) :- nao_tem_restricao(X, carne).
evidencia(paleolitica, X, 0.08) :- tem_faixa_etaria(X, jovem).
evidencia(paleolitica, X, 0.05) :- tem_faixa_etaria(X, adulto).

evidencia(flexitariana, X, 0.05) :- nao_tem_restricao(X, carne).
evidencia(flexitariana, X, 0.25) :- tem_frequencia_carne(X, ocasionalmente).
evidencia(flexitariana, X, 0.30) :- tem_frequencia_carne(X, raramente).
evidencia(flexitariana, X, 0.12) :- tem_objetivo(X, saude_geral).
evidencia(flexitariana, X, 0.08) :- tem_objetivo(X, controle_cronicas).
evidencia(flexitariana, X, 0.05) :- tem_faixa_etaria(X, jovem).
evidencia(flexitariana, X, 0.05) :- tem_faixa_etaria(X, adulto).
evidencia(flexitariana, X, 0.05) :- tem_nivel_atividade(X, moderado).
evidencia(flexitariana, X, 0.05) :- tem_doenca(X, colesterol_alto).
evidencia(flexitariana, X, 0.05) :- tem_orcamento(X, flexivel).
evidencia(flexitariana, X, 0.05) :- tem_orcamento(X, baixo).

% CONTRAINDICACOES ESTRITAS -----------------------------------------------------
% contraindicada(Dieta, X) :- Condicao(X, Valor).

contraindicada(hiperproteica, X) :- tem_restricao(X, carne).
contraindicada(hiperproteica, X) :- tem_doenca(X, problemas_renais).
contraindicada(vegetariana, X)   :- tem_restricao(X, laticinios).
contraindicada(cetogenica, X)    :- tem_disposicao_restricao(X, nao).
contraindicada(cetogenica, X)    :- tem_doenca(X, colesterol_alto).
contraindicada(cetogenica, X)    :- tem_doenca(X, doenca_cardiaca).
contraindicada(mediterranea, X)  :- tem_tempo_preparo(X, baixa).
contraindicada(mediterranea, X)  :- tem_orcamento(X, baixo).
contraindicada(vegana, X)        :- tem_tempo_preparo(X, baixa).
contraindicada(paleolitica, X)   :- tem_tempo_preparo(X, baixa).
contraindicada(paleolitica, X)   :- tem_orcamento(X, baixo).
contraindicada(low_fat, X)       :- tem_objetivo(X, ganho_massa).
contraindicada(sem_gluten, X)    :- tem_objetivo(X, ganho_massa).
contraindicada(paleolitica, X)   :- tem_doenca(X, problemas_renais).
contraindicada(cetogenica, X)    :- tem_tipo_diabetes(X, tipo_1).
