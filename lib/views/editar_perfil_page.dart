import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/config/validacao.dart';
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

  final _nomeFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _telefoneFocus = FocusNode();
  final _senhaFocus = FocusNode();

  bool _nomeEmFoco = false;
  bool _emailEmFoco = false;
  bool _telefoneEmFoco = false;
  bool _senhaEmFoco = false;

  bool _senhaVisivel = false;

  @override
  void initState() {
    super.initState();

    final usuario = context.read<LoginViewModel>().usuario;

    _nomeController = TextEditingController(text: usuario?.nome ?? '');

    _emailController = TextEditingController(text: usuario?.email ?? '');

    final telefoneInicial = usuario?.telefone ?? '';

    _telefoneController = TextEditingController(
      text: formatarTelefone(telefoneInicial),
    );

    _nomeFocus.addListener(_atualizarFoco);
    _emailFocus.addListener(_atualizarFoco);
    _telefoneFocus.addListener(_atualizarFoco);
    _senhaFocus.addListener(_atualizarFoco);
  }

  void _atualizarFoco() {
    if (!mounted) return;

    setState(() {
      _nomeEmFoco = _nomeFocus.hasFocus;
      _emailEmFoco = _emailFocus.hasFocus;
      _telefoneEmFoco = _telefoneFocus.hasFocus;
      _senhaEmFoco = _senhaFocus.hasFocus;
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();

    _nomeFocus.removeListener(_atualizarFoco);
    _emailFocus.removeListener(_atualizarFoco);
    _telefoneFocus.removeListener(_atualizarFoco);
    _senhaFocus.removeListener(_atualizarFoco);

    _nomeFocus.dispose();
    _emailFocus.dispose();
    _telefoneFocus.dispose();
    _senhaFocus.dispose();

    super.dispose();
  }

  String formatarTelefone(String valor) {
    valor = valor.replaceAll(RegExp(r'\D'), '');

    if (valor.length > 11) {
      valor = valor.substring(0, 11);
    }

    if (valor.isEmpty) {
      return '';
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

  BoxDecoration _decoracaoCampo({required bool emFoco, bool comErro = false}) {
    return BoxDecoration(
      border: Border.all(
        color: comErro
            ? CupertinoColors.systemRed
            : emFoco
            ? const Color(0xFF0066FF)
            : CupertinoColors.systemGrey4,
        width: emFoco ? 1.5 : 1,
      ),
      borderRadius: BorderRadius.circular(10),
    );
  }

  Widget _iconeCampo({
    required bool emFoco,
    IconData icone = CupertinoIcons.pencil_circle_fill,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Icon(
        icone,
        color: emFoco ? const Color(0xFF34C759) : CupertinoColors.systemGrey,
        size: 24,
      ),
    );
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

    // A API recebe o telefone somente com números.
    final telefoneSomenteNumeros = _telefoneController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

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

      await showCupertinoDialog<void>(
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
      await showCupertinoDialog<void>(
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
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
        ),
      ),
    );
  }

  Widget _buildErro(String? erro) {
    if (erro == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        erro,
        style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        previousPageTitle: 'Voltar',
        middle: Text(
          'Editar perfil',
          style: TextStyle(fontWeight: FontWeight.w400),
        ),
        border: null,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Nome completo
              _buildFieldTitle('Nome completo'),

              FormField<String>(
                initialValue: _nomeController.text,
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe seu nome';
                  }

                  return null;
                },
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CupertinoTextField(
                        controller: _nomeController,
                        focusNode: _nomeFocus,
                        padding: const EdgeInsets.all(16),
                        onChanged: state.didChange,
                        decoration: _decoracaoCampo(
                          emFoco: _nomeEmFoco,
                          comErro: state.hasError,
                        ),
                        suffix: _iconeCampo(emFoco: _nomeEmFoco),
                      ),
                      _buildErro(state.errorText),
                    ],
                  );
                },
              ),

              // E-mail
              _buildFieldTitle('E-mail'),

              FormField<String>(
                initialValue: _emailController.text,
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe seu e-mail';
                  }

                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(valor.trim())) {
                    return 'Informe um e-mail válido';
                  }

                  return null;
                },
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CupertinoTextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        padding: const EdgeInsets.all(16),
                        onChanged: state.didChange,
                        decoration: _decoracaoCampo(
                          emFoco: _emailEmFoco,
                          comErro: state.hasError,
                        ),
                        suffix: _iconeCampo(emFoco: _emailEmFoco),
                      ),
                      _buildErro(state.errorText),
                    ],
                  );
                },
              ),

              // Telefone
              _buildFieldTitle('Número de telefone'),

              FormField<String>(
                initialValue: _telefoneController.text,
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Informe seu telefone';
                  }

                  if (!RegExp(r'^\(\d{2}\) \d{5}-\d{4}$').hasMatch(valor)) {
                    return 'Informe um telefone válido';
                  }

                  return null;
                },
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CupertinoTextField(
                        controller: _telefoneController,
                        focusNode: _telefoneFocus,
                        keyboardType: TextInputType.phone,
                        padding: const EdgeInsets.all(16),
                        onChanged: (valor) {
                          final telefone = formatarTelefone(valor);

                          _telefoneController.value = TextEditingValue(
                            text: telefone,
                            selection: TextSelection.collapsed(
                              offset: telefone.length,
                            ),
                          );

                          state.didChange(telefone);
                        },
                        decoration: _decoracaoCampo(
                          emFoco: _telefoneEmFoco,
                          comErro: state.hasError,
                        ),
                        suffix: _iconeCampo(emFoco: _telefoneEmFoco),
                      ),
                      _buildErro(state.errorText),
                    ],
                  );
                },
              ),

              // Senha
              _buildFieldTitle('Senha'),

              CupertinoTextField(
                controller: _senhaController,
                focusNode: _senhaFocus,
                obscureText: !_senhaVisivel,
                placeholder: 'Deixe em branco para manter a senha',
                padding: const EdgeInsets.all(16),
                decoration: _decoracaoCampo(emFoco: _senhaEmFoco),
                suffix: CupertinoButton(
                  padding: const EdgeInsets.only(left: 8, right: 12),
                  minSize: 32,
                  onPressed: () {
                    setState(() {
                      _senhaVisivel = !_senhaVisivel;
                    });
                  },
                  child: Icon(
                    _senhaVisivel
                        ? CupertinoIcons.eye
                        : CupertinoIcons.eye_slash,
                    color: _senhaEmFoco
                        ? const Color(0xFF34C759)
                        : CupertinoColors.systemGrey,
                    size: 21,
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'Deixe em branco caso não queira alterar.',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botão Atualizar
              Consumer<EditarPerfilViewModel>(
                builder: (context, viewModel, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: const Color(0xFF0066FF),
                      borderRadius: BorderRadius.circular(10),
                      onPressed: viewModel.carregando ? null : _atualizar,
                      child: viewModel.carregando
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
                  );
                },
              ),

              const SizedBox(height: 16),

              // Botão Cancelar
              Consumer<EditarPerfilViewModel>(
                builder: (context, viewModel, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: const Color(0xFFFF5C66),
                      borderRadius: BorderRadius.circular(10),
                      onPressed: viewModel.carregando
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
