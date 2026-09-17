import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';
import 'package:route_pires_flutter/views/login_page.dart';

class PerfilMototaxista extends StatefulWidget {
  const PerfilMototaxista({super.key});

  @override
  State<PerfilMototaxista> createState() => _PerfilMototaxistaState();
}

class _PerfilMototaxistaState extends State<PerfilMototaxista> {
  bool disponivel = true;
  bool alterandoDisponibilidade = false;

  // ============================================================
  // ALTERAR DISPONIBILIDADE
  // ============================================================

  Future<void> _alterarDisponibilidade(bool valor) async {
    if (alterandoDisponibilidade) return;

    final loginViewModel = context.read<LoginViewModel>();
    final mototaxistaId = loginViewModel.usuario?.id;

    if (mototaxistaId == null || mototaxistaId.isEmpty) {
      _mostrarErro('Não foi possível identificar o mototaxista.');
      return;
    }

    final valorAnterior = disponivel;

    setState(() {
      disponivel = valor;
      alterandoDisponibilidade = true;
    });

    try {
      final sucesso = await context
          .read<MototaxistaViewModel>()
          .alterarDisponibilidade(id: mototaxistaId, disponivel: valor);

      if (!mounted) return;

      if (!sucesso) {
        setState(() {
          disponivel = valorAnterior;
        });

        final erro = context.read<MototaxistaViewModel>().erro;

        _mostrarErro(erro ?? 'Não foi possível alterar sua disponibilidade.');
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        disponivel = valorAnterior;
      });

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

    await loginViewModel.sair();

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<LoginViewModel>().usuario;

    final nome = usuario?.nome ?? 'Mototaxista';

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
                '@mototaxi',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ========================================================
            // DISPONIBILIDADE
            // ========================================================
            const Center(
              child: Text(
                'Disponibilidade:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: alterandoDisponibilidade
                  ? const SizedBox(
                      width: 64,
                      height: 32,
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  : CupertinoSwitch(
                      value: disponivel,
                      activeTrackColor: CupertinoColors.systemGreen,
                      onChanged: _alterarDisponibilidade,
                    ),
            ),

            const SizedBox(height: 22),

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
