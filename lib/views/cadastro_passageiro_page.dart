import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/cadastro_passageiro_viewmodel.dart';
import 'package:route_pires_flutter/views/dados_pessoais_form.dart';
import 'package:route_pires_flutter/views/termos_de_uso.dart';

class CadastroPassageiroPage extends StatefulWidget {
  const CadastroPassageiroPage({super.key});

  @override
  State<CadastroPassageiroPage> createState() => _CadastroPassageiroPageState();
}

class _CadastroPassageiroPageState extends State<CadastroPassageiroPage> {
  final _formKey = GlobalKey<FormState>();
  final _dadosKey = GlobalKey<DadosPessoaisFormState>();

  bool termosAceitos = false;

  Future<void> finalizarCadastro() async {
    final formValido = _formKey.currentState!.validate();
    if (!formValido) return;
    final dados = _dadosKey.currentState;
    if (dados == null) return;

    final viewModel = context.read<CadastroPassageiroViewModel>();

    final ok = await viewModel.cadastrar(
      nome: dados.nome.trim(),
      email: dados.email.trim(),
      telefone: dados.telefone,
      senha: dados.senha,
    );

    if (!mounted) return;

    if (ok) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Cadastro'),
          content: Text(
            'Cadastro realizado. Bem-vindo, '
            '${dados.nome.trim()}!',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      Navigator.pop(context);
      return;
    }

    _mostrarMensagem(viewModel.erro ?? 'Erro ao realizar cadastro');
  }

  void _mostrarMensagem(String mensagem) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Cadastro'),
        content: Text(mensagem),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CadastroPassageiroViewModel>();

    return PopScope(
      canPop: !viewModel.carregando,
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFFFFFFFF),

        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: !viewModel.carregando,
          backgroundColor: CupertinoColors.white,
          middle: const Text(
            'Cadastro de Passageiro',
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

                  const SizedBox(height: 8),

                  TermosDeUso(
                    aceitouTermos: termosAceitos,

                    onChanged: (valor) {
                      setState(() {
                        termosAceitos = valor;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),

                    child: SizedBox(
                      width: double.infinity,
                      height: 48,

                      child: CupertinoButton(
                        padding: EdgeInsets.zero,

                        color: const Color(0xFF006FFD),

                        borderRadius: BorderRadius.circular(10),

                        onPressed: viewModel.carregando
                            ? null
                            : finalizarCadastro,

                        child: viewModel.carregando
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white,
                              )
                            : const Text(
                                'FINALIZAR',
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
      ),
    );
  }
}
