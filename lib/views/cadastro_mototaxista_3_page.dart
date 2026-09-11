import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/model/mototaxista_cadastro.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';
import 'package:route_pires_flutter/views/campo_formulario.dart';
import 'package:route_pires_flutter/views/termos_de_uso.dart';

class CadastroMototaxista3Page extends StatefulWidget {
  final String nome;
  final String email;
  final String telefone;
  final String senha;

  final String cnh;
  final String dataValidade;

  final String placa;
  final String renavam;
  final String modelo;
  final String ano;
  final bool aceitouTermos;

  const CadastroMototaxista3Page({
    super.key,
    this.nome = "",
    this.email = "",
    this.telefone = "",
    this.senha = "",
    this.cnh = "",
    this.dataValidade = "",
    this.placa = "",
    this.renavam = "",
    this.modelo = "",
    this.ano = "",
    this.aceitouTermos = false,
  });

  @override
  State<CadastroMototaxista3Page> createState() =>
      _CadastroMototaxista3PageState();
}

class _CadastroMototaxista3PageState extends State<CadastroMototaxista3Page> {
  final _formKey = GlobalKey<FormState>();

  final _placaController = TextEditingController();
  final _renavamController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anoController = TextEditingController();

  bool aceitouTermos = false;

  @override
  void initState() {
    super.initState();

    // RECUPERA OS DADOS ANTERIORES
    _placaController.text = widget.placa;
    _renavamController.text = widget.renavam;
    _modeloController.text = widget.modelo;
    _anoController.text = widget.ano;

    aceitouTermos = widget.aceitouTermos;
  }

  @override
  void dispose() {
    _placaController.dispose();
    _renavamController.dispose();
    _modeloController.dispose();
    _anoController.dispose();

    super.dispose();
  }

  String formatarPlaca(String valor) {
    valor = valor.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

    if (valor.length > 7) {
      valor = valor.substring(0, 7);
    }

    return valor;
  }

  Future<void> finalizarCadastro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cadastro = MototaxistaCadastro(
      nome: widget.nome.trim(),
      email: widget.email.trim(),
      senha: widget.senha,
      telefone: widget.telefone,
      cnh: widget.cnh.trim(),
      placa: _placaController.text.trim(),
      renavam: _renavamController.text.trim(),
      modelo: _modeloController.text.trim(),
      ano: _anoController.text.trim(),
    );

    final cadastroViewModel = context.read<MototaxistaViewModel>();

    final cadastrou = await cadastroViewModel.cadastrar(cadastro);

    if (!mounted) {
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(cadastrou ? 'Cadastro realizado' : 'Erro no cadastro'),
        content: Text(
          cadastrou
              ? 'Seu cadastro de mototaxista foi concluído.'
              : (cadastroViewModel.erro ??
                    'Não foi possível concluir o cadastro'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);

              if (cadastrou) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void voltar() {
    Navigator.pop(context, {
      "placa": _placaController.text,
      "renavam": _renavamController.text,
      "modelo": _modeloController.text,
      "ano": _anoController.text,
      "aceitouTermos": aceitouTermos,
    });
  }

  @override
  Widget build(BuildContext context) {
    final cadastroViewModel = context.watch<MototaxistaViewModel>();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,

      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,

        middle: const Text("Cadastro de Mototaxista - Passo 3/3"),

        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: voltar,
          child: const Icon(CupertinoIcons.back),
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
                const SizedBox(height: 10),

                // =========================
                // PLACA
                // =========================
                CampoFormulario(
                  label: "Placa da moto",
                  placeholder: "ABC1D23",
                  controller: _placaController,
                  keyboardType: TextInputType.text,

                  onChanged: (valor) {
                    final placa = formatarPlaca(valor);

                    _placaController.value = TextEditingValue(
                      text: placa,
                      selection: TextSelection.collapsed(offset: placa.length),
                    );
                  },

                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return "Informe a placa da moto";
                    }

                    final regex = RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$');

                    if (!regex.hasMatch(valor)) {
                      return "Informe uma placa válida";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // =========================
                // RENAVAM
                // =========================
                CampoFormulario(
                  label: "RENAVAM",
                  placeholder: "Digite o RENAVAM",
                  controller: _renavamController,
                  keyboardType: TextInputType.number,

                  onChanged: (valor) {
                    valor = valor.replaceAll(RegExp(r'\D'), '');

                    if (valor.length > 11) {
                      valor = valor.substring(0, 11);
                    }

                    _renavamController.value = TextEditingValue(
                      text: valor,
                      selection: TextSelection.collapsed(offset: valor.length),
                    );
                  },

                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return "Informe o RENAVAM";
                    }

                    final regex = RegExp(r'^\d{11}$');

                    if (!regex.hasMatch(valor)) {
                      return "O RENAVAM deve possuir 11 números";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // =========================
                // MODELO
                // =========================
                CampoFormulario(
                  label: "Modelo da moto",
                  placeholder: "Honda CG 150",
                  controller: _modeloController,

                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return "Informe o modelo da moto";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // =========================
                // ANO
                // =========================
                CampoFormulario(
                  label: "Ano da moto",
                  placeholder: "Ex: 2024",
                  controller: _anoController,
                  keyboardType: TextInputType.number,

                  onChanged: (valor) {
                    valor = valor.replaceAll(RegExp(r'\D'), '');

                    if (valor.length > 4) {
                      valor = valor.substring(0, 4);
                    }

                    _anoController.value = TextEditingValue(
                      text: valor,
                      selection: TextSelection.collapsed(offset: valor.length),
                    );
                  },

                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return "Informe o ano da moto";
                    }

                    final regex = RegExp(r'^\d{4}$');

                    if (!regex.hasMatch(valor)) {
                      return "Informe um ano válido";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // =========================
                // TERMOS DE USO
                // =========================
                TermosDeUso(
                  aceitouTermos: aceitouTermos,
                  onChanged: (valor) {
                    setState(() {
                      aceitouTermos = valor;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // =========================
                // BOTÃO FINALIZAR
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),

                  child: SizedBox(
                    width: double.infinity,
                    height: 48,

                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: const Color(0xFF006FFD),
                      borderRadius: BorderRadius.circular(12),

                      onPressed: cadastroViewModel.carregando
                          ? null
                          : finalizarCadastro,

                      child: cadastroViewModel.carregando
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text(
                              "FINALIZAR CADASTRO",
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
