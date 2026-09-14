import 'package:dio/dio.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/api_config.dart';
import 'package:route_pires_flutter/model/mototaxista_cadastro.dart';
import 'package:route_pires_flutter/model/mototaxista_resumo.dart';

class MototaxistaRepository {
  final Dio _dio;

  MototaxistaRepository() : _dio = ApiClient().dio;

  Future<void> cadastrar(MototaxistaCadastro mototaxista) async {
    await _dio.post(ApiConfig.mototaxistas, data: mototaxista.toJson());
  }

  Future<List<MototaxistaResumo>> listar({CancelToken? cancelToken}) async {
    final response = await _dio.get(
      ApiConfig.mototaxistas,
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
}
