import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:route_pires_flutter/views/cadastro_mototaxista_3_page.dart';
import 'package:route_pires_flutter/views/campo_formulario.dart';

class CadastroMototaxista2Page extends StatefulWidget {
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

  const CadastroMototaxista2Page({
    super.key,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.senha,
    this.cnh = "",
    this.dataValidade = "",
    this.placa = "",
    this.renavam = "",
    this.modelo = "",
    this.ano = "",
    this.aceitouTermos = false,
  });

  @override
  State<CadastroMototaxista2Page> createState() =>
      _CadastroMototaxista2PageState();
}

class _CadastroMototaxista2PageState extends State<CadastroMototaxista2Page> {
  final _formKey = GlobalKey<FormState>();

  final _cnhController = TextEditingController();
  final _dataValidadeController = TextEditingController();

  // DADOS DA PÁGINA 3
  String placa = "";
  String renavam = "";
  String modelo = "";
  String ano = "";
  bool aceitouTermos = false;

  @override
  void initState() {
    super.initState();

    _cnhController.text = widget.cnh;
    _dataValidadeController.text = widget.dataValidade;

    placa = widget.placa;
    renavam = widget.renavam;
    modelo = widget.modelo;
    ano = widget.ano;
    aceitouTermos = widget.aceitouTermos;
  }

  @override
  void dispose() {
    _cnhController.dispose();
    _dataValidadeController.dispose();

    super.dispose();
  }

  String formatarData(String valor) {
    valor = valor.replaceAll(RegExp(r'\D'), '');

    if (valor.length > 8) {
      valor = valor.substring(0, 8);
    }

    if (valor.length <= 2) {
      return valor;
    }

    if (valor.length <= 4) {
      return '${valor.substring(0, 2)}/${valor.substring(2)}';
    }

    return '${valor.substring(0, 2)}/'
        '${valor.substring(2, 4)}/'
        '${valor.substring(4)}';
  }

  Future<void> irParaProximoPasso() async {
    // Valida os campos da página 2
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final resultado = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => CadastroMototaxista3Page(
          nome: widget.nome,
          email: widget.email,
          telefone: widget.telefone,
          senha: widget.senha,

          // Dados desta página
          cnh: _cnhController.text,
          dataValidade: _dataValidadeController.text,

          // Dados que vieram da página 3 anteriormente
          placa: placa,
          renavam: renavam,
          modelo: modelo,
          ano: ano,
          aceitouTermos: aceitouTermos,
        ),
      ),
    );

    // RECEBE OS DADOS DA PÁGINA 3
    if (resultado != null) {
      setState(() {
        placa = resultado["placa"];
        renavam = resultado["renavam"];
        modelo = resultado["modelo"];
        ano = resultado["ano"];
        aceitouTermos = resultado["aceitouTermos"];
      });
    }
  }

  void voltar() {
    Navigator.pop(context, {
      "cnh": _cnhController.text,
      "dataValidade": _dataValidadeController.text,

      "placa": placa,
      "renavam": renavam,
      "modelo": modelo,
      "ano": ano,
      "aceitouTermos": aceitouTermos,
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,

      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,

        middle: const Text("Cadastro de Mototaxista - Passo 2/3"),

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
                // CNH
                // =========================
                CampoFormulario(
                  label: "Número de CNH",
                  placeholder: "69314369120",
                  controller: _cnhController,
                  keyboardType: TextInputType.number,

                  onChanged: (valor) {
                    valor = valor.replaceAll(RegExp(r'\D'), '');

                    if (valor.length > 11) {
                      valor = valor.substring(0, 11);
                    }

                    _cnhController.value = TextEditingValue(
                      text: valor,
                      selection: TextSelection.collapsed(offset: valor.length),
                    );
                  },

                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return "Informe sua CNH";
                    }

                    final regex = RegExp(r'^\d{11}$');

                    if (!regex.hasMatch(valor)) {
                      return "A CNH deve possuir 11 números";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // =========================
                // DATA DE VALIDADE
                // =========================
                CampoFormulario(
                  label: "Data de validade",
                  placeholder: "21/12/2034",
                  controller: _dataValidadeController,
                  keyboardType: TextInputType.datetime,

                  onChanged: (valor) {
                    final data = formatarData(valor);

                    _dataValidadeController.value = TextEditingValue(
                      text: data,
                      selection: TextSelection.collapsed(offset: data.length),
                    );
                  },

                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return "Informe a data de validade";
                    }

                    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');

                    if (!regex.hasMatch(valor)) {
                      return "Informe a data no formato DD/MM/AAAA";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // =========================
                // BOTÃO
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

                      onPressed: irParaProximoPasso,

                      child: const Text(
                        "PRÓXIMO PASSO",
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
