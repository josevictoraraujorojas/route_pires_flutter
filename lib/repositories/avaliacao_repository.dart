import 'package:dio/dio.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/api_config.dart';

/// Avaliação que o usuário recebeu de quem participou da corrida com ele.
typedef AvaliacaoRecebida = ({int nota, String? comentario, DateTime? data});

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

  /// Avaliações recebidas pelo usuário logado, da mais nova para a mais antiga.
  Future<List<AvaliacaoRecebida>> listarRecebidas({
    required String usuarioId,
    required bool doMototaxista,
  }) async {
    final resposta = await _dio.get<dynamic>(
      doMototaxista
          ? '${ApiConfig.avaliacoesMototaxista}/mototaxista/$usuarioId'
          : '${ApiConfig.avaliacoesPassageiro}/avaliado/$usuarioId',
    );
    // Sem avaliações a API devolve 204 (passageiro) ou lista vazia.
    final dados = resposta.data;
    if (dados is! List) return [];
    final lista = <AvaliacaoRecebida>[
      for (final item in dados.whereType<Map>())
        (
          nota: (item['nota'] as num?)?.toInt() ?? 0,
          comentario: (item['comentario'] as String?)?.trim(),
          data: DateTime.tryParse('${item['data'] ?? ''}'),
        ),
    ];
    lista.sort(
      (a, b) => (b.data ?? DateTime(0)).compareTo(a.data ?? DateTime(0)),
    );
    return lista;
  }
}
