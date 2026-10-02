import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/config/localizacao_atual.dart';
import 'package:route_pires_flutter/config/safe_change_notifier.dart';
import 'package:route_pires_flutter/config/validacao.dart';
import 'package:route_pires_flutter/model/mototaxista_cadastro.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';

class MototaxistaViewModel extends ChangeNotifier with SafeChangeNotifier {
  final MototaxistaRepository _repository;

  MototaxistaViewModel({MototaxistaRepository? repository})
    : _repository = repository ?? MototaxistaRepository();

  MototaxistaRascunho rascunho = MototaxistaRascunho();
  bool _carregando = false;
  String? _erro;
  String? _idLocalizacao;
  bool _disponivel = false;
  bool _emAtendimento = false;
  bool _localizacaoAtiva = true;
  bool _enviandoLocalizacao = false;
  Timer? _timerLocalizacao;
  CancelToken? _cancelLocalizacao;
  int _geracaoLocalizacao = 0;
  int _revisaoDisponibilidade = 0;

  bool get carregando => _carregando;
  String? get erro => _erro;

  void definirEmAtendimento({required String id, required bool emAtendimento}) {
    _idLocalizacao = id;
    _emAtendimento = emAtendimento;
    _sincronizarLocalizacao();
  }

  void definirLocalizacaoAtiva(bool ativa) {
    _localizacaoAtiva = ativa;
    _sincronizarLocalizacao();
  }

  void pararLocalizacao() {
    _geracaoLocalizacao++;
    _idLocalizacao = null;
    _disponivel = false;
    _emAtendimento = false;
    _sincronizarLocalizacao();
  }

  void limparRascunho() {
    rascunho = MototaxistaRascunho();
    _erro = null;
    avisar();
  }

  Future<bool?> consultarDisponibilidade({required String id}) async {
    final geracao = _geracaoLocalizacao;
    final revisao = ++_revisaoDisponibilidade;
    _erro = null;
    try {
      final disponivel = await _repository.obterDisponibilidade(id: id);
      if (!foiDisposed &&
          geracao == _geracaoLocalizacao &&
          revisao == _revisaoDisponibilidade) {
        _idLocalizacao = id;
        _disponivel = disponivel;
        _sincronizarLocalizacao();
      }
      return disponivel;
    } on DioException catch (e) {
      _erro = mensagemErroDio(
        e,
        fallback: 'Não foi possível consultar sua disponibilidade',
        porStatus: const {
          403: 'Você não tem permissão para consultar este perfil',
          404: 'Mototaxista não encontrado',
        },
      );
      avisar();
      return null;
    } catch (_) {
      _erro = 'Não foi possível consultar sua disponibilidade';
      avisar();
      return null;
    }
  }

  Future<bool> alterarDisponibilidade({
    required String id,
    required bool disponivel,
  }) async {
    final geracao = _geracaoLocalizacao;
    final revisao = ++_revisaoDisponibilidade;
    _erro = null;
    try {
      await _repository.atualizarDisponibilidade(
        id: id,
        disponivel: disponivel,
      );

      if (!foiDisposed &&
          geracao == _geracaoLocalizacao &&
          revisao == _revisaoDisponibilidade) {
        _idLocalizacao = id;
        _disponivel = disponivel;
        _sincronizarLocalizacao();
      }

      return true;
    } on DioException catch (e) {
      _erro = mensagemErroDio(
        e,
        fallback: 'Não foi possível alterar a disponibilidade',
        porStatus: const {
          400: 'Valor de disponibilidade inválido',
          404: 'Mototaxista não encontrado',
          500: 'Erro interno no servidor',
        },
      );

      avisar();
      return false;
    } catch (_) {
      _erro = 'Não foi possível alterar a disponibilidade';
      avisar();
      return false;
    }
  }

  void _sincronizarLocalizacao() {
    if ((!_disponivel && !_emAtendimento) ||
        !_localizacaoAtiva ||
        _idLocalizacao == null ||
        foiDisposed) {
      _timerLocalizacao?.cancel();
      _timerLocalizacao = null;
      _cancelLocalizacao?.cancel();
      return;
    }
    if (_timerLocalizacao != null) return;
    _cancelLocalizacao = CancelToken();
    _timerLocalizacao = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_publicarLocalizacao());
    });
    unawaited(_publicarLocalizacao());
  }

  Future<void> _publicarLocalizacao() async {
    final id = _idLocalizacao;
    final cancelToken = _cancelLocalizacao;
    if (_enviandoLocalizacao ||
        id == null ||
        cancelToken == null ||
        cancelToken.isCancelled ||
        foiDisposed) {
      return;
    }
    _enviandoLocalizacao = true;
    try {
      final ponto = await posicaoAtual();
      if (foiDisposed || cancelToken.isCancelled || _idLocalizacao != id) {
        return;
      }
      await _repository.publicarLocalizacao(
        id,
        ponto.latitude,
        ponto.longitude,
        cancelToken: cancelToken,
      );
    } catch (_) {
      // A localização não impede disponibilidade, aceite ou encerramento.
    } finally {
      _enviandoLocalizacao = false;
    }
  }

  @override
  void dispose() {
    pararLocalizacao();
    super.dispose();
  }

  Future<bool> cadastrar([MototaxistaCadastro? mototaxista]) async {
    if (_carregando) return false;
    final cadastro = mototaxista ?? rascunho.paraCadastro();
    if (!senhaValida(cadastro.senha)) {
      _erro = mensagemSenhaInvalida;
      avisar();
      return false;
    }
    if (int.tryParse(cadastro.ano) == null) {
      _erro = 'Informe um ano válido';
      avisar();
      return false;
    }

    _carregando = true;
    _erro = null;
    avisar();

    try {
      await _repository.cadastrar(cadastro);
      return true;
    } on DioException catch (error) {
      _erro = mensagemErroDio(
        error,
        fallback: 'Não foi possível concluir o cadastro',
        porStatus: const {
          400: 'Os dados informados são inválidos',
          409: 'Já existe um cadastro com estes dados',
          500: 'O servidor não conseguiu concluir o cadastro',
        },
      );
      return false;
    } catch (_) {
      _erro = 'Ocorreu um erro inesperado ao realizar o cadastro';
      return false;
    } finally {
      _carregando = false;
      avisar();
    }
  }
}
