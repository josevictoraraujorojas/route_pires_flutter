import 'package:dio/dio.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/api_config.dart';
import 'package:route_pires_flutter/model/mototaxista_cadastro.dart';
import 'package:route_pires_flutter/model/mototaxista_resumo.dart';

class MototaxistaRepository {
  final Dio _dio;

  MototaxistaRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  // ============================================================
  // CADASTRAR MOTOTAXISTA
  // ============================================================

  Future<void> cadastrar(MototaxistaCadastro mototaxista) async {
    final json = mototaxista.toJson();

    await _dio.post(ApiConfig.mototaxistas, data: json);
  }

  // ============================================================
  // LISTAR MOTOTAXISTAS
  // ============================================================

  Future<List<MototaxistaResumo>> listar({
    double? latitude,
    double? longitude,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      ApiConfig.mototaxistasDisponiveis,
      queryParameters: latitude == null && longitude == null
          ? null
          : {'latitude': latitude, 'longitude': longitude},
      cancelToken: cancelToken,
    );

    final data = response.data;

    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => MototaxistaResumo.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((mototaxista) => mototaxista.id.isNotEmpty)
        .toList();
  }

  Future<MototaxistaResumo> buscarPerfilParaPassageiro({
    required String id,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      ApiConfig.perfilMototaxistaParaPassageiro(id),
      cancelToken: cancelToken,
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Resposta inválida do mototaxista');
    }
    return MototaxistaResumo.fromJson({
      ...Map<String, dynamic>.from(data),
      'id': id,
    });
  }

  Future<bool> obterDisponibilidade({required String id}) async {
    final response = await _dio.get(
      '${ApiConfig.mototaxistas}/$id',
      queryParameters: {'_': DateTime.now().microsecondsSinceEpoch},
    );
    final data = response.data;
    if (data is Map && data['disponivel'] is bool) {
      return data['disponivel'] as bool;
    }
    throw const FormatException('Resposta sem disponibilidade do mototaxista');
  }

  // ============================================================
  // ATUALIZAR PARCIALMENTE A DISPONIBILIDADE
  // ============================================================

  Future<void> atualizarDisponibilidade({
    required String id,
    required bool disponivel,
    double? latitude,
    double? longitude,
    CancelToken? cancelToken,
  }) async {
    await _dio.patch(
      '${ApiConfig.mototaxistas}/$id',
      cancelToken: cancelToken,
      data: {
        'disponivel': disponivel,
        'latitude': ?latitude,
        'longitude': ?longitude,
      },
    );
  }

  Future<void> publicarLocalizacao(
    String id,
    double latitude,
    double longitude, {
    CancelToken? cancelToken,
  }) async {
    await _dio.patch(
      '${ApiConfig.mototaxistas}/$id',
      cancelToken: cancelToken,
      data: {'latitude': latitude, 'longitude': longitude},
    );
  }
}
