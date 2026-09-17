import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';

class SolicitacoesViewModel extends ChangeNotifier {
  SolicitacoesViewModel({
    required this.mototaxistaId,
    CorridaRepository? repository,
  }) : _repository = repository ?? CorridaRepository();

  final String mototaxistaId;
  final CorridaRepository _repository;
  final CancelToken _cancelToken = CancelToken();

  bool _carregando = false;
  bool _atualizandoStatus = false;
  String? _erro;
  List<SolicitacaoCorrida> _solicitacoes = const [];
  bool _disposed = false;

  bool get carregando => _carregando;
  bool get atualizandoStatus => _atualizandoStatus;
  String? get erro => _erro;
  List<SolicitacaoCorrida> get solicitacoes => _solicitacoes;

  void _avisar() {
    if (!_disposed) notifyListeners();
  }

  bool _foiCancelado(DioException e) {
    return e.type == DioExceptionType.cancel || _disposed;
  }

  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    _avisar();

    try {
      _solicitacoes = await _repository.listarPendentes(
        mototaxistaId: mototaxistaId,
        cancelToken: _cancelToken,
      );
    } on DioException catch (e) {
      if (_foiCancelado(e)) return;
      _solicitacoes = const [];
      _erro = mensagemErroDio(
        e,
        fallback: 'Erro ao buscar solicitações',
        porStatus: const {500: 'Erro interno no servidor'},
      );
    } catch (_) {
      if (_disposed) return;
      _solicitacoes = const [];
      _erro = 'Ocorreu um erro inesperado';
    } finally {
      _carregando = false;
      _avisar();
    }
  }

  Future<bool> recusar(SolicitacaoCorrida solicitacao) async {
    _atualizandoStatus = true;
    _erro = null;
    _avisar();

    try {
      _solicitacoes = _solicitacoes
          .where((item) => item.id != solicitacao.id)
          .toList();
      return true;
    } catch (_) {
      if (_disposed) return false;
      _erro = 'Ocorreu um erro inesperado';
      return false;
    } finally {
      _atualizandoStatus = false;
      _avisar();
    }
  }

  Future<bool> aceitar(SolicitacaoCorrida solicitacao) async {
    _atualizandoStatus = true;
    _erro = null;
    _avisar();

    try {
      await _repository.atualizarStatus(
        categoria: solicitacao.categoria,
        id: solicitacao.id,
        status: 'ANDAMENTO',
        cancelToken: _cancelToken,
      );

      _solicitacoes = _solicitacoes
          .where((item) => item.id != solicitacao.id)
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

      _solicitacoes = _solicitacoes
          .where((item) => item.id != solicitacao.id)
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
      _avisar();
    }
  }

  Future<bool> cancelar(
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

      _solicitacoes = _solicitacoes
          .where((item) => item.id != solicitacao.id)
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
      _avisar();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel();
    }
    super.dispose();
  }
}
