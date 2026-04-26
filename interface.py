import re
import sys
from pathlib import Path

from pyswip import Prolog


def safe_str(valor):
    if isinstance(valor, bytes):
        return valor.decode("utf-8", errors="ignore")
    return str(valor)


class SistemaEspecialistaDietas:
    RE_DIETA = re.compile(
        r"^\s*dieta\((?P<id>[a-z_][a-zA-Z0-9_]*),\s*'(?P<nome>(?:\\'|[^'])*)',\s*(?P<prob>\d+(?:\.\d+)?)\)\.\s*$"
    )
    RE_DESCRICAO = re.compile(
        r"^\s*descricao_dieta\((?P<id>[a-z_][a-zA-Z0-9_]*),\s*'(?P<desc>(?:\\'|[^'])*)'\)\.\s*$"
    )
    RE_EVIDENCIA = re.compile(
        r"^\s*evidencia\((?P<dieta>[a-z_][a-zA-Z0-9_]*),\s*X,\s*(?P<peso>\d+(?:\.\d+)?)\)\s*:-\s*(?P<pred>[a-z_][a-zA-Z0-9_]*)\(X,\s*(?P<valor>[a-z_][a-zA-Z0-9_]*)\)\.\s*$"
    )
    RE_CONTRA = re.compile(
        r"^\s*contraindicada\((?P<dieta>[a-z_][a-zA-Z0-9_]*),\s*X\)\s*:-\s*(?P<pred>[a-z_][a-zA-Z0-9_]*)\(X,\s*(?P<valor>[a-z_][a-zA-Z0-9_]*)\)\.\s*$"
    )

    MAPA_DIRETO_ATTR_PRED = {
        "objetivo": "tem_objetivo",
        "nivel_atividade": "tem_nivel_atividade",
        "faixa_etaria": "tem_faixa_etaria",
        "imc_faixa": "tem_imc_faixa",
        "tempo_preparo": "tem_tempo_preparo",
        "orcamento": "tem_orcamento",
        "tipo_diabetes": "tem_tipo_diabetes",
        "frequencia_carne": "tem_frequencia_carne",
        "disposicao_restricao": "tem_disposicao_restricao",
    }
    MAPA_DIRETO_PRED_ATTR = {v: k for k, v in MAPA_DIRETO_ATTR_PRED.items()}

    MAPA_DOENCA_ATTR = {
        "diabetes": "tem_diabetes",
        "hipertensao": "tem_hipertensao",
        "colesterol_alto": "tem_colesterol_alto",
        "problemas_renais": "tem_problemas_renais",
        "doenca_cardiaca": "tem_doenca_cardiaca",
    }
    MAPA_RESTRICAO_ATTR = {
        "carne": "restricao_carne",
        "lactose": "alergia_lactose",
        "gluten": "restricao_gluten",
        "laticinios": "restricao_laticinios",
    }

    def __init__(self):
        self.prolog = Prolog()
        self._testes_carregados = False
        self._base_dir = Path(__file__).resolve().parent
        self._base_path = self._base_dir / "base_conhecimento.pl"
        self._motor_path = self._base_dir / "motor_inferencia.pl"
        self.individuo_atual = "usuario_atual"

        try:
            self.prolog.consult(str(self._motor_path))
            list(self.prolog.query(f"definir_individuo_atual({self.individuo_atual})"))
        except Exception as e:
            print(f"Erro ao carregar arquivos Prolog: {e}")
            sys.exit(1)

        self.avisos_legais = (
            "AVISO: Este prototipo e apenas informativo. "
            "Consulte um especialista para uma recomendacao correta."
        )

    # Utilitarios -----------------------------------------------------------------------------------------------

    def _escape_texto_prolog(self, texto):
        return texto.replace("\\", "\\\\").replace("'", "\\'")

    def _formatar_numero(self, valor):
        txt = f"{valor:.4f}".rstrip("0").rstrip(".")
        return txt if "." in txt else f"{txt}.0"

    def _ler_linhas_base(self):
        return self._base_path.read_text(encoding="utf-8").splitlines(keepends=True)

    def _escrever_linhas_base(self, linhas):
        self._base_path.write_text("".join(linhas), encoding="utf-8")
        self.prolog.consult(str(self._base_path))
        self.prolog.consult(str(self._motor_path))
        list(self.prolog.query(f"definir_individuo_atual({self.individuo_atual})"))

    def _indice_apos_ultimo(self, linhas, pred_prefix):
        ultimo = -1
        for i, linha in enumerate(linhas):
            if linha.lstrip().startswith(pred_prefix):
                ultimo = i
        return ultimo + 1 if ultimo >= 0 else len(linhas)

    def _atributo_valor_para_condicao(self, attr, val):
        if attr in self.MAPA_DIRETO_ATTR_PRED:
            return self.MAPA_DIRETO_ATTR_PRED[attr], val

        if attr == "tem_diabetes":
            return ("tem_doenca", "diabetes") if val == "sim" else ("nao_tem_doenca", "diabetes")
        if attr == "tem_hipertensao":
            return ("tem_doenca", "hipertensao") if val == "sim" else ("nao_tem_doenca", "hipertensao")
        if attr == "tem_colesterol_alto":
            return ("tem_doenca", "colesterol_alto") if val == "sim" else ("nao_tem_doenca", "colesterol_alto")
        if attr == "tem_problemas_renais":
            return ("tem_doenca", "problemas_renais") if val == "sim" else ("nao_tem_doenca", "problemas_renais")
        if attr == "tem_doenca_cardiaca":
            return ("tem_doenca", "doenca_cardiaca") if val == "sim" else ("nao_tem_doenca", "doenca_cardiaca")

        if attr == "restricao_carne":
            return ("tem_restricao", "carne") if val == "sim" else ("nao_tem_restricao", "carne")
        if attr == "alergia_lactose":
            return ("tem_restricao", "lactose") if val == "sim" else ("nao_tem_restricao", "lactose")
        if attr == "restricao_gluten":
            return ("tem_restricao", "gluten") if val == "sim" else ("nao_tem_restricao", "gluten")
        if attr == "restricao_laticinios":
            return ("tem_restricao", "laticinios") if val == "sim" else ("nao_tem_restricao", "laticinios")

        return None, None

    def _condicao_para_atributo_valor(self, pred, valor):
        if pred in self.MAPA_DIRETO_PRED_ATTR:
            return self.MAPA_DIRETO_PRED_ATTR[pred], valor

        if pred == "tem_doenca":
            attr = self.MAPA_DOENCA_ATTR.get(valor)
            return (attr, "sim") if attr else (pred, valor)
        if pred == "nao_tem_doenca":
            attr = self.MAPA_DOENCA_ATTR.get(valor)
            return (attr, "nao") if attr else (pred, valor)

        if pred == "tem_restricao":
            attr = self.MAPA_RESTRICAO_ATTR.get(valor)
            return (attr, "sim") if attr else (pred, valor)
        if pred == "nao_tem_restricao":
            attr = self.MAPA_RESTRICAO_ATTR.get(valor)
            return (attr, "nao") if attr else (pred, valor)

        return pred, valor

    def _listar_regras_evidencia(self, dieta_id=None):
        regras = []
        for i, linha in enumerate(self._ler_linhas_base()):
            m = self.RE_EVIDENCIA.match(linha)
            if not m:
                continue
            dados = m.groupdict()
            if dieta_id and dados["dieta"] != dieta_id:
                continue
            attr, val_attr = self._condicao_para_atributo_valor(dados["pred"], dados["valor"])
            regras.append({
                "idx": i,
                "dieta": dados["dieta"],
                "peso": float(dados["peso"]),
                "pred": dados["pred"],
                "valor": dados["valor"],
                "attr": attr,
                "attr_val": val_attr,
            })
        return regras

    def _listar_regras_contra(self, dieta_id=None):
        regras = []
        for i, linha in enumerate(self._ler_linhas_base()):
            m = self.RE_CONTRA.match(linha)
            if not m:
                continue
            dados = m.groupdict()
            if dieta_id and dados["dieta"] != dieta_id:
                continue
            attr, val_attr = self._condicao_para_atributo_valor(dados["pred"], dados["valor"])
            regras.append({
                "idx": i,
                "dieta": dados["dieta"],
                "pred": dados["pred"],
                "valor": dados["valor"],
                "attr": attr,
                "attr_val": val_attr,
            })
        return regras

    def _incluir_dieta_arquivo(self, dieta_id, nome, prob, desc):
        linhas = self._ler_linhas_base()
        for linha in linhas:
            m = self.RE_DIETA.match(linha)
            if m and m.group("id") == dieta_id:
                return False, f"[!] Erro: a dieta '{dieta_id}' ja existe."

        dieta_line = f"dieta({dieta_id}, '{self._escape_texto_prolog(nome)}', {self._formatar_numero(prob)}).\n"
        desc_line = (
            f"descricao_dieta({dieta_id}, '{self._escape_texto_prolog(desc)}').\n"
        )

        idx_dieta = self._indice_apos_ultimo(linhas, "dieta(")
        linhas.insert(idx_dieta, dieta_line)
        idx_desc = self._indice_apos_ultimo(linhas, "descricao_dieta(")
        linhas.insert(idx_desc, desc_line)
        self._escrever_linhas_base(linhas)
        return True, f"[OK] Dieta '{dieta_id}' adicionada com sucesso."

    def _alterar_dieta_arquivo(self, dieta_id, nome, prob, desc):
        linhas = self._ler_linhas_base()
        achou_dieta = False
        achou_desc = False

        for i, linha in enumerate(linhas):
            md = self.RE_DIETA.match(linha)
            if md and md.group("id") == dieta_id:
                linhas[i] = (
                    f"dieta({dieta_id}, '{self._escape_texto_prolog(nome)}', {self._formatar_numero(prob)}).\n"
                )
                achou_dieta = True
                continue

            ms = self.RE_DESCRICAO.match(linha)
            if ms and ms.group("id") == dieta_id:
                linhas[i] = (
                    f"descricao_dieta({dieta_id}, '{self._escape_texto_prolog(desc)}').\n"
                )
                achou_desc = True

        if not achou_dieta:
            return False, f"[!] Erro: dieta '{dieta_id}' nao encontrada."

        if not achou_desc:
            idx_desc = self._indice_apos_ultimo(linhas, "descricao_dieta(")
            linhas.insert(
                idx_desc,
                f"descricao_dieta({dieta_id}, '{self._escape_texto_prolog(desc)}').\n",
            )

        self._escrever_linhas_base(linhas)
        return True, f"[OK] Dieta '{dieta_id}' alterada com sucesso."

    def _excluir_dieta_arquivo(self, dieta_id):
        linhas = self._ler_linhas_base()
        novas = []
        removida = False

        for linha in linhas:
            md = self.RE_DIETA.match(linha)
            ms = self.RE_DESCRICAO.match(linha)
            me = self.RE_EVIDENCIA.match(linha)
            mc = self.RE_CONTRA.match(linha)

            if md and md.group("id") == dieta_id:
                removida = True
                continue
            if ms and ms.group("id") == dieta_id:
                continue
            if me and me.group("dieta") == dieta_id:
                continue
            if mc and mc.group("dieta") == dieta_id:
                continue
            novas.append(linha)

        if not removida:
            return False, f"[!] Erro: dieta '{dieta_id}' nao encontrada."

        self._escrever_linhas_base(novas)
        return True, f"[OK] Dieta '{dieta_id}' removida (incluindo evidencias e contraindicacoes)."

    def _salvar_regra_evidencia(self, dieta_id, attr, val, peso, modo):
        pred, valor_cond = self._atributo_valor_para_condicao(attr, val)
        if not pred:
            return False, "[!] Erro: atributo/valor nao mapeado para uma relacao LPO."

        regras = self._listar_regras_evidencia(dieta_id)
        regra_existente = next(
            (r for r in regras if r["pred"] == pred and r["valor"] == valor_cond),
            None,
        )
        linhas = self._ler_linhas_base()

        if modo == "incluir" and regra_existente:
            return False, "[!] Aviso: esta evidencia ja existe."
        if modo == "alterar" and not regra_existente:
            return False, "[!] Erro: evidencia nao encontrada para alteracao."

        nova_linha = (
            f"evidencia({dieta_id}, X, {self._formatar_numero(peso)}) :- "
            f"{pred}(X, {valor_cond}).\n"
        )

        if regra_existente:
            linhas[regra_existente["idx"]] = nova_linha
        else:
            idx = self._indice_apos_ultimo(linhas, "evidencia(")
            linhas.insert(idx, nova_linha)

        self._escrever_linhas_base(linhas)
        acao = "atualizada" if regra_existente else "registrada"
        return True, f"[OK] Evidencia {acao} com sucesso."

    def _excluir_regra_evidencia(self, dieta_id, attr, val):
        pred, valor_cond = self._atributo_valor_para_condicao(attr, val)
        if not pred:
            return False, "[!] Erro: atributo/valor nao mapeado para uma relacao LPO."

        linhas = self._ler_linhas_base()
        novas = []
        removida = False

        for linha in linhas:
            m = self.RE_EVIDENCIA.match(linha)
            if (
                m
                and m.group("dieta") == dieta_id
                and m.group("pred") == pred
                and m.group("valor") == valor_cond
            ):
                removida = True
                continue
            novas.append(linha)

        if not removida:
            return False, "[!] Erro: evidencia nao encontrada."

        self._escrever_linhas_base(novas)
        return True, "[OK] Evidencia removida com sucesso."

    def _salvar_regra_contra(self, dieta_id, attr, val, modo, attr_old=None, val_old=None):
        pred, valor_cond = self._atributo_valor_para_condicao(attr, val)
        if not pred:
            return False, "[!] Erro: atributo/valor nao mapeado para uma relacao LPO."

        linhas = self._ler_linhas_base()

        if modo == "incluir":
            ja_existe = any(
                m
                and m.group("dieta") == dieta_id
                and m.group("pred") == pred
                and m.group("valor") == valor_cond
                for linha in linhas
                for m in [self.RE_CONTRA.match(linha)]
            )
            if ja_existe:
                return False, "[!] Aviso: essa contraindicacao ja existe."
            idx = self._indice_apos_ultimo(linhas, "contraindicada(")
            linhas.insert(
                idx,
                f"contraindicada({dieta_id}, X) :- {pred}(X, {valor_cond}).\n",
            )
            self._escrever_linhas_base(linhas)
            return True, "[OK] Contraindicacao registrada com sucesso."

        if modo == "alterar":
            pred_old, val_cond_old = self._atributo_valor_para_condicao(attr_old, val_old)
            if not pred_old:
                return False, "[!] Erro: regra antiga invalida."

            alterou = False
            for i, linha in enumerate(linhas):
                m = self.RE_CONTRA.match(linha)
                if (
                    m
                    and m.group("dieta") == dieta_id
                    and m.group("pred") == pred_old
                    and m.group("valor") == val_cond_old
                ):
                    linhas[i] = (
                        f"contraindicada({dieta_id}, X) :- {pred}(X, {valor_cond}).\n"
                    )
                    alterou = True
                    break

            if not alterou:
                return False, "[!] Erro: regra antiga nao encontrada."

            self._escrever_linhas_base(linhas)
            return True, "[OK] Contraindicacao alterada com sucesso."

        return False, "[!] Erro interno de operacao."

    def _excluir_regra_contra(self, dieta_id, attr, val):
        pred, valor_cond = self._atributo_valor_para_condicao(attr, val)
        if not pred:
            return False, "[!] Erro: atributo/valor nao mapeado para uma relacao LPO."

        linhas = self._ler_linhas_base()
        novas = []
        removida = False

        for linha in linhas:
            m = self.RE_CONTRA.match(linha)
            if (
                m
                and m.group("dieta") == dieta_id
                and m.group("pred") == pred
                and m.group("valor") == valor_cond
            ):
                removida = True
                continue
            novas.append(linha)

        if not removida:
            return False, "[!] Erro: contraindicacao nao encontrada."

        self._escrever_linhas_base(novas)
        return True, "[OK] Contraindicacao removida com sucesso."

    # Sessao -----------------------------------------------------------------------------------------------------

    def limpar_sessao(self):
        list(self.prolog.query(f"definir_individuo_atual({self.individuo_atual})"))
        list(self.prolog.query(f"limpar_respostas({self.individuo_atual})"))

    def exibir_cabecalho(self, titulo):
        print("\n" + "=" * 60)
        print(titulo.center(60))
        print("=" * 60)

    # Menu principal ---------------------------------------------------------------------------------------------

    def menu_principal(self):
        while True:
            self.exibir_cabecalho("SISTEMA ESPECIALISTA DE RECOMENDACAO DE DIETAS")
            print("1. Obter Recomendacao de Dieta")
            print("2. Acessar CRUD (Gerenciar Base de Conhecimento)")
            print("3. Realizar Testes Unitarios")
            print("4. Sair")

            opcao = input("\nEscolha uma opcao: ").strip()

            if opcao == "1":
                self.fluxo_recomendacao()
            elif opcao == "2":
                self.menu_crud()
            elif opcao == "3":
                self.realizar_testes()
            elif opcao == "4":
                print("\nEncerrando o sistema. Ate logo!")
                break
            else:
                print("\nOpcao invalida. Tente novamente.")

    # Fluxo de recomendacao -------------------------------------------------------------------------------------

    def fazer_pergunta(self, attr):
        attr_str = safe_str(attr)
        query = f"detalhes_pergunta({attr_str}, Texto, Opcoes, Justificativa)"
        resultados = list(self.prolog.query(query))
        if not resultados:
            return False

        resultado = resultados[0]
        texto = safe_str(resultado["Texto"])
        opcoes = [safe_str(opt) for opt in resultado["Opcoes"]]

        print(f"\n>>> {texto}")
        for i, opt in enumerate(opcoes, 1):
            print(f"    {i}. {opt}")

        while True:
            try:
                idx = int(input("Resposta (numero): ")) - 1
                if 0 <= idx < len(opcoes):
                    escolha = opcoes[idx]
                    list(
                        self.prolog.query(
                            f"registrar_resposta({self.individuo_atual}, {attr_str}, {escolha})"
                        )
                    )
                    return True
                print(f"Por favor, escolha um numero entre 1 e {len(opcoes)}.")
            except ValueError:
                print("Entrada invalida. Digite um numero.")

    def fluxo_recomendacao(self):
        self.limpar_sessao()
        self.exibir_cabecalho("QUESTIONARIO DE PERFIL")

        perguntas_base = list(self.prolog.query("listar_perguntas_base(L)"))[0]["L"]
        for p in perguntas_base:
            self.fazer_pergunta(p)

        respondidas = set()
        while True:
            ativas = list(self.prolog.query("listar_perguntas_condicionais_ativas(L)"))[0]["L"]
            novas = [safe_str(p) for p in ativas if safe_str(p) not in respondidas]
            if not novas:
                break
            for p in novas:
                self.fazer_pergunta(p)
                respondidas.add(p)

        self.exibir_resultados()

    # Resultados e explicabilidade ------------------------------------------------------------------------------

    def exibir_resultados(self):
        while True:
            self.exibir_cabecalho("RESULTADO DO DIAGNOSTICO NUTRICIONAL")
            recoms = []

            resultados = list(
                self.prolog.query(
                    f"dieta(Id, Nome, _), nao_contraindicada(Id, {self.individuo_atual}), calcular_score(Id, {self.individuo_atual}, S)"
                )
            )
            for r in resultados:
                recoms.append(
                    {
                        "id": safe_str(r["Id"]),
                        "nome": safe_str(r["Nome"]),
                        "score": float(r["S"]),
                    }
                )
            recoms.sort(key=lambda x: x["score"], reverse=True)

            if not recoms:
                print("\n[!] Nenhuma dieta aprovada para o perfil informado.")
            else:
                for item in recoms:
                    desc_query = list(self.prolog.query(f"descricao_dieta({item['id']}, Desc)"))
                    descricao = (
                        safe_str(desc_query[0]["Desc"])
                        if desc_query
                        else "Descricao nao cadastrada na base."
                    )
                    print(f"\n[{item['score'] * 100:>3.0f}% ] {item['nome'].upper()}")
                    print(f"       {descricao}")

            print("\n" + "-" * 60)
            print(self.avisos_legais)
            print("-" * 60)

            print("\nOPCOES DE EXPLICACAO:")
            print("1. Por que estas dietas foram escolhidas?")
            print("2. Por que uma dieta foi descartada?")
            print("3. Por que me perguntaram isso?")
            print("4. Voltar ao Menu Principal")

            op = input("\nEscolha: ").strip()
            if op == "1":
                self.explicar_sucesso(recoms)
            elif op == "2":
                self.explicar_exclusao()
            elif op == "3":
                self.explicar_gatilhos()
            elif op == "4":
                break

    def explicar_sucesso(self, recomendacoes):
        print("\n--- JUSTIFICATIVA DE SUCESSO ---")
        if not recomendacoes:
            print("Nenhuma dieta para justificar.")
            input("\nPressione ENTER para voltar...")
            return

        for item in recomendacoes:
            print(f"\n> {item['nome']} ({item['score'] * 100:.0f}%):")
            regras = self._listar_regras_evidencia(item["id"])
            alguma = False
            for r in regras:
                consulta = f"{r['pred']}({self.individuo_atual}, {r['valor']})"
                if list(self.prolog.query(consulta)):
                    alguma = True
                    print(
                        f"  [+] '{r['attr']}' = '{r['attr_val']}'  (+{r['peso'] * 100:.0f}%)"
                    )
            if not alguma:
                print("  (Nenhuma evidencia adicional ativa; score vem da probabilidade base.)")

        input("\nPressione ENTER para voltar...")

    def explicar_exclusao(self):
        excluidas = []
        todas = list(self.prolog.query("dieta(Id, Nome, _)"))
        for d in todas:
            id_d = safe_str(d["Id"])
            regras = self._listar_regras_contra(id_d)
            ativas = []
            for r in regras:
                consulta = f"{r['pred']}({self.individuo_atual}, {r['valor']})"
                if list(self.prolog.query(consulta)):
                    ativas.append(r)
            if ativas:
                excluidas.append({"id": id_d, "nome": safe_str(d["Nome"]), "razoes": ativas})

        if not excluidas:
            print("\nNenhuma dieta foi descartada por contraindicacao neste perfil.")
            input("\nPressione ENTER para voltar...")
            return

        print("\nDietas descartadas nesta sessao:")
        for i, d in enumerate(excluidas, 1):
            print(f"  {i}. {d['nome']}")

        try:
            idx = int(input("Numero (ou 0 para voltar): ")) - 1
            if 0 <= idx < len(excluidas):
                dieta = excluidas[idx]
                print(f"\n--- MOTIVOS DE EXCLUSAO: {dieta['nome']} ---")
                for r in dieta["razoes"]:
                    print(f"  [!] Condicao ativa: '{r['attr']} = {r['attr_val']}'.")
        except ValueError:
            print("Opcao invalida.")

        input("\nPressione ENTER para voltar...")

    def explicar_gatilhos(self):
        pergs = []
        gatilhos = list(self.prolog.query("gatilho_pergunta(Attr, Pai, Val)"))
        for p in gatilhos:
            attr = safe_str(p["Attr"])
            if list(self.prolog.query(f"resposta_usuario({self.individuo_atual}, {attr}, _)")):
                pergs.append(
                    {
                        "attr": attr,
                        "pai": safe_str(p["Pai"]),
                        "val": safe_str(p["Val"]),
                    }
                )

        if not pergs:
            print("\nNenhuma pergunta condicional foi disparada nesta sessao.")
            input("\nPressione ENTER para voltar...")
            return

        print("\nPerguntas condicionais respondidas:")
        for i, p in enumerate(pergs, 1):
            res = list(self.prolog.query(f"detalhes_pergunta({p['attr']}, T, _, _)"))
            if res:
                print(f"  {i}. {safe_str(res[0]['T'])}")

        try:
            idx = int(input("Numero (ou 0 para voltar): ")) - 1
            if 0 <= idx < len(pergs):
                p = pergs[idx]
                print("\n--- EXPLICACAO LOGICA ---")
                print("Esta pergunta apareceu porque voce respondeu antes:")
                print(f"  -> '{p['pai']}' com valor '{p['val']}'.")
        except ValueError:
            print("Opcao invalida.")

        input("\nPressione ENTER para voltar...")

    # Testes -----------------------------------------------------------------------------------------------------

    def realizar_testes(self):
        self.exibir_cabecalho("TESTES UNITARIOS DO SISTEMA")

        if not self._testes_carregados:
            print("\nCarregando suite de testes (testes_unitarios.pl)...")
            try:
                self.prolog.consult(str(self._base_dir / "testes_unitarios.pl"))
                self._testes_carregados = True
                print("[OK] Arquivo carregado.")
            except Exception as e:
                print(f"\n[ERRO] Nao foi possivel carregar testes_unitarios.pl:\n  {e}")
                input("\nPressione ENTER para voltar...")
                return

        print("\n" + "-" * 60)
        print("Iniciando execucao - resultados abaixo:")
        print("-" * 60 + "\n")

        try:
            list(self.prolog.query("executar_testes_sistema"))
            print("\n" + "-" * 60)
            print("[OK] Execucao da suite concluida.")
            print("Legenda: 'passed' = aprovado | 'failed' = reprovado | 'error' = erro inesperado")
        except Exception as e:
            print(f"\n[!] Excecao durante os testes: {e}")

        input("\nPressione ENTER para voltar ao menu...")

    # Helpers CRUD -----------------------------------------------------------------------------------------------

    def selecionar_dieta(self, mensagem="Selecione a Dieta:"):
        dietas = list(self.prolog.query("dieta(Id, Nome, _)"))
        print(f"\n{mensagem}")
        for i, d in enumerate(dietas, 1):
            print(f"{i}. {safe_str(d['Nome'])} ({safe_str(d['Id'])})")

        entrada = input("Escolha (numero): ").strip()
        if not entrada:
            return None
        try:
            idx = int(entrada) - 1
            if 0 <= idx < len(dietas):
                return safe_str(dietas[idx]["Id"])
        except ValueError:
            pass
        print("[!] Opcao invalida.")
        return None

    def selecionar_atributo(self, mensagem="Selecione o Atributo:"):
        attrs = list(self.prolog.query("pergunta(Attr, _, _, _, _)"))
        print(f"\n{mensagem}")
        for i, a in enumerate(attrs, 1):
            print(f"{i}. {safe_str(a['Attr'])}")

        entrada = input("Escolha (numero): ").strip()
        if not entrada:
            return None
        try:
            idx = int(entrada) - 1
            if 0 <= idx < len(attrs):
                return safe_str(attrs[idx]["Attr"])
        except ValueError:
            pass
        print("[!] Opcao invalida.")
        return None

    def selecionar_valor(self, attr):
        res = list(self.prolog.query(f"pergunta({attr}, _, _, Ops, _)"))
        if not res:
            return None
        ops = [safe_str(o) for o in res[0]["Ops"]]

        print(f"\nSelecione o valor para '{attr}':")
        for i, o in enumerate(ops, 1):
            print(f"{i}. {o}")

        entrada = input("Escolha (numero): ").strip()
        if not entrada:
            return None
        try:
            idx = int(entrada) - 1
            if 0 <= idx < len(ops):
                return ops[idx]
        except ValueError:
            pass
        print("[!] Opcao invalida.")
        return None

    # Menu CRUD --------------------------------------------------------------------------------------------------

    def menu_crud(self):
        while True:
            self.exibir_cabecalho("GERENCIADOR DA BASE DE CONHECIMENTO")
            print("1. Gerenciar Dietas")
            print("2. Gerenciar Evidencias (Suportes)")
            print("3. Gerenciar Contraindicacoes (Restricoes)")
            print("4. Voltar")
            opcao = input("\nEscolha: ").strip()
            if opcao == "1":
                self.submenu_dietas()
            elif opcao == "2":
                self.submenu_suportes()
            elif opcao == "3":
                self.submenu_exclusoes()
            elif opcao == "4":
                break

    def submenu_dietas(self):
        while True:
            print("\n--- DIETAS ---")
            print("1. Listar | 2. Adicionar | 3. Alterar | 4. Remover | 5. Voltar")
            op = input("Opcao: ").strip()

            if op == "1":
                for d in self.prolog.query("dieta(Id, Nome, P)"):
                    print(f" - {safe_str(d['Id'])}: {safe_str(d['Nome'])} ({float(d['P']):.2f})")

            elif op in {"2", "3"}:
                if op == "2":
                    id_d = input("ID interno (ex: dieta_nova): ").strip().lower()
                else:
                    id_d = self.selecionar_dieta("Selecione a dieta para alterar:")
                if not id_d:
                    continue

                nome = input("Nome de exibicao: ").strip()
                desc = input("Descricao: ").strip()
                if not nome or not desc:
                    print("[!] Nome e descricao sao obrigatorios.")
                    continue

                try:
                    prob = float(input("Probabilidade base (0.0 a 1.0): ").strip())
                    if not (0 <= prob <= 1):
                        raise ValueError
                except ValueError:
                    print("[!] Probabilidade invalida.")
                    continue

                if op == "2":
                    ok, msg = self._incluir_dieta_arquivo(id_d, nome, prob, desc)
                else:
                    ok, msg = self._alterar_dieta_arquivo(id_d, nome, prob, desc)
                print(msg)

            elif op == "4":
                id_d = self.selecionar_dieta("Selecione a dieta para remover:")
                if id_d:
                    _, msg = self._excluir_dieta_arquivo(id_d)
                    print(msg)

            elif op == "5":
                break

    def submenu_suportes(self):
        while True:
            print("\n--- EVIDENCIAS HEURISTICAS (SUPORTES) ---")
            print("1. Listar | 2. Adicionar | 3. Alterar Peso | 4. Remover | 5. Voltar")
            op = input("Opcao: ").strip()

            if op == "1":
                id_d = self.selecionar_dieta()
                if id_d:
                    regras = self._listar_regras_evidencia(id_d)
                    if not regras:
                        print(f"\nNenhuma evidencia para '{id_d}'.")
                    for r in regras:
                        print(
                            f" -> Se '{r['attr']}' for '{r['attr_val']}', soma +{r['peso'] * 100:.0f}%"
                        )

            elif op in {"2", "3"}:
                id_d = self.selecionar_dieta()
                if not id_d:
                    continue
                attr = self.selecionar_atributo()
                if not attr:
                    continue
                val = self.selecionar_valor(attr)
                if not val:
                    continue
                try:
                    peso = float(input("Digite o peso (0.0 a 1.0): ").strip())
                    if not (0 <= peso <= 1):
                        raise ValueError
                except ValueError:
                    print("[!] Peso invalido.")
                    continue

                modo = "incluir" if op == "2" else "alterar"
                _, msg = self._salvar_regra_evidencia(id_d, attr, val, peso, modo)
                print(msg)

            elif op == "4":
                id_d = self.selecionar_dieta()
                if not id_d:
                    continue
                attr = self.selecionar_atributo()
                if not attr:
                    continue
                val = self.selecionar_valor(attr)
                if not val:
                    continue
                _, msg = self._excluir_regra_evidencia(id_d, attr, val)
                print(msg)

            elif op == "5":
                break

    def submenu_exclusoes(self):
        while True:
            print("\n--- CONTRAINDICACOES (RESTRICOES) ---")
            print("1. Listar | 2. Adicionar | 3. Alterar | 4. Remover | 5. Voltar")
            op = input("Opcao: ").strip()

            if op == "1":
                id_d = self.selecionar_dieta()
                if id_d:
                    regras = self._listar_regras_contra(id_d)
                    if not regras:
                        print(f"\nNenhuma contraindicacao para '{id_d}'.")
                    for r in regras:
                        print(f" -> BLOQUEIA se '{r['attr']}' for '{r['attr_val']}'")

            elif op == "2":
                id_d = self.selecionar_dieta()
                if not id_d:
                    continue
                attr = self.selecionar_atributo("Atributo da restricao:")
                if not attr:
                    continue
                val = self.selecionar_valor(attr)
                if not val:
                    continue
                _, msg = self._salvar_regra_contra(id_d, attr, val, "incluir")
                print(msg)

            elif op == "3":
                id_d = self.selecionar_dieta()
                if not id_d:
                    continue
                print("\nSelecione a regra antiga:")
                attr_old = self.selecionar_atributo()
                if not attr_old:
                    continue
                val_old = self.selecionar_valor(attr_old)
                if not val_old:
                    continue
                print("\nSelecione os novos parametros:")
                attr_new = self.selecionar_atributo("Novo atributo:")
                if not attr_new:
                    continue
                val_new = self.selecionar_valor(attr_new)
                if not val_new:
                    continue
                _, msg = self._salvar_regra_contra(
                    id_d,
                    attr_new,
                    val_new,
                    "alterar",
                    attr_old=attr_old,
                    val_old=val_old,
                )
                print(msg)

            elif op == "4":
                id_d = self.selecionar_dieta()
                if not id_d:
                    continue
                attr = self.selecionar_atributo()
                if not attr:
                    continue
                val = self.selecionar_valor(attr)
                if not val:
                    continue
                _, msg = self._excluir_regra_contra(id_d, attr, val)
                print(msg)

            elif op == "5":
                break


if __name__ == "__main__":
    app = SistemaEspecialistaDietas()
    app.menu_principal()
