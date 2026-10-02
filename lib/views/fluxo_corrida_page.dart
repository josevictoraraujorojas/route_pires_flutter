import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show CircleAvatar, CircularProgressIndicator;
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/model/mototaxista_resumo.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/viewmodel/corrida_viewmodel.dart';
import 'package:route_pires_flutter/views/minhas_corridas_page.dart';
import 'package:route_pires_flutter/views/previsao_chegada.dart';

class FluxoCorridaPage extends StatefulWidget {
  const FluxoCorridaPage({
    super.key,
    required this.passageiroId,
    required this.categoria,
    required this.origem,
    required this.destino,
    this.formaPagamento = 'PIX',
    this.descricaoCarga,
    this.pesoCarga,
    this.cargaFragil = false,
  });

  final String passageiroId;
  final CategoriaCorrida categoria;
  final LocalizacaoPonto origem;
  final LocalizacaoPonto destino;
  final String formaPagamento;
  final String? descricaoCarga;
  final double? pesoCarga;
  final bool cargaFragil;

  @override
  State<FluxoCorridaPage> createState() => _FluxoCorridaPageState();
}

class _FluxoCorridaPageState extends State<FluxoCorridaPage>
    with WidgetsBindingObserver {
  late final CorridaViewModel viewModel;
  Timer? _relogio;
  int _segundosDecorridos = 0;
  bool _tentouEncerrarPrazo = false;
  bool _confirmandoTroca = false;
  bool _mostrarAcompanhamentoNaLista = true;
  Route<void>? _rotaEspera;
  bool _appAtivo = true;

  bool get _visivel =>
      mounted &&
      _appAtivo &&
      TickerMode.valuesOf(context).enabled &&
      (ModalRoute.of(context)?.isCurrent != false ||
          _rotaEspera?.isCurrent == true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appAtivo =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    viewModel = CorridaViewModel(
      passageiroId: widget.passageiroId,
      categoria: widget.categoria,
      origem: widget.origem,
      destino: widget.destino,
      formaPagamento: widget.formaPagamento,
      descricaoCarga: widget.descricaoCarga,
      pesoCarga: widget.pesoCarga,
      cargaFragil: widget.cargaFragil,
    );
    viewModel.addListener(_sincronizarEspera);
    viewModel.iniciar();
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_visivel) return;
      if (viewModel.etapa == EtapaCorrida.aceita) {
        setState(() {});
        if (++_segundosDecorridos % 15 == 0) {
          unawaited(viewModel.atualizarSolicitacao());
        }
        return;
      }
      if (viewModel.etapa != EtapaCorrida.aguardando) return;
      setState(() {});
      if (viewModel.segundosRestantes == 0) {
        if (!_tentouEncerrarPrazo &&
            !viewModel.atualizandoSolicitacao &&
            viewModel.podeConsultarSolicitacao) {
          _tentouEncerrarPrazo = true;
          unawaited(viewModel.encerrarEspera(porTempo: true));
        }
      } else if (++_segundosDecorridos % 3 == 0) {
        unawaited(viewModel.atualizarSolicitacao());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _relogio?.cancel();
    viewModel.removeListener(_sincronizarEspera);
    viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appAtivo = state == AppLifecycleState.resumed;
    if (_visivel) unawaited(viewModel.atualizarSolicitacao());
  }

  void _sincronizarEspera() {
    if (viewModel.etapa != EtapaCorrida.aguardando) {
      final rota = _rotaEspera;
      if (rota == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            viewModel.etapa == EtapaCorrida.aguardando ||
            !rota.isActive) {
          return;
        }
        Navigator.of(context, rootNavigator: true).removeRoute(rota);
      });
    }
  }

  void _mostrarEspera() {
    if (_rotaEspera != null) return;
    final solicitacaoId = viewModel.corridaCriada?.id;
    final rota = CupertinoDialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoEsperaResposta(viewModel: viewModel),
    );
    _rotaEspera = rota;
    Navigator.of(context, rootNavigator: true).push(rota).whenComplete(() {
      if (_rotaEspera == rota) _rotaEspera = null;
      if (!mounted || viewModel.etapa != EtapaCorrida.aguardando) return;
      if (viewModel.corridaCriada?.id == solicitacaoId) {
        setState(() => _mostrarAcompanhamentoNaLista = true);
      }
    });
  }

  Future<void> _confirmar() async {
    if (viewModel.etapa != EtapaCorrida.negociacao ||
        viewModel.corridaCriada != null) {
      return;
    }
    final ok = await viewModel.confirmarNegociacao();
    if (!mounted) return;

    if (ok) {
      _iniciarAcompanhamento();
      if (viewModel.etapa == EtapaCorrida.aguardando) {
        final solicitacaoId = viewModel.corridaCriada?.id;
        setState(() => _mostrarAcompanhamentoNaLista = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted ||
              viewModel.etapa != EtapaCorrida.aguardando ||
              viewModel.corridaCriada?.id != solicitacaoId) {
            return;
          }
          _mostrarEspera();
        });
      }
      return;
    }

    await _mostrarErroCriacao();
  }

  Future<void> _mostrarErroCriacao() async {
    if (viewModel.erroCriacao == null) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Erro'),
        content: Text(viewModel.erroCriacao ?? 'Erro ao solicitar corrida'),
        actions: [
          if (viewModel.criacaoIncerta)
            CupertinoDialogAction(
              child: const Text('Verificar solicitação'),
              onPressed: () {
                Navigator.pop(context);
                viewModel.iniciar();
              },
            ),
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _iniciarAcompanhamento() {
    _segundosDecorridos = 0;
    _tentouEncerrarPrazo = false;
    if (viewModel.etapa == EtapaCorrida.aguardando) {
      unawaited(viewModel.atualizarSolicitacao());
    }
  }

  Future<void> _trocarMotorista(MototaxistaResumo outro) async {
    if (_confirmandoTroca ||
        viewModel.etapa != EtapaCorrida.aguardando ||
        viewModel.trocandoMotorista ||
        viewModel.encerrandoEspera) {
      return;
    }
    _confirmandoTroca = true;
    final motoristaAtual = viewModel.motorista;
    final confirmou = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => _DialogoTrocaMotorista(
        motoristaAtual: motoristaAtual,
        novoMotorista: outro.nome,
      ),
    );
    _confirmandoTroca = false;
    if (!mounted || confirmou != true) return;
    final trocou = await viewModel.trocarMotorista(outro);
    if (!mounted) return;
    if (!trocou &&
        viewModel.erroCriacao != null &&
        viewModel.etapa != EtapaCorrida.aguardando) {
      await _mostrarErroCriacao();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        final bloquear = viewModel.bloqueiaSaida;
        return PopScope(
          canPop: !bloquear,
          child: CupertinoPageScaffold(
            backgroundColor: CupertinoColors.white,
            navigationBar: CupertinoNavigationBar(
              automaticallyImplyLeading: !bloquear,
              backgroundColor: CupertinoColors.white,
              middle: Text(
                viewModel.titulo,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(children: [Expanded(child: _conteudo())]),
            ),
          ),
        );
      },
    );
  }

  Widget _conteudo() {
    if (viewModel.recuperando) return _listaMotoristas();
    return switch (viewModel.etapa) {
      EtapaCorrida.motoristas => _listaMotoristas(),
      EtapaCorrida.negociacao => _negociacao(),
      EtapaCorrida.aguardando => _aguardando(),
      EtapaCorrida.aceita => _aceita(),
    };
  }

  Widget _aguardando() {
    final prazoVencido = viewModel.segundosRestantes == 0;
    final outros = viewModel.motoristas
        .where((m) => m.id != viewModel.motoristaSelecionado?.id)
        .toList();
    return Column(
      children: [
        if (_mostrarAcompanhamentoNaLista)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: _CartaoEspera(viewModel: viewModel),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 16, 4),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Outros mototaxistas',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: viewModel.carregando || viewModel.trocandoMotorista
                    ? null
                    : () => viewModel.buscarMotoristas(manterEtapa: true),
                child: const Text('Atualizar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _corpoLista(
            motoristas: outros,
            onSelecionar:
                viewModel.encerrandoEspera ||
                    viewModel.trocandoMotorista ||
                    prazoVencido
                ? null
                : _trocarMotorista,
            mensagemVazia: 'Nenhum outro mototaxista disponível',
            manterEtapaNaFalha: true,
          ),
        ),
      ],
    );
  }

  Widget _aceita() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            size: 56,
            color: CupertinoColors.activeGreen,
          ),
          const SizedBox(height: 16),
          const Text(
            'Você tem uma corrida em andamento.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PrevisaoChegada(corrida: viewModel.corridaCriada),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: viewModel.corridaCriada == null
                ? null
                : () => Navigator.pop(
                    context,
                    viewModel.solicitacaoAtiva ??
                        SolicitacaoCorrida(
                          id: viewModel.corridaCriada!.id,
                          categoria: widget.categoria,
                          status: 'ANDAMENTO',
                          mototaxistaId:
                              viewModel.motoristaSelecionado?.id ?? '',
                          passageiroId: widget.passageiroId,
                          origem: widget.origem,
                          destino: widget.destino,
                          formaPagamento: widget.formaPagamento,
                          descricaoCarga: widget.descricaoCarga,
                          pesoCarga: widget.pesoCarga,
                          cargaFragil: widget.cargaFragil,
                          tempoRestanteSegundos:
                              viewModel.corridaCriada?.tempoRestanteSegundos,
                          distanciaRestanteMetros:
                              viewModel.corridaCriada?.distanciaRestanteMetros,
                          pontoAtual: viewModel.corridaCriada?.pontoAtual,
                          estimativaAtualizadaEm:
                              viewModel.corridaCriada?.estimativaAtualizadaEm,
                        ),
                  ),
            child: const Text('Acompanhar corrida'),
          ),
        ],
      ),
    ),
  );

  String get _textoStatusLista {
    if (viewModel.carregando) return 'Procurando Corrida...';
    if (viewModel.erro != null) return viewModel.erro!;
    final quantidade = viewModel.motoristas.length;
    if (quantidade == 0) return 'Nenhum mototaxista encontrado';
    if (quantidade == 1) return '1 mototaxista';
    return '$quantidade mototaxistas';
  }

  Widget _statusBusca(String texto) {
    return Container(
      width: double.infinity,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF006FFD)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Color(0xFF006FFD),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _botaoCancelar() {
    return SizedBox(
      width: 124,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF006FFD)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          onPressed: viewModel.bloqueiaSaida
              ? null
              : () => Navigator.pop(context),
          child: const Text(
            'Cancelar busca',
            style: TextStyle(color: Color(0xFF006FFD), fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _listaMotoristas() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
          child: _statusBusca(_textoStatusLista),
        ),
        Expanded(child: _corpoLista()),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: _botaoCancelar(),
        ),
      ],
    );
  }

  Widget _corpoLista({
    List<MototaxistaResumo>? motoristas,
    void Function(MototaxistaResumo)? onSelecionar,
    String mensagemVazia = 'Nenhum mototaxista encontrado',
    bool manterEtapaNaFalha = false,
  }) {
    final lista = motoristas ?? viewModel.motoristas;
    if (viewModel.carregando && lista.isEmpty) {
      if (motoristas != null) {
        return const Center(child: CupertinoActivityIndicator());
      }
      return Center(
        child: Image.asset(
          'assets/images/img_busca.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
        ),
      );
    }

    if (viewModel.erro != null) {
      if (manterEtapaNaFalha) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(viewModel.erro!, textAlign: TextAlign.center),
              ),
              CupertinoButton(
                onPressed: () => viewModel.buscarMotoristas(manterEtapa: true),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(viewModel.erro!, textAlign: TextAlign.center),
            ),
            CupertinoButton(
              onPressed: viewModel.iniciar,
              child: const Text('Tentar novamente'),
            ),
            CupertinoButton(
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const MinhasCorridasPage(),
                  ),
                );
                if (mounted) viewModel.iniciar();
              },
              child: const Text('Ver minhas corridas'),
            ),
          ],
        ),
      );
    }

    if (lista.isEmpty) {
      return Center(
        child: Text(
          mensagemVazia,
          style: const TextStyle(color: Color(0xFF8F9098), fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final mototaxista = lista[index];
        return _ItemMotorista(
          mototaxista: mototaxista,
          onPressed: onSelecionar == null && motoristas != null
              ? null
              : () => (onSelecionar ?? viewModel.selecionarMotorista)(
                  mototaxista,
                ),
        );
      },
    );
  }

  Widget _negociacao() {
    final mototaxista = viewModel.motoristaSelecionado;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        children: [
          _statusBusca('Confirmar solicitação'),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: .85,
                  child: Image.asset(
                    'assets/images/img_busca.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withAlpha(180),
                    border: Border.all(color: const Color(0xFF006FFD)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Solicitar ${widget.categoria.label.toLowerCase()}?',
                        style: TextStyle(
                          color: Color(0xFF303038),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const CircleAvatar(
                        radius: 54,
                        backgroundColor: Color(0xFFEAF2FF),
                        child: Icon(
                          CupertinoIcons.person_fill,
                          size: 70,
                          color: Color(0xFFAAD8FF),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Estrelas(valor: mototaxista?.estrelas ?? 0, tamanho: 28),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(color: const Color(0xFF006FFD)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          viewModel.motorista,
                          style: const TextStyle(
                            color: Color(0xFF303038),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _BotaoNegociacao(
                              texto: 'Voltar',
                              onPressed: viewModel.carregandoCriacao
                                  ? null
                                  : viewModel.recusarNegociacao,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _BotaoNegociacao(
                              texto: viewModel.carregandoCriacao
                                  ? '...'
                                  : 'Confirmar',
                              preenchido: true,
                              onPressed: viewModel.carregandoCriacao
                                  ? null
                                  : _confirmar,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _botaoCancelar(),
        ],
      ),
    );
  }
}

class _IndicadorPrazo extends StatelessWidget {
  const _IndicadorPrazo({
    required this.segundosRestantes,
    required this.tamanho,
  });

  final int segundosRestantes;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: tamanho,
      child: Semantics(
        label: '$segundosRestantes segundos restantes para resposta',
        child: ExcludeSemantics(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: tamanho,
                child: CircularProgressIndicator(
                  value:
                      segundosRestantes /
                      CorridaViewModel.prazoAceite.inSeconds,
                  strokeWidth: 4,
                  backgroundColor: const Color(0xFFE4EAF3),
                  color: const Color(0xFF006FFD),
                ),
              ),
              Text(
                '${segundosRestantes}s',
                style: TextStyle(
                  color: Color(0xFF006FFD),
                  fontSize: tamanho >= 64 ? 18 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotaoCancelarEspera extends StatelessWidget {
  const _BotaoCancelarEspera({required this.viewModel, this.discreto = false});

  final CorridaViewModel viewModel;
  final bool discreto;

  @override
  Widget build(BuildContext context) {
    final prazoVencido = viewModel.segundosRestantes == 0;
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: discreto ? null : const Color(0xFFFFDDE1),
        disabledColor: discreto
            ? CupertinoColors.transparent
            : const Color(0xFFF3E8EA),
        borderRadius: BorderRadius.circular(7),
        onPressed: viewModel.encerrandoEspera || viewModel.trocandoMotorista
            ? null
            : () => viewModel.encerrarEspera(porTempo: prazoVencido),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.delete_solid,
              size: 16,
              color: Color(0xFFE01830),
            ),
            const SizedBox(width: 8),
            Text(
              viewModel.encerrandoEspera
                  ? 'Cancelando...'
                  : prazoVencido
                  ? 'Tentar encerrar espera'
                  : 'Cancelar solicitação',
              style: const TextStyle(
                color: Color(0xFFE01830),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoEspera extends StatelessWidget {
  const _CartaoEspera({required this.viewModel});

  final CorridaViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final segundos = viewModel.segundosRestantes;
    final prazoVencido = segundos == 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        border: Border.all(color: const Color(0xFFD9E8FF)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14006FFD),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _IndicadorPrazo(segundosRestantes: segundos, tamanho: 48),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  viewModel.trocandoMotorista
                      ? 'Trocando de mototaxista...'
                      : viewModel.encerrandoEspera
                      ? 'Encerrando solicitação...'
                      : prazoVencido
                      ? 'Tempo de resposta encerrado'
                      : 'Aguardando resposta de ${viewModel.motorista}',
                  style: const TextStyle(
                    color: Color(0xFF1B2340),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.trocandoMotorista
                ? 'Confirmando a troca da solicitação atual...'
                : viewModel.encerrandoEspera
                ? 'Confirmando o cancelamento da solicitação...'
                : prazoVencido
                ? viewModel.erroAcompanhamento != null
                      ? 'O prazo terminou. Tente encerrar a solicitação.'
                      : 'O prazo terminou. Aguardando o encerramento da solicitação.'
                : 'Sua solicitação continua ativa enquanto você vê outros mototaxistas.',
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          if (viewModel.erroAcompanhamento != null) ...[
            const SizedBox(height: 8),
            Text(
              viewModel.erroAcompanhamento!,
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          ],
          const SizedBox(height: 10),
          _BotaoCancelarEspera(viewModel: viewModel, discreto: true),
        ],
      ),
    );
  }
}

class _CaixaDialogo extends StatelessWidget {
  const _CaixaDialogo({required this.child, this.larguraMaxima = 360});

  final Widget child;
  final double larguraMaxima;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: larguraMaxima),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogoTrocaMotorista extends StatelessWidget {
  const _DialogoTrocaMotorista({
    required this.motoristaAtual,
    required this.novoMotorista,
  });

  final String motoristaAtual;
  final String novoMotorista;

  @override
  Widget build(BuildContext context) {
    return _CaixaDialogo(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFEAF2FF),
            child: Icon(
              CupertinoIcons.arrow_right_arrow_left,
              color: Color(0xFF006FFD),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Trocar para $novoMotorista?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1B2340),
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'A solicitação para '),
                TextSpan(
                  text: motoristaAtual,
                  style: const TextStyle(
                    color: Color(0xFF1B2340),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: ' será cancelada. Você poderá revisar a solicitação para ',
                ),
                TextSpan(
                  text: novoMotorista,
                  style: const TextStyle(
                    color: Color(0xFF1B2340),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' antes de enviá-la.'),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: CupertinoButton.filled(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(7),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Cancelar atual e continuar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF006FFD)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Continuar aguardando',
                style: TextStyle(
                  color: Color(0xFF006FFD),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogoEsperaResposta extends StatefulWidget {
  const _DialogoEsperaResposta({required this.viewModel});

  final CorridaViewModel viewModel;

  @override
  State<_DialogoEsperaResposta> createState() => _DialogoEsperaRespostaState();
}

class _DialogoEsperaRespostaState extends State<_DialogoEsperaResposta> {
  Timer? _relogio;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_atualizar);
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) => _atualizar());
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _relogio?.cancel();
    widget.viewModel.removeListener(_atualizar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prazoVencido = widget.viewModel.segundosRestantes == 0;
    final encerrando = widget.viewModel.encerrandoEspera;
    return _CaixaDialogo(
      larguraMaxima: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IndicadorPrazo(
            segundosRestantes: widget.viewModel.segundosRestantes,
            tamanho: 64,
          ),
          const SizedBox(height: 16),
          Text(
            encerrando
                ? 'Encerrando solicitação'
                : prazoVencido
                ? 'Tempo de resposta encerrado'
                : 'Aguardando ${widget.viewModel.motorista}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1B2340),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            encerrando
                ? 'Confirmando o encerramento da solicitação...'
                : prazoVencido
                ? 'O prazo terminou. Você pode tentar encerrar a solicitação.'
                : 'Você pode ver outros mototaxistas enquanto esta solicitação continua ativa.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (widget.viewModel.erroAcompanhamento != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.viewModel.erroAcompanhamento!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: CupertinoButton.filled(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(7),
              onPressed: widget.viewModel.encerrandoEspera
                  ? null
                  : () => Navigator.pop(context),
              child: const Text(
                'Ver outros mototaxistas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _BotaoCancelarEspera(viewModel: widget.viewModel, discreto: true),
        ],
      ),
    );
  }
}

class _ItemMotorista extends StatelessWidget {
  const _ItemMotorista({required this.mototaxista, required this.onPressed});

  final MototaxistaResumo mototaxista;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 13),
      onPressed: onPressed,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFEAF2FF),
            child: Icon(CupertinoIcons.person_fill, color: Color(0xFFAAD8FF)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              mototaxista.nome,
              style: const TextStyle(
                color: Color(0xFF1F2024),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _Estrelas(valor: mototaxista.estrelas, tamanho: 17),
        ],
      ),
    );
  }
}

class _Estrelas extends StatelessWidget {
  const _Estrelas({required this.valor, required this.tamanho});

  final int valor;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final numero = index + 1;
        return Icon(
          numero <= valor ? CupertinoIcons.star_fill : CupertinoIcons.star,
          color: numero <= valor
              ? const Color(0xFF007AFF)
              : const Color(0xFFC5C6CC),
          size: tamanho,
        );
      }),
    );
  }
}

class _BotaoNegociacao extends StatelessWidget {
  const _BotaoNegociacao({
    required this.texto,
    required this.onPressed,
    this.preenchido = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool preenchido;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: preenchido ? null : Border.all(color: const Color(0xFF006FFD)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: preenchido ? const Color(0xFF006FFD) : CupertinoColors.white,
        disabledColor: preenchido
            ? const Color(0xFFB4D2FF)
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
        onPressed: onPressed,
        child: Text(
          texto,
          style: TextStyle(
            color: preenchido ? CupertinoColors.white : const Color(0xFF006FFD),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
