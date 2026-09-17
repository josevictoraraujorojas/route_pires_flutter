import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_pires_flutter/repositories/localizacao_repository.dart';

void main() {
  test('Não deve cachear busca vazia', () async {
    var chamadas = 0;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (opcoes, handler) {
          chamadas++;
          handler.resolve(
            Response(
              requestOptions: opcoes,
              statusCode: 200,
              data: {'features': []},
            ),
          );
        },
      ),
    );

    final repository = LocalizacaoRepository(dio: dio);
    await repository.buscar('rua inexistente');
    await repository.buscar('rua inexistente');

    expect(chamadas, 2);
  });
}
