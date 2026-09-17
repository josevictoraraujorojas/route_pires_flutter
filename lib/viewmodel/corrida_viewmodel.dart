import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/config/safe_change_notifier.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/corrida_response.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/model/mototaxista_resumo.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';

enum EtapaCorrida { motoristas, negociacao }

class CorridaViewModel extends ChangeNotifier with SafeChangeNotifier {
  CorridaViewModel({
    required this.passageiroId,
    required this.categoria,
    required this.origem,
    required this.destino,
    MototaxistaRepository? mototaxistaRepository,
    CorridaRepository? corridaRepository,
  }) : _mototaxistaRepository =
           mototaxistaRepository ?? MototaxistaRepository(),
       _corridaRepository = corridaRepository ?? CorridaRepository();

  final String passageiroId;
  final CategoriaCorrida categoria;
  final LocalizacaoPonto origem;
  final LocalizacaoPonto destino;
  final MototaxistaRepository _mototaxistaRepository;
  final CorridaRepository _corridaRepository;
  final CancelToken _cancelLista = CancelToken();
  final CancelToken _cancelCriacao = CancelToken();

  EtapaCorrida _etapa = EtapaCorrida.motoristas;
  List<MototaxistaResumo> _motoristas = const [];
  MototaxistaResumo? _motoristaSelecionado;
  CorridaResponse? _corridaCriada;
  bool _carregandoLista = false;
  bool _carregandoCriacao = false;
  String? _erroLista;
  String? _erroCriacao;

  EtapaCorrida get etapa => _etapa;
  List<MototaxistaResumo> get motoristas => _motoristas;
  MototaxistaResumo? get motoristaSelecionado => _motoristaSelecionado;
  CorridaResponse? get corridaCriada => _corridaCriada;
  bool get carregando => _carregandoLista;
  bool get carregandoCriacao => _carregandoCriacao;
  String? get erro => _erroLista;
  String? get erroCriacao => _erroCriacao;
  String get titulo => carregando ? 'Buscando Corrida' : 'Corrida';
  String get motorista => _motoristaSelecionado?.nome ?? '';
  bool get bloqueiaSaida => _carregandoCriacao || _corridaCriada != null;

  bool _foiCancelado(DioException e) {
    return e.type == DioExceptionType.cancel || foiDisposed;
  }

  Future<void> buscarMotoristas() async {
    _carregandoLista = true;
    _erroLista = null;
    _etapa = EtapaCorrida.motoristas;
    avisar();

    try {
      final lista = await _mototaxistaRepository.listar(
        cancelToken: _cancelLista,
      );
      _motoristas = lista
          .where((mototaxista) => mototaxista.disponivel)
          .toList();
    } on DioException catch (e) {
      if (_foiCancelado(e)) return;
      _motoristas = const [];
      _erroLista = mensagemErroDio(
        e,
        fallback: 'Erro ao buscar mototaxistas',
        porStatus: const {500: 'Erro interno no servidor'},
      );
    } catch (_) {
      if (foiDisposed) return;
      _motoristas = const [];
      _erroLista = 'Ocorreu um erro inesperado';
    } finally {
      _carregandoLista = false;
      avisar();
    }
  }

  void selecionarMotorista(MototaxistaResumo mototaxista) {
    _motoristaSelecionado = mototaxista;
    _erroCriacao = null;
    _etapa = EtapaCorrida.negociacao;
    avisar();
  }

  void recusarNegociacao() {
    _motoristaSelecionado = null;
    _erroCriacao = null;
    _etapa = EtapaCorrida.motoristas;
    avisar();
  }

  Future<bool> confirmarNegociacao() async {
    if (_corridaCriada != null) return true;
    if (_carregandoCriacao) return false;

    final mototaxista = _motoristaSelecionado;
    if (mototaxista == null) {
      _erroCriacao = 'Selecione um mototaxista';
      avisar();
      return false;
    }

    _carregandoCriacao = true;
    _erroCriacao = null;
    avisar();

    try {
      _corridaCriada = await _corridaRepository.criar(
        categoria: categoria,
        passageiroId: passageiroId,
        mototaxistaId: mototaxista.id,
        origem: origem,
        destino: destino,
        cancelToken: _cancelCriacao,
      );
      return !foiDisposed;
    } on DioException catch (e) {
      if (_foiCancelado(e)) return false;
      _erroCriacao = mensagemErroDio(
        e,
        fallback: 'Erro ao solicitar corrida',
        porStatus: const {
          400: 'Dados inválidos',
          500: 'Erro interno no servidor',
        },
      );
      return false;
    } catch (_) {
      if (foiDisposed) return false;
      _erroCriacao = 'Ocorreu um erro inesperado';
      return false;
    } finally {
      if (_corridaCriada == null) {
        _carregandoCriacao = false;
      }
      avisar();
    }
  }

  @override
  void dispose() {
    if (!_cancelLista.isCancelled) {
      _cancelLista.cancel();
    }
    if (!_cancelCriacao.isCancelled) {
      _cancelCriacao.cancel();
    }
    super.dispose();
  }
}
