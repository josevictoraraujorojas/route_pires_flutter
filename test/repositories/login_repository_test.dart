import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_pires_flutter/repositories/login_repository.dart';

class AuthAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = switch (options.path) {
      '/auth/web/csrf' => '{"token":"csrf","headerName":"X-CSRF-TOKEN"}',
      '/auth/web/logout' => '{}',
      _ =>
        '{"id":"u-1","nome":"Ana","email":"ana@teste.com",'
            '"telefone":"123","tipo":"PASSAGEIRO",'
            '"accessToken":"jwt","expiresAt":"2026-09-24T12:00:00Z"}',
    };
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AuthAdapter adapter;
  late Dio dio;

  setUp(() {
    adapter = AuthAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example'))
      ..httpClientAdapter = adapter;
  });

  test('mobile recebe token e consulta /auth/me', () async {
    final repository = LoginRepository(dio: dio, isWeb: false);
    final login = await repository.logar(email: 'ana@teste.com', senha: 'a b');
    final atual = await repository.usuarioAtual();

    expect(adapter.requests.first.path, '/login');
    expect(login.accessToken, 'jwt');
    expect(login.usuario.id, 'u-1');
    expect(adapter.requests.last.path, '/auth/me');
    expect(atual.id, 'u-1');
  });

  test('Web usa login por cookie e contrato CSRF', () async {
    final repository = LoginRepository(dio: dio, isWeb: true);
    final login = await repository.logar(email: 'ana@teste.com', senha: 'a b');
    final csrf = await repository.obterCsrf();
    await repository.sairWeb();

    expect(adapter.requests[0].path, '/auth/web/login');
    expect(login.usuario.nome, 'Ana');
    expect(adapter.requests[1].path, '/auth/web/csrf');
    expect(csrf.token, 'csrf');
    expect(csrf.headerName, 'X-CSRF-TOKEN');
    expect(adapter.requests[2].path, '/auth/web/logout');
  });
}
