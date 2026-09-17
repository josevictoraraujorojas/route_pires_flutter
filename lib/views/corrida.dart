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

  GoogleNavigationViewController? mapController;

  // ============================================================
  // DESTINOS DA ROTA
  // ============================================================

  NavigationWaypoint? destinoCliente;

  NavigationWaypoint? destinoFinal;

  final List<NavigationWaypoint> pontosDaRota = [];

  // Índice do ponto que está sendo atendido.
  //
  // 0 = primeiro ponto
  // 1 = segundo ponto
  // 2 = terceiro ponto
  // etc.
  int pontoAtual = 0;

  // Evita que o mesmo evento de chegada seja processado
  // mais de uma vez simultaneamente.
  bool processandoChegada = false;

  // Listener do evento de chegada.
  StreamSubscription<OnArrivalEvent>? arrivalSubscription;

  // ============================================================
  // INICIALIZAÇÃO DA NAVEGAÇÃO
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

    // ==========================================================
    // ESCUTA QUANDO O MOTOTAXISTA CHEGA A UM WAYPOINT
    // ==========================================================

    arrivalSubscription = GoogleMapsNavigator.setOnArrivalListener(
      _aoChegarNoPonto,
    );

    if (!mounted) return;

    setState(() {
      navegacaoInicializada = true;
    });

    widget.onTituloChanged('Procurando Corrida');
  }

  // ============================================================
  // CRIA OS DESTINOS
  // ============================================================

  Destinations criarDestinos() {
    final solicitacao = solicitacaoSelecionada;

    if (solicitacao == null) {
      throw Exception('Nenhuma solicitação selecionada.');
    }

    // Limpa a lista antes de criar novamente.
    pontosDaRota.clear();

    // ==========================================================
    // PONTO 1 - CLIENTE
    // ==========================================================

    destinoCliente = NavigationWaypoint.withLatLngTarget(
      title: solicitacao.passageiroNome,
      target: LatLng(
        latitude: solicitacao.origem.latitude,
        longitude: solicitacao.origem.longitude,
      ),
    );

    pontosDaRota.add(destinoCliente!);

    // ==========================================================
    // PONTO 2 - DESTINO FINAL
    // ==========================================================

    destinoFinal = NavigationWaypoint.withLatLngTarget(
      title: 'Destino final',
      target: LatLng(
        latitude: solicitacao.destino.latitude,
        longitude: solicitacao.destino.longitude,
      ),
    );

    pontosDaRota.add(destinoFinal!);

    pontoAtual = 0;

    print('=================================');
    print('PONTOS DA ROTA');
    print('=================================');

    for (int i = 0; i < pontosDaRota.length; i++) {
      print('Ponto ${i + 1}: ${pontosDaRota[i].title}');
    }

    print('=================================');

    return Destinations(
      waypoints: pontosDaRota,
      displayOptions: NavigationDisplayOptions(),
      routingOptions: criarOpcoesDeRota(),
    );
  }

  // ============================================================
  // OPÇÕES DE ROTA
  // ============================================================

  RoutingOptions criarOpcoesDeRota() {
    return RoutingOptions(travelMode: NavigationTravelMode.driving);
  }

  // ============================================================
  // EVENTO DE CHEGADA A UM PONTO
  // ============================================================

  Future<void> _aoChegarNoPonto(OnArrivalEvent evento) async {
    // Impede processamento duplicado.
    if (processandoChegada) {
      print('Chegada já está sendo processada.');
      return;
    }

    processandoChegada = true;

    try {
      print('');
      print('=================================');
      print('CHEGOU AO WAYPOINT');
      print('=================================');
      print('Ponto atual: ${pontoAtual + 1}');
      print('Total de pontos: ${pontosDaRota.length}');
      print('Waypoint recebido: ${evento.waypoint}');
      print('=================================');

      // ========================================================
      // AINDA EXISTE OUTRO PONTO?
      // ========================================================

      if (pontoAtual < pontosDaRota.length - 1) {
        // Avança o índice.
        pontoAtual++;

        print(
          'Avançando para o ponto '
          '${pontoAtual + 1} '
          'de ${pontosDaRota.length}',
        );

        // ======================================================
        // MANDA O GOOGLE NAVIGATION CONTINUAR PARA O PRÓXIMO
        // ======================================================

        final resposta = await GoogleMapsNavigator.continueToNextDestination();

        print(
          'continueToNextDestination(): '
          '$resposta',
        );

        print('Navegação para o próximo ponto iniciada.');

        if (mounted) {
          setState(() {});
        }
      } else {
        // ======================================================
        // CHEGOU AO ÚLTIMO PONTO
        // ======================================================

        print('');
        print('=================================');
        print('ÚLTIMO DESTINO ALCANÇADO');
        print('=================================');

        if (mounted) {
          widget.onTituloChanged('Destino final alcançado');

          setState(() {});
        }

        // Não chama finalizarNavegacao() automaticamente.
        //
        // O botão "Finalizar navegação" continuará disponível.
      }
    } catch (e) {
      print('Erro ao avançar para o próximo ponto: $e');
    } finally {
      processandoChegada = false;
    }
  }

  // ============================================================
  // INICIAR NAVEGAÇÃO
  // ============================================================

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
      print('');
      print('=================================');
      print('INICIANDO NAVEGAÇÃO');
      print('=================================');
      print('Tipo: $tipoSolicitacao');
      print('Solicitação: $solicitacaoSelecionada');
      print('=================================');

      // ========================================================
      // CRIA OS PONTOS
      // ========================================================

      print('Criando destinos...');

      final destinos = criarDestinos();

      print('Total de pontos: ${pontosDaRota.length}');

      // ========================================================
      // CALCULA A ROTA
      // ========================================================

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

      // ========================================================
      // INICIA A ORIENTAÇÃO
      // ========================================================

      await GoogleMapsNavigator.startGuidance();

      print('Navegação iniciada!');

      print(
        'Navegando para o ponto '
        '${pontoAtual + 1} '
        'de ${pontosDaRota.length}',
      );

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

  // ============================================================
  // FINALIZAR NAVEGAÇÃO
  // ============================================================

  Future<void> finalizarNavegacao() async {
    final viewModel = solicitacoesViewModel;
    final atual = solicitacaoSelecionada;

    print('');
    print('=================================');
    print('FINALIZANDO NAVEGAÇÃO');
    print('=================================');

    try {
      await GoogleMapsNavigator.stopGuidance();

      print('Guidance finalizado.');

      await GoogleMapsNavigator.clearDestinations();

      print('Rota removida do mapa.');

      // Mantendo o comportamento que já existia
      // no seu arquivo.
      if (viewModel != null && atual != null) {
        await viewModel.finalizar(atual);
      }

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

        pontosDaRota.clear();

        pontoAtual = 0;

        processandoChegada = false;
      });

      widget.onTituloChanged('Procurando Corrida');

      print('Lista voltou.');
    } catch (e) {
      print('Erro ao finalizar navegação: $e');
    }
  }

  // ============================================================
  // ABRIR PASSAGEIRO
  // ============================================================

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

  // ============================================================
  // CANCELAR SOLICITAÇÃO
  // ============================================================

  Future<void> cancelarSolicitacao() async {
    final viewModel = solicitacoesViewModel;

    final atual = solicitacaoSelecionada;

    if (viewModel == null || atual == null) {
      return;
    }

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

  // ============================================================
  // VOLTAR PARA LISTA
  // ============================================================

  void voltarParaLista() {
    setState(() {
      mostrandoPassageiro = false;

      solicitacaoSelecionada = null;

      tipoSolicitacao = null;
    });

    widget.onTituloChanged('Procurando Corrida');
  }

  // ============================================================
  // INIT STATE
  // ============================================================

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

  // ============================================================
  // ATUALIZAÇÃO DAS SOLICITAÇÕES
  // ============================================================

  void _aoAtualizarSolicitacoes() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

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

  // ============================================================
  // DRAWER
  // ============================================================

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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    // Remove o listener de chegada.
    arrivalSubscription?.cancel();

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
