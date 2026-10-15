import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/config/api_config.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/corrida_response.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() => registerFallbackValue(CancelToken()));

  test('Mudança da previsão é percebida mesmo sem mudança de status', () {
    final inicial = CorridaResponse.fromJson({
      'id': 'corrida-1',
      'status': 'ANDAMENTO',
      'tempoRestanteSegundos': 120,
      'distanciaRestanteMetros': 900.0,
      'pontoAtual': 0,
      'estimativaAtualizadaEm': '2026-10-02T15:00:00Z',
    });
    final atualizada = CorridaResponse.fromJson({
      'id': 'corrida-1',
      'status': 'ANDAMENTO',
      'tempoRestanteSegundos': 60,
      'distanciaRestanteMetros': 400.0,
      'pontoAtual': 0,
      'estimativaAtualizadaEm': '2026-10-02T15:00:15Z',
    });

    expect(atualizada, isNot(inicial));
    expect(atualizada.tempoRestanteSegundos, 60);
    expect(atualizada.distanciaRestanteMetros, 400.0);
    expect(atualizada.pontoAtual, 0);
    expect(
      atualizada.estimativaAtualizadaEm,
      DateTime.utc(2026, 10, 2, 15, 0, 15),
    );
  });

  test(
    'Busca envia coordenadas do embarque e preserva consulta antiga',
    () async {
      final dio = MockDio();
      final consultas = <Map<String, dynamic>?>[];
      when(
        () => dio.get<dynamic>(
          ApiConfig.mototaxistasDisponiveis,
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        consultas.add(
          invocation.namedArguments[#queryParameters] as Map<String, dynamic>?,
        );
        return Response(
          requestOptions: RequestOptions(path: ''),
          data: [],
        );
      });
      final repository = MototaxistaRepository(dio: dio);
      await repository.listar(latitude: -17.3, longitude: -48.2);
      await repository.listar();
      expect(consultas, [
        {'latitude': -17.3, 'longitude': -48.2},
        null,
      ]);
    },
  );

  test('GPS usa PATCH do perfil sem reenviar disponibilidade', () async {
    final dio = MockDio();
    String? path;
    Map? data;
    when(
      () => dio.patch<dynamic>(
        any(),
        data: any(named: 'data'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((invocation) async {
      path = invocation.positionalArguments.first as String;
      data = invocation.namedArguments[#data] as Map;
      return Response(requestOptions: RequestOptions(path: path!));
    });
    await MototaxistaRepository(dio: dio)
        .publicarLocalizacao('moto-1', -17.3, -48.2);
    expect(path, '${ApiConfig.mototaxistas}/moto-1');
    expect(data, {'latitude': -17.3, 'longitude': -48.2});
  });

  for (final categoria in CategoriaCorrida.values) {
    test(
      'Publica previsão de ${categoria.name} no PUT existente sem status',
      () async {
        final dio = MockDio();
        String? path;
        Map? data;
        when(
          () => dio.put<dynamic>(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((invocation) async {
          path = invocation.positionalArguments.first as String;
          data = invocation.namedArguments[#data] as Map;
          return Response(requestOptions: RequestOptions(path: path!));
        });
        await CorridaRepository(dio: dio).atualizarDadosNavegacao(
          categoria: categoria,
          id: 'corrida-1',
          tempoRestanteSegundos: 120,
          distanciaRestanteMetros: 900,
          pontoAtual: 0,
        );
        final base = categoria == CategoriaCorrida.corrida
            ? ApiConfig.corridasPassageiro
            : ApiConfig.corridaFrete;
        expect(path, '$base/corrida-1');
        expect(data, {
          'tempoRestanteSegundos': 120,
          'distanciaRestanteMetros': 900.0,
          'pontoAtual': 0,
        });
      },
    );
  }
}
