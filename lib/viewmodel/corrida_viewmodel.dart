import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/config/safe_change_notifier.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/corrida_response.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/model/mototaxista_resumo.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';

enum EtapaCorrida { motoristas, negociacao, aguardando, aceita }

class CorridaViewModel extends ChangeNotifier with SafeChangeNotifier {
  CorridaViewModel({
    required this.passageiroId,
    required this.categoria,
    required this.origem,
    required this.destino,
    this.formaPagamento = 'PIX',
    this.descricaoCarga,
    this.pesoCarga,
    this.cargaFragil = false,
    MototaxistaRepository? mototaxistaRepository,
    CorridaRepository? corridaRepository,
  }) : _mototaxistaRepository =
           mototaxistaRepository ?? MototaxistaRepository(),
       _corridaRepository = corridaRepository ?? CorridaRepository();

  final String passageiroId;
  final CategoriaCorrida categoria;
  final LocalizacaoPonto origem;
  final LocalizacaoPonto destino;
  final String formaPagamento;
  final String? descricaoCarga;
  final double? pesoCarga;
  final bool cargaFragil;
  final MototaxistaRepository _mototaxistaRepository;
  final CorridaRepository _corridaRepository;
  final CancelToken _cancelLista = CancelToken();
  final CancelToken _cancelCriacao = CancelToken();
  final CancelToken _cancelAcompanhamento = CancelToken();
  static const prazoAceite = Duration(seconds: 60);

  EtapaCorrida _etapa = EtapaCorrida.motoristas;
  List<MototaxistaResumo> _motoristas = const [];
  MototaxistaResumo? _motoristaSelecionado;
  CorridaResponse? _corridaCriada;
  SolicitacaoCorrida? _solicitacaoAtiva;
  CategoriaCorrida? _categoriaSolicitacao;
  bool _carregandoLista = false;
  bool _recuperando = false;
  bool _carregandoCriacao = false;
  String? _erroLista;
  String? _erroCriacao;
  String? _erroAcompanhamento;
  bool _atualizandoSolicitacao = false;
  bool _encerrandoEspera = false;
  bool _trocandoMotorista = false;
  int _versaoAcompanhamento = 0;
  bool _criacaoIncerta = false;
  DateTime? _inicioEspera;

  EtapaCorrida get etapa => _etapa;
  List<MototaxistaResumo> get motoristas => _motoristas;
  MototaxistaResumo? get motoristaSelecionado => _motoristaSelecionado;
  CorridaResponse? get corridaCriada => _corridaCriada;
  SolicitacaoCorrida? get solicitacaoAtiva => _solicitacaoAtiva;
  bool get carregando => _carregandoLista || _recuperando;
  bool get recuperando => _recuperando;
  bool get carregandoCriacao => _carregandoCriacao;
  String? get erro => _erroLista;
  String? get erroCriacao => _erroCriacao;
  String? get erroAcompanhamento => _erroAcompanhamento;
  bool get atualizandoSolicitacao => _atualizandoSolicitacao;
  bool get encerrandoEspera => _encerrandoEspera;
  bool get trocandoMotorista => _trocandoMotorista;
  bool get criacaoIncerta => _criacaoIncerta;
  int get segundosRestantes {
    final inicio = _inicioEspera;
    if (inicio == null) return prazoAceite.inSeconds;
    final restante = prazoAceite - DateTime.now().difference(inicio);
    return restante.inSeconds.clamp(0, prazoAceite.inSeconds);
  }

  String get titulo {
    if (_recuperando) return 'Buscando Corrida';
    return switch (_etapa) {
      EtapaCorrida.aguardando => 'Aguardando resposta',
      EtapaCorrida.aceita => 'Corrida aceita',
      _ => carregando ? 'Buscando Corrida' : 'Corrida',
    };
  }

  String get motorista => _motoristaSelecionado?.nome ?? '';
  bool get bloqueiaSaida =>
      _carregandoCriacao ||
      _trocandoMotorista ||
      _etapa == EtapaCorrida.aguardando ||
      _etapa == EtapaCorrida.aceita;

