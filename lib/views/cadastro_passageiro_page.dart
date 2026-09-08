import 'package:flutter/cupertino.dart';

class CadastroPassageiroPage extends StatefulWidget {
  const CadastroPassageiroPage({super.key});

  @override
  State<CadastroPassageiroPage> createState() => _CadastroPassageiroPageState();
}

class _CadastroPassageiroPageState extends State<CadastroPassageiroPage> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  bool termosAceitos = false;
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

  void finalizarCadastro() {
    if (nomeController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        telefoneController.text.trim().isEmpty ||
        senhaController.text.isEmpty ||
        confirmarSenhaController.text.isEmpty) {
      _mostrarMensagem('Preencha todos os campos.');
      return;
    }

    if (senhaController.text != confirmarSenhaController.text) {
      _mostrarMensagem('As senhas não conferem.');
      return;
    }

    if (!termosAceitos) {
      _mostrarMensagem('Aceite os termos de uso e a política de privacidade.');
      return;
    }

    _mostrarMensagem(
      'Formulário válido. A integração com a API de cadastro ainda não foi configurada.',
    );
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: SafeArea(
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
              ),
              _CampoCadastro(
                label: 'E-mail',
                placeholder: 'nome@email.com',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _CampoCadastro(
                label: 'Número de telefone',
                placeholder: '(64) 12345-6789',
                controller: telefoneController,
                keyboardType: TextInputType.phone,
              ),
              _CampoCadastro(
                label: 'Senha',
                placeholder: 'Crie uma senha',
                controller: senhaController,
                obscureText: !senhaVisivel,
                onToggleObscure: () {
                  setState(() => senhaVisivel = !senhaVisivel);
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
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoCheckbox(
                    value: termosAceitos,
                    activeColor: const Color(0xFF006FFD),
                    onChanged: (value) {
                      setState(() => termosAceitos = value ?? false);
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
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: CupertinoButton(
                  color: const Color(0xFF006FFD),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: finalizarCadastro,
                  child: const Text(
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
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final VoidCallback? onToggleObscure;

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
          CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            style: const TextStyle(fontSize: 18, color: Color(0xFF1F2024)),
            placeholderStyle: const TextStyle(
              fontSize: 18,
              color: Color(0xFF8F9098),
            ),
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
              border: Border.all(color: const Color(0xFFC5C6CC)),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ],
      ),
    );
  }
}
