import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:route_pires_flutter/views/drawer_corrida.dart';
import 'package:route_pires_flutter/views/drawer_entrega.dart';
import 'package:route_pires_flutter/views/lista_passageiros.dart';

enum TipoSolicitacao { corrida, entrega }

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

  bool mostrandoPassageiro = false;

  bool listaExpandida = true;

  // ============================================================
  // SOLICITAÇÃO SELECIONADA
  // ============================================================

  Map<String, dynamic>? solicitacaoSelecionada;

  TipoSolicitacao? tipoSolicitacao;

  // ============================================================
  // DESTINOS
  // ============================================================

  NavigationWaypoint? destinoCliente;

  NavigationWaypoint? destinoFinal;

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

    if (!mounted) return;

    setState(() {
      navegacaoInicializada = true;
    });
  }

  // ============================================================
  // CRIAR DESTINOS
  // ============================================================

  Destinations criarDestinos() {
    if (solicitacaoSelecionada == null) {
      throw Exception('Nenhuma solicitação selecionada.');
    }

    // ==========================================================
    // DADOS DO CLIENTE
    // ==========================================================

    final double latitudeCliente = double.parse(
      solicitacaoSelecionada!['latitude_cliente'].toString(),
    );

    final double longitudeCliente = double.parse(
      solicitacaoSelecionada!['longitude_cliente'].toString(),
    );

    // ==========================================================
    // DADOS DO DESTINO FINAL
    // ==========================================================

    final double latitudeDestino = double.parse(
      solicitacaoSelecionada!['latitude_destino'].toString(),
    );

    final double longitudeDestino = double.parse(
      solicitacaoSelecionada!['longitude_destino'].toString(),
    );

    final String nome =
        solicitacaoSelecionada!['nome']?.toString() ?? 'Cliente';

    // ==========================================================
    // WAYPOINT DO CLIENTE
    // ==========================================================

    destinoCliente = NavigationWaypoint.withLatLngTarget(
      title: nome,

      target: LatLng(latitude: latitudeCliente, longitude: longitudeCliente),
    );

    // ==========================================================
    // WAYPOINT DO DESTINO FINAL
    // ==========================================================

    destinoFinal = NavigationWaypoint.withLatLngTarget(
      title: 'Destino final',

      target: LatLng(latitude: latitudeDestino, longitude: longitudeDestino),
    );

    // ==========================================================
    // LOG
    // ==========================================================

    print('=================================');
    print('DESTINOS DA SOLICITAÇÃO');
    print('=================================');

    print('Cliente: $nome');

    print('Latitude cliente: $latitudeCliente');

    print('Longitude cliente: $longitudeCliente');

    print('---------------------------------');

    print('Latitude destino: $latitudeDestino');

    print('Longitude destino: $longitudeDestino');

    print('=================================');

    // ==========================================================
    // RETORNA OS DOIS DESTINOS
    // ==========================================================

    return Destinations(
      waypoints: [destinoCliente!, destinoFinal!],

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
      print('=================================');
      print('INICIANDO NAVEGAÇÃO');
      print('Tipo: $tipoSolicitacao');
      print('Solicitação: $solicitacaoSelecionada');
      print('=================================');

      // ========================================================
      // CRIAR OS DOIS DESTINOS
      // ========================================================

      print('Criando destinos...');

      final destinos = criarDestinos();

      // ========================================================
      // CALCULAR ROTA
      // ========================================================

      print('Calculando rota...');

      final status = await GoogleMapsNavigator.setDestinations(destinos);

      // ========================================================
      // VERIFICAR STATUS
      // ========================================================

      if (status != NavigationRouteStatus.statusOk) {
        print('Erro ao calcular rota: $status');

        if (!mounted) return;

        setState(() {
          iniciandoNavegacao = false;
        });

        return;
      }

      print('Rota calculada com sucesso!');

      // ========================================================
      // INICIAR GUIDANCE
      // ========================================================

      await GoogleMapsNavigator.startGuidance();

      print('Navegação iniciada!');

      // ========================================================
      // ESCONDER LISTA E DRAWER
      // ========================================================

      if (!mounted) return;

      setState(() {
        iniciandoNavegacao = false;

        navegacaoAtiva = true;

        mostrandoPassageiro = false;

        listaExpandida = false;
      });

      print('Lista e drawer escondidos.');
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
    print('=================================');
    print('FINALIZANDO NAVEGAÇÃO');
    print('=================================');

    try {
      // ========================================================
      // PARAR NAVEGAÇÃO
      // ========================================================

      await GoogleMapsNavigator.stopGuidance();

      print('Guidance finalizado.');

      // ========================================================
      // REMOVER ROTA
      // ========================================================

      await GoogleMapsNavigator.clearDestinations();

      print('Rota removida do mapa.');

      // ========================================================
      // LIMPAR ESTADOS
      // ========================================================

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

      print('Lista voltou.');
    } catch (e) {
      print('Erro ao finalizar navegação: $e');
    }
  }

  // ============================================================
  // ABRIR SOLICITAÇÃO
  // ============================================================

  void abrirPassageiro(Map<String, dynamic> solicitacao) {
    final String tipo =
        solicitacao['tipo']?.toString().toLowerCase() ?? 'corrida';

    setState(() {
      // Aqui guardamos TODOS os dados.
      //
      // Isso inclui:
      // latitude_cliente
      // longitude_cliente
      // latitude_destino
      // longitude_destino

      solicitacaoSelecionada = solicitacao;

      mostrandoPassageiro = true;

      if (tipo == 'entrega') {
        tipoSolicitacao = TipoSolicitacao.entrega;
      } else {
        tipoSolicitacao = TipoSolicitacao.corrida;
      }
    });

    print(
      'Solicitação selecionada: '
      '$tipoSolicitacao',
    );

    print('Dados: $solicitacao');
  }

  // ============================================================
  // VOLTAR PARA LISTA
  // ============================================================

  void voltarParaLista() {
    setState(() {
      mostrandoPassageiro = false;

      solicitacaoSelecionada = null;

      tipoSolicitacao = null;
    });
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
    return navegacaoInicializada
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
                // PAINEL INFERIOR
                // ==================================================
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
                          // ========================================
                          // SETA
                          // ========================================

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

                          // ========================================
                          // CONTEÚDO
                          // ========================================
                          Expanded(
                            child:
                                mostrandoPassageiro &&
                                    solicitacaoSelecionada != null
                                ? _construirDrawer()
                                : listaExpandida
                                ? ListaPassageiros(
                                    onPassageiroSelecionado: abrirPassageiro,
                                  )
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ==================================================
                // BOTÃO FINALIZAR
                // ==================================================
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

                // ==================================================
                // LOADING
                // ==================================================
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

  // ============================================================
  // CONSTRUIR DRAWER
  // ============================================================

  Widget _construirDrawer() {
    if (tipoSolicitacao == TipoSolicitacao.entrega) {
      return DrawerEntrega(
        entrega: solicitacaoSelecionada!,

        onIniciar: iniciarNavegacao,

        onVoltar: voltarParaLista,
      );
    }

    return DrawerCorrida(
      corrida: solicitacaoSelecionada!,

      onIniciar: iniciarNavegacao,

      onVoltar: voltarParaLista,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (navegacaoInicializada) {
      GoogleMapsNavigator.cleanup();
    }

    super.dispose();
  }
}
