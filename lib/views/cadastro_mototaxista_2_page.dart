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

  CadastroMototaxista2Page({
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.white,

      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.white,

        middle: const Text("Cadastro de Mototaxista - Passo 2/3"),

        leading: CupertinoButton(
          padding: EdgeInsets.zero,

          onPressed: () {
            Navigator.pop(context, {
              "cnh": _cnhController.text,
              "dataValidade": _dataValidadeController.text,

              "placa": placa,
              "renavam": renavam,
              "modelo": modelo,
              "ano": ano,
              "aceitouTermos": aceitouTermos,
            });
          },

          child: const Icon(CupertinoIcons.back),
        ),
      ),

      child: SafeArea(
        child: Form(
          key: _formKey,

          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),

            children: [
              // CNH
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

                  RegExp regex = RegExp(r'^\d{11}$');

                  if (!regex.hasMatch(valor)) {
                    return "A CNH deve possuir 11 números";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // DATA
              CampoFormulario(
                label: "Data de validade",
                placeholder: "21/12/2034",
                controller: _dataValidadeController,
                keyboardType: TextInputType.datetime,

                onChanged: (valor) {
                  String data = formatarData(valor);

                  _dataValidadeController.value = TextEditingValue(
                    text: data,
                    selection: TextSelection.collapsed(offset: data.length),
                  );
                },

                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return "Informe a data de validade";
                  }

                  RegExp regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');

                  if (!regex.hasMatch(valor)) {
                    return "Informe a data no formato DD/MM/AAAA";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // BOTÃO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: CupertinoButton.filled(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final resultado = await Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => CadastroMototaxista3Page(
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
}
