import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/viewmodel/solicitacoes_viewmodel.dart';
import 'package:route_pires_flutter/views/drawer_corrida.dart';
import 'package:route_pires_flutter/views/drawer_entrega.dart';
import 'package:route_pires_flutter/views/lista_passageiros.dart';

enum TipoSolicitacao { corrida, entrega }

class Corrida extends StatefulWidget {
  final Function(String) onTituloChanged;
  final String? mototaxistaId;

  const Corrida({super.key, required this.onTituloChanged, this.mototaxistaId});

  @override
  State<Corrida> createState() => _CorridaState();
}

class _CorridaState extends State<Corrida> {
  bool navegacaoInicializada = false;

  bool iniciandoNavegacao = false;

  bool navegacaoAtiva = false;

  bool mostrandoPassageiro = false;

  bool listaExpandida = true;

  SolicitacaoCorrida? solicitacaoSelecionada;

  TipoSolicitacao? tipoSolicitacao;

  SolicitacoesViewModel? solicitacoesViewModel;

  NavigationWaypoint? destinoCliente;

  NavigationWaypoint? destinoFinal;

  GoogleNavigationViewController? mapController;

  Future<void> inicializarNavegacao() async {
    final termosAceitos = await GoogleMapsNavigator.areTermsAccepted();

    if (!termosAceitos) {
      final aceitou = await GoogleMapsNavigator.showTermsAndConditionsDialog(
        'Google Navigation',
        'Route Pires',
      );

      if (!aceitou) {
        return;
      }
    }

    await GoogleMapsNavigator.initializeNavigationSession();

    if (!mounted) return;

    setState(() {
      navegacaoInicializada = true;
    });

    widget.onTituloChanged('Procurando Corrida');
  }

  Destinations criarDestinos() {
    final solicitacao = solicitacaoSelecionada;
    if (solicitacao == null) {
      throw Exception('Nenhuma solicitação selecionada.');
    }

    destinoCliente = NavigationWaypoint.withLatLngTarget(
      title: solicitacao.passageiroNome,
      target: LatLng(
        latitude: solicitacao.origem.latitude,
        longitude: solicitacao.origem.longitude,
      ),
    );

    destinoFinal = NavigationWaypoint.withLatLngTarget(
      title: 'Destino final',
      target: LatLng(
        latitude: solicitacao.destino.latitude,
        longitude: solicitacao.destino.longitude,
      ),
    );

    return Destinations(
      waypoints: [destinoCliente!, destinoFinal!],
      displayOptions: NavigationDisplayOptions(),
      routingOptions: criarOpcoesDeRota(),
    );
  }

  RoutingOptions criarOpcoesDeRota() {
    return RoutingOptions(travelMode: NavigationTravelMode.driving);
  }

