import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';

class _Dio extends Mock implements Dio {}

class _Gps extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => Position(
    latitude: -17.3,
    longitude: -48.28,
    timestamp: DateTime.now(),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  testWidgets('Publica GPS ao ficar disponível e a cada 15 segundos', (
    tester,
  ) async {
    final gpsAnterior = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = _Gps();
    addTearDown(() => GeolocatorPlatform.instance = gpsAnterior);
    final publicacoes = <Map<String, dynamic>>[];
    final dio = _Dio();
    when(
      () => dio.patch<dynamic>(
        any(),
        data: any(named: 'data'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((call) async {
      final data = call.namedArguments[#data];
      if (data is Map && data.containsKey('latitude')) {
        publicacoes.add(Map<String, dynamic>.from(data));
      }
      return Response(
        requestOptions: RequestOptions(path: '/mototaxistas/moto-1'),
        data: {'disponivel': true},
      );
    });
    final viewModel = MototaxistaViewModel(
      repository: MototaxistaRepository(dio: dio),
    );
    addTearDown(viewModel.dispose);

    expect(
      await viewModel.alterarDisponibilidade(id: 'moto-1', disponivel: true),
      isTrue,
    );
    await tester.pump();
    expect(publicacoes, [
      {'latitude': -17.3, 'longitude': -48.28},
    ]);

    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(publicacoes, hasLength(2));

    await viewModel.alterarDisponibilidade(id: 'moto-1', disponivel: false);
    await tester.pump(const Duration(seconds: 30));
    expect(publicacoes, hasLength(2));
  });

  testWidgets('Atendimento mantém GPS offline e pausa sem enviar atrasado', (
    tester,
  ) async {
    final gpsAnterior = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = _Gps();
    addTearDown(() => GeolocatorPlatform.instance = gpsAnterior);
    final publicacoes = <Map<String, dynamic>>[];
    final tokens = <CancelToken>[];
    final espera = Completer<Response<dynamic>>();
    final dio = _Dio();
    when(
      () => dio.patch<dynamic>(
        any(),
        data: any(named: 'data'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((call) {
      publicacoes.add(Map<String, dynamic>.from(call.namedArguments[#data]));
      tokens.add(call.namedArguments[#cancelToken] as CancelToken);
      return espera.future;
    });
    final viewModel = MototaxistaViewModel(
      repository: MototaxistaRepository(dio: dio),
    );
    addTearDown(viewModel.dispose);

    viewModel.definirEmAtendimento(id: 'moto-1', emAtendimento: false);
    await tester.pump(const Duration(seconds: 15));
    expect(publicacoes, isEmpty);

    viewModel.definirEmAtendimento(id: 'moto-1', emAtendimento: true);
    await tester.pump();
    expect(publicacoes, [
      {'latitude': -17.3, 'longitude': -48.28},
    ]);
    await tester.pump(const Duration(seconds: 30));
    expect(
      publicacoes,
      hasLength(1),
      reason: 'Não sobrepõe uma publicação em voo',
    );

    viewModel.definirLocalizacaoAtiva(false);
    expect(tokens.single.isCancelled, isTrue);
    espera.complete(
      Response(requestOptions: RequestOptions(path: '/mototaxistas/moto-1')),
    );
    await tester.pump(const Duration(seconds: 30));
    expect(publicacoes, hasLength(1));

    viewModel.definirLocalizacaoAtiva(true);
    await tester.pump();
    expect(publicacoes, hasLength(2));
    viewModel.pararLocalizacao();
    await tester.pump(const Duration(seconds: 30));
    expect(publicacoes, hasLength(2));
  });

  for (final consultar in [true, false]) {
    testWidgets(
      'Não retoma GPS se ${consultar ? 'consulta' : 'alteração'} termina após logout',
      (tester) async {
        final gpsAnterior = GeolocatorPlatform.instance;
        GeolocatorPlatform.instance = _Gps();
        addTearDown(() => GeolocatorPlatform.instance = gpsAnterior);
        final resposta = Completer<Response<dynamic>>();
        var enviosGps = 0;
        final dio = _Dio();
        when(
          () => dio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) => resposta.future);
        when(
          () => dio.patch<dynamic>(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((call) async {
          final data = call.namedArguments[#data] as Map;
          if (data.containsKey('disponivel')) return resposta.future;
          enviosGps++;
          return Response(
            requestOptions: RequestOptions(path: '/mototaxistas/moto-1'),
          );
        });
        final viewModel = MototaxistaViewModel(
          repository: MototaxistaRepository(dio: dio),
        );
        addTearDown(viewModel.dispose);
        final operacao = consultar
            ? viewModel.consultarDisponibilidade(id: 'moto-1')
            : viewModel.alterarDisponibilidade(id: 'moto-1', disponivel: true);
        viewModel.pararLocalizacao();
        resposta.complete(
          Response(
            requestOptions: RequestOptions(path: '/mototaxistas/moto-1'),
            data: {'disponivel': true},
          ),
        );
        await operacao;
        await tester.pump();
        expect(enviosGps, 0);
        viewModel.pararLocalizacao();
      },
    );
  }
}
