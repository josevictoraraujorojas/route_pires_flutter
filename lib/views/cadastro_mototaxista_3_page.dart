import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';
import 'package:route_pires_flutter/views/campo_formulario.dart';
import 'package:route_pires_flutter/views/termos_de_uso.dart';

class CadastroMototaxista3Page extends StatefulWidget {
  const CadastroMototaxista3Page({super.key});

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
    final rascunho = context.read<MototaxistaViewModel>().rascunho;
    _placaController.text = rascunho.placa;
    _renavamController.text = rascunho.renavam;
    _modeloController.text = rascunho.modelo;
    _anoController.text = rascunho.ano;
    aceitouTermos = rascunho.aceitouTermos;
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

  void _salvarRascunho() {
    final rascunho = context.read<MototaxistaViewModel>().rascunho;
    rascunho.placa = _placaController.text;
    rascunho.renavam = _renavamController.text;
    rascunho.modelo = _modeloController.text;
    rascunho.ano = _anoController.text;
    rascunho.aceitouTermos = aceitouTermos;
  }

  Future<void> finalizarCadastro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _salvarRascunho();
    final cadastroViewModel = context.read<MototaxistaViewModel>();
    final cadastrou = await cadastroViewModel.cadastrar();

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
    _salvarRascunho();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cadastroViewModel = context.watch<MototaxistaViewModel>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (cadastroViewModel.carregando) return;
        voltar();
      },
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.white,

        navigationBar: CupertinoNavigationBar(
          backgroundColor: CupertinoColors.white,

          middle: const Text("Cadastro de Mototaxista - Passo 3/3"),

          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: cadastroViewModel.carregando ? null : voltar,
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
                    label: "Placa da moto",
                    placeholder: "ABC1D23",
                    controller: _placaController,
                    keyboardType: TextInputType.text,

                    onChanged: (valor) {
                      final placa = formatarPlaca(valor);

                      _placaController.value = TextEditingValue(
                        text: placa,
                        selection: TextSelection.collapsed(
                          offset: placa.length,
                        ),
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
                        selection: TextSelection.collapsed(
                          offset: valor.length,
                        ),
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
                        selection: TextSelection.collapsed(
                          offset: valor.length,
                        ),
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

                  TermosDeUso(
                    aceitouTermos: aceitouTermos,
                    onChanged: (valor) {
                      setState(() {
                        aceitouTermos = valor;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

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
      ),
    );
  }
}
