import 'package:dio/dio.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/api_config.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/corrida_response.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';

class CorridaRepository {
  CorridaRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  static const statusInicial = 'PENDENTE';
  static const _statusFinalizados = {
    'FINALIZADO',
    'FINALIZADA',
    'CONCLUIDA',
    'CONCLUÍDA',
    'CANCELADO',
    'CANCELADA',
  };

  Map<String, dynamic>? _mapaComId(dynamic data) {
    if (data is! Map) return null;
    final mapa = Map<String, dynamic>.from(data);
    final id = mapa['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    return mapa;
  }

  Future<CorridaResponse> criar({
    required CategoriaCorrida categoria,
    required String passageiroId,
    required String mototaxistaId,
    required LocalizacaoPonto origem,
    required LocalizacaoPonto destino,
    String formaPagamento = 'PIX',
    String? descricaoCarga,
    double? pesoCarga,
    bool cargaFragil = false,
    CancelToken? cancelToken,
  }) {
    final (path, extra) = switch (categoria) {
      CategoriaCorrida.corrida => (
        ApiConfig.corridasPassageiro,
        <String, dynamic>{
          'passageiroId': passageiroId,
          'mototaxistaId': mototaxistaId,
        },
      ),
      CategoriaCorrida.freteSimples => (
        ApiConfig.corridaFrete,
        _extraFrete(
          passageiroId: passageiroId,
          mototaxistaId: mototaxistaId,
          modalidadeFrete: 'FRETE_SIMPLES',
          descricaoCarga: descricaoCarga,
          pesoCarga: pesoCarga,
          cargaFragil: cargaFragil,
        ),
      ),
      CategoriaCorrida.frete => (
        ApiConfig.corridaFrete,
        _extraFrete(
          passageiroId: passageiroId,
          mototaxistaId: mototaxistaId,
          modalidadeFrete: 'FRETE',
          descricaoCarga: descricaoCarga,
          pesoCarga: pesoCarga,
          cargaFragil: cargaFragil,
        ),
      ),
    };

    return _criar(
      path: path,
      extra: extra,
      origem: origem,
      destino: destino,
      formaPagamento: formaPagamento,
      cancelToken: cancelToken,
    );
  }

  Map<String, dynamic> _extraFrete({
    required String passageiroId,
    required String mototaxistaId,
    required String modalidadeFrete,
    String? descricaoCarga,
    double? pesoCarga,
    required bool cargaFragil,
  }) {
    return {
      'solicitanteId': passageiroId,
      'mototaxistaId': mototaxistaId,
      'modalidadeFrete': modalidadeFrete,
      'descricaoCarga': descricaoCarga?.trim() ?? '',
      'cargaFragil': cargaFragil,
      'pesoCarga': pesoCarga ?? 0,
    };
  }

  Future<CorridaResponse> _criar({
    required String path,
    required Map<String, dynamic> extra,
    required LocalizacaoPonto origem,
    required LocalizacaoPonto destino,
    required String formaPagamento,
    CancelToken? cancelToken,
  }) async {
    final agora = DateTime.now().toUtc();
    final response = await _dio.post(
      path,
      cancelToken: cancelToken,
      data: {
        ...extra,
        'formaPagamento': formaPagamento,
        'origem': _localizacaoJson(origem, agora),
        'destino': _localizacaoJson(destino, agora),
      },
    );

    return _parseResposta(response.data);
  }

  Map<String, dynamic> _localizacaoJson(
    LocalizacaoPonto ponto,
    DateTime timestamp,
  ) {
    return {
      'localizacao': {'latitude': ponto.latitude, 'longitude': ponto.longitude},
      'timestamp': timestamp.toIso8601String(),
    };
  }

  CorridaResponse _parseResposta(dynamic data) {
    final mapa = _mapaComId(data);
    if (mapa != null) {
      return CorridaResponse.fromJson(mapa);
    }
    if (data is List) {
      for (final item in data) {
        final daLista = _mapaComId(item);
        if (daLista != null) {
          return CorridaResponse.fromJson(daLista);
        }
      }
    }
    throw StateError('Resposta da corrida sem id');
  }

  Future<List<SolicitacaoCorrida>> listarPendentes({
    required String mototaxistaId,
    CancelToken? cancelToken,
  }) async {
    final respostas = await Future.wait([
      _dio.get(ApiConfig.corridasPassageiro, cancelToken: cancelToken),
      _dio.get(ApiConfig.corridaFrete, cancelToken: cancelToken),
    ]);

    final solicitacoes = [
      ..._extrairSolicitacoes(
        respostas[0].data,
        categoria: CategoriaCorrida.corrida,
      ),
      ..._extrairSolicitacoes(
        respostas[1].data,
        categoria: CategoriaCorrida.frete,
      ),
    ];

    final pendentes = solicitacoes
        .where((solicitacao) => solicitacao.id.isNotEmpty)
        .where((solicitacao) => solicitacao.mototaxistaId == mototaxistaId)
        .where(
          (solicitacao) =>
              !_statusFinalizados.contains(solicitacao.status.toUpperCase()),
        )
        .toList();

    final idsPassageiros = pendentes
        .map((solicitacao) => solicitacao.passageiroId)
        .where((id) => id.isNotEmpty)
        .toSet();

    final passageiros = await _buscarPassageiros(
      idsPassageiros,
      cancelToken: cancelToken,
    );

    return pendentes.map((solicitacao) {
      final dados = passageiros[solicitacao.passageiroId];
      if (dados == null) return solicitacao;
      return solicitacao.copyWith(
        passageiroNome: dados.nome,
        passageiroAvaliacao: dados.avaliacaoMedia,
      );
    }).toList();
  }

  Future<List<SolicitacaoCorrida>> listarMinhas({
    required String passageiroId,
    CancelToken? cancelToken,
  }) async {
    final respostas = await Future.wait([
      _dio.get(ApiConfig.corridasPassageiro, cancelToken: cancelToken),
      _dio.get(ApiConfig.corridaFrete, cancelToken: cancelToken),
    ]);
    final corridas = [
      ..._extrairSolicitacoes(
        respostas[0].data,
        categoria: CategoriaCorrida.corrida,
      ),
      ..._extrairSolicitacoes(
        respostas[1].data,
        categoria: CategoriaCorrida.frete,
      ),
    ].where((corrida) => corrida.passageiroId == passageiroId).toList();
    corridas.sort(
      (a, b) => (b.dataHoraSolicitacao ?? DateTime(1970)).compareTo(
        a.dataHoraSolicitacao ?? DateTime(1970),
      ),
    );
    return corridas;
  }

  Future<Map<String, _PassageiroResumo>> _buscarPassageiros(
    Set<String> ids, {
    CancelToken? cancelToken,
  }) async {
    final resultado = <String, _PassageiroResumo>{};

    await Future.wait(
      ids.map((id) async {
        try {
          final response = await _dio.get(
            ApiConfig.passageiroResumo(id),
            cancelToken: cancelToken,
          );

          final data = response.data;
          if (data is Map) {
            final mapa = Map<String, dynamic>.from(data);
            resultado[id] = _PassageiroResumo(
              nome: mapa['nome']?.toString() ?? 'Passageiro',
              avaliacaoMedia: switch (mapa['avaliacaoMedia']) {
                num valor => valor.toDouble(),
                _ => null,
              },
            );
          }
        } on DioException catch (e) {
          if (e.response?.statusCode == 401 ||
              e.response?.statusCode == 403 ||
              e.type == DioExceptionType.cancel) {
            rethrow;
          }
          // Melhor esforço para outras falhas: mantém o nome padrão.
        } catch (_) {
          // Melhor esforço: se a busca falhar, mantém o nome padrão.
        }
      }),
    );

    return resultado;
  }

  List<SolicitacaoCorrida> _extrairSolicitacoes(
    dynamic data, {
    required CategoriaCorrida categoria,
  }) {
    if (data is! List) return const [];

    return data
        .whereType<Map>()
        .map(
          (item) => SolicitacaoCorrida.fromJson(
            Map<String, dynamic>.from(item),
            categoria: categoria,
          ),
        )
        .toList();
  }

  Future<void> atualizarStatus({
    required CategoriaCorrida categoria,
    required String id,
    required String status,
    String? motivoCancelamento,
    CancelToken? cancelToken,
  }) async {
    final path = categoria == CategoriaCorrida.corrida
        ? ApiConfig.corridasPassageiro
        : ApiConfig.corridaFrete;

    final data = <String, dynamic>{'status': status};

    if (motivoCancelamento != null && motivoCancelamento.trim().isNotEmpty) {
      data['motivoCancelamento'] = motivoCancelamento;
    }

    await _dio.put('$path/$id', cancelToken: cancelToken, data: data);
  }
}

class _PassageiroResumo {
  const _PassageiroResumo({required this.nome, this.avaliacaoMedia});

  final String nome;
  final double? avaliacaoMedia;
}
