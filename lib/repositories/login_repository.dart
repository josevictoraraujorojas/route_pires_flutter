import 'package:dio/dio.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/model/usuario_response.dart';

class LoginRepository {
  final Dio _dio;

  LoginRepository() : _dio = ApiClient().dio;

  Future<UsuarioResponse> logar({
    required String email,
    required String senha,
  }) async {
    final response = await _dio.post(
      '/login',
      data: {'email': email, 'senha': senha},
    );

    return UsuarioResponse.fromJson(response.data);
  }
}
