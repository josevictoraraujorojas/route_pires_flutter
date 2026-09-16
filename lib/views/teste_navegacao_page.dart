import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:route_pires_flutter/views/lista_passageiros.dart';

class TesteNavegacaoPage extends StatefulWidget {
  const TesteNavegacaoPage({super.key});

  @override
  State<TesteNavegacaoPage> createState() => _TesteNavegacaoPageState();
}

class _TesteNavegacaoPageState extends State<TesteNavegacaoPage> {
  // ============================================================
  // ESTADOS
  // ============================================================

  bool navegacaoInicializada = false;
  bool iniciandoNavegacao = false;
  bool navegacaoAtiva = false;

  // Controle da lista de passageiros
  bool listaExpandida = false;

  // ============================================================
  // DESTINO
  // ============================================================

  NavigationWaypoint? destino;

  // ============================================================
  // LISTENER
  // ============================================================

  StreamSubscription<RemainingTimeOrDistanceChangedEvent>? distanciaListener;

  // ============================================================
  // INFORMAÇÕES DA NAVEGAÇÃO
  // ============================================================

  double distanciaRestante = 0;
  double tempoRestante = 0;

  TrafficDelaySeverity nivelTransito = TrafficDelaySeverity.noData;

  // ============================================================
  // CONTROLLER DO MAPA
  // ============================================================

  GoogleNavigationViewController? mapController;

  // ============================================================
  // INICIALIZAR NAVEGAÇÃO
  // ============================================================

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

    configurarListenerDistancia();

    if (!mounted) return;

    setState(() {
      navegacaoInicializada = true;
    });
  }

  // ============================================================
  // CRIAR DESTINO
  // ============================================================

  void criarDestino() {
    destino = NavigationWaypoint.withLatLngTarget(
      title: 'Destino',
      target: LatLng(latitude: -17.4654, longitude: -48.2044),
    );
  }

  // ============================================================
  // CRIAR DESTINOS
  // ============================================================

  Destinations criarDestinos() {
    criarDestino();

    return Destinations(
      waypoints: [destino!],
      displayOptions: NavigationDisplayOptions(),
      routingOptions: criarOpcoesDeRota(),
    );
  }

  // ============================================================
  // OPÇÕES DA ROTA
  // ============================================================

  RoutingOptions criarOpcoesDeRota() {
    return RoutingOptions(travelMode: NavigationTravelMode.driving);
  }

  // ============================================================
  // INICIAR NAVEGAÇÃO
  // ============================================================

  Future<void> iniciarNavegacao() async {
    if (iniciandoNavegacao) return;

    if (!mounted) return;

    setState(() {
      iniciandoNavegacao = true;
    });

    try {
      print('Criando destino...');

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
      });
    } catch (e) {
      print('Erro ao iniciar navegação: $e');

      if (!mounted) return;

      setState(() {
        iniciandoNavegacao = false;
      });
    }
  }

  // ============================================================
  // FINALIZAR NAVEGAÇÃO
  // ============================================================

  Future<void> finalizarNavegacao() async {
    print('Finalizando navegação...');

    try {
      await GoogleMapsNavigator.stopGuidance();

      print('Navegação finalizada!');

      if (!mounted) return;

      setState(() {
        navegacaoAtiva = false;

        distanciaRestante = 0;
        tempoRestante = 0;

        nivelTransito = TrafficDelaySeverity.noData;
      });
    } catch (e) {
      print('Erro ao finalizar navegação: $e');
    }
  }

  // ============================================================
  // LISTENER DE DISTÂNCIA, TEMPO E TRÂNSITO
  // ============================================================

  void configurarListenerDistancia() {
    distanciaListener =
        GoogleMapsNavigator.setOnRemainingTimeOrDistanceChangedListener((
          evento,
        ) {
          print('=================================');
          print('ATUALIZAÇÃO DA NAVEGAÇÃO');
          print('Distância: ${evento.remainingDistance}');
          print('Tempo: ${evento.remainingTime}');
          print('Trânsito: ${evento.delaySeverity}');
          print('=================================');

          if (!mounted) return;

          setState(() {
            distanciaRestante = evento.remainingDistance;

            tempoRestante = evento.remainingTime;

            nivelTransito = evento.delaySeverity;
          });
        });
  }

  // ============================================================
  // FORMATAR DISTÂNCIA
  // ============================================================

  String obterDistanciaFormatada() {
    if (distanciaRestante <= 0) {
      return 'Calculando...';
    }

    if (distanciaRestante >= 1000) {
      final km = distanciaRestante / 1000;

      return '${km.toStringAsFixed(1)} km';
    }

    return '${distanciaRestante.toStringAsFixed(0)} m';
  }

  // ============================================================
  // FORMATAR TEMPO
  // ============================================================

  String obterTempoFormatado() {
    if (tempoRestante <= 0) {
      return 'Calculando...';
    }

    final minutos = (tempoRestante / 60).ceil();

    return '$minutos min';
  }

  // ============================================================
  // TEXTO DO TRÂNSITO
  // ============================================================

  String obterTextoTransito() {
    switch (nivelTransito) {
      case TrafficDelaySeverity.light:
        return 'Trânsito leve';

      case TrafficDelaySeverity.medium:
        return 'Trânsito médio';

      case TrafficDelaySeverity.heavy:
        return 'Trânsito intenso';

      case TrafficDelaySeverity.noData:
        return 'Sem dados';
    }
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    inicializarNavegacao();
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Navegação',
          style: TextStyle(color: CupertinoColors.black),
        ),
      ),

      child: navegacaoInicializada
          ? SafeArea(
              child: Stack(
                children: [
                  // ==================================================
                  // MAPA
                  // ==================================================

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

                  // ==================================================
                  // LISTA DE PASSAGEIROS
                  // ==================================================
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
                          // ========================================
                          // SETA
                          // ========================================

                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  listaExpandida = !listaExpandida;
                                });
                              },

                              child: SizedBox(
                                width: double.infinity,

                                height: 45,

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
                          ),

                          // ========================================
                          // LISTA
                          // ========================================
                          Expanded(
                            child: listaExpandida
                                ? const ListaPassageiros()
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ==================================================
                  // BOTÃO DE NAVEGAÇÃO
                  // ==================================================
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,

                    child: CupertinoButton.filled(
                      onPressed: iniciandoNavegacao
                          ? null
                          : navegacaoAtiva
                          ? finalizarNavegacao
                          : iniciarNavegacao,

                      child: Text(
                        iniciandoNavegacao
                            ? 'Calculando rota...'
                            : navegacaoAtiva
                            ? 'Finalizar navegação'
                            : 'Iniciar navegação',

                        style: const TextStyle(color: CupertinoColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const Center(child: CupertinoActivityIndicator()),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    distanciaListener?.cancel();

    if (navegacaoInicializada) {
      GoogleMapsNavigator.cleanup();
    }

    super.dispose();
  }
}
