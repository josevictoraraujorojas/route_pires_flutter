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

  bool inicializandoNavegacao = false;

  String? erroNavegacao;

  bool iniciandoNavegacao = false;

  bool navegacaoAtiva = false;

  bool corridaAceita = false;

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

  Future<bool> inicializarNavegacao() async {
    if (navegacaoInicializada) return true;
    if (inicializandoNavegacao) return false;

    setState(() {
      inicializandoNavegacao = true;
      erroNavegacao = null;
    });

    try {
      final termosAceitos = await GoogleMapsNavigator.areTermsAccepted();
      if (!termosAceitos) {
        final aceitou = await GoogleMapsNavigator.showTermsAndConditionsDialog(
          'Google Navigation',
          'Route Pires',
        );
        if (!aceitou) {
          if (mounted) {
            setState(() {
              erroNavegacao = 'Os termos da navegação não foram aceitos. As solicitações continuam disponíveis.';
            });
          }
          return false;
        }
      }

      await GoogleMapsNavigator.initializeNavigationSession();
      if (!mounted) {
        await GoogleMapsNavigator.cleanup();
        return false;
      }

      arrivalSubscription = GoogleMapsNavigator.setOnArrivalListener(
        _aoChegarNoPonto,
      );
      setState(() {
        navegacaoInicializada = true;
        erroNavegacao = null;
      });
      return true;
    } catch (_) {
      if (mounted) {
        setState(() {
          erroNavegacao = 'Não foi possível iniciar o Google Navigation. As solicitações continuam disponíveis.';
        });
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          inicializandoNavegacao = false;
        });
      }
    }
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

  Future<void> _aoChegarNoPonto(OnArrivalEvent _) async {
    // Impede processamento duplicado.
    if (processandoChegada) {
      return;
    }

    processandoChegada = true;

    try {
      // ========================================================
      // AINDA EXISTE OUTRO PONTO?
      // ========================================================

      if (pontoAtual < pontosDaRota.length - 1) {
        // Avança o índice.
        pontoAtual++;

        // ======================================================
        // MANDA O GOOGLE NAVIGATION CONTINUAR PARA O PRÓXIMO
        // ======================================================

        await GoogleMapsNavigator.continueToNextDestination();

        if (mounted) {
          setState(() {});
        }
      } else {
        // ======================================================
        // CHEGOU AO ÚLTIMO PONTO
        // ======================================================

        if (mounted) {
          widget.onTituloChanged('Destino final alcançado');

          setState(() {});
        }

        // Não chama finalizarNavegacao() automaticamente.
        //
        // O botão "Finalizar navegação" continuará disponível.
      }
    } catch (_) {
      if (mounted) widget.onTituloChanged('Falha na navegação');
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

    setState(() {
      iniciandoNavegacao = true;
    });

    try {
      // Confirma os termos antes de alterar o estado da corrida na API.
      if (!navegacaoInicializada && !await inicializarNavegacao()) return;
      if (!mounted) return;

      // Uma tentativa de rota pode falhar depois do aceite. Nesse caso, uma
      // nova tentativa não deve enviar ANDAMENTO pela segunda vez.
      if (!corridaAceita) {
        final aceitou = await viewModel.aceitar(atual);
        if (!mounted) return;
        if (!aceitou) {
          _mostrarErroCorrida(
            viewModel.erro ?? 'Não foi possível aceitar a corrida',
          );
          return;
        }
        setState(() {
          corridaAceita = true;
        });
      }

      final destinos = criarDestinos();
      final status = await GoogleMapsNavigator.setDestinations(destinos);
      if (status != NavigationRouteStatus.statusOk) {
        if (!mounted) return;
        setState(() {
          erroNavegacao = 'Não foi possível traçar a rota. A corrida segue em andamento; tente a navegação novamente ou use as ações abaixo.';
        });
        return;
      }

      await GoogleMapsNavigator.startGuidance();
      if (!mounted) return;
      setState(() {
        navegacaoAtiva = true;
        erroNavegacao = null;
        mostrandoPassageiro = false;
        listaExpandida = false;
      });
      widget.onTituloChanged('Em Navegação');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        erroNavegacao = 'A navegação falhou. A corrida segue em andamento; tente novamente ou use as ações abaixo.';
      });
    } finally {
      if (mounted) setState(() => iniciandoNavegacao = false);
    }
  }

  // ============================================================
  // FINALIZAR NAVEGAÇÃO
  // ============================================================

  Future<void> finalizarNavegacao() async {
    final viewModel = solicitacoesViewModel;
    final atual = solicitacaoSelecionada;
    if (viewModel == null ||
        atual == null ||
        iniciandoNavegacao ||
        viewModel.atualizandoStatus) {
      return;
    }

    setState(() => iniciandoNavegacao = true);

    try {
      final finalizou = await viewModel.finalizar(atual);
      if (!mounted) return;
      if (!finalizou) {
        _mostrarErroCorrida(
          viewModel.erro ?? 'Não foi possível finalizar a corrida',
        );
        return;
      }

      await _pararNavegacao();
      if (!mounted) return;
      _limparCorridaSelecionada();
      unawaited(viewModel.carregar());
    } catch (_) {
      if (mounted) {
        _mostrarErroCorrida('Não foi possível finalizar a corrida');
      }
    } finally {
      if (mounted) setState(() => iniciandoNavegacao = false);
    }
  }

  Future<void> _pararNavegacao() async {
    if (!navegacaoInicializada) return;
    try {
      await GoogleMapsNavigator.stopGuidance();
    } catch (_) {
      // O status confirmado pela API não depende do encerramento do SDK.
    }
    try {
      await GoogleMapsNavigator.clearDestinations();
    } catch (_) {
      // Continua a atualização da interface mesmo se o mapa falhar.
    }
  }

  void _mostrarErroCorrida(String mensagem) {
    if (!mounted) return;
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Erro'),
        content: Text(mensagem),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _limparCorridaSelecionada() {
    setState(() {
      navegacaoAtiva = false;
      mostrandoPassageiro = false;
      solicitacaoSelecionada = null;
      tipoSolicitacao = null;
      corridaAceita = false;
      listaExpandida = true;
      erroNavegacao = null;
      destinoCliente = null;
      destinoFinal = null;
      pontosDaRota.clear();
      pontoAtual = 0;
      processandoChegada = false;
    });
    widget.onTituloChanged('Procurando Corrida');
  }

  // ============================================================
  // ABRIR PASSAGEIRO
  // ============================================================

  void abrirPassageiro(SolicitacaoCorrida solicitacao) {
    setState(() {
      solicitacaoSelecionada = solicitacao;

      mostrandoPassageiro = true;

      corridaAceita = solicitacao.status.toUpperCase() == 'ANDAMENTO';

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

    if (viewModel == null || atual == null || viewModel.atualizandoStatus) {
      return;
    }

    final cancelou = corridaAceita
        ? await viewModel.cancelar(atual)
        : await viewModel.recusar(atual);

    if (!mounted) return;

    if (cancelou) {
      await _pararNavegacao();
      if (!mounted) return;
      _limparCorridaSelecionada();
      unawaited(viewModel.carregar());
      return;
    }

    _mostrarErroCorrida(
      viewModel.erro ?? 'Não foi possível cancelar a solicitação',
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

      corridaAceita = false;

      if (navegacaoInicializada) erroNavegacao = null;
    });

    widget.onTituloChanged('Procurando Corrida');
    final viewModel = solicitacoesViewModel;
    if (viewModel != null) unawaited(viewModel.carregar());
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    unawaited(inicializarNavegacao());

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

  Future<void> _tentarNavegacao() async {
    if (corridaAceita && solicitacaoSelecionada != null) {
      await iniciarNavegacao();
      return;
    }
    if (!navegacaoInicializada) {
      await inicializarNavegacao();
      return;
    }

    final controller = mapController;
    if (controller == null) return;
    try {
      await controller.setMyLocationEnabled(true);
      await controller.followMyLocation(
        CameraPerspective.tilted,
        zoomLevel: 18,
      );
      if (mounted) setState(() => erroNavegacao = null);
    } catch (_) {
      if (mounted) {
        setState(() {
          erroNavegacao = 'Não foi possível acompanhar sua localização. As solicitações continuam disponíveis.';
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: navegacaoInicializada
                ? GoogleMapsNavigationView(
                    onViewCreated: (controller) async {
                      mapController = controller;
                      try {
                        await controller.setMyLocationEnabled(true);
                        await controller.followMyLocation(
                          CameraPerspective.tilted,
                          zoomLevel: 18,
                        );
                      } catch (_) {
                        if (mounted) {
                          setState(() {
                            erroNavegacao = 'O mapa não conseguiu acompanhar sua localização. As ações da corrida continuam disponíveis.';
                          });
                        }
                      }
                    },
                  )
                : const ColoredBox(
                    color: Color(0xFFEAF2FF),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.location,
                        size: 72,
                        color: CupertinoColors.systemGrey2,
                      ),
                    ),
                  ),
          ),

          if (!navegacaoInicializada || erroNavegacao != null)
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: CupertinoColors.systemGrey4,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      inicializandoNavegacao
                          ? 'Iniciando navegação...'
                          : erroNavegacao ?? 'Navegação indisponível.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF1F2024)),
                    ),
                    if (inicializandoNavegacao)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: CupertinoActivityIndicator(),
                      )
                    else
                      CupertinoButton(
                        onPressed: iniciandoNavegacao || inicializandoNavegacao
                            ? null
                            : _tentarNavegacao,
                        child: const Text('Tentar navegação'),
                      ),
                  ],
                ),
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
                          mostrandoPassageiro && solicitacaoSelecionada != null
                          ? _construirDrawer()
                          : listaExpandida
                          ? ListaPassageiros(
                              solicitacoes:
                                  solicitacoesViewModel?.solicitacoes ??
                                  const [],
                              carregando:
                                  solicitacoesViewModel?.carregando ?? false,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed:
                          iniciandoNavegacao ||
                              (solicitacoesViewModel?.atualizandoStatus ??
                                  false)
                          ? null
                          : finalizarNavegacao,
                      child: const Text(
                        'Finalizar corrida',
                        style: TextStyle(color: CupertinoColors.white),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      onPressed:
                          iniciandoNavegacao ||
                              (solicitacoesViewModel?.atualizandoStatus ??
                                  false)
                          ? null
                          : cancelarSolicitacao,
                      child: const Text('Cancelar corrida'),
                    ),
                  ),
                ],
              ),
            ),

          if (iniciandoNavegacao)
            Positioned.fill(
              child: Container(
                color: CupertinoColors.black.withValues(alpha: 0.15),
                child: const Center(
                  child: CupertinoActivityIndicator(radius: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _construirDrawer() {
    final carregando =
        (solicitacoesViewModel?.atualizandoStatus ?? false) ||
        iniciandoNavegacao ||
        inicializandoNavegacao;

    if (corridaAceita) {
      return _construirCorridaEmAndamento(carregando);
    }

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

  Widget _construirCorridaEmAndamento(bool carregando) {
    final solicitacao = solicitacaoSelecionada!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      children: [
        Text(
          solicitacao.ehEntrega ? 'Frete em andamento' : 'Corrida em andamento',
          style: const TextStyle(
            color: Color(0xFF1F2024),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Modalidade: ${solicitacao.categoria.label}',
          style: const TextStyle(color: Color(0xFF1F2024)),
        ),
        Text(
          'Pagamento: ${solicitacao.formaPagamento ?? 'não informado'}',
          style: const TextStyle(color: Color(0xFF1F2024)),
        ),
        const SizedBox(height: 8),
        Text(
          'Passageiro: ${solicitacao.passageiroNome}',
          style: const TextStyle(color: Color(0xFF1F2024)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            onPressed: carregando ? null : iniciarNavegacao,
            child: Text(
              erroNavegacao == null ? 'Iniciar navegação' : 'Tentar navegação',
              style: const TextStyle(color: CupertinoColors.white),
            ),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          onPressed: carregando ? null : finalizarNavegacao,
          child: const Text('Finalizar corrida'),
        ),
        CupertinoButton(
          onPressed: carregando ? null : cancelarSolicitacao,
          child: const Text('Cancelar corrida'),
        ),
        CupertinoButton(
          onPressed: carregando ? null : voltarParaLista,
          child: const Text('Voltar às solicitações'),
        ),
      ],
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
