import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';
import 'package:route_pires_flutter/views/cadastro_mototaxista_3_page.dart';
import 'package:route_pires_flutter/views/campo_formulario.dart';

class CadastroMototaxista2Page extends StatefulWidget {
  const CadastroMototaxista2Page({super.key});

  @override
  State<CadastroMototaxista2Page> createState() =>
      _CadastroMototaxista2PageState();
}

class _CadastroMototaxista2PageState extends State<CadastroMototaxista2Page> {
  final _formKey = GlobalKey<FormState>();

  final _cnhController = TextEditingController();
  final _dataValidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rascunho = context.read<MototaxistaViewModel>().rascunho;
    _cnhController.text = rascunho.cnh;
    _dataValidadeController.text = rascunho.dataValidade;
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

  void _salvarRascunho() {
    final rascunho = context.read<MototaxistaViewModel>().rascunho;
    rascunho.cnh = _cnhController.text;
    rascunho.dataValidade = _dataValidadeController.text;
  }

  Future<void> irParaProximoPasso() async {
    if (!_formKey.currentState!.validate()) return;
    _salvarRascunho();
    await Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const CadastroMototaxista3Page()),
    );
  }

  void voltar() {
    _salvarRascunho();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        voltar();
      },
      child: CupertinoPageScaffold(
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
                        selection: TextSelection.collapsed(
                          offset: valor.length,
                        ),
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

                      final dia = int.parse(valor.substring(0, 2));
                      final mes = int.parse(valor.substring(3, 5));
                      final ano = int.parse(valor.substring(6));
                      final data = DateTime(ano, mes, dia);
                      if (data.day != dia ||
                          data.month != mes ||
                          data.year != ano) {
                        return "Informe uma data de validade real";
                      }
                      final hoje = DateTime.now();
                      if (data.isBefore(
                        DateTime(hoje.year, hoje.month, hoje.day),
                      )) {
                        return "A CNH está vencida";
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
      ),
    );
  }
}
