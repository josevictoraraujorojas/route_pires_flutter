import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/precos_corridas_viewmodel.dart';
import 'package:route_pires_flutter/views/campo_formulario.dart';

class PrecosCorridasPage extends StatefulWidget {
  const PrecosCorridasPage({super.key});

  @override
  State<PrecosCorridasPage> createState() => _PrecosCorridasPageState();
}

class _PrecosCorridasPageState extends State<PrecosCorridasPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregar();
    });
  }

  void _carregar() {
    final usuario = context.read<LoginViewModel>().usuario;

    if (usuario != null) {
      context.read<PrecosCorridasViewModel>().carregarPrecos(id: usuario.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PrecosCorridasViewModel>();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        previousPageTitle: 'Voltar',
        middle: Text(
          'Preços das corridas',
          style: TextStyle(fontWeight: FontWeight.w400),
        ),
        border: null,
      ),
      child: SafeArea(
        child: viewModel.carregando
            ? const Center(child: CupertinoActivityIndicator(radius: 16))
            : viewModel.erro != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 40,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      viewModel.erro!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: CupertinoColors.systemGrey),
                    ),
                    CupertinoButton(
                      onPressed: _carregar,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              )
            : const _FormularioPrecos(),
      ),
    );
  }
}

class _FormularioPrecos extends StatefulWidget {
  const _FormularioPrecos();

  @override
  State<_FormularioPrecos> createState() => _FormularioPrecosState();
}

class _FormularioPrecosState extends State<_FormularioPrecos> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _precoZonaUrbanaController;
  late final TextEditingController _precoBairrosAfastadosController;
  late final TextEditingController _precoBandeira2Controller;

  @override
  void initState() {
    super.initState();

    final viewModel = context.read<PrecosCorridasViewModel>();

    _precoZonaUrbanaController = TextEditingController(
      text: _formatarPreco(viewModel.precoZonaUrbana),
    );

    _precoBairrosAfastadosController = TextEditingController(
      text: _formatarPreco(viewModel.precoBairrosAfastados),
    );

    _precoBandeira2Controller = TextEditingController(
      text: _formatarPreco(viewModel.precoBandeira2),
    );
  }

  @override
  void dispose() {
    _precoZonaUrbanaController.dispose();
    _precoBairrosAfastadosController.dispose();
    _precoBandeira2Controller.dispose();
    super.dispose();
  }

  String _formatarPreco(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  double? _converterPreco(String valor) {
    return double.tryParse(valor.trim().replaceAll(',', '.'));
  }

  void _definirTexto(TextEditingController controller, String texto) {
    controller.value = TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }

  String _formatarDigitacaoPreco(String valor) {
    // Permite somente números e vírgula.
    valor = valor.replaceAll(RegExp(r'[^0-9,]'), '');

    // Permite somente uma vírgula.
    final partes = valor.split(',');

    if (partes.length > 2) {
      valor = '${partes.first},${partes.sublist(1).join()}';
    }

    // Limita a duas casas decimais.
    final partesFinais = valor.split(',');

    if (partesFinais.length == 2) {
      final decimais = partesFinais[1].length > 2
          ? partesFinais[1].substring(0, 2)
          : partesFinais[1];

      valor = '${partesFinais[0]},$decimais';
    }

    return valor;
  }

  String? _validarPreco(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe o preço';
    }

    final preco = _converterPreco(valor);

    if (preco == null || !preco.isFinite) {
      return 'Informe um preço válido';
    }

    if (preco < 0.01) {
      return 'O preço deve ser maior que zero';
    }

    return null;
  }

  Future<void> _atualizar() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    final id = context.read<LoginViewModel>().usuario?.id;
    if (id == null || id.isEmpty) return;

    final viewModel = context.read<PrecosCorridasViewModel>();

    final ok = await viewModel.salvarPrecos(
      id: id,
      precoZonaUrbana: _converterPreco(_precoZonaUrbanaController.text)!,
      precoBairrosAfastados: _converterPreco(
        _precoBairrosAfastadosController.text,
      )!,
      precoBandeira2: _converterPreco(_precoBandeira2Controller.text)!,
    );

    if (!mounted) return;

    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(ok ? 'Sucesso' : 'Erro'),
        content: Text(
          ok
              ? 'Preços atualizados com sucesso!'
              : viewModel.erro ?? 'Falha ao atualizar os preços.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(dialogContext).pop();

              if (ok) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salvando = context.select<PrecosCorridasViewModel, bool>(
      (viewModel) => viewModel.salvando,
    );

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          CampoFormulario(
            label: 'Preço da zona urbana',
            placeholder: 'Ex.: 10,00',
            controller: _precoZonaUrbanaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (valor) {
              _definirTexto(
                _precoZonaUrbanaController,
                _formatarDigitacaoPreco(valor),
              );
            },
            validator: _validarPreco,
          ),

          const SizedBox(height: 16),

          CampoFormulario(
            label: 'Preço dos bairros afastados',
            placeholder: 'Ex.: 15,00',
            controller: _precoBairrosAfastadosController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (valor) {
              _definirTexto(
                _precoBairrosAfastadosController,
                _formatarDigitacaoPreco(valor),
              );
            },
            validator: _validarPreco,
          ),

          const SizedBox(height: 16),

          CampoFormulario(
            label: 'Preço da bandeira 2',
            placeholder: 'Ex.: 12,00',
            controller: _precoBandeira2Controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (valor) {
              _definirTexto(
                _precoBandeira2Controller,
                _formatarDigitacaoPreco(valor),
              );
            },
            validator: _validarPreco,
          ),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CupertinoButton(
                  color: const Color(0xFF0066FF),
                  borderRadius: BorderRadius.circular(10),
                  onPressed: salvando ? null : _atualizar,
                  child: salvando
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : const Text(
                          'Atualizar',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  color: const Color(0xFFFF5C66),
                  borderRadius: BorderRadius.circular(10),
                  onPressed: salvando ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
