import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:route_pires_flutter/views/campo_formulario.dart';
import 'package:route_pires_flutter/views/termos_de_uso.dart';

class CadastroMototaxista3Page extends StatefulWidget {
  final String placa;
  final String renavam;
  final String modelo;
  final String ano;
  final bool aceitouTermos;

  const CadastroMototaxista3Page({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.white,

      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.white,

        middle: const Text("Cadastro de Mototaxista - Passo 3/3"),

        leading: CupertinoButton(
          padding: EdgeInsets.zero,

          onPressed: () {
            Navigator.pop(context, {
              "placa": _placaController.text,
              "renavam": _renavamController.text,
              "modelo": _modeloController.text,
              "ano": _anoController.text,
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
              // PLACA
              CampoFormulario(
                label: "Placa da moto",
                placeholder: "ABC1D23",
                controller: _placaController,
                keyboardType: TextInputType.text,

                onChanged: (valor) {
                  String placa = formatarPlaca(valor);

                  _placaController.value = TextEditingValue(
                    text: placa,
                    selection: TextSelection.collapsed(offset: placa.length),
                  );
                },

                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return "Informe a placa da moto";
                  }

                  RegExp regex = RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$');

                  if (!regex.hasMatch(valor)) {
                    return "Informe uma placa válida";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // RENAVAM
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

                  RegExp regex = RegExp(r'^\d{11}$');

                  if (!regex.hasMatch(valor)) {
                    return "O RENAVAM deve possuir 11 números";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              //MODELO
              CampoFormulario(
                label: "Modelo da moto",
                placeholder: "Honda cg 150c",
                controller: _modeloController,
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return "Informe o modelo da moto";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ANO
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

                  RegExp regex = RegExp(r'^\d{4}$');

                  if (!regex.hasMatch(valor)) {
                    return "Informe um ano válido";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              // TERMOS
              TermosDeUso(
                aceitouTermos: aceitouTermos,
                onChanged: (valor) {
                  setState(() {
                    aceitouTermos = valor;
                  });
                },
              ),

              const SizedBox(height: 20),

              // BOTÃO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: CupertinoButton.filled(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      print(_placaController.text);
                      print(_renavamController.text);
                      print(_anoController.text);
                    }
                  },

                  child: const Text("Finalizar Cadastro"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
