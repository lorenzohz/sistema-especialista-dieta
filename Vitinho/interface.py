import sys
from pyswip import Prolog

def safe_str(valor):
    if isinstance(valor, bytes):
        return valor.decode('utf-8', errors='ignore')
    return str(valor)

class SistemaEspecialistaDietas:
    def __init__(self):
        self.prolog = Prolog()
        try:
            self.prolog.consult("motor_inferencia.pl")
        except Exception as e:
            print(f"Erro ao carregar arquivos Prolog: {e}")
            sys.exit(1)
        
        self.avisos_legais = "AVISO: Este protótipo é apenas informativo. Consulte um especialista para uma recomendação correta."

    def limpar_sessao(self):
        """Remove fatos de usuários anteriores do motor Prolog."""
        list(self.prolog.query("retractall(user_fact(_, _))"))

    def exibir_cabecalho(self, titulo):
        print("\n" + "="*60)
        print(f"{titulo.center(60)}")
        print("="*60)

    def menu_principal(self):
        while True:
            self.exibir_cabecalho("SISTEMA ESPECIALISTA DE RECOMENDAÇÃO DE DIETAS")
            print("1. Obter Recomendação de Dieta")
            print("2. Acessar CRUD (Gerenciar Base de Conhecimento)")
            print("3. Realizar Testes Unitários")
            print("4. Sair")
            
            opcao = input("\nEscolha uma opção: ")

            if opcao == '1':
                self.fluxo_recomendacao()
            elif opcao == '2':
                self.menu_crud()
            elif opcao == '3':
                print("\n[!] Ainda em construção...")
            elif opcao == '4':
                print("\nEncerrando o sistema. Até logo!")
                break
            else:
                print("\nOpção inválida. Tente novamente.")

    def fazer_pergunta(self, attr):
        """Busca detalhes da pergunta no Prolog e interage com o usuário."""
        # Consulta: detalhes_pergunta(Attr, Texto, Opcoes, Justificativa)
        query = f"detalhes_pergunta({attr}, Texto, Opcoes, Justificativa)"
        resultado = list(self.prolog.query(query))[0]
        
        texto = resultado['Texto']
        opcoes = [opt for opt in resultado['Opcoes']]
        
        print(f"\n>>> {texto}")
        for i, opt in enumerate(opcoes, 1):
            print(f"    {i}. {opt}")
        
        while True:
            try:
                idx = int(input("Resposta (número): ")) - 1
                if 0 <= idx < len(opcoes):
                    escolha = opcoes[idx]
                    # Salva o fato no Prolog
                    self.prolog.assertz(f"user_fact({attr}, {escolha})")
                    break
                else:
                    print("Por favor, escolha um número da lista.")
            except ValueError:
                print("Entrada inválida. Digite um número.")

    def fluxo_recomendacao(self):
        self.limpar_sessao()
        self.exibir_cabecalho("QUESTIONÁRIO DE PERFIL")

        # 1. Perguntas Base
        perguntas_base = list(self.prolog.query("listar_perguntas_base(L)"))[0]['L']
        for p in perguntas_base:
            self.fazer_pergunta(p)

        # 2. Perguntas Condicionais (Loop até não haver mais perguntas ativas)
        while True:
            try:
                ativas = list(self.prolog.query("listar_perguntas_condicionais_ativas(L)"))[0]['L']
                if not ativas:
                    break
                for p in ativas:
                    self.fazer_pergunta(p)
            except Exception:
                break

        self.exibir_resultados()

    def exibir_resultados(self):
        while True:
            self.exibir_cabecalho("RESULTADO DO DIAGNÓSTICO NUTRICIONAL")
            recoms = []
            
            resultados = list(self.prolog.query("dieta(Id, Nome, _), nao_excluida(Id), calcular_score(Id, S)"))
            for r in resultados:
                recoms.append({'id': safe_str(r['Id']), 'nome': safe_str(r['Nome']), 'score': float(r['S'])})
            
            recoms.sort(key=lambda x: x['score'], reverse=True)
            
            if not recoms:
                print("\n[!] Devido às restrições informadas, nenhuma dieta base foi aprovada.")
                print("    Consulte a opção 2 abaixo para entender os bloqueios.")
            else:
                for item in recoms:
                    # Busca a descrição da dieta no Prolog
                    id_dieta = item['id']
                    desc_query = list(self.prolog.query(f"descricao_dieta({id_dieta}, Desc)"))
                    if desc_query:
                        descricao = safe_str(desc_query[0]['Desc'])
                    else:
                        descricao = "Descrição detalhada não cadastrada na base."
                        
                    print(f"\n[{item['score']*100:>3.0f}% ] {item['nome'].upper()}")
                    print(f"       {descricao}")

            print("\n" + "-"*60)
            print(self.avisos_legais)
            print("-"*60)
            
            print("\nOPÇÕES DE EXPLICAÇÃO:")
            print("1. Por que estas dietas foram escolhidas?")
            print("2. Por que uma dieta foi DESCARTADA? (Regras de Exclusão)")
            print("3. Por que me perguntaram isso? (Gatilhos Lógicos)")
            print("4. Voltar ao Menu Principal")
            
            op = input("\nEscolha: ")
            if op == '1': self.explicar_sucesso(recoms)
            elif op == '2': self.explicar_exclusao()
            elif op == '3': self.explicar_gatilhos()
            elif op == '4': break

    def explicar_sucesso(self, recomendacoes):
        print("\n--- JUSTIFICATIVA DE SUCESSO ---")
        for item in recomendacoes:
            print(f"\n> {item['nome']}:")
            query = f"suporta({item['id']}, Attr, Val, W), user_fact(Attr, Val)"
            for f in self.prolog.query(query):
                attr = safe_str(f['Attr'])
                val = safe_str(f['Val'])
                peso = float(f['W'])
                print(f"  [+] Confirmado: '{attr}' é '{val}' (+{peso*100:.0f}%)")
                
        input("\nPressione ENTER para voltar às recomendações...")

    def explicar_exclusao(self):
        excluidas = []
        todas_dietas = list(self.prolog.query("dieta(Id, Nome, _)"))
        
        for d in todas_dietas:
            id_d = safe_str(d['Id'])
            razoes = list(self.prolog.query(f"exclui({id_d}, Attr, Val), user_fact(Attr, Val)"))
            if razoes:
                excluidas.append({'id': id_d, 'nome': safe_str(d['Nome']), 'razoes': razoes})

        if not excluidas:
            print("\nNenhuma dieta foi excluída por regras restritivas neste perfil.")
        else:
            print("\nEscolha uma dieta descartada:")
            for i, d in enumerate(excluidas, 1): print(f"{i}. {d['nome']}")
            try:
                idx = int(input("Número: ")) - 1
                for r in excluidas[idx]['razoes']:
                    attr = safe_str(r['Attr'])
                    val = safe_str(r['Val'])
                    print(f"  [!] MOTIVO: O fato '{attr}={val}' é incompatível.")
            except: print("Opção inválida.")
        
        input("\nPressione ENTER para voltar...")

    def explicar_gatilhos(self):
        pergs = []
        gatilhos_base = list(self.prolog.query("gatilho_pergunta(Attr, Pai, Val)"))
        
        for p in gatilhos_base:
            attr = safe_str(p['Attr'])
            if list(self.prolog.query(f"user_fact({attr}, _)")):
                pergs.append({'attr': attr, 'pai': safe_str(p['Pai']), 'val': safe_str(p['Val'])})

        if not pergs:
            print("\nNenhuma pergunta de ajuste fino foi disparada ou respondida ainda.")
        else:
            print("\nSelecione uma pergunta para ver o gatilho lógico:")
            for i, p in enumerate(pergs, 1):
                res = list(self.prolog.query(f"detalhes_pergunta({p['attr']}, T, _, _)"))[0]
                print(f"{i}. {safe_str(res['T'])}")
            
            try:
                idx = int(input("Número: ")) - 1
                p = pergs[idx]
                print(f"\n--- EXPLICAÇÃO LÓGICA ---")
                print(f"Esta pergunta foi gerada porque, anteriormente, você confirmou que:")
                print(f"-> '{p['pai']}' tem o valor '{p['val']}'.")
            except: print("Inválido.")
        
        input("\nPressione ENTER para voltar...")
    
    def selecionar_dieta(self, mensagem="Selecione a Dieta:"):
        dietas = list(self.prolog.query("dieta(Id, Nome, _)"))
        print(f"\n{mensagem}")
        for i, d in enumerate(dietas, 1):
            print(f"{i}. {safe_str(d['Nome'])} ({safe_str(d['Id'])})")
        try:
            idx = int(input("Escolha: ")) - 1
            return safe_str(dietas[idx]['Id'])
        except: return None

    def selecionar_atributo(self, mensagem="Selecione o Atributo:"):
        attrs = list(self.prolog.query("pergunta(Attr, _, _, _, _)"))
        print(f"\n{mensagem}")
        for i, a in enumerate(attrs, 1):
            print(f"{i}. {safe_str(a['Attr'])}")
        try:
            idx = int(input("Escolha: ")) - 1
            return safe_str(attrs[idx]['Attr'])
        except: return None

    def selecionar_valor(self, attr):
        query = f"pergunta({attr}, _, _, Ops, _)"
        res = list(self.prolog.query(query))
        if not res: return None
        ops = [safe_str(o) for o in res[0]['Ops']]
        print(f"\nSelecione o Valor para '{attr}':")
        for i, o in enumerate(ops, 1):
            print(f"{i}. {o}")
        try:
            idx = int(input("Escolha: ")) - 1
            return ops[idx]
        except: return None

    def menu_crud(self):
        while True:
            self.exibir_cabecalho("GERENCIADOR DA BASE DE CONHECIMENTO")
            print("1. Gerenciar Dietas\n2. Gerenciar Suportes (Pesos)\n3. Gerenciar Exclusões (Bloqueios)\n4. Voltar")
            opcao = input("\nEscolha: ")
            if opcao == '1': self.submenu_dietas()
            elif opcao == '2': self.submenu_suportes()
            elif opcao == '3': self.submenu_exclusoes()
            elif opcao == '4': break

    def submenu_dietas(self):
        while True:
            print("\n--- DIETAS ---")
            print("1. Listar | 2. Adicionar | 3. Alterar | 4. Remover | 5. Voltar")
            op = input("Opção: ")
            if op == '1':
                for d in self.prolog.query("dieta(Id, Nome, P)"):
                    print(f" - {safe_str(d['Id'])}: {safe_str(d['Nome'])} ({float(d['P']):.2f})")
            elif op in ['2', '3']:
                id_d = input("ID (ex: nova_dieta): ") if op == '2' else self.selecionar_dieta()
                if not id_d: continue
                nome = input("Nome de Exibição: ")
                try:
                    prob = float(input("Probabilidade (0.0 a 1.0): "))
                    if not (0 <= prob <= 1): raise ValueError
                except: print("Erro: Probabilidade deve ser entre 0 e 1."); continue
                desc = input("Descrição: ")
                action = "incluir_dieta" if op == '2' else "alterar_dieta"
                list(self.prolog.query(f"{action}({id_d}, '{nome}', {prob}, '{desc}')"))
                print(f"\n[OK] Dieta {'adicionada' if op == '2' else 'alterada'} com sucesso!")
            elif op == '4':
                id_d = self.selecionar_dieta()
                if id_d:
                    list(self.prolog.query(f"excluir_dieta({id_d})"))
                    print(f"\n[OK] Dieta '{id_d}' e suas regras removidas!")
            elif op == '5': break

    def submenu_suportes(self):
        while True:
            print("\n--- REGRAS DE SUPORTE (PONTUAÇÃO) ---")
            print("1. Listar | 2. Adicionar | 3. Alterar Peso | 4. Remover | 5. Voltar")
            op = input("Opção: ")
            if op == '1':
                id_d = self.selecionar_dieta()
                if id_d:
                    for r in self.prolog.query(f"suporta({id_d}, A, V, P)"):
                        print(f" -> {safe_str(r['A'])}={safe_str(r['V'])}: +{float(r['P'])*100:.0f}%")
            elif op in ['2', '3']:
                id_d = self.selecionar_dieta()
                attr = self.selecionar_atributo()
                val = self.selecionar_valor(attr)
                if not (id_d and attr and val): continue
                try:
                    peso = float(input("Novo Peso (0.0 a 1.0): "))
                    if not (0 <= peso <= 1): raise ValueError
                except: print("Erro: Peso inválido."); continue
                action = "incluir_suporte" if op == '2' else "alterar_suporte"
                list(self.prolog.query(f"{action}({id_d}, {attr}, {val}, {peso})"))
                print(f"\n[OK] Regra de suporte {'adicionada' if op == '2' else 'alterada'}!")
            elif op == '4':
                id_d = self.selecionar_dieta(); attr = self.selecionar_atributo(); val = self.selecionar_valor(attr)
                if id_d and attr and val:
                    list(self.prolog.query(f"excluir_suporte({id_d}, {attr}, {val})"))
                    print("\n[OK] Regra de suporte removida!")
            elif op == '5': break

    def submenu_exclusoes(self):
        while True:
            print("\n--- REGRAS DE EXCLUSÃO (BLOQUEIOS) ---")
            print("1. Listar | 2. Adicionar | 3. Alterar | 4. Remover | 5. Voltar")
            op = input("Opção: ")
            if op == '1':
                id_d = self.selecionar_dieta()
                if id_d:
                    for r in self.prolog.query(f"exclui({id_d}, A, V)"):
                        print(f" -> BLOQUEIA se {safe_str(r['A'])} for {safe_str(r['V'])}")
            elif op in ['2', '3']:
                id_d = self.selecionar_dieta()
                if op == '3':
                    print("Selecione a regra antiga para alterar:")
                    attr_old = self.selecionar_atributo(); val_old = self.selecionar_valor(attr_old)
                attr_new = self.selecionar_atributo("Novo Atributo:"); val_new = self.selecionar_valor(attr_new)
                if op == '2':
                    list(self.prolog.query(f"incluir_exclusao({id_d}, {attr_new}, {val_new})"))
                else:
                    list(self.prolog.query(f"alterar_exclusao({id_d}, {attr_old}, {val_old}, {attr_new}, {val_new})"))
                print(f"\n[OK] Regra de exclusão {'adicionada' if op == '2' else 'alterada'}!")
            elif op == '4':
                id_d = self.selecionar_dieta(); attr = self.selecionar_atributo(); val = self.selecionar_valor(attr)
                if id_d and attr and val:
                    list(self.prolog.query(f"excluir_exclusao({id_d}, {attr}, {val})"))
                    print("\n[OK] Regra de exclusão removida!")
            elif op == '5': break

if __name__ == "__main__":
    app = SistemaEspecialistaDietas()
    app.menu_principal()