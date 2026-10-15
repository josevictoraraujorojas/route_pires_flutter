import 'package:dio/dio.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/api_config.dart';

class EditarPerfilRepository {
  final Dio _dio;

  EditarPerfilRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<void> atualizarPerfil({
    required String id,
    required String nome,
    required String email,
    required String telefone,
    String? senha,
  }) async {
    final data = <String, dynamic>{
      'nome': nome,
      'email': email,
      'telefone': telefone,
    };

    if (senha != null && senha.trim().isNotEmpty) {
      data['senha'] = senha;
    }

    await _dio.patch(
      '${ApiConfig.passageiros}/$id',
      data: data,
    );
  }
}