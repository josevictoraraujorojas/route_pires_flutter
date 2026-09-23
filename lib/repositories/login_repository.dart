import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/model/login_response.dart';
import 'package:route_pires_flutter/model/usuario_response.dart';

class LoginRepository {
  final Dio _dio;

  LoginRepository({Dio? dio, bool? isWeb})
    : _dio = dio ?? ApiClient().dio,
      _isWeb = isWeb ?? kIsWeb;

  final bool _isWeb;

  Future<LoginResponse> logar({
    required String email,
    required String senha,
  }) async {
    final response = await _dio.post(
      _isWeb ? '/auth/web/login' : '/login',
      data: {'email': email, 'senha': senha},
    );

    return LoginResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<UsuarioResponse> usuarioAtual() async {
    final response = await _dio.get('/auth/me');
    return UsuarioResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<CsrfResponse> obterCsrf() async {
    final response = await _dio.get('/auth/web/csrf');
    return CsrfResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> sairWeb() async {
    await _dio.post('/auth/web/logout');
  }
}
