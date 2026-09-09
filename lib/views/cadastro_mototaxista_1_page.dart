import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:route_pires_flutter/views/cadastro_mototaxista_2_page.dart';
import 'package:route_pires_flutter/views/campo_formulario.dart';

class CadastroMototaxista1Page extends StatefulWidget {
  const CadastroMototaxista1Page({super.key});

  @override
  State<CadastroMototaxista1Page> createState() =>
      _CadastroMototaxista1PageState();
}

class _CadastroMototaxista1PageState extends State<CadastroMototaxista1Page> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _senhaConfirmacaoController = TextEditingController();

  bool isObscureSenha = true;
  bool isObscureConfirmacaoSenha = true;

  String cnh = "";
  String dataValidade = "";

  String placa = "";
  String renavam = "";
  String ano = "";
  bool aceitouTermos = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _senhaConfirmacaoController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.white,

      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Colors.white,
        middle: Text("Cadastro de Mototaxista - Passo 1/3"),
      ),

      child: SafeArea(
        child: Form(
          key: _formKey,

          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),

            children: [
              // NOME
              CampoFormulario(
                label: "Nome Completo",
                placeholder: "Digite seu nome completo",
                controller: _nomeController,

                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return "Informe seu nome";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // E-MAIL
              CampoFormulario(
                label: "E-mail",
                placeholder: "nome@email.com",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,

                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return "Informe seu e-mail";
                  }

                  if (!valor.contains("@")) {
                    return "Informe um e-mail válido";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // TELEFONE
              CampoFormulario(
                label: "Número de telefone",
                placeholder: "(64) 91234-5678",
                controller: _telefoneController,
                keyboardType: TextInputType.phone,

                onChanged: (valor) {
                  String telefone = formatarTelefone(valor);

                  _telefoneController.value = TextEditingValue(
                    text: telefone,
                    selection: TextSelection.collapsed(offset: telefone.length),
                  );
                },

                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return "Informe seu telefone";
                  }

                  RegExp regex = RegExp(r'^\(\d{2}\) \d{5}-\d{4}$');

                  if (!regex.hasMatch(valor)) {
                    return "Informe um telefone válido";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // SENHA
              CampoFormulario(
                label: "Senha",
                placeholder: "Crie uma senha",
                controller: _senhaController,
                senha: true,
                obscureText: isObscureSenha,

                onTap: () {
                  setState(() {
                    isObscureSenha = !isObscureSenha;
                  });
                },

                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return "Crie a senha";
                  }

                  if (valor.length < 8) {
                    return "A senha deve ter pelo menos 8 caracteres";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // CONFIRMAR SENHA
              CampoFormulario(
                label: "Confirmar senha",
                placeholder: "Confirme a senha",
                controller: _senhaConfirmacaoController,
                senha: true,
                obscureText: isObscureConfirmacaoSenha,

                onTap: () {
                  setState(() {
                    isObscureConfirmacaoSenha = !isObscureConfirmacaoSenha;
                  });
                },

                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return "Confirme sua senha";
                  }

                  if (valor != _senhaController.text) {
                    return "As senhas não coincidem";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              // BOTÃO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: CupertinoButton.filled(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final resultado = await Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => CadastroMototaxista2Page(
                            nome: _nomeController.text,
                            email: _emailController.text,
                            telefone: _telefoneController.text,
                            senha: _senhaController.text,

                            cnh: cnh,
                            dataValidade: dataValidade,

                            placa: placa,
                            renavam: renavam,
                            ano: ano,
                            aceitouTermos: aceitouTermos,
                          ),
                        ),
                      );

                      // RECEBE OS DADOS DA PÁGINA 2
                      if (resultado != null) {
                        setState(() {
                          cnh = resultado["cnh"];
                          dataValidade = resultado["dataValidade"];

                          placa = resultado["placa"];
                          renavam = resultado["renavam"];
                          ano = resultado["ano"];
                          aceitouTermos = resultado["aceitouTermos"];
                        });
                      }
                    }
                  },

                  child: const Text("Próximo Passo"),
                ),
              ),
            ],
          ),
        ),
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
}
