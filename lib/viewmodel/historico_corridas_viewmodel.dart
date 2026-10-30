import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';
import 'package:route_pires_flutter/services/atualizacoes_service.dart';
import 'package:route_pires_flutter/config/safe_change_notifier.dart';

class HistoricoCorridasViewModel extends ChangeNotifier
    with SafeChangeNotifier {
  final CorridaRepository _repository;
  final MototaxistaRepository _mototaxistaRepository;

  HistoricoCorridasViewModel({
    CorridaRepository? repository,
    MototaxistaRepository? mototaxistaRepository,
  }) : _repository = repository ?? CorridaRepository(),
       _mototaxistaRepository =
           mototaxistaRepository ?? MototaxistaRepository() {
    _eventos = AtualizacaoPorEvento(
      aceita: (e) => e.corridas && e.dados['acao'] != 'PREVISAO_ATUALIZADA',
      atualizar: () async {
        if (_passageiroId case final id?) await carregarHistoricoInicial(id);
      },
      ocupado: () => _carregando || _carregandoMais,
      habilitado: () => _passageiroId != null,
    );
  }

  late final AtualizacaoPorEvento _eventos;
  String? _passageiroId;

  @override
  void dispose() {
    _eventos.dispose();
    super.dispose();
  }

  bool _carregando = false;
  String? _erro;
  List<SolicitacaoCorrida> _corridas = [];

  bool _temMais = true;
  String? _ultimoId;
  bool _carregandoMais = false;

  final Map<String, String> _nomesMototaxistas = {};

  bool get carregando => _carregando;
  bool get carregandoMais => _carregandoMais;
  String? get erro => _erro;
  List<SolicitacaoCorrida> get corridas => _corridas;
  bool get temMais => _temMais;

  String getNomeMototaxista(String? mototaxistaId) {
    if (mototaxistaId == null || mototaxistaId.isEmpty) {
      return 'Mototaxista não identificado';
    }
    return _nomesMototaxistas[mototaxistaId] ?? 'Carregando nome...';
  }

  Future<void> _buscarNomesMototaxistas(
    List<SolicitacaoCorrida> novasCorridas,
  ) async {
    final idsParaBuscar = novasCorridas
        .map((c) => c.mototaxistaId)
        .where((id) => id.isNotEmpty && !_nomesMototaxistas.containsKey(id))
        .cast<String>()
        .toSet();

    if (idsParaBuscar.isEmpty) return;

    await Future.wait(
      idsParaBuscar.map((id) async {
        try {
          final perfil = await _mototaxistaRepository
              .buscarPerfilParaPassageiro(id: id);
          _nomesMototaxistas[id] = perfil.nome;
          avisar();
        } catch (_) {
          _nomesMototaxistas[id] = 'Mototaxista (ID: ${id.substring(0, 4)})';
        }
      }),
    );
  }

  Future<void> carregarHistoricoInicial(String passageiroId) async {
    if (foiDisposed || _carregando || _carregandoMais) return;
    _passageiroId = passageiroId;
    _carregando = true;
    _erro = null;
    _ultimoId = null;
    avisar();

    try {
      final pagina = await _repository.listarHistorico(
        passageiroId: passageiroId,
        limite: 15,
      );

      if (foiDisposed) return;
      _corridas = pagina.corridas;
      _ultimoId = pagina.aposId;
      _temMais = pagina.temMais;

      avisar();

      _buscarNomesMototaxistas(_corridas);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        _erro = 'Verifique sua conexão com a internet.';
      } else {
        _erro = 'Não foi possível carregar o histórico.';
      }
    } catch (e) {
      _erro = 'Ocorreu um erro inesperado.';
    } finally {
      _carregando = false;
      avisar();
    }
  }

  Future<void> carregarMaisHistorico(String passageiroId) async {
    if (foiDisposed || !_temMais || _carregandoMais || _carregando) return;

    _carregandoMais = true;
    avisar();

    try {
      final pagina = await _repository.listarHistorico(
        passageiroId: passageiroId,
        aposId: _ultimoId,
        limite: 15,
      );

      if (foiDisposed) return;
      _corridas.addAll(pagina.corridas);
      _ultimoId = pagina.aposId;
      _temMais = pagina.temMais;

      avisar();

      _buscarNomesMototaxistas(pagina.corridas);
    } catch (e) {
      debugPrint('Erro ao carregar mais corridas: $e');
    } finally {
      _carregandoMais = false;
      avisar();
    }
  }
}