  bool _foiCancelado(DioException e) {
    return e.type == DioExceptionType.cancel || foiDisposed;
  }

  Future<void> iniciar() async {
    if (_recuperando) return;
    _recuperando = true;
    _erroLista = null;
    _etapa = EtapaCorrida.motoristas;
    avisar();
    try {
      final corridas = await _corridaRepository.listarMinhas(
        passageiroId: passageiroId,
        cancelToken: _cancelLista,
      );
      if (foiDisposed) return;
      _criacaoIncerta = false;
      final emAndamento = corridas
          .where((corrida) => corrida.status.toUpperCase() == 'ANDAMENTO')
          .toList();
      for (final corrida in emAndamento) {
        final atual = await _corridaRepository.buscarPorId(
          categoria: corrida.categoria,
          id: corrida.id,
          cancelToken: _cancelLista,
        );
        if (foiDisposed) return;
        if (atual.status?.toUpperCase() == 'ANDAMENTO') {
          _restaurarPendente(corrida, etapa: EtapaCorrida.aceita);
          return;
        }
      }
      final pendentes = corridas
          .where((corrida) => corrida.status.toUpperCase() == 'PENDENTE')
          .toList();
      if (pendentes.length > 1) {
        _erroLista = 'Há mais de uma solicitação pendente. Resolva-as em Minhas corridas.';
        return;
      }
      if (pendentes.isNotEmpty) {
        final pendente = pendentes.single;
        final atual = await _corridaRepository.buscarPorId(
          categoria: pendente.categoria,
          id: pendente.id,
          cancelToken: _cancelLista,
        );
        if (foiDisposed) return;
        final status = atual.status?.toUpperCase();
        if (status == 'PENDENTE') {
          _restaurarPendente(pendente);
          final inicio = pendente.dataHoraSolicitacao;
          if (inicio != null &&
              DateTime.now().difference(inicio) >= prazoAceite) {
            await encerrarEspera(porTempo: true);
            if (_etapa == EtapaCorrida.aguardando) {
              await buscarMotoristas(manterEtapa: true);
            }
          } else {
            await buscarMotoristas(manterEtapa: true);
          }
        } else if (status == 'ANDAMENTO') {
          _restaurarPendente(
            pendente.copyWith(status: 'ANDAMENTO'),
            etapa: EtapaCorrida.aceita,
          );
        } else {
          await buscarMotoristas();
        }
        return;
      }
      await buscarMotoristas();
    } on DioException catch (e) {
      if (_foiCancelado(e)) return;
      _erroLista = mensagemErroDio(
        e,
        fallback: 'Não foi possível verificar solicitações pendentes',
      );
    } catch (_) {
      if (foiDisposed) return;
      _erroLista = 'Não foi possível verificar solicitações pendentes';
    } finally {
      _recuperando = false;
      avisar();
    }
  }

  void _restaurarPendente(
    SolicitacaoCorrida pendente, {
    EtapaCorrida etapa = EtapaCorrida.aguardando,
  }) {
    _solicitacaoAtiva = pendente;
    _corridaCriada = CorridaResponse(id: pendente.id, status: pendente.status);
    _categoriaSolicitacao = pendente.categoria;
    _motoristaSelecionado = MototaxistaResumo(
      id: pendente.mototaxistaId,
      nome: 'mototaxista',
    );
    _inicioEspera = pendente.dataHoraSolicitacao ?? DateTime.now();
    _etapa = etapa;
    avisar();
  }

  Future<void> buscarMotoristas({bool manterEtapa = false}) async {
    _carregandoLista = true;
    _erroLista = null;
    if (!manterEtapa) _etapa = EtapaCorrida.motoristas;
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
    if (_carregandoCriacao || _trocandoMotorista || _corridaCriada != null) {
      return;
    }
    _motoristaSelecionado = mototaxista;
    _erroCriacao = null;
    _etapa = EtapaCorrida.negociacao;
    avisar();
  }

