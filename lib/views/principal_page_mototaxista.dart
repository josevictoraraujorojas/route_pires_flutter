import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';
import 'package:route_pires_flutter/views/corrida.dart';
import 'package:route_pires_flutter/views/perfil_mototaxista.dart';

class PrincipalPageMototaxista extends StatefulWidget {
  const PrincipalPageMototaxista({super.key});

  @override
  State<PrincipalPageMototaxista> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPageMototaxista>
    with WidgetsBindingObserver {
  String tituloCorrida = 'Procurando Corrida';
  LoginViewModel? _login;
  MototaxistaViewModel? _mototaxista;
  String? _mototaxistaId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_login != null) return;
    _login = context.read<LoginViewModel>()..addListener(_sincronizarSessao);
    _mototaxista = context.read<MototaxistaViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sincronizarSessao());
  }

  void _sincronizarSessao() {
    if (!mounted) return;
    final id = _login?.usuario?.id;
    if (id == _mototaxistaId) return;
    _mototaxista?.pararLocalizacao();
    _mototaxistaId = id;
    if (id == null || id.isEmpty) return;
    _mototaxista?.definirLocalizacaoAtiva(
      WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    unawaited(_mototaxista?.consultarDisponibilidade(id: id));
  }

  void _atendimentoMudou(bool emAtendimento) {
    final id = _mototaxistaId;
    if (id != null) {
      _mototaxista?.definirEmAtendimento(id: id, emAtendimento: emAtendimento);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _mototaxista?.definirLocalizacaoAtiva(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _login?.removeListener(_sincronizarSessao);
    _mototaxista?.pararLocalizacao();
    super.dispose();
  }

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
        backgroundColor: CupertinoColors.white,
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
          // ============================================================
          // CORRIDA
          // ============================================================

          case 0:
            return CupertinoTabView(
              builder: (context) {
                return CupertinoPageScaffold(
                  backgroundColor: CupertinoColors.white,
                  navigationBar: CupertinoNavigationBar(
                    backgroundColor: CupertinoColors.white,
                    middle: Text(tituloCorrida),
                  ),
                  child: Corrida(
                    onTituloChanged: alterarTituloCorrida,
                    mototaxistaId: mototaxistaId,
                    onAtendimentoChanged: _atendimentoMudou,
                  ),
                );
              },
            );

          // ============================================================
          // AVALIAÇÕES
          // ============================================================

          case 1:
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(
                  backgroundColor: CupertinoColors.white,
                  navigationBar: CupertinoNavigationBar(
                    backgroundColor: CupertinoColors.white,
                    middle: Text('Avaliações'),
                  ),
                  child: Center(child: Text('Avaliações')),
                );
              },
            );

          // ============================================================
          // NEGOCIAÇÃO
          // ============================================================

          case 2:
            return CupertinoTabView(
              builder: (context) {
                return const CupertinoPageScaffold(
                  backgroundColor: CupertinoColors.white,
                  navigationBar: CupertinoNavigationBar(
                    backgroundColor: CupertinoColors.white,
                    middle: Text('Negociação'),
                  ),
                  child: Center(child: Text('Negociação')),
                );
              },
            );

          // ============================================================
          // PERFIL
          // ============================================================

          case 3:
            return CupertinoTabView(
              builder: (context) {
                return const PerfilMototaxista();
              },
            );

          // ============================================================
          // PADRÃO
          // ============================================================

          default:
            return CupertinoTabView(
              builder: (context) {
                return CupertinoPageScaffold(
                  backgroundColor: CupertinoColors.white,
                  navigationBar: CupertinoNavigationBar(
                    backgroundColor: CupertinoColors.white,
                    middle: Text(tituloCorrida),
                  ),
                  child: Corrida(
                    onTituloChanged: alterarTituloCorrida,
                    mototaxistaId: mototaxistaId,
                    onAtendimentoChanged: _atendimentoMudou,
                  ),
                );
              },
            );
        }
      },
    );
  }
}
