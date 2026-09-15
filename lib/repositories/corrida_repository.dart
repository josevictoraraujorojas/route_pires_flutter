import 'package:dio/dio.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/api_config.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/corrida_response.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';

class CorridaRepository {
  CorridaRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  static const statusInicial = 'ANDAMENTO';

  Future<CorridaResponse> criar({
    required CategoriaCorrida categoria,
    required String passageiroId,
    required String mototaxistaId,
    required LocalizacaoPonto origem,
    required LocalizacaoPonto destino,
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
          descricaoCarga: 'Frete simples',
        ),
      ),
      CategoriaCorrida.frete => (
        ApiConfig.corridaFrete,
        _extraFrete(
          passageiroId: passageiroId,
          mototaxistaId: mototaxistaId,
          descricaoCarga: 'Frete',
        ),
      ),
    };

    return _criar(
      path: path,
      extra: extra,
      origem: origem,
      destino: destino,
      cancelToken: cancelToken,
    );
  }

  Map<String, dynamic> _extraFrete({
    required String passageiroId,
    required String mototaxistaId,
    required String descricaoCarga,
  }) {
    return {
      'solicitanteId': passageiroId,
      'mototaxistaId': mototaxistaId,
      'descricaoCarga': descricaoCarga,
      'cargaFragil': false,
      'pesoCarga': 1.0,
    };
  }

  Future<CorridaResponse> _criar({
    required String path,
    required Map<String, dynamic> extra,
    required LocalizacaoPonto origem,
    required LocalizacaoPonto destino,
    CancelToken? cancelToken,
  }) async {
    final agora = DateTime.now().toUtc();
    final response = await _dio.post(
      path,
      cancelToken: cancelToken,
      data: {
        ...extra,
        'origem': _localizacaoJson(origem, agora),
        'destino': _localizacaoJson(destino, agora),
        'dataHoraSolicitacao': agora.toIso8601String(),
        'status': statusInicial,
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

  Map<String, dynamic>? _mapaComId(dynamic data) {
    if (data is! Map) return null;
    final mapa = Map<String, dynamic>.from(data);
    final id = mapa['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    return mapa;
  }
}
