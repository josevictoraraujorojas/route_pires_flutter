import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/editar_perfil_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/historico_corridas_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';

import 'package:route_pires_flutter/views/editar_perfil_page.dart';
import 'package:route_pires_flutter/views/historico_corridas_page.dart';
import 'package:route_pires_flutter/views/notificacoes_page.dart';

class PerfilPassageiro extends StatefulWidget {
  const PerfilPassageiro({super.key});

  @override
  State<PerfilPassageiro> createState() => _PerfilPassageiroState();
}

class _PerfilPassageiroState extends State<PerfilPassageiro> {
  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> _fazerLogout() async {
    final loginViewModel = context.read<LoginViewModel>();
    final saiu = await loginViewModel.sair();

    if (!mounted) return;
    if (!saiu) {
      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Erro'),
          content: Text(
            loginViewModel.erro ?? 'Não foi possível sair da conta',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
              onPressed: () => Navigator.of(dialogContext).pop(),
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

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<LoginViewModel>().usuario;
    final nome = usuario?.nome ?? 'Passageiro';
    final email = usuario?.email ?? '@passageiro';

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

            // NOME E USERNAME
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

            // MENUS
            _buildMenuItem('Editar perfil', () {
              Navigator.push(
                context, 
                CupertinoPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => EditarPerfilViewModel(),
                    child: const EditarPerfilPage(),
                  )
                )
              );
            }),
            _buildMenuItem('Histórico de corridas', () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => HistoricoCorridasViewModel(),
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