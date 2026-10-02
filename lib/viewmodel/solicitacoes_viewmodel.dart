import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/config/api_retry.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';

class SolicitacoesViewModel extends ChangeNotifier {
  SolicitacoesViewModel({
    required this.mototaxistaId,
    CorridaRepository? repository,
    DateTime Function()? clock,
  }) : _repository = repository ?? CorridaRepository(),
       _retryConsulta = ApiRetryGate(clock: clock),
       _retryEstimativa = ApiRetryGate(clock: clock);

  final String mototaxistaId;
  final CorridaRepository _repository;
  final CancelToken _cancelToken = CancelToken();

  bool _carregando = false;
  bool _atualizandoStatus = false;
  String? _erro;
  List<SolicitacaoCorrida> _solicitacoes = const [];
  final Map<String, int> _ausenciasConsecutivas = {};
  final Set<String> _encerradasLocalmente = {};
  int _revisaoLista = 0;
  bool _disposed = false;
  Timer? _atualizacaoAutomatica;
  Duration? _periodoPolling;
  bool _online = false;
  bool _pollAtiva = true;
  bool _bootstrapFeito = false;
  bool _consultaInicialTentada = false;
  final ApiRetryGate _retryConsulta;
  final ApiRetryGate _retryEstimativa;
  Timer? _intervaloEstimativa;
  String? _ultimaEstimativaCorrida;
  int? _ultimaEstimativaEtapa;
  CancelToken? _cancelEstimativa;
  bool _publicandoEstimativa = false;
  ({SolicitacaoCorrida solicitacao, int tempo, double distancia, int ponto})?
  _estimativaPendente;

  bool get carregando => _carregando;
  bool get atualizandoStatus => _atualizandoStatus;
  String? get erro => _erro;
  List<SolicitacaoCorrida> get solicitacoes => _solicitacoes;
  int get revisaoLista => _revisaoLista;

  bool get _emAtendimento =>
      _solicitacoes.any((item) => item.status.toUpperCase() == 'ANDAMENTO');

  void configurarPolling({required bool online, bool ativa = true}) {
    _online = online;
    _pollAtiva = ativa;
    _sincronizarPolling();
  }

  void suspenderPublicacaoEstimativa() => descartarEstimativaPendente();

  void publicarEstimativa({
    required SolicitacaoCorrida solicitacao,
    required double tempoRestanteSegundos,
    required double distanciaRestanteMetros,
    required int pontoAtual,
  }) {
    if (_disposed ||
        solicitacao.status.toUpperCase() != 'ANDAMENTO' ||
        solicitacao.mototaxistaId != mototaxistaId ||
        !tempoRestanteSegundos.isFinite ||
        tempoRestanteSegundos < 0 ||
        !distanciaRestanteMetros.isFinite ||
        distanciaRestanteMetros < 0 ||
        (pontoAtual != 0 && pontoAtual != 1)) {
      return;
    }
    _estimativaPendente = (
      solicitacao: solicitacao,
      tempo: tempoRestanteSegundos.round(),
      distancia: distanciaRestanteMetros,
      ponto: pontoAtual,
    );
    unawaited(_enviarEstimativa());
  }

  Future<void> _enviarEstimativa() async {
    if (_disposed || _publicandoEstimativa || !_retryEstimativa.canAttempt) {
      return;
    }
    final dados = _estimativaPendente;
    if (dados == null) return;
    final chave = _chave(dados.solicitacao);
    final mudouEtapa =
        chave != _ultimaEstimativaCorrida ||
        dados.ponto != _ultimaEstimativaEtapa;
    if (!mudouEtapa && _intervaloEstimativa != null) return;
    _estimativaPendente = null;
    _publicandoEstimativa = true;
    _ultimaEstimativaCorrida = chave;
    _ultimaEstimativaEtapa = dados.ponto;
    final cancelToken = _cancelEstimativa = CancelToken();
    _intervaloEstimativa?.cancel();
    _intervaloEstimativa = Timer(const Duration(seconds: 30), () {
      _intervaloEstimativa = null;
      unawaited(_enviarEstimativa());
    });
    try {
      await _repository.atualizarDadosNavegacao(
        categoria: dados.solicitacao.categoria,
        id: dados.solicitacao.id,
        tempoRestanteSegundos: dados.tempo,
        distanciaRestanteMetros: dados.distancia,
        pontoAtual: dados.ponto,
        cancelToken: cancelToken,
      );
      _retryEstimativa.succeeded();
    } catch (erro) {
      _retryEstimativa.failed(erro);
      // A previsão é complementar; não bloqueia as ações da corrida.
    } finally {
      _publicandoEstimativa = false;
      unawaited(_enviarEstimativa());
    }
  }

  void pararPublicacaoEstimativa() {
    descartarEstimativaPendente();
    _intervaloEstimativa?.cancel();
    _intervaloEstimativa = null;
    _ultimaEstimativaCorrida = null;
    _ultimaEstimativaEtapa = null;
  }

  void descartarEstimativaPendente() {
    _estimativaPendente = null;
    _cancelEstimativa?.cancel();
  }

  void _avisar() {
    if (!_disposed) notifyListeners();
  }

  bool _foiCancelado(DioException e) {
    return e.type == DioExceptionType.cancel || _disposed;
  }

  void iniciarAtualizacaoAutomatica() {
    _sincronizarPolling();
  }

  void _sincronizarPolling() {
    if (_disposed ||
        !_pollAtiva ||
        !_consultaInicialTentada ||
        (!_online && !_emAtendimento)) {
      _atualizacaoAutomatica?.cancel();
      _atualizacaoAutomatica = null;
      _periodoPolling = null;
      return;
    }
    final periodo = Duration(seconds: _emAtendimento ? 30 : 15);
    if (_atualizacaoAutomatica != null && _periodoPolling == periodo) return;
    _atualizacaoAutomatica?.cancel();
    _periodoPolling = periodo;
    _atualizacaoAutomatica = Timer.periodic(periodo, (_) {
      unawaited(carregar(silenciosa: true));
    });
  }

  void pararAtualizacaoAutomatica() {
    _pollAtiva = false;
    _atualizacaoAutomatica?.cancel();
    _atualizacaoAutomatica = null;
    _periodoPolling = null;
  }

  String _chave(SolicitacaoCorrida corrida) =>
      '${corrida.categoria.name}:${corrida.id}';

  Object _conteudo(SolicitacaoCorrida corrida) => (
    corrida.id,
    corrida.categoria,
    corrida.status,
    corrida.mototaxistaId,
    corrida.passageiroId,
    corrida.passageiroNome,
    corrida.passageiroAvaliacao,
    corrida.origem,
    corrida.destino,
    corrida.descricaoCarga,
    corrida.pesoCarga,
    corrida.cargaFragil,
    corrida.formaPagamento,
    corrida.dataHoraSolicitacao,
    corrida.tempoRestanteSegundos,
    corrida.distanciaRestanteMetros,
    corrida.pontoAtual,
    corrida.estimativaAtualizadaEm,
  );

  bool _mesmaLista(
    List<SolicitacaoCorrida> anterior,
    List<SolicitacaoCorrida> nova,
  ) {
    if (anterior.length != nova.length) return false;
    for (var i = 0; i < anterior.length; i++) {
      if (_conteudo(anterior[i]) != _conteudo(nova[i])) return false;
    }
    return true;
  }

  Future<bool> _naoPertenceMais(SolicitacaoCorrida corrida) async {
    try {
      final atual = await _repository.buscarPorId(
        categoria: corrida.categoria,
        id: corrida.id,
        cancelToken: _cancelToken,
      );
      if (_disposed) return false;
      final status = atual.status?.toUpperCase();
      return const {
            'FINALIZADO',
            'FINALIZADA',
            'CONCLUIDA',
            'CONCLUÍDA',
            'CANCELADO',
            'CANCELADA',
          }.contains(status) ||
          (atual.mototaxistaId != null && atual.mototaxistaId != mototaxistaId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return true;
      rethrow;
    }
  }

  Future<void> carregar({bool silenciosa = false}) async {
    if (_disposed ||
        _carregando ||
        _atualizandoStatus ||
        !_pollAtiva ||
        !_retryConsulta.canAttempt ||
        (!_online && _bootstrapFeito && !_emAtendimento)) {
      return;
    }
    final erroAnterior = _erro;
    var listaMudou = false;
    _consultaInicialTentada = true;
    _carregando = true;
    if (!silenciosa) {
      _erro = null;
      _avisar();
    }

    try {
      final recebidas = await _repository.listarPendentes(
        mototaxistaId: mototaxistaId,
        cancelToken: _cancelToken,
      );
      if (_disposed) return;
      final anteriores = {
        for (final solicitacao in _solicitacoes)
          _chave(solicitacao): solicitacao,
      };
      final novas = <SolicitacaoCorrida>[];
      final recebidasIds = <String>{};
      for (var solicitacao in recebidas) {
        final chave = _chave(solicitacao);
        if (_encerradasLocalmente.contains(chave)) continue;
        recebidasIds.add(chave);
        _ausenciasConsecutivas.remove(chave);
        final anterior = anteriores[chave];
        if (anterior != null) {
          solicitacao = solicitacao.copyWith(
            status:
                anterior.status.toUpperCase() == 'ANDAMENTO' &&
                    solicitacao.status.toUpperCase() == 'PENDENTE'
                ? 'ANDAMENTO'
                : null,
            passageiroNome:
                solicitacao.passageiroNome == 'Passageiro' &&
                    anterior.passageiroNome != 'Passageiro'
                ? anterior.passageiroNome
                : null,
          );
        }
        novas.add(solicitacao);
      }
      for (final anterior in _solicitacoes) {
        final chave = _chave(anterior);
        if (recebidasIds.contains(chave) ||
            _encerradasLocalmente.contains(chave)) {
          continue;
        }
        final ausencias = (_ausenciasConsecutivas[chave] ?? 0) + 1;
        if (ausencias < 2 || !await _naoPertenceMais(anterior)) {
          _ausenciasConsecutivas[chave] = ausencias.clamp(0, 2);
          novas.add(anterior);
        } else {
          _ausenciasConsecutivas.remove(chave);
        }
      }
      listaMudou = !_mesmaLista(_solicitacoes, novas);
      if (listaMudou) {
        _solicitacoes = novas;
        _revisaoLista++;
      }
      _bootstrapFeito = true;
      _retryConsulta.succeeded();
      _erro = null;
    } on DioException catch (e) {
      if (_foiCancelado(e)) return;
      _retryConsulta.failed(e);
      _erro = mensagemErroDio(
        e,
        fallback: 'Erro ao buscar solicitações',
        porStatus: const {500: 'Erro interno no servidor'},
      );
    } catch (e) {
      if (_disposed) return;
      _retryConsulta.failed(e);
      _erro = 'Ocorreu um erro inesperado';
    } finally {
      _carregando = false;
      _sincronizarPolling();
      if (!silenciosa || listaMudou || _erro != erroAnterior) _avisar();
    }
  }

  Future<bool> recusar(
    SolicitacaoCorrida solicitacao, {
    String motivo = 'Recusada pelo mototaxista',
  }) async {
    _atualizandoStatus = true;
    _erro = null;
    _avisar();

    try {
      await _repository.atualizarStatus(
        categoria: solicitacao.categoria,
        id: solicitacao.id,
        status: 'CANCELADO',
        motivoCancelamento: motivo,
        cancelToken: _cancelToken,
      );

      // Remove da lista somente depois que o backend confirmar.
      _encerradasLocalmente.add(_chave(solicitacao));
      _solicitacoes = _solicitacoes
          .where((item) => _chave(item) != _chave(solicitacao))
          .toList();

      return true;
    } on DioException catch (e) {
      if (_foiCancelado(e)) return false;

      _erro = mensagemErroDio(
        e,
        fallback: 'Erro ao recusar solicitação',
        porStatus: const {
          400: 'Dados inválidos',
          404: 'Solicitação não encontrada',
          500: 'Erro interno no servidor',
        },
      );

      return false;
    } catch (_) {
      if (_disposed) return false;

      _erro = 'Ocorreu um erro inesperado';
      return false;
    } finally {
      _atualizandoStatus = false;
      _sincronizarPolling();
      _avisar();
    }
  }

  Future<bool> aceitar(SolicitacaoCorrida solicitacao) async {
    _atualizandoStatus = true;
    _erro = null;
    _avisar();

    try {
      final atual = await _repository.buscarPorId(
        categoria: solicitacao.categoria,
        id: solicitacao.id,
        cancelToken: _cancelToken,
      );
      if (atual.status?.toUpperCase() != 'PENDENTE') {
        _erro = 'Esta solicitação não está mais pendente. Atualize a lista.';
        return false;
      }
      await _repository.atualizarStatus(
        categoria: solicitacao.categoria,
        id: solicitacao.id,
        status: 'ANDAMENTO',
        cancelToken: _cancelToken,
      );

      _solicitacoes = _solicitacoes
          .map(
            (item) => _chave(item) == _chave(solicitacao)
                ? item.copyWith(status: 'ANDAMENTO')
                : item,
          )
          .toList();
      return true;
    } on DioException catch (e) {
      if (_foiCancelado(e)) return false;
      _erro = mensagemErroDio(
        e,
        fallback: 'Erro ao aceitar solicitação',
        porStatus: const {
          400: 'Dados inválidos',
          404: 'Solicitação não encontrada',
          500: 'Erro interno no servidor',
        },
      );
      return false;
    } catch (_) {
      if (_disposed) return false;
      _erro = 'Ocorreu um erro inesperado';
      return false;
    } finally {
      _atualizandoStatus = false;
      _sincronizarPolling();
      _avisar();
    }
  }

  Future<bool> finalizar(SolicitacaoCorrida solicitacao) async {
    _atualizandoStatus = true;
    _erro = null;
    _avisar();

    try {
      await _repository.atualizarStatus(
        categoria: solicitacao.categoria,
        id: solicitacao.id,
        status: 'FINALIZADO',
        cancelToken: _cancelToken,
      );

      _encerradasLocalmente.add(_chave(solicitacao));
      _solicitacoes = _solicitacoes
          .where((item) => _chave(item) != _chave(solicitacao))
          .toList();
      return true;
    } on DioException catch (e) {
      if (_foiCancelado(e)) return false;
      _erro = mensagemErroDio(
        e,
        fallback: 'Erro ao aceitar solicitação',
        porStatus: const {
          400: 'Dados inválidos',
          404: 'Solicitação não encontrada',
          500: 'Erro interno no servidor',
        },
      );
      return false;
    } catch (_) {
      if (_disposed) return false;
      _erro = 'Ocorreu um erro inesperado';
      return false;
    } finally {
      _atualizandoStatus = false;
      _sincronizarPolling();
      _avisar();
    }
  }

  Future<bool> cancelar(
    SolicitacaoCorrida solicitacao, {
    String motivo = 'Cancelada pelo mototaxista',
  }) async {
    _atualizandoStatus = true;
    _erro = null;
    _avisar();

    try {
      await _repository.atualizarStatus(
        categoria: solicitacao.categoria,
        id: solicitacao.id,
        status: 'CANCELADO',
        motivoCancelamento: motivo,
        cancelToken: _cancelToken,
      );

      _encerradasLocalmente.add(_chave(solicitacao));
      _solicitacoes = _solicitacoes
          .where((item) => _chave(item) != _chave(solicitacao))
          .toList();
      return true;
    } on DioException catch (e) {
      if (_foiCancelado(e)) return false;
      _erro = mensagemErroDio(
        e,
        fallback: 'Erro ao cancelar solicitação',
        porStatus: const {
          400: 'Dados inválidos',
          404: 'Solicitação não encontrada',
          500: 'Erro interno no servidor',
        },
      );
      return false;
    } catch (_) {
      if (_disposed) return false;
      _erro = 'Ocorreu um erro inesperado';
      return false;
    } finally {
      _atualizandoStatus = false;
      _sincronizarPolling();
      _avisar();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    pararPublicacaoEstimativa();
    pararAtualizacaoAutomatica();
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel();
    }
    super.dispose();
  }
}
