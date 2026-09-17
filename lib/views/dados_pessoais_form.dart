import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/config/validacao.dart';
import 'package:route_pires_flutter/views/campo_formulario.dart';

class DadosPessoaisForm extends StatefulWidget {
  const DadosPessoaisForm({super.key});

  @override
  State<DadosPessoaisForm> createState() => DadosPessoaisFormState();
}

class DadosPessoaisFormState extends State<DadosPessoaisForm> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  bool senhaVisivel = false;
  bool confirmarSenhaVisivel = false;

  String get nome => nomeController.text;
  String get email => emailController.text;
  String get telefone => telefoneController.text;
  String get senha => senhaController.text;

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        CampoFormulario(
          label: 'Número de telefone',
          placeholder: '(64) 91234-5678',
          controller: telefoneController,
          keyboardType: TextInputType.phone,
          onChanged: (valor) {
            final telefone = formatarTelefone(valor);
            telefoneController.value = TextEditingValue(
              text: telefone,
              selection: TextSelection.collapsed(offset: telefone.length),
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
        CampoFormulario(
          label: 'Senha',
          placeholder: 'Crie uma senha',
          controller: senhaController,
          senha: true,
          obscureText: !senhaVisivel,
          onTap: () => setState(() => senhaVisivel = !senhaVisivel),
          validator: (valor) {
            if (valor == null || valor.trim().isEmpty) {
              return 'Crie a senha';
            }
            if (!senhaValida(valor)) {
              return mensagemSenhaInvalida;
            }
            return null;
          },
        ),
        CampoFormulario(
          label: 'Confirmar senha',
          placeholder: 'Confirme a senha',
          controller: confirmarSenhaController,
          senha: true,
          obscureText: !confirmarSenhaVisivel,
          onTap: () =>
              setState(() => confirmarSenhaVisivel = !confirmarSenhaVisivel),
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
      ],
    );
  }
}
