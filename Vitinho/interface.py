import sys
import re
from pathlib import Path
from pyswip import Prolog

def safe_str(valor):
    """Converte valores retornados pelo pyswip (bytes ou str) para string Python."""
    if isinstance(valor, bytes):
        return valor.decode('utf-8', errors='ignore')
    return str(valor)

class SistemaEspecialistaDietas:
    def __init__(self):
        self.prolog = Prolog()
        self._testes_carregados = False
        self._base_dir = Path(__file__).resolve().parent

        try:
            self.prolog.consult(str(self._base_dir / "motor_inferencia.pl"))
        except Exception as e:
            print(f"Erro ao carregar arquivos Prolog: {e}")
            sys.exit(1)

        self.avisos_legais = (
            "AVISO: Este protótipo é apenas informativo. "
            "Consulte um especialista para uma recomendação correta."
        )

    # Utilitários de sessão e exibição -------------------------------------------------------------------------

    def limpar_sessao(self):
        """Remove fatos de usuários anteriores do motor Prolog."""
        list(self.prolog.query("retractall(user_fact(_, _))"))

    def exibir_cabecalho(self, titulo):
        print("\n" + "="*60)
        print(f"{titulo.center(60)}")
        print("="*60)

    # Menu Principal -------------------------------------------------------------------------------------------

    def menu_principal(self):
        while True:
            self.exibir_cabecalho("SISTEMA ESPECIALISTA DE RECOMENDAÇÃO DE DIETAS")
            print("1. Obter Recomendação de Dieta")
            print("2. Acessar CRUD (Gerenciar Base de Conhecimento)")
            print("3. Realizar Testes Unitários")
            print("4. Sair")

            opcao = input("\nEscolha uma opção: ").strip()

            if opcao == '1':
                self.fluxo_recomendacao()
            elif opcao == '2':
                self.menu_crud()
            elif opcao == '3':
                self.realizar_testes()
            elif opcao == '4':
                print("\nEncerrando o sistema. Até logo!")
                break
            else:
                print("\nOpção inválida. Tente novamente.")

    # Fluxo de Recomendação ------------------------------------------------------------------------------------

    def fazer_pergunta(self, attr):
        """
        Busca detalhes da pergunta no Prolog e interage com o usuário.
        Retorna True se a resposta foi registrada, False caso contrário.
        """
        attr_str = safe_str(attr)
        query = f"detalhes_pergunta({attr_str}, Texto, Opcoes, Justificativa)"
        resultados = list(self.prolog.query(query))
        if not resultados:
            return False

        resultado = resultados[0]
        texto  = safe_str(resultado['Texto'])
        opcoes = [safe_str(opt) for opt in resultado['Opcoes']]

        print(f"\n>>> {texto}")
        for i, opt in enumerate(opcoes, 1):
            print(f"    {i}. {opt}")

        while True:
            try:
                idx = int(input("Resposta (número): ")) - 1
                if 0 <= idx < len(opcoes):
                    escolha = opcoes[idx]
                    self.prolog.assertz(f"user_fact({attr_str}, {escolha})")
                    return True
                else:
                    print(f"Por favor, escolha um número entre 1 e {len(opcoes)}.")
            except ValueError:
                print("Entrada inválida. Digite um número.")

    def fluxo_recomendacao(self):
        self.limpar_sessao()
        self.exibir_cabecalho("QUESTIONÁRIO DE PERFIL")

        # 1. Perguntas base (obrigatórias)
        perguntas_base = list(self.prolog.query("listar_perguntas_base(L)"))[0]['L']
        for p in perguntas_base:
            self.fazer_pergunta(p)

        # 2. Perguntas condicionais — loop até esgotar todas as ativas
        respondidas = set()
        while True:
            try:
                ativas = list(self.prolog.query(
                    "listar_perguntas_condicionais_ativas(L)"
                ))[0]['L']
                novas = [safe_str(p) for p in ativas if safe_str(p) not in respondidas]
                if not novas:
                    break
                for p in novas:
                    self.fazer_pergunta(p)
                    respondidas.add(p)
            except Exception:
                break

        self.exibir_resultados()

    # Exibição e Explicação dos Resultados ---------------------------------------------------------------------

    def exibir_resultados(self):
        while True:
            self.exibir_cabecalho("RESULTADO DO DIAGNÓSTICO NUTRICIONAL")
            recoms = []

            resultados = list(self.prolog.query(
                "dieta(Id, Nome, _), nao_excluida(Id), calcular_score(Id, S)"
            ))
            for r in resultados:
                recoms.append({
                    'id':    safe_str(r['Id']),
                    'nome':  safe_str(r['Nome']),
                    'score': float(r['S'])
                })

            recoms.sort(key=lambda x: x['score'], reverse=True)

            if not recoms:
                print("\n[!] Devido às restrições informadas, nenhuma dieta foi aprovada.")
                print("    Use a opção 2 abaixo para entender os bloqueios.")
            else:
                for item in recoms:
                    desc_query = list(self.prolog.query(
                        f"descricao_dieta({item['id']}, Desc)"
                    ))
                    descricao = (
                        safe_str(desc_query[0]['Desc'])
                        if desc_query
                        else "Descrição não cadastrada na base."
                    )
                    print(f"\n[{item['score']*100:>3.0f}% ] {item['nome'].upper()}")
                    print(f"       {descricao}")

            print("\n" + "-" * 60)
            print(self.avisos_legais)
            print("-" * 60)

            print("\nOPÇÕES DE EXPLICAÇÃO:")
            print("1. Por que estas dietas foram escolhidas?")
            print("2. Por que uma dieta foi DESCARTADA? (Regras de Exclusão)")
            print("3. Por que me perguntaram isso? (Gatilhos Lógicos)")
            print("4. Voltar ao Menu Principal")

            op = input("\nEscolha: ").strip()
            if op == '1':
                self.explicar_sucesso(recoms)
            elif op == '2':
                self.explicar_exclusao()
            elif op == '3':
                self.explicar_gatilhos()
            elif op == '4':
                break

    def explicar_sucesso(self, recomendacoes):
        print("\n--- JUSTIFICATIVA DE SUCESSO ---")
        if not recomendacoes:
            print("Nenhuma dieta para justificar.")
        else:
            for item in recomendacoes:
                print(f"\n> {item['nome']} ({item['score']*100:.0f}%):")
                query = f"suporta({item['id']}, Attr, Val, W), user_fact(Attr, Val)"
                fatos = list(self.prolog.query(query))
                if not fatos:
                    print("  (Nenhum fato específico confirmado — score vem da probabilidade base.)")
                for f in fatos:
                    attr = safe_str(f['Attr'])
                    val  = safe_str(f['Val'])
                    peso = float(f['W'])
                    print(f"  [+] '{attr}' = '{val}'  (+{peso*100:.0f}%)")

        input("\nPressione ENTER para voltar às recomendações...")

    def explicar_exclusao(self):
        excluidas = []
        todas_dietas = list(self.prolog.query("dieta(Id, Nome, _)"))

        for d in todas_dietas:
            id_d = safe_str(d['Id'])
            razoes = list(self.prolog.query(
                f"exclui({id_d}, Attr, Val), user_fact(Attr, Val)"
            ))
            if razoes:
                excluidas.append({
                    'id':     id_d,
                    'nome':   safe_str(d['Nome']),
                    'razoes': razoes
                })

        if not excluidas:
            print("\nNenhuma dieta foi excluída por regras restritivas neste perfil.")
        else:
            print("\nDietas descartadas nesta sessão:")
            for i, d in enumerate(excluidas, 1):
                print(f"  {i}. {d['nome']}")
            try:
                idx = int(input("Número (ou 0 para voltar): ")) - 1
                if 0 <= idx < len(excluidas):
                    selecionada = excluidas[idx]
                    print(f"\n--- MOTIVOS DE EXCLUSÃO: {selecionada['nome']} ---")
                    for r in selecionada['razoes']:
                        attr = safe_str(r['Attr'])
                        val  = safe_str(r['Val'])
                        print(f"  [!] O fato '{attr} = {val}' é incompatível com esta dieta.")
            except (ValueError, IndexError):
                print("Opção inválida.")

        input("\nPressione ENTER para voltar...")

    def explicar_gatilhos(self):
        pergs = []
        gatilhos = list(self.prolog.query("gatilho_pergunta(Attr, Pai, Val)"))

        for p in gatilhos:
            attr = safe_str(p['Attr'])
            if list(self.prolog.query(f"user_fact({attr}, _)")):
                pergs.append({
                    'attr': attr,
                    'pai':  safe_str(p['Pai']),
                    'val':  safe_str(p['Val'])
                })

        if not pergs:
            print("\nNenhuma pergunta de ajuste fino foi disparada nesta sessão.")
        else:
            print("\nPerguntas condicionais respondidas — selecione para ver o gatilho:")
            for i, p in enumerate(pergs, 1):
                res = list(self.prolog.query(
                    f"detalhes_pergunta({p['attr']}, T, _, _)"
                ))
                if res:
                    print(f"  {i}. {safe_str(res[0]['T'])}")

            try:
                idx = int(input("Número (ou 0 para voltar): ")) - 1
                if 0 <= idx < len(pergs):
                    p = pergs[idx]
                    print(f"\n--- EXPLICAÇÃO LÓGICA ---")
                    print(f"Esta pergunta foi gerada porque você respondeu anteriormente:")
                    print(f"  -> '{p['pai']}' tem o valor '{p['val']}'.")
                    just_query = list(self.prolog.query(
                        f"pergunta({p['attr']}, _, _, _, J)"
                    ))
                    if just_query:
                        print(f"\nJustificativa da pergunta:")
                        print(f"  {safe_str(just_query[0]['J'])}")
            except (ValueError, IndexError):
                print("Opção inválida.")

        input("\nPressione ENTER para voltar...")

    # Testes Unitários -----------------------------------------------------------------------------------------

    def realizar_testes(self):
        self.exibir_cabecalho("TESTES UNITÁRIOS DO SISTEMA")

        if not self._testes_carregados:
            print("\nCarregando suite de testes (testes_unitarios.pl)...")
            try:
                self.prolog.consult(str(self._base_dir / "testes_unitarios.pl"))
                self._testes_carregados = True
                print("[OK] Arquivo carregado.")
            except Exception as e:
                print(f"\n[ERRO] Não foi possível carregar testes_unitarios.pl:\n  {e}")
                print("\nVerifique se o arquivo está na mesma pasta do sistema.")
                input("\nPressione ENTER para voltar...")
                return

        print("\n" + "-" * 60)
        print("Iniciando execução — resultados abaixo:")
        print("-" * 60 + "\n")

        try:
            list(self.prolog.query("executar_testes_sistema"))
            print("\n" + "-" * 60)
            print("[OK] Execução da suite concluída.")
            print(
                "Legenda: 'passed' = aprovado  |  'failed' = reprovado  "
                "|  'error' = erro inesperado"
            )
        except Exception as e:
            print(f"\n[!] Exceção durante os testes: {e}")
            print("Isso pode indicar falha em algum caso. Verifique a saída acima.")

        input("\nPressione ENTER para voltar ao menu...")

    # Helpers de seleção para o CRUD ---------------------------------------------------------------------------

    def selecionar_dieta(self, mensagem="Selecione a Dieta:"):
        dietas = list(self.prolog.query("dieta(Id, Nome, _)"))
        print(f"\n{mensagem}")
        for i, d in enumerate(dietas, 1):
            print(f"{i}. {safe_str(d['Nome'])} ({safe_str(d['Id'])})")
        
        entrada = input("Escolha (número): ").strip()
        if not entrada: return None # Cancelamento silencioso

        try:
            idx = int(entrada) - 1
            if 0 <= idx < len(dietas):
                return safe_str(dietas[idx]['Id'])
            else:
                print(f"[!] Erro: Por favor, selecione um número entre 1 e {len(dietas)}.")
                return None
        except ValueError:
            print("[!] Erro: Entrada inválida. Digite apenas números.")
            return None

    def selecionar_atributo(self, mensagem="Selecione o Atributo:"):
        attrs = list(self.prolog.query("pergunta(Attr, _, _, _, _)"))
        print(f"\n{mensagem}")
        for i, a in enumerate(attrs, 1):
            print(f"{i}. {safe_str(a['Attr'])}")
        
        entrada = input("Escolha (número): ").strip()
        if not entrada: return None

        try:
            idx = int(entrada) - 1
            if 0 <= idx < len(attrs):
                return safe_str(attrs[idx]['Attr'])
            else:
                print(f"[!] Erro: Opção fora do intervalo (1 a {len(attrs)}).")
                return None
        except ValueError:
            print("[!] Erro: Digite um número válido.")
            return None

    def selecionar_valor(self, attr):
        query = f"pergunta({attr}, _, _, Ops, _)"
        res = list(self.prolog.query(query))
        if not res: return None
        ops = [safe_str(o) for o in res[0]['Ops']]
        
        print(f"\nSelecione o Valor para '{attr}':")
        for i, o in enumerate(ops, 1):
            print(f"{i}. {o}")
        
        entrada = input("Escolha (número): ").strip()
        if not entrada: return None

        try:
            idx = int(entrada) - 1
            if 0 <= idx < len(ops):
                return ops[idx]
            else:
                print(f"[!] Erro: Opção inválida.")
                return None
        except ValueError:
            return None

    # Menu CRUD ------------------------------------------------------------------------------------------------

    def menu_crud(self):
        while True:
            self.exibir_cabecalho("GERENCIADOR DA BASE DE CONHECIMENTO")
            print("1. Gerenciar Dietas")
            print("2. Gerenciar Perguntas (Atributos)")
            print("3. Gerenciar Suportes (Pesos)")
            print("4. Gerenciar Exclusões (Bloqueios)")
            print("5. Voltar")
            opcao = input("\nEscolha: ")
            if opcao == '1': self.submenu_dietas()
            elif opcao == '2': self.submenu_perguntas()
            elif opcao == '3': self.submenu_suportes()
            elif opcao == '4': self.submenu_exclusoes()
            elif opcao == '5': break

    def submenu_dietas(self):
        while True:
            print("\n--- DIETAS ---")
            print("1. Listar | 2. Adicionar | 3. Alterar | 4. Remover | 5. Voltar")
            op = input("Opção: ")
            
            if op == '1':
                for d in self.prolog.query("dieta(Id, Nome, P)"):
                    print(f" - {safe_str(d['Id'])}: {safe_str(d['Nome'])} ({float(d['P']):.2f})")
            
            elif op in ['2', '3']:
                id_d = input("ID interno (ex: dieta_nova): ").strip().lower() if op == '2' else self.selecionar_dieta("Selecione a Dieta para alterar:")
                
                if not id_d: 
                    print("[!] Operação cancelada ou ID inválido.")
                    continue
                
                nome = input("Nome de Exibição: ").strip()
                if not nome:
                    print("[!] Erro: O nome não pode ser vazio."); continue
                
                desc = input("Descrição: ").strip()
                if not desc:
                    print("[!] Erro: A descrição não pode ser vazia."); continue

                try:
                    prob_input = input("Probabilidade (0.0 a 1.0): ").strip()
                    prob = float(prob_input)
                    if not (0 <= prob <= 1): raise ValueError
                except ValueError:
                    print("[!] Erro: A probabilidade deve ser um número entre 0.0 e 1.0."); continue

                action = "incluir_dieta" if op == '2' else "alterar_dieta"
                list(self.prolog.query(f"{action}({id_d}, '{nome}', {prob}, '{desc}')"))
                print(f"\n[OK] Dieta '{id_d}' {'adicionada' if op == '2' else 'alterada'} com sucesso!")
            
            elif op == '4':
                id_d = self.selecionar_dieta("Selecione a Dieta para REMOVER:")
                if id_d:
                    list(self.prolog.query(f"excluir_dieta({id_d})"))
                    print(f"\n[OK] Dieta '{id_d}' e todas as suas regras foram removidas.")
            elif op == '5': break

    def submenu_perguntas(self):
        while True:
            print("\n--- PERGUNTAS (ATRIBUTOS) ---")
            print("1. Listar | 2. Adicionar | 3. Alterar | 4. Remover | 5. Voltar")
            op = input("Opção: ")
            
            if op == '1':
                for p in self.prolog.query("pergunta(A, Tipo, T, Ops, _)"):
                    tipo_str = safe_str(p['Tipo']) 
                    ops = [safe_str(o) for o in p['Ops']]
                    print(f" - [{safe_str(p['A'])}] ({tipo_str}): {safe_str(p['T'])} {ops}")
                    
            elif op in ['2', '3']:
                if op == '2':
                    attr = input("ID interno do Atributo (ex: restringe_doce): ").strip().lower()
                    if not attr: continue
                    existe = list(self.prolog.query(f"pergunta({attr}, _, _, _, _)"))
                    if existe:
                        print(f"[!] Erro: Já existe uma pergunta com o ID '{attr}'.")
                        continue
                else:
                    attr = self.selecionar_atributo("Selecione a Pergunta para alterar:")
                    if not attr: continue

                print("\nÉ uma pergunta BASE (sempre aparece) ou CONDICIONAL (depende de outra)?")
                print("1. Base\n2. Condicional")
                tipo_op = input("Escolha (1 ou 2): ").strip()
                
                if tipo_op not in ['1', '2']:
                    print("[!] Erro: Opção inválida. Escolha 1 para Base ou 2 para Condicional.")
                    continue
                
                if tipo_op == '2':
                    print("\nDepende de qual pergunta anterior?")
                    pai = self.selecionar_atributo()
                    if not pai: continue
                    val = self.selecionar_valor(pai)
                    if not val: continue
                    tipo = f"depende({pai}, {val})"
                else:
                    tipo = "base"

                texto = input("Texto da pergunta (ex: Você corta doces?): ").strip()
                if not texto: print("[!] O texto não pode ser vazio."); continue

                ops_str = input("Opções separadas por vírgula (ex: sim, nao, as_vezes): ").strip()
                lista_opcoes = [o.strip().lower().replace(" ", "_") for o in ops_str.split(",") if o.strip()]
                if len(lista_opcoes) < 2:
                    print("[!] Erro: Você deve fornecer pelo menos 2 opções válidas.")
                    continue
                    
                ops_formatadas = "[" + ",".join(lista_opcoes) + "]"

                justificativa = input("Justificativa (por que perguntar isso?): ").strip()
                if not justificativa: print("[!] A justificativa não pode ser vazia."); continue

                action = "incluir_pergunta" if op == '2' else "alterar_pergunta"
                try:
                    list(self.prolog.query(f"{action}({attr}, {tipo}, '{texto}', {ops_formatadas}, '{justificativa}')"))
                    print(f"\n[OK] Pergunta '{attr}' {'adicionada' if op == '2' else 'alterada'} com sucesso!")
                except Exception as e:
                    print(f"[!] Erro ao salvar pergunta: {e}")

            elif op == '4':
                attr = self.selecionar_atributo("Selecione a Pergunta para REMOVER:")
                if attr:
                    list(self.prolog.query(f"excluir_pergunta({attr})"))
                    print(f"\n[OK] Pergunta '{attr}' e todas as regras ligadas a ela foram removidas para evitar erros.")
                    
            elif op == '5': break

    def submenu_suportes(self):
        while True:
            print("\n--- REGRAS DE SUPORTE (PONTUAÇÃO) ---")
            print("1. Listar | 2. Adicionar | 3. Alterar Peso | 4. Remover | 5. Voltar")
            op = input("Opção: ")
            
            if op == '1':
                id_d = self.selecionar_dieta()
                if id_d:
                    regras = list(self.prolog.query(f"suporta({id_d}, A, V, P)"))
                    if not regras: print(f"\nNenhuma regra de suporte para '{id_d}'.")
                    for r in regras:
                        print(f" -> Se '{safe_str(r['A'])}' for '{safe_str(r['V'])}', soma +{float(r['P'])*100:.0f}%")
            
            elif op in ['2', '3']:
                id_d = self.selecionar_dieta()
                if not id_d: continue 
                attr = self.selecionar_atributo()
                if not attr: continue 
                val = self.selecionar_valor(attr)
                if not val: continue 

                existe = list(self.prolog.query(f"suporta({id_d}, {attr}, {val}, P_Atual)"))
                
                if op == '2' and existe:
                    print(f"\n[!] Aviso: Já existe uma regra para {id_d} com {attr}={val}.")
                    confirmar = input("Deseja sobrescrever o peso atual? (s/n): ").lower()
                    if confirmar != 's': continue
                elif op == '3' and not existe:
                    print(f"\n[!] Erro: Esta regra NÃO EXISTE. Use a opção 'Adicionar' ou verifique os dados.")
                    continue

                if existe:
                    peso_atual = float(existe[0]['P_Atual'])
                    print(f"\nPeso atual desta regra: {peso_atual*100:.0f}%")

                try:
                    peso_input = input("Digite o novo Peso/Importância (0.0 a 1.0): ").strip()
                    peso = float(peso_input)
                    if not (0 <= peso <= 1): raise ValueError
                except ValueError:
                    print("[!] Erro: Peso inválido."); continue

                action = "incluir_suporte" if op == '2' else "alterar_suporte"
                list(self.prolog.query(f"{action}({id_d}, {attr}, {val}, {peso})"))
                print(f"\n[OK] Regra de suporte {'registrada' if op == '2' else 'atualizada'} com sucesso!")

            elif op == '4':
                id_d = self.selecionar_dieta()
                if not id_d: continue
                attr = self.selecionar_atributo()
                if not attr: continue
                val = self.selecionar_valor(attr)
                if not val: continue
                
                existe = list(self.prolog.query(f"suporta({id_d}, {attr}, {val}, _)"))
                if not existe:
                    print(f"\n[!] Erro: Não foi possível remover. A regra ({id_d}, {attr}={val}) NÃO EXISTE na base.")
                    continue

                list(self.prolog.query(f"excluir_suporte({id_d}, {attr}, {val})"))
                print(f"\n[OK] Regra de suporte removida com sucesso!")
                
            elif op == '5': break

    def submenu_exclusoes(self):
        while True:
            print("\n--- REGRAS DE EXCLUSÃO (BLOQUEIOS) ---")
            print("1. Listar | 2. Adicionar | 3. Alterar | 4. Remover | 5. Voltar")
            op = input("Opção: ")
            
            if op == '1':
                id_d = self.selecionar_dieta()
                if id_d:
                    regras = list(self.prolog.query(f"exclui({id_d}, A, V)"))
                    if not regras: print(f"\nNenhuma regra de exclusão para '{id_d}'.")
                    for r in regras:
                        print(f" -> BLOQUEIA se '{safe_str(r['A'])}' for '{safe_str(r['V'])}'")
            
            elif op == '2':
                id_d = self.selecionar_dieta()
                if not id_d: continue
                attr = self.selecionar_atributo("Atributo a ser bloqueado:")
                if not attr: continue
                val = self.selecionar_valor(attr)
                if not val: continue

                existe = list(self.prolog.query(f"exclui({id_d}, {attr}, {val})"))
                if existe:
                    print(f"\n[!] Aviso: A dieta '{id_d}' JÁ ESTÁ BLOQUEADA para '{attr}={val}'.")
                    continue

                list(self.prolog.query(f"incluir_exclusao({id_d}, {attr}, {val})"))
                print(f"\n[OK] Regra de exclusão ativada!")

            elif op == '3':
                id_d = self.selecionar_dieta()
                if not id_d: continue
                
                print("\nSelecione a regra ANTIGA que deseja alterar:")
                attr_old = self.selecionar_atributo()
                if not attr_old: continue
                val_old = self.selecionar_valor(attr_old)
                if not val_old: continue

                existe_antiga = list(self.prolog.query(f"exclui({id_d}, {attr_old}, {val_old})"))
                if not existe_antiga:
                    print(f"\n[!] Erro: A regra ({id_d}, {attr_old}={val_old}) NÃO EXISTE. Nada para alterar.")
                    continue

                print("\nSelecione os NOVOS parâmetros para o bloqueio:")
                attr_new = self.selecionar_atributo("Novo Atributo:")
                if not attr_new: continue
                val_new = self.selecionar_valor(attr_new)
                if not val_new: continue

                list(self.prolog.query(f"alterar_exclusao({id_d}, {attr_old}, {val_old}, {attr_new}, {val_new})"))
                print(f"\n[OK] Regra de exclusão alterada com sucesso!")

            elif op == '4':
                id_d = self.selecionar_dieta()
                if not id_d: continue
                attr = self.selecionar_atributo()
                if not attr: continue
                val = self.selecionar_valor(attr)
                if not val: continue
                
                existe = list(self.prolog.query(f"exclui({id_d}, {attr}, {val})"))
                if not existe:
                    print(f"\n[!] Erro: Não foi possível remover. A regra ({id_d}, {attr}={val}) NÃO EXISTE na base.")
                    continue

                list(self.prolog.query(f"excluir_exclusao({id_d}, {attr}, {val})"))
                print("\n[OK] Regra de exclusão removida com sucesso!")
                
            elif op == '5': break

if __name__ == "__main__":
    app = SistemaEspecialistaDietas()
    app.menu_principal()