import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/views/corrida.dart';

class PrincipalPageMototaxista extends StatefulWidget {
  const PrincipalPageMototaxista({super.key});

  @override
  State<PrincipalPageMototaxista> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPageMototaxista> {
  String tituloCorrida = 'Procurando Corrida';

  void alterarTituloCorrida(String novoTitulo) {
    setState(() {
      tituloCorrida = novoTitulo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mototaxistaId = context.watch<LoginViewModel>().usuario?.id;

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: CupertinoColors.systemBlue,
        inactiveColor: CupertinoColors.systemGrey2,

        items: [
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
          case 0:
            return CupertinoTabView(
              builder: (context) {
                return CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text(tituloCorrida),
                  ),

                  child: Corrida(
                    onTituloChanged: alterarTituloCorrida,
                    mototaxistaId: mototaxistaId,
                  ),
                );
              },
            );

          case 1:
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text('Avaliações'),
                  ),
                  child: Center(child: Text('Avaliações')),
                );
              },
            );

          case 2:
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text('Negociação'),
                  ),
                  child: Center(child: Text('Negociação')),
                );
              },
            );

          case 3:
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(middle: Text('Perfil')),
                  child: Center(child: Text('Perfil')),
                );
              },
            );

          default:
            return CupertinoTabView(
              builder: (context) {
                return CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text(tituloCorrida),
                  ),
                  child: Corrida(
                    onTituloChanged: alterarTituloCorrida,
                    mototaxistaId: mototaxistaId,
                  ),
                );
              },
            );
        }
      },
    );
  }
}
