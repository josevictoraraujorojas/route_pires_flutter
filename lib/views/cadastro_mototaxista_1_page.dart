import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';
import 'package:route_pires_flutter/views/cadastro_mototaxista_2_page.dart';
import 'package:route_pires_flutter/views/dados_pessoais_form.dart';

class CadastroMototaxista1Page extends StatefulWidget {
  const CadastroMototaxista1Page({super.key});

  @override
  State<CadastroMototaxista1Page> createState() =>
      _CadastroMototaxista1PageState();
}

class _CadastroMototaxista1PageState extends State<CadastroMototaxista1Page> {
  final _formKey = GlobalKey<FormState>();
  final _dadosKey = GlobalKey<DadosPessoaisFormState>();

  Future<void> irParaProximoPasso() async {
    if (!_formKey.currentState!.validate()) return;
    final dados = _dadosKey.currentState;
    if (dados == null) return;
    final rascunho = context.read<MototaxistaViewModel>().rascunho;
    rascunho.nome = dados.nome;
    rascunho.email = dados.email;
    rascunho.telefone = dados.telefone;
    rascunho.senha = dados.senha;
    await Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const CadastroMototaxista2Page()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text(
          'Cadastro de Mototaxista - Passo 1/3',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Text(
                    'Crie sua conta',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                DadosPessoaisForm(key: _dadosKey),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: const Color(0xFF006FFD),
                      borderRadius: BorderRadius.circular(10),
                      onPressed: irParaProximoPasso,
                      child: const Text(
                        'PRÓXIMO PASSO',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