  Future<void> iniciarNavegacao() async {
    if (iniciandoNavegacao) return;

    final viewModel = solicitacoesViewModel;
    final atual = solicitacaoSelecionada;

    if (viewModel == null || atual == null) {
      return;
    }

    final aceitou = await viewModel.aceitar(atual);

    if (!aceitou) {
      if (!mounted) return;

      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Erro'),
          content: Text(viewModel.erro ?? 'Não foi possível aceitar a corrida'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

      if (!mounted) return;

      setState(() {
        iniciandoNavegacao = false;
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      iniciandoNavegacao = true;
    });

    try {
      print('=================================');
      print('INICIANDO NAVEGAÇÃO');
      print('Tipo: $tipoSolicitacao');
      print('Solicitação: $solicitacaoSelecionada');
      print('=================================');

      print('Criando destinos...');

      final destinos = criarDestinos();

      print('Calculando rota...');

      final status = await GoogleMapsNavigator.setDestinations(destinos);

      if (status != NavigationRouteStatus.statusOk) {
        print('Erro ao calcular rota: $status');

        if (!mounted) return;

        setState(() {
          iniciandoNavegacao = false;
        });

        return;
      }

      print('Rota calculada com sucesso!');

      await GoogleMapsNavigator.startGuidance();

      print('Navegação iniciada!');

      if (!mounted) return;

      setState(() {
        iniciandoNavegacao = false;

        navegacaoAtiva = true;

        mostrandoPassageiro = false;

        listaExpandida = false;
      });

      widget.onTituloChanged('Em Navegação');

      print('Lista e drawer escondidos.');
    } catch (e) {
      print('Erro ao iniciar navegação: $e');

      if (!mounted) return;

      setState(() {
        iniciandoNavegacao = false;
      });
    }
  }

  Future<void> finalizarNavegacao() async {
    print('=================================');
    print('FINALIZANDO NAVEGAÇÃO');
    print('=================================');

    try {
      await GoogleMapsNavigator.stopGuidance();

      print('Guidance finalizado.');

      await GoogleMapsNavigator.clearDestinations();

      print('Rota removida do mapa.');

      if (!mounted) return;

      setState(() {
        navegacaoAtiva = false;

        iniciandoNavegacao = false;

        mostrandoPassageiro = false;

        solicitacaoSelecionada = null;

        tipoSolicitacao = null;

        listaExpandida = true;

        destinoCliente = null;

        destinoFinal = null;
      });

      widget.onTituloChanged('Procurando Corrida');

      print('Lista voltou.');
    } catch (e) {
      print('Erro ao finalizar navegação: $e');
    }
  }

  void abrirPassageiro(SolicitacaoCorrida solicitacao) {
    setState(() {
      solicitacaoSelecionada = solicitacao;

      mostrandoPassageiro = true;

      tipoSolicitacao = solicitacao.ehEntrega
          ? TipoSolicitacao.entrega
          : TipoSolicitacao.corrida;
    });

    widget.onTituloChanged(
      solicitacao.ehEntrega ? 'Detalhes da Entrega' : 'Detalhes da Corrida',
    );
  }

  Future<void> cancelarSolicitacao() async {
    final viewModel = solicitacoesViewModel;
    final atual = solicitacaoSelecionada;
    if (viewModel == null || atual == null) return;

    final recusou = await viewModel.recusar(atual);

    if (!mounted) return;

    if (recusou) {
      voltarParaLista();
      return;
    }

    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Erro'),
        content: Text(
          viewModel.erro ?? 'Não foi possível recusar a solicitação',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void voltarParaLista() {
    setState(() {
      mostrandoPassageiro = false;

      solicitacaoSelecionada = null;

      tipoSolicitacao = null;
    });

    widget.onTituloChanged('Procurando Corrida');
  }

  @override
  void initState() {
    super.initState();

    inicializarNavegacao();

    final mototaxistaId = widget.mototaxistaId;
    if (mototaxistaId != null && mototaxistaId.isNotEmpty) {
      solicitacoesViewModel = SolicitacoesViewModel(
        mototaxistaId: mototaxistaId,
      )..addListener(_aoAtualizarSolicitacoes);
      solicitacoesViewModel!.carregar();
    }
  }

  void _aoAtualizarSolicitacoes() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return navegacaoInicializada
        ? SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GoogleMapsNavigationView(
                    onViewCreated: (controller) async {
                      mapController = controller;

                      await controller.setMyLocationEnabled(true);

                      await controller.followMyLocation(
                        CameraPerspective.tilted,
                        zoomLevel: 18,
                      );

                      print('Mapa criado');
                    },
                  ),
                ),

                if (!navegacaoAtiva)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),

                      curve: Curves.easeInOut,

                      height: listaExpandida ? 500 : 100,

                      width: double.infinity,

                      decoration: const BoxDecoration(
                        color: CupertinoColors.white,

                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),

                        boxShadow: [
                          BoxShadow(
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: Offset(0, -2),
                            color: CupertinoColors.systemGrey4,
                          ),
                        ],
                      ),

                      child: Column(
                        children: [
                          SizedBox(
                            height: 45,
                            width: double.infinity,

                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  listaExpandida = !listaExpandida;

                                  if (!listaExpandida) {
                                    mostrandoPassageiro = false;

                                    solicitacaoSelecionada = null;

                                    tipoSolicitacao = null;

                                    widget.onTituloChanged(
                                      'Procurando Corrida',
                                    );
                                  }
                                });
                              },

                              child: Center(
                                child: Icon(
                                  listaExpandida
                                      ? CupertinoIcons.chevron_down
                                      : CupertinoIcons.chevron_up,

                                  size: 20,

                                  color: CupertinoColors.systemBlue,
                                ),
                              ),
                            ),
                          ),

                          Expanded(
                            child:
                                mostrandoPassageiro &&
                                    solicitacaoSelecionada != null
                                ? _construirDrawer()
                                : listaExpandida
                                ? ListaPassageiros(
                                    solicitacoes:
                                        solicitacoesViewModel?.solicitacoes ??
                                        const [],
                                    carregando:
                                        solicitacoesViewModel?.carregando ??
                                        false,
                                    erro:
                                        solicitacoesViewModel?.erro ??
                                        (widget.mototaxistaId == null ||
                                                widget.mototaxistaId!.isEmpty
                                            ? 'Faça login como mototaxista para ver solicitações'
                                            : null),
                                    onPassageiroSelecionado: abrirPassageiro,
                                  )
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (navegacaoAtiva)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,

                    child: CupertinoButton.filled(
                      onPressed: iniciandoNavegacao ? null : finalizarNavegacao,

                      child: const Text(
                        'Finalizar navegação',
                        style: TextStyle(color: CupertinoColors.white),
                      ),
                    ),
                  ),

                if (iniciandoNavegacao)
                  Positioned.fill(
                    child: Container(
                      color: CupertinoColors.black.withOpacity(0.15),

                      child: const Center(
                        child: CupertinoActivityIndicator(radius: 15),
                      ),
                    ),
                  ),
              ],
            ),
          )
        : const Center(child: CupertinoActivityIndicator());
  }

  Widget _construirDrawer() {
    final carregando = solicitacoesViewModel?.atualizandoStatus ?? false;

    if (tipoSolicitacao == TipoSolicitacao.entrega) {
      return DrawerEntrega(
        entrega: solicitacaoSelecionada!,
        onIniciar: iniciarNavegacao,
        onVoltar: cancelarSolicitacao,
        carregando: carregando,
      );
    }

    return DrawerCorrida(
      corrida: solicitacaoSelecionada!,
      onIniciar: iniciarNavegacao,
      onVoltar: cancelarSolicitacao,
      carregando: carregando,
    );
  }

  @override
  void dispose() {
    final viewModel = solicitacoesViewModel;
    if (viewModel != null) {
      viewModel.removeListener(_aoAtualizarSolicitacoes);
      viewModel.dispose();
    }

    if (navegacaoInicializada) {
      GoogleMapsNavigator.cleanup();
    }

    super.dispose();
  }
}
