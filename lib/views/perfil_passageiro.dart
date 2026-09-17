import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/views/login_page.dart';

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

    // Remove o usuário salvo e encerra a sessão
    await loginViewModel.sair();

    if (!mounted) return;

    // Vai diretamente para o Login
    // removendo todas as telas anteriores.
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ============================================================
  // CONFIRMAR LOGOUT
  // ============================================================

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
                // Fecha o diálogo
                Navigator.of(dialogContext).pop();

                // Faz logout
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<LoginViewModel>().usuario;

    final nome = usuario?.nome ?? 'Passageiro';

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Perfil')),

      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 18),

            // ========================================================
            // ÍCONE / FOTO DO PERFIL
            // ========================================================
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      size: 42,
                      color: Color(0xFF9BCBFF),
                    ),
                  ),

                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        color: CupertinoColors.systemBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.pencil,
                        size: 13,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ========================================================
            // NOME
            // ========================================================
            Center(
              child: Text(
                nome,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ========================================================
            // USUÁRIO
            // ========================================================
            const Center(
              child: Text(
                '@passageiro',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ========================================================
            // LINHA SEPARADORA
            // ========================================================
            Container(height: 1, color: CupertinoColors.separator),

            // ========================================================
            // SAIR DA CONTA
            // ========================================================
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              onPressed: _confirmarLogout,
              child: const Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sair da conta',
                        style: TextStyle(
                          color: CupertinoColors.label,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 20,
                    color: CupertinoColors.systemGrey,
                  ),
                ],
              ),
            ),

            // ========================================================
            // LINHA INFERIOR
            // ========================================================
            Container(height: 1, color: CupertinoColors.separator),
          ],
        ),
      ),
    );
  }
}