  void recusarNegociacao() {
    if (_corridaCriada != null) return;
    _motoristaSelecionado = null;
    _erroCriacao = null;
    _etapa = EtapaCorrida.motoristas;
    avisar();
  }

  Future<bool> confirmarNegociacao() async {
    if (_corridaCriada != null) return true;
    if (_carregandoCriacao) return false;
    if (_criacaoIncerta) {
      _erroCriacao =
          'Verifique se a solicitação foi criada antes de tentar novamente.';
      avisar();
      return false;
    }

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
        formaPagamento: formaPagamento,
        descricaoCarga: descricaoCarga,
        pesoCarga: pesoCarga,
        cargaFragil: cargaFragil,
        cancelToken: _cancelCriacao,
      );
      if (foiDisposed) return false;
      _solicitacaoAtiva = null;
      _categoriaSolicitacao = categoria;
      _inicioEspera = DateTime.now();
      _etapa = _corridaCriada!.status?.toUpperCase() == 'ANDAMENTO'
          ? EtapaCorrida.aceita
          : EtapaCorrida.aguardando;
      return !foiDisposed;
    } on DioException catch (e) {
      if (_foiCancelado(e)) return false;
      _criacaoIncerta = e.response == null;
      _erroCriacao = _criacaoIncerta
          ? 'Não foi possível confirmar o envio. Verifique suas corridas antes de tentar novamente.'
          : mensagemErroDio(
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
      _carregandoCriacao = false;
      avisar();
    }
  }

  Future<void> atualizarSolicitacao() async {
    if (_etapa != EtapaCorrida.aguardando ||
        _atualizandoSolicitacao ||
        _encerrandoEspera) {
      return;
    }
    final corrida = _corridaCriada;
    if (corrida == null) return;

    _atualizandoSolicitacao = true;
    final versao = _versaoAcompanhamento;
    try {
      final atual = await _corridaRepository.buscarPorId(
        categoria: _categoriaSolicitacao ?? categoria,
        id: corrida.id,
        cancelToken: _cancelAcompanhamento,
      );
      if (foiDisposed || versao != _versaoAcompanhamento) return;
      final status = atual.status?.toUpperCase();
      if (status == 'ANDAMENTO') {
        _etapa = EtapaCorrida.aceita;
        avisar();
      } else if (status == 'CANCELADO' || status == 'CANCELADA') {
        await _voltarALista();
      } else if (status != 'PENDENTE') {
        _erroAcompanhamento =
            'Estado da solicitação: ${atual.status ?? 'desconhecido'}';
        avisar();
      } else if (_erroAcompanhamento != null) {
        _erroAcompanhamento = null;
        avisar();
      }
    } on DioException catch (e) {
      if (_foiCancelado(e) || versao != _versaoAcompanhamento) return;
      _erroAcompanhamento = mensagemErroDio(
        e,
        fallback: 'Não foi possível consultar a solicitação',
      );
      avisar();
    } catch (_) {
      if (foiDisposed || versao != _versaoAcompanhamento) return;
      _erroAcompanhamento = 'Não foi possível consultar a solicitação';
      avisar();
    } finally {
      _atualizandoSolicitacao = false;
    }
  }

  Future<void> encerrarEspera({bool porTempo = false}) async {
    if (_etapa != EtapaCorrida.aguardando || _encerrandoEspera) return;
    final corrida = _corridaCriada;
    if (corrida == null) return;

    _encerrandoEspera = true;
    _versaoAcompanhamento++;
    _erroAcompanhamento = null;
    avisar();
    try {
      final antes = await _corridaRepository.buscarPorId(
        categoria: _categoriaSolicitacao ?? categoria,
        id: corrida.id,
        cancelToken: _cancelAcompanhamento,
      );
      if (foiDisposed) return;
      final status = antes.status?.toUpperCase();
      if (status == 'ANDAMENTO') {
        _etapa = EtapaCorrida.aceita;
      } else if (status == 'CANCELADO' || status == 'CANCELADA') {
        await _voltarALista();
      } else if (status == 'PENDENTE') {
        await _corridaRepository.atualizarStatus(
          categoria: _categoriaSolicitacao ?? categoria,
          id: corrida.id,
          status: 'CANCELADO',
          motivoCancelamento: porTempo
              ? 'Tempo de aceite esgotado'
              : 'Cancelada pelo passageiro',
          cancelToken: _cancelAcompanhamento,
        );
        if (foiDisposed) return;
        final depois = await _corridaRepository.buscarPorId(
          categoria: _categoriaSolicitacao ?? categoria,
          id: corrida.id,
          cancelToken: _cancelAcompanhamento,
        );
        if (foiDisposed) return;
        final statusFinal = depois.status?.toUpperCase();
        if (statusFinal == 'CANCELADO' || statusFinal == 'CANCELADA') {
          await _voltarALista();
        } else if (statusFinal == 'ANDAMENTO') {
          _etapa = EtapaCorrida.aceita;
        } else {
          _erroAcompanhamento = 'Não foi possível confirmar o cancelamento';
        }
      } else {
        _erroAcompanhamento =
            'Estado da solicitação: ${antes.status ?? 'desconhecido'}';
      }
    } on DioException catch (e) {
      if (_foiCancelado(e)) return;
      _erroAcompanhamento = mensagemErroDio(
        e,
        fallback: 'Não foi possível cancelar a solicitação',
      );
    } catch (_) {
      if (foiDisposed) return;
      _erroAcompanhamento = 'Não foi possível cancelar a solicitação';
    } finally {
      _encerrandoEspera = false;
      if (!_trocandoMotorista || _corridaCriada != null) avisar();
    }
  }

  Future<bool> trocarMotorista(MototaxistaResumo outro) async {
    if (_etapa != EtapaCorrida.aguardando || _trocandoMotorista) return false;
    if (outro.id == _motoristaSelecionado?.id) return false;
    _trocandoMotorista = true;
    avisar();
    try {
      await encerrarEspera();
      if (foiDisposed ||
          _etapa != EtapaCorrida.aguardando ||
          _corridaCriada != null) {
        return false;
      }
      if (_erroLista != null) {
        _etapa = EtapaCorrida.motoristas;
        avisar();
        return false;
      }
      final disponiveis = _motoristas.where((m) => m.id == outro.id);
      if (disponiveis.isEmpty) {
        _erroCriacao = 'Esse mototaxista não está mais disponível';
        _etapa = EtapaCorrida.motoristas;
        avisar();
        return false;
      }
      _motoristaSelecionado = disponiveis.first;
      _erroCriacao = null;
      _etapa = EtapaCorrida.negociacao;
      avisar();
      return true;
    } finally {
      _trocandoMotorista = false;
      avisar();
    }
  }

  Future<void> _voltarALista() async {
    if (_trocandoMotorista) {
      await buscarMotoristas(manterEtapa: true);
      if (foiDisposed) return;
      _corridaCriada = null;
      _solicitacaoAtiva = null;
      _categoriaSolicitacao = null;
      _motoristaSelecionado = null;
      _inicioEspera = null;
      _erroAcompanhamento = null;
      return;
    }
    _corridaCriada = null;
    _solicitacaoAtiva = null;
    _categoriaSolicitacao = null;
    _motoristaSelecionado = null;
    _inicioEspera = null;
    _erroAcompanhamento = null;
    await buscarMotoristas();
  }

  @override
  void dispose() {
    if (!_cancelLista.isCancelled) {
      _cancelLista.cancel();
    }
    if (!_cancelCriacao.isCancelled) {
      _cancelCriacao.cancel();
    }
    if (!_cancelAcompanhamento.isCancelled) {
      _cancelAcompanhamento.cancel();
    }
    super.dispose();
  }
}
