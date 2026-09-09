import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/cadastro_passageiro_viewmodel.dart';

class CadastroPassageiroPage extends StatefulWidget {
  const CadastroPassageiroPage({super.key});

  @override
  State<CadastroPassageiroPage> createState() => _CadastroPassageiroPageState();
}

class _CadastroPassageiroPageState extends State<CadastroPassageiroPage> {
  final _formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  bool termosAceitos = false;
  bool termosErro = false;
  bool senhaVisivel = false;
  bool confirmarSenhaVisivel = false;

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> finalizarCadastro() async {
    final formValido = _formKey.currentState!.validate();
    setState(() => termosErro = !termosAceitos);

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

    if (ok) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Cadastro'),
          content: Text(
            'Cadastro realizado. Bem-vindo, ${nomeController.text.trim()}!',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String formatarTelefone(String valor) {
    valor = valor.replaceAll(RegExp(r'\D'), '');

    if (valor.length > 11) {
      valor = valor.substring(0, 11);
    }

    if (valor.length <= 2) {
      return '($valor';
    }

    if (valor.length <= 7) {
      return '(${valor.substring(0, 2)}) ${valor.substring(2)}';
    }

    return '(${valor.substring(0, 2)}) '
        '${valor.substring(2, 7)}-'
        '${valor.substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CadastroPassageiroViewModel>();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(
                    CupertinoIcons.chevron_left,
                    size: 36,
                    color: Color(0xFF006FFD),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cadastro de passageiro',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 42),
                _CampoCadastro(
                  label: 'Nome completo',
                  placeholder: 'Digite seu nome completo',
                  controller: nomeController,
                  textCapitalization: TextCapitalization.words,
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe seu nome';
                    }
                    return null;
                  },
                ),
                _CampoCadastro(
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
                _CampoCadastro(
                  label: 'Número de telefone',
                  placeholder: '(64) 12345-6789',
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
                _CampoCadastro(
                  label: 'Senha',
                  placeholder: 'Crie uma senha',
                  controller: senhaController,
                  obscureText: !senhaVisivel,
                  onToggleObscure: () {
                    setState(() => senhaVisivel = !senhaVisivel);
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
                _CampoCadastro(
                  label: 'Confirmar senha',
                  placeholder: 'Confirme a senha',
                  controller: confirmarSenhaController,
                  obscureText: !confirmarSenhaVisivel,
                  onToggleObscure: () {
                    setState(
                      () => confirmarSenhaVisivel = !confirmarSenhaVisivel,
                    );
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
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CupertinoCheckbox(
                      value: termosAceitos,
                      activeColor: const Color(0xFF006FFD),
                      onChanged: (value) {
                        setState(() {
                          termosAceitos = value ?? false;
                          if (termosAceitos) {
                            termosErro = false;
                          }
                        });
                      },
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 8, left: 8),
                        child: Text(
                          'Li e concordo com os Termos de uso e a Política de Privacidade',
                          style: TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (termosErro)
                  const Padding(
                    padding: EdgeInsets.only(top: 5, left: 5),
                    child: Text(
                      'Aceite os termos de uso e a política de privacidade.',
                      style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: CupertinoButton(
                    color: const Color(0xFF006FFD),
                    borderRadius: BorderRadius.circular(16),
                    onPressed: viewModel.carregando ? null : finalizarCadastro,
                    child: viewModel.carregando
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text(
                            'FINALIZAR',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoCadastro extends StatelessWidget {
  const _CampoCadastro({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.onToggleObscure,
    this.onChanged,
    this.validator,
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, color: CupertinoColors.black),
          ),
          const SizedBox(height: 10),
          FormField<String>(
            initialValue: controller.text,
            validator: validator,
            builder: (campo) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoTextField(
                    controller: controller,
                    placeholder: placeholder,
                    keyboardType: keyboardType,
                    textCapitalization: textCapitalization,
                    obscureText: obscureText,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF1F2024),
                    ),
                    placeholderStyle: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF8F9098),
                    ),
                    onChanged: (valor) {
                      onChanged?.call(valor);
                      campo.didChange(controller.text);
                    },
                    suffix: onToggleObscure == null
                        ? null
                        : CupertinoButton(
                            padding: const EdgeInsets.only(right: 12),
                            onPressed: onToggleObscure,
                            child: Icon(
                              obscureText
                                  ? CupertinoIcons.eye_slash_fill
                                  : CupertinoIcons.eye_fill,
                              color: const Color(0xFF8F9098),
                            ),
                          ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: campo.hasError
                            ? CupertinoColors.systemRed
                            : const Color(0xFFC5C6CC),
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  if (campo.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 5, left: 5),
                      child: Text(
                        campo.errorText!,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
