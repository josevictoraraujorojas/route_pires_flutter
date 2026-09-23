import 'package:dio/dio.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/api_config.dart';
import 'package:route_pires_flutter/model/mototaxista_cadastro.dart';
import 'package:route_pires_flutter/model/mototaxista_resumo.dart';

class MototaxistaRepository {
  final Dio _dio;

  MototaxistaRepository() : _dio = ApiClient().dio;

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

  Future<List<MototaxistaResumo>> listar({CancelToken? cancelToken}) async {
    final response = await _dio.get(
      ApiConfig.mototaxistasDisponiveis,
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

  // ============================================================
  // ATUALIZAR PARCIALMENTE A DISPONIBILIDADE
  // ============================================================

  Future<void> atualizarDisponibilidade({
    required String id,
    required bool disponivel,
  }) async {
    await _dio.patch(
      '${ApiConfig.mototaxistas}/$id',
      data: {'disponivel': disponivel},
    );
  }
}
