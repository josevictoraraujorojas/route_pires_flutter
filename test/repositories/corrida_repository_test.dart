import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/config/api_config.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/corrida_response.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(CancelToken());
  });

  late MockDio dio;
  late CorridaRepository repository;

  const origem = LocalizacaoPonto(
    latitude: -17.3037,
    longitude: -48.2855,
    rotulo: 'Rua Inicial - Setor Universitário',
  );
  const destino = LocalizacaoPonto(
    latitude: -17.2948,
    longitude: -48.2718,
    rotulo: 'Rua Final - Centro',
  );

  setUp(() {
    dio = MockDio();
    repository = CorridaRepository(dio: dio);
  });

  Future<({String path, Map<String, dynamic> data})> capturarPost(
    CategoriaCorrida categoria,
  ) async {
    late String path;
    late Map<String, dynamic> data;
    when(
      () => dio.post<dynamic>(
        any(),
        data: any(named: 'data'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((invocation) async {
      path = invocation.positionalArguments.first as String;
      data = Map<String, dynamic>.from(invocation.namedArguments[#data] as Map);
      return Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        statusCode: 201,
        data: {'id': 'corrida-1', 'status': 'ANDAMENTO'},
      );
    });

    await repository.criar(
      categoria: categoria,
      passageiroId: 'passageiro-1',
      mototaxistaId: 'moto-1',
      origem: origem,
      destino: destino,
    );

    return (path: path, data: data);
  }

  void esperarGeoPoints(Map<String, dynamic> data) {
    expect(data['origem']['localizacao']['latitude'], origem.latitude);
    expect(data['origem']['localizacao']['longitude'], origem.longitude);
    expect(data['destino']['localizacao']['latitude'], destino.latitude);
    expect(data['destino']['localizacao']['longitude'], destino.longitude);
    expect(data['origem']['timestamp'], data['dataHoraSolicitacao']);
    expect(data['destino']['timestamp'], data['dataHoraSolicitacao']);
    expect(data['status'], 'PENDENTE');
  }

  group('CorridaRepository Tests |', () {
    test('Deve postar corrida de passageiro no path e body certos', () async {
      final post = await capturarPost(CategoriaCorrida.corrida);

      expect(post.path, ApiConfig.corridasPassageiro);
      expect(post.data['passageiroId'], 'passageiro-1');
      expect(post.data['mototaxistaId'], 'moto-1');
      expect(post.data.containsKey('solicitanteId'), isFalse);
      expect(post.data.containsKey('descricaoCarga'), isFalse);
      esperarGeoPoints(post.data);
    });

    test('Deve postar frete simples no path e body certos', () async {
      final post = await capturarPost(CategoriaCorrida.freteSimples);

      expect(post.path, ApiConfig.corridaFrete);
      expect(post.data['solicitanteId'], 'passageiro-1');
      expect(post.data['mototaxistaId'], 'moto-1');
      expect(post.data['descricaoCarga'], 'Frete simples');
      expect(post.data['cargaFragil'], isFalse);
      expect(post.data['pesoCarga'], 1.0);
      expect(post.data.containsKey('passageiroId'), isFalse);
      esperarGeoPoints(post.data);
    });

    test('Deve postar frete no path e body certos', () async {
      final post = await capturarPost(CategoriaCorrida.frete);

      expect(post.path, ApiConfig.corridaFrete);
      expect(post.data['solicitanteId'], 'passageiro-1');
      expect(post.data['descricaoCarga'], 'Frete');
      expect(post.data['cargaFragil'], isFalse);
      expect(post.data['pesoCarga'], 1.0);
      esperarGeoPoints(post.data);
    });

    Future<void> stubResposta(dynamic data) async {
      when(
        () => dio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: ApiConfig.corridasPassageiro),
          statusCode: 201,
          data: data,
        ),
      );
    }

    Future<CorridaResponse> criarPassageiro() {
      return repository.criar(
        categoria: CategoriaCorrida.corrida,
        passageiroId: 'passageiro-1',
        mototaxistaId: 'moto-1',
        origem: origem,
        destino: destino,
      );
    }

    test('Deve aceitar mapa 2xx com id', () async {
      await stubResposta({'id': 'corrida-1', 'status': 'ANDAMENTO'});

      final corrida = await criarPassageiro();

      expect(corrida.id, 'corrida-1');
    });

    test('Não deve tratar mapa 2xx sem id como corrida criada', () async {
      await stubResposta({'status': 'ANDAMENTO'});

      await expectLater(criarPassageiro(), throwsA(isA<StateError>()));
    });

    test('Não deve tratar body vazio como corrida criada', () async {
      await stubResposta(<String, dynamic>{});

      await expectLater(criarPassageiro(), throwsA(isA<StateError>()));
    });

    test('Não deve tratar lista 2xx como corrida criada', () async {
      await stubResposta([
        {'id': 'outra-corrida', 'status': 'ANDAMENTO'},
      ]);

      await expectLater(criarPassageiro(), throwsA(isA<StateError>()));
    });
  });
}
