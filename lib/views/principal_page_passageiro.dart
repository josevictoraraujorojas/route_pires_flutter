import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/views/perfil_passageiro.dart';
import 'package:route_pires_flutter/views/minhas_corridas_page.dart';
import 'package:route_pires_flutter/views/selecao_local_page.dart';

class PrincipalPagePassageiro extends StatefulWidget {
  const PrincipalPagePassageiro({super.key});

  @override
  State<PrincipalPagePassageiro> createState() =>
      _PrincipalPagePassageiroState();
}

class _PrincipalPagePassageiroState extends State<PrincipalPagePassageiro> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: CupertinoColors.systemBlue,
        inactiveColor: CupertinoColors.systemGrey2,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.compass),
            label: 'Corrida',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_fill),
            label: 'Avaliações',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.envelope_fill),
            label: 'Negociação',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_fill),
            label: 'Perfil',
          ),
        ],
      ),

      tabBuilder: (context, index) {
        switch (index) {
          // =====================================================
          // CORRIDA
          // =====================================================
          case 0:
            return CupertinoTabView(
              builder: (context) {
                return CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: const Text('Corrida'),
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.push<void>(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const MinhasCorridasPage(),
                        ),
                      ),
                      child: const Text('Minhas corridas'),
                    ),
                  ),
                  child: SafeArea(child: Center(child: SelecaoLocalPage())),
                );
              },
            );

          // =====================================================
          // AVALIAÇÕES
          // =====================================================
          case 1:
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text('Avaliações'),
                  ),
                  child: SafeArea(child: Center(child: Text('Avaliações'))),
                );
              },
            );

          // =====================================================
          // NEGOCIAÇÃO
          // =====================================================
          case 2:
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text('Negociação'),
                  ),
                  child: SafeArea(child: Center(child: Text('Negociação'))),
                );
              },
            );

          // =====================================================
          // PERFIL
          // =====================================================
          case 3:
            return CupertinoTabView(
              builder: (context) {
                return PerfilPassageiro();
              },
            );

          // =====================================================
          // PADRÃO
          // =====================================================
          default:
            return CupertinoTabView(
              builder: (context) {
                return CupertinoPageScaffold(
                  navigationBar: const CupertinoNavigationBar(
                    middle: Text('Corrida'),
                  ),
                  child: SafeArea(child: Center(child: SelecaoLocalPage())),
                );
              },
            );
        }
      },
    );
  }
}
