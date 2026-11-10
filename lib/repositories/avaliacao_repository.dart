import 'package:dio/dio.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/api_config.dart';

class AvaliacaoRepository {
  AvaliacaoRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  /// Com [doMototaxista] o mototaxista avalia o passageiro; sem ele, o
  /// passageiro avalia o mototaxista. Avaliador e avaliado saem da corrida.
  Future<void> avaliar({
    required String corridaId,
    required bool doMototaxista,
    required int nota,
    String? comentario,
  }) async {
    await _dio.post(
      doMototaxista
          ? ApiConfig.avaliacoesPassageiro
          : ApiConfig.avaliacoesMototaxista,
      data: {'corrida': corridaId, 'nota': nota, 'comentario': ?comentario},
    );
  }
}
