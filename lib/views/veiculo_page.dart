import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/model/veiculo.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/veiculo_viewmodel.dart';
import 'package:route_pires_flutter/views/campo_formulario.dart';

class VeiculoPage extends StatefulWidget {
  const VeiculoPage({super.key});

  @override
  State<VeiculoPage> createState() => _VeiculoPageState();
}

class _VeiculoPageState extends State<VeiculoPage> {
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
      context.read<VeiculoViewModel>().carregar(usuario.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VeiculoViewModel>();
    final veiculo = viewModel.veiculo;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        previousPageTitle: 'Voltar',
        middle: Text(
          'Veículo ou Placa',
          style: TextStyle(fontWeight: FontWeight.w400),
        ),
        border: null,
      ),
      child: SafeArea(
        child: viewModel.carregando
            ? const Center(child: CupertinoActivityIndicator(radius: 16))
            : veiculo == null
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
                      viewModel.erro ??
                          'Não foi possível carregar os dados do veículo',
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
            : _FormularioVeiculo(veiculo: veiculo),
      ),
    );
  }
}

class _FormularioVeiculo extends StatefulWidget {
  const _FormularioVeiculo({required this.veiculo});

  final Veiculo veiculo;

  @override
  State<_FormularioVeiculo> createState() => _FormularioVeiculoState();
}

class _FormularioVeiculoState extends State<_FormularioVeiculo> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _placaController;
  late final TextEditingController _renavamController;
  late final TextEditingController _modeloController;
  late final TextEditingController _anoController;

  @override
  void initState() {
    super.initState();
    _placaController = TextEditingController(text: widget.veiculo.placa);
    _renavamController = TextEditingController(text: widget.veiculo.renavam);
    _modeloController = TextEditingController(text: widget.veiculo.modelo);
    _anoController = TextEditingController(text: widget.veiculo.ano);
  }

  @override
  void dispose() {
    _placaController.dispose();
    _renavamController.dispose();
    _modeloController.dispose();
    _anoController.dispose();
    super.dispose();
  }

  void _definirTexto(TextEditingController controller, String texto) {
    controller.value = TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }

  String _somenteNumeros(String valor, int limite) {
    valor = valor.replaceAll(RegExp(r'\D'), '');
    return valor.length > limite ? valor.substring(0, limite) : valor;
  }

  String _formatarPlaca(String valor) {
    valor = valor.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    return valor.length > 7 ? valor.substring(0, 7) : valor;
  }

  Future<void> _atualizar() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    final id = context.read<LoginViewModel>().usuario?.id;
    if (id == null) return;

    final viewModel = context.read<VeiculoViewModel>();
    final ok = await viewModel.salvar(
      id: id,
      veiculo: Veiculo(
        placa: _placaController.text,
        renavam: _renavamController.text,
        modelo: _modeloController.text.trim(),
        ano: _anoController.text,
      ),
    );

    if (!mounted) return;

    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(ok ? 'Sucesso' : 'Erro'),
        content: Text(
          ok
              ? 'Veículo atualizado com sucesso!'
              : viewModel.erro ?? 'Falha ao atualizar',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (ok) Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salvando = context.select<VeiculoViewModel, bool>(
      (viewModel) => viewModel.salvando,
    );

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          CampoFormulario(
            label: 'Placa da moto',
            placeholder: 'ABC1D23',
            controller: _placaController,
            keyboardType: TextInputType.text,
            onChanged: (valor) {
              _definirTexto(_placaController, _formatarPlaca(valor));
            },
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Informe a placa da moto';
              }

              if (!RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$').hasMatch(valor)) {
                return 'Informe uma placa válida';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          CampoFormulario(
            label: 'RENAVAM',
            placeholder: 'Digite o RENAVAM',
            controller: _renavamController,
            keyboardType: TextInputType.number,
            onChanged: (valor) {
              _definirTexto(_renavamController, _somenteNumeros(valor, 11));
            },
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Informe o RENAVAM';
              }

              if (!RegExp(r'^\d{11}$').hasMatch(valor)) {
                return 'O RENAVAM deve possuir 11 números';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          CampoFormulario(
            label: 'Modelo da moto',
            placeholder: 'Honda CG 150',
            controller: _modeloController,
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Informe o modelo da moto';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          CampoFormulario(
            label: 'Ano da moto',
            placeholder: 'Ex.: 2024',
            controller: _anoController,
            keyboardType: TextInputType.number,
            onChanged: (valor) {
              _definirTexto(_anoController, _somenteNumeros(valor, 4));
            },
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Informe o ano da moto';
              }

              if (!RegExp(r'^\d{4}$').hasMatch(valor)) {
                return 'Informe um ano válido';
              }

              final ano = int.parse(valor);

              if (ano < 1900 || ano > DateTime.now().year + 1) {
                return 'Informe um ano de fabricação válido';
              }

              return null;
            },
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
