import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/cadastro_passageiro_viewmodel.dart';
import 'package:route_pires_flutter/views/campo_formulario.dart';
import 'package:route_pires_flutter/views/termos_de_uso.dart';

class CadastroPassageiroPage extends StatefulWidget {
  const CadastroPassageiroPage({super.key});

  @override
  State<CadastroPassageiroPage> createState() => _CadastroPassageiroPageState();
}

class _CadastroPassageiroPageState extends State<CadastroPassageiroPage> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  // ============================================================
  // ESTADOS
  // ============================================================

  bool termosAceitos = false;
  bool termosErro = false;

  bool senhaVisivel = false;
  bool confirmarSenhaVisivel = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();

    super.dispose();
  }

  // ============================================================
  // FINALIZAR CADASTRO
  // ============================================================

  Future<void> finalizarCadastro() async {
    final formValido = _formKey.currentState!.validate();

    setState(() {
      termosErro = !termosAceitos;
    });

    if (!formValido || !termosAceitos) {
      return;
    }

    final viewModel = context.read<CadastroPassageiroViewModel>();

    final ok = await viewModel.cadastrar(
      nome: nomeController.text.trim(),
      email: emailController.text.trim(),
      telefone: telefoneController.text,
      senha: senhaController.text,
    );

    if (!mounted) return;

    // ==========================================================
    // CADASTRO REALIZADO
    // ==========================================================

    if (ok) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Cadastro'),
          content: Text(
            'Cadastro realizado. Bem-vindo, '
            '${nomeController.text.trim()}!',
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

    // ==========================================================
    // ERRO NO CADASTRO
    // ==========================================================

    _mostrarMensagem(viewModel.erro ?? 'Erro ao realizar cadastro');
  }

  // ============================================================
  // MENSAGEM DE ERRO
  // ============================================================

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

  // ============================================================
  // FORMATAÇÃO TELEFONE
  // ============================================================

  String formatarTelefone(String valor) {
    valor = valor.replaceAll(RegExp(r'\D'), '');

    if (valor.length > 11) {
      valor = valor.substring(0, 11);
    }

    if (valor.length <= 2) {
      return '($valor';
    }

    if (valor.length <= 7) {
      return '(${valor.substring(0, 2)}) '
          '${valor.substring(2)}';
    }

    return '(${valor.substring(0, 2)}) '
        '${valor.substring(2, 7)}-'
        '${valor.substring(7)}';
  }

  // ============================================================
  // TELA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CadastroPassageiroViewModel>();

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFFFFFFF),

      // ========================================================
      // BARRA SUPERIOR
      // ========================================================
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text(
          'Cadastro de Passageiro',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),

      // ========================================================
      // CONTEÚDO
      // ========================================================
      child: SizedBox(
        width: double.infinity,

        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ==================================================
                // ESPAÇAMENTO SUPERIOR
                // ==================================================

                const SizedBox(height: 24),

                // ==================================================
                // TÍTULO
                // ==================================================
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

                // ==================================================
                // NOME
                // ==================================================
                CampoFormulario(
                  label: 'Nome completo',
                  placeholder: 'Digite seu nome completo',
                  controller: nomeController,

                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe seu nome';
                    }

                    return null;
                  },
                ),

                // ==================================================
                // E-MAIL
                // ==================================================
                CampoFormulario(
                  label: 'E-mail',
                  placeholder: 'nome@email.com',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,

                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe seu e-mail';
                    }

                    if (!valor.contains('@')) {
                      return 'Informe um e-mail válido';
                    }

                    return null;
                  },
                ),

                // ==================================================
                // TELEFONE
                // ==================================================
                CampoFormulario(
                  label: 'Número de telefone',
                  placeholder: '(64) 91234-5678',
                  controller: telefoneController,
                  keyboardType: TextInputType.phone,

                  onChanged: (valor) {
                    final telefone = formatarTelefone(valor);

                    telefoneController.value = TextEditingValue(
                      text: telefone,
                      selection: TextSelection.collapsed(
                        offset: telefone.length,
                      ),
                    );
                  },

                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe seu telefone';
                    }

                    if (!RegExp(r'^\(\d{2}\) \d{5}-\d{4}$').hasMatch(valor)) {
                      return 'Informe um telefone válido';
                    }

                    return null;
                  },
                ),

                // ==================================================
                // SENHA
                // ==================================================
                CampoFormulario(
                  label: 'Senha',
                  placeholder: 'Crie uma senha',
                  controller: senhaController,

                  senha: true,

                  obscureText: !senhaVisivel,

                  onTap: () {
                    setState(() {
                      senhaVisivel = !senhaVisivel;
                    });
                  },

                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Crie a senha';
                    }

                    if (valor.length < 8) {
                      return 'A senha deve ter pelo menos 8 caracteres';
                    }

                    return null;
                  },
                ),

                // ==================================================
                // CONFIRMAR SENHA
                // ==================================================
                CampoFormulario(
                  label: 'Confirmar senha',
                  placeholder: 'Confirme a senha',
                  controller: confirmarSenhaController,

                  senha: true,

                  obscureText: !confirmarSenhaVisivel,

                  onTap: () {
                    setState(() {
                      confirmarSenhaVisivel = !confirmarSenhaVisivel;
                    });
                  },

                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Confirme sua senha';
                    }

                    if (valor != senhaController.text) {
                      return 'As senhas não coincidem';
                    }

                    return null;
                  },
                ),

                // ==================================================
                // ESPAÇAMENTO
                // ==================================================
                const SizedBox(height: 8),

                // ==================================================
                // TERMOS DE USO
                // ==================================================
                TermosDeUso(
                  aceitouTermos: termosAceitos,

                  onChanged: (valor) {
                    setState(() {
                      termosAceitos = valor;
                      termosErro = false;
                    });
                  },
                ),

                // ==================================================
                // ERRO DOS TERMOS
                // ==================================================
                if (termosErro)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(left: 29, right: 24, top: 5),
                    child: const Text(
                      'Você precisa aceitar os termos de uso',
                      style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 12,
                      ),
                    ),
                  ),

                // ==================================================
                // ESPAÇAMENTO
                // ==================================================
                const SizedBox(height: 20),

                // ==================================================
                // BOTÃO FINALIZAR
                // ==================================================
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

                // ==================================================
                // ESPAÇO FINAL
                // ==================================================
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
