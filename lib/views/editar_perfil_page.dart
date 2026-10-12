import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/editar_perfil_viewmodel.dart';

class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;
  final _senhaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final usuario = context.read<LoginViewModel>().usuario;

    _nomeController = TextEditingController(text: usuario?.nome ?? '');
    _emailController = TextEditingController(text: usuario?.email ?? '');
    
    final telefoneInicial = usuario?.telefone ?? '';
    _telefoneController = TextEditingController(text: formatarTelefone(telefoneInicial));
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
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
      return '(${valor.substring(0, 2)}) ${valor.substring(2)}';
    }
    return '(${valor.substring(0, 2)}) '
        '${valor.substring(2, 7)}-'
        '${valor.substring(7)}';
  }

  Future<void> _atualizar() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_formKey.currentState!.validate()) return;

    final loginViewModel = context.read<LoginViewModel>();
    final usuarioAnterior = loginViewModel.usuario;
    if (usuarioAnterior == null) return;

    final viewModel = context.read<EditarPerfilViewModel>();
    
    final novoNome = _nomeController.text.trim();
    final novoEmail = _emailController.text.trim();
    final telefoneSomenteNumeros = _telefoneController.text.replaceAll(RegExp(r'\D'), '');

    final ok = await viewModel.atualizarPerfil(
      id: usuarioAnterior.id,
      nome: novoNome,
      email: novoEmail,
      telefone: telefoneSomenteNumeros,
      senha: _senhaController.text,
    );

    if (!mounted) return;

    if (ok) {
      final usuarioLocalMemory = usuarioAnterior.copyWith(
        nome: novoNome,
        email: novoEmail,
        telefone: formatarTelefone(telefoneSomenteNumeros),
      );
      
      loginViewModel.atualizarUsuarioLocal(usuarioLocalMemory);

      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Sucesso'),
          content: const Text('Perfil atualizado com sucesso!'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
                Navigator.of(context).pop(); 
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Erro'),
          content: Text(viewModel.erro ?? 'Falha ao atualizar'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        previousPageTitle: 'Voltar',
        middle: const Text('Editar perfil', style: TextStyle(fontWeight: FontWeight.w400)),
        border: null,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildFieldTitle('Nome completo'),
              FormField<String>(
                  initialValue: _nomeController.text,
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) return 'Informe seu nome';
                    return null;
                  },
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CupertinoTextField(
                          controller: _nomeController,
                          padding: const EdgeInsets.all(16),
                          onChanged: (valor) => state.didChange(valor),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: state.hasError
                                    ? CupertinoColors.systemRed
                                    : const Color(0xFF0066FF),
                                width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffix: const Padding(
                            padding: EdgeInsets.only(right: 12.0),
                            child: Icon(CupertinoIcons.pencil_circle_fill, color: Color(0xFF34C759), size: 24),
                          ),
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(state.errorText!, style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 12)),
                          )
                      ],
                    );
                  }),

              _buildFieldTitle('E-mail'),
              FormField<String>(
                  initialValue: _emailController.text,
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) return 'Informe seu e-mail';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(valor.trim())) return 'Informe um e-mail válido';
                    return null;
                  },
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CupertinoTextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          padding: const EdgeInsets.all(16),
                          onChanged: (valor) => state.didChange(valor),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: state.hasError
                                    ? CupertinoColors.systemRed
                                    : CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffix: const Padding(
                            padding: EdgeInsets.only(right: 12.0),
                            child: Icon(CupertinoIcons.pencil_circle_fill, color: CupertinoColors.systemGrey, size: 24),
                          ),
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(state.errorText!, style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 12)),
                          )
                      ],
                    );
                  }),

              _buildFieldTitle('Número de telefone'),
              FormField<String>(
                  initialValue: _telefoneController.text,
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) return 'Informe seu telefone';
                    if (!RegExp(r'^\(\d{2}\) \d{5}-\d{4}$').hasMatch(valor)) return 'Informe um telefone válido';
                    return null;
                  },
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CupertinoTextField(
                          controller: _telefoneController,
                          keyboardType: TextInputType.phone,
                          padding: const EdgeInsets.all(16),
                          onChanged: (valor) {
                            final telefone = formatarTelefone(valor);
                            _telefoneController.value = TextEditingValue(
                              text: telefone,
                              selection: TextSelection.collapsed(offset: telefone.length),
                            );
                            state.didChange(telefone);
                          },
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: state.hasError
                                    ? CupertinoColors.systemRed
                                    : CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffix: const Padding(
                            padding: EdgeInsets.only(right: 12.0),
                            child: Icon(CupertinoIcons.pencil_circle_fill, color: CupertinoColors.systemGrey, size: 24),
                          ),
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(state.errorText!, style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 12)),
                          )
                      ],
                    );
                  }),

              _buildFieldTitle('Senha'),
              CupertinoTextField(
                controller: _senhaController,
                obscureText: true,
                placeholder: '******',
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(10),
                ),
                suffix: const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Icon(CupertinoIcons.pencil_circle_fill, color: CupertinoColors.systemGrey, size: 24),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4.0, left: 4.0),
                child: Text('Deixe em branco caso não queira alterar.', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
              ),

              const SizedBox(height: 32),

              Consumer<EditarPerfilViewModel>(
                builder: (context, viewModel, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: const Color(0xFF0066FF),
                      borderRadius: BorderRadius.circular(10),
                      onPressed: viewModel.carregando ? null : _atualizar,
                      child: viewModel.carregando
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : const Text('Atualizar', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              Consumer<EditarPerfilViewModel>(
                builder: (context, viewModel, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: const Color(0xFFFF5C66),
                      borderRadius: BorderRadius.circular(10),
                      onPressed: viewModel.carregando ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}