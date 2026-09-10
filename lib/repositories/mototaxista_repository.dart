import 'package:dio/dio.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/model/mototaxista_cadastro.dart';

class MototaxistaRepository {
  final Dio _dio;

  MototaxistaRepository() : _dio = ApiClient().dio;

  Future<void> cadastrar(MototaxistaCadastro mototaxista) async {
    await _dio.post('/mototaxistas', data: mototaxista.toJson());
  }
}