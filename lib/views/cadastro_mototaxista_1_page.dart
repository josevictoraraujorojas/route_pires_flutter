import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/config/validacao.dart';
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

  // Dados das próximas páginas
  String cnh = "";
  String dataValidade = "";

  String placa = "";
  String renavam = "";
  String modelo = "";
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

  Future<void> irParaProximoPasso() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
          modelo: modelo,
          ano: ano,

          aceitouTermos: aceitouTermos,
        ),
      ),
    );

    if (resultado != null) {
      setState(() {
        cnh = resultado["cnh"];
        dataValidade = resultado["dataValidade"];

        placa = resultado["placa"];
        renavam = resultado["renavam"];
        modelo = resultado["modelo"];
        ano = resultado["ano"];

        aceitouTermos = resultado["aceitouTermos"];
      });
    }
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

                CampoFormulario(
                  label: 'Nome completo',
                  placeholder: 'Digite seu nome completo',
                  controller: _nomeController,

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
                  controller: _emailController,
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
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,

                  onChanged: (valor) {
                    final telefone = formatarTelefone(valor);

                    _telefoneController.value = TextEditingValue(
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

                    final regex = RegExp(r'^\(\d{2}\) \d{5}-\d{4}$');

                    if (!regex.hasMatch(valor)) {
                      return 'Informe um telefone válido';
                    }

                    return null;
                  },
                ),

                CampoFormulario(
                  label: 'Senha',
                  placeholder: 'Crie uma senha',
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
                      return 'Confirme sua senha';
                    }

                    if (valor != _senhaController.text) {
                      return 'As senhas não coincidem';
                    }

                    return null;
                  },
                ),

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
