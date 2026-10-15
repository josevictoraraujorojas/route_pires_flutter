import 'package:dio/dio.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/api_config.dart';

class CadastroPassageiroRepository {
  final Dio _dio;

  CadastroPassageiroRepository() : _dio = ApiClient().dio;

  Future<void> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    await _dio.post(
      ApiConfig.passageiros,
      data: {
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'senha': senha,
      },
    );
  }
}
