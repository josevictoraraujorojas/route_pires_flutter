import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/editar_perfil_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/historico_corridas_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/veiculo_viewmodel.dart';
import 'package:route_pires_flutter/views/editar_perfil_page.dart';
import 'package:route_pires_flutter/views/historico_corridas_page.dart';
import 'package:route_pires_flutter/views/notificacoes_page.dart';
import 'package:route_pires_flutter/views/veiculo_page.dart';

class PerfilMototaxista extends StatefulWidget {
  const PerfilMototaxista({super.key});

  @override
  State<PerfilMototaxista> createState() => _PerfilMototaxistaState();
}

class _PerfilMototaxistaState extends State<PerfilMototaxista> {
  bool carregandoDisponibilidade = true;
  bool alterandoDisponibilidade = false;
  String? erroDisponibilidade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregarDisponibilidade();
    });
  }

  Future<void> _carregarDisponibilidade() async {
    final mototaxistaId = context.read<LoginViewModel>().usuario?.id;
    if (mototaxistaId == null || mototaxistaId.isEmpty) {
      setState(() {
        carregandoDisponibilidade = false;
        erroDisponibilidade = 'Não foi possível identificar o mototaxista.';
      });
      return;
    }

    setState(() {
      carregandoDisponibilidade = true;
      erroDisponibilidade = null;
    });

    final viewModel = context.read<MototaxistaViewModel>();
    final valor = await viewModel.consultarDisponibilidade(id: mototaxistaId);
    if (!mounted) return;

    setState(() {
      carregandoDisponibilidade = false;
      erroDisponibilidade = valor == null
          ? viewModel.erro ?? 'Não foi possível consultar sua disponibilidade.'
          : null;
    });
  }

  // ============================================================
  // ALTERAR DISPONIBILIDADE
  // ============================================================

  Future<void> _alterarDisponibilidade(bool valor) async {
    if (alterandoDisponibilidade || carregandoDisponibilidade) {
      return;
    }

    final loginViewModel = context.read<LoginViewModel>();
    final mototaxistaId = loginViewModel.usuario?.id;

    if (mototaxistaId == null || mototaxistaId.isEmpty) {
      _mostrarErro('Não foi possível identificar o mototaxista.');
      return;
    }

    final viewModel = context.read<MototaxistaViewModel>();
    if (viewModel.disponibilidadePara(mototaxistaId) == null) return;

    setState(() {
      alterandoDisponibilidade = true;
    });

    try {
      final sucesso = await viewModel.alterarDisponibilidade(
        id: mototaxistaId,
        disponivel: valor,
      );

      if (!mounted) return;

      if (!sucesso) {
        _mostrarErro(
          viewModel.erro ?? 'Não foi possível alterar sua disponibilidade.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      _mostrarErro('Não foi possível alterar sua disponibilidade.');
    } finally {
      if (mounted) {
        setState(() {
          alterandoDisponibilidade = false;
        });
      }
    }
  }

  // ============================================================
  // ERRO
  // ============================================================

  void _mostrarErro(String mensagem) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Erro'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(mensagem),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _fazerLogout() async {
    final loginViewModel = context.read<LoginViewModel>();

    final saiu = await loginViewModel.sair();

    if (!mounted) return;
    if (!saiu) {
      _mostrarErro(loginViewModel.erro ?? 'Não foi possível sair da conta');
    }
  }

  void _confirmarLogout() {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Sair'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Deseja realmente sair da sua conta?'),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                await _fazerLogout();
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // COMPONENTES DA TELA
  // ============================================================

  Widget _buildMenuItem(String title, VoidCallback onTap, {bool isLast = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.black,
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemGrey,
                  size: 18,
                ),
              ],
            ),
          ),
          if (!isLast)
            Container(height: 1, color: CupertinoColors.systemGrey5),
        ],
      ),
    );
  }

  Widget _buildDisponibilidade(bool? disponivel) {
    if (carregandoDisponibilidade || alterandoDisponibilidade) {
      return const SizedBox(
        width: 64,
        height: 32,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (disponivel == null) {
      return Column(
        children: [
          Text(
            erroDisponibilidade ??
                'Não foi possível consultar sua disponibilidade.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: CupertinoColors.systemRed),
          ),
          CupertinoButton(
            onPressed: _carregarDisponibilidade,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }

    return CupertinoSwitch(
      value: disponivel,
      activeTrackColor: CupertinoColors.systemGreen,
      onChanged: _alterarDisponibilidade,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<LoginViewModel>().usuario;
    final disponivel = context.select<MototaxistaViewModel, bool?>(
      (viewModel) => viewModel.disponibilidadePara(usuario?.id),
    );

    final nome = usuario?.nome ?? 'Mototaxista';
    final email = usuario?.email ?? '@mototaxista';

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text('Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 24),

            // FOTO DO PERFIL
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6E8FF),
                      borderRadius: BorderRadius.circular(45),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      size: 50,
                      color: Color(0xFFA3C9FF),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: CupertinoColors.white, width: 2),
                      ),
                      child: const Icon(
                        CupertinoIcons.pencil,
                        size: 14,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // NOME E E-MAIL
            Center(
              child: Text(
                nome,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.black,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                email,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // DISPONIBILIDADE
            const Center(
              child: Text(
                'Disponibilidade:',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(child: _buildDisponibilidade(disponivel)),
            const SizedBox(height: 8),
            const Text(
              'Enquanto estiver disponível ou atendendo, mantenha o aplicativo aberto e a tela ligada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            // MENUS
            _buildMenuItem('Editar perfil', () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => EditarPerfilViewModel(),
                    child: const EditarPerfilPage(),
                  ),
                ),
              );
            }),
            _buildMenuItem('Veículo ou Placa', () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => VeiculoViewModel(),
                    child: const VeiculoPage(),
                  ),
                ),
              );
            }),
            _buildMenuItem('Histórico de corridas', () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) =>
                        HistoricoCorridasViewModel(doMototaxista: true),
                    child: const HistoricoCorridasPage(),
                  ),
                ),
              );
            }),
            _buildMenuItem('Notificações', () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => const NotificacoesPage(),
                ),
              );
            }),
            _buildMenuItem('Sair da conta', _confirmarLogout, isLast: true),
          ],
        ),
      ),
    );
  }
}
