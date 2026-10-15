import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
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

  test('Endereço reverso mantém o nome do lugar sem campo de rua', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (opcoes, handler) => handler.resolve(
          Response(
            requestOptions: opcoes,
            statusCode: 200,
            data: {
              'features': [
                {
                  'geometry': {
                    'coordinates': [-48.2855, -17.3037],
                  },
                  'properties': {
                    'name': 'Mercado Central',
                    'city': 'Pires do Rio',
                  },
                },
                {
                  'geometry': {
                    'coordinates': [-48.2855, -17.3037],
                  },
                  'properties': {
                    'name': 'Mercado Central',
                    'street': 'Rua das Flores',
                    'housenumber': '42',
                    'city': 'Pires do Rio',
                  },
                },
              ],
            },
          ),
        ),
      ),
    );

    final endereco = await LocalizacaoRepository(dio: dio)
        .endereco(const LatLng(-17.3037, -48.2855));

    expect(endereco.rotulo, 'Mercado Central, Pires do Rio');
  });

  test(
    'Endereço reverso sem resultado evita repetir a consulta imediatamente',
    () async {
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
      const ponto = LatLng(-17.3037, -48.2855);

      expect(
        (await repository.endereco(ponto)).rotulo,
        'Endereço indisponível',
      );
      expect(
        (await repository.endereco(ponto)).rotulo,
        'Endereço indisponível',
      );
      expect(chamadas, 1);
    },
  );
}
