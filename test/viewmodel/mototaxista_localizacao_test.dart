import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';

class _Dio extends Mock implements Dio {}

class _Gps extends GeolocatorPlatform {
  double latitude = -17.3;
  double longitude = -48.28;
  int capturas = 0;
  bool falhar = false;
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    capturas++;
    if (falhar) throw StateError('GPS indisponível');
    return Position(
      latitude: latitude,
      longitude: longitude,
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
}

({
  MototaxistaViewModel viewModel,
  _Gps gps,
  _Dio dio,
  List<Map<String, dynamic>> publicacoes,
})
_preparar(WidgetTester tester) {
  final anterior = GeolocatorPlatform.instance;
  final gps = _Gps();
  GeolocatorPlatform.instance = gps;
  addTearDown(() => GeolocatorPlatform.instance = anterior);
  final publicacoes = <Map<String, dynamic>>[];
  final dio = _Dio();
  when(
    () => dio.patch<dynamic>(
      any(),
      data: any(named: 'data'),
      cancelToken: any(named: 'cancelToken'),
    ),
  ).thenAnswer((call) async {
    final body = Map<String, dynamic>.from(call.namedArguments[#data] as Map);
    if (body.containsKey('latitude')) publicacoes.add(body);
    return Response(
      requestOptions: RequestOptions(path: '/mototaxistas/moto-1'),
      data: {'disponivel': true},
    );
  });
  final viewModel = MototaxistaViewModel(
    repository: MototaxistaRepository(dio: dio),
    clock: tester.binding.clock.now,
  );
  addTearDown(viewModel.dispose);
  return (viewModel: viewModel, gps: gps, dio: dio, publicacoes: publicacoes);
}

void main() {
  testWidgets('Publica GPS inicial e renova parado somente após 60 segundos', (
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
      clock: tester.binding.clock.now,
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
    expect(publicacoes, hasLength(1));

    await tester.pump(const Duration(seconds: 45));
    await tester.pump();
    expect(publicacoes, hasLength(2));

    await viewModel.alterarDisponibilidade(id: 'moto-1', disponivel: false);
    await tester.pump(const Duration(seconds: 30));
    expect(publicacoes, hasLength(2));
  });

  testWidgets(
    'Amostra a cada 15s, acumula movimento desde o último envio e respeita 30s',
    (tester) async {
      final c = _preparar(tester);
      await c.viewModel.alterarDisponibilidade(id: 'moto-1', disponivel: true);
      await tester.pump();
      expect(c.publicacoes, hasLength(1));
      expect(c.gps.capturas, 1);

      c.gps.latitude += 0.0001; // Cerca de 11m: ainda abaixo do limiar.
      await tester.pump(const Duration(seconds: 15));
      await tester.pump();
      expect(c.gps.capturas, 2);
      expect(c.publicacoes, hasLength(1));

      c.gps.latitude += 0.0001; // Acumulado acima de 20m, após 30s.
      await tester.pump(const Duration(seconds: 15));
      await tester.pump();
      expect(c.publicacoes, hasLength(2));
      expect(c.publicacoes.last['latitude'], c.gps.latitude);

      c.gps.latitude += 0.0003;
      await tester.pump(const Duration(seconds: 15));
      await tester.pump();
      expect(
        c.publicacoes,
        hasLength(2),
        reason: 'Movimento não ignora o cooldown',
      );
      await tester.pump(const Duration(seconds: 15));
      await tester.pump();
      expect(c.publicacoes, hasLength(3));
      expect(c.gps.capturas, 5);
      c.viewModel.pararLocalizacao();
      await tester.pump();
    },
  );

  testWidgets('Pausa e retomada preservam o cooldown do GPS em movimento', (
    tester,
  ) async {
    final c = _preparar(tester);
    await c.viewModel.alterarDisponibilidade(id: 'moto-1', disponivel: true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    c.viewModel.definirLocalizacaoAtiva(false);
    c.gps.latitude += 0.001;
    await tester.pump(const Duration(seconds: 5));
    c.viewModel.definirLocalizacaoAtiva(true);
    await tester.pump();
    expect(c.publicacoes, hasLength(1));
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(c.publicacoes, hasLength(1));
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(c.publicacoes, hasLength(2));
    c.viewModel.pararLocalizacao();
    await tester.pump();
  });

  testWidgets(
    'Falha de publicação aplica backoff 30/60/120/300 mesmo após resume',
    (tester) async {
      final c = _preparar(tester);
      var tentativas = 0;
      when(
        () => c.dio.patch<dynamic>(
          any(),
          data: any(named: 'data'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((call) async {
        final body = call.namedArguments[#data] as Map;
        if (body.containsKey('latitude')) {
          tentativas++;
          if (tentativas <= 4) {
            throw DioException(
              requestOptions: RequestOptions(path: '/mototaxistas/moto-1'),
              type: DioExceptionType.connectionError,
            );
          }
        }
        return Response(
          requestOptions: RequestOptions(path: '/mototaxistas/moto-1'),
        );
      });
      await c.viewModel.alterarDisponibilidade(id: 'moto-1', disponivel: true);
      await tester.pump();
      expect(tentativas, 1);
      c.viewModel.definirLocalizacaoAtiva(false);
      c.viewModel.definirLocalizacaoAtiva(true);
      await tester.pump();
      expect(tentativas, 1);
      for (final (duracao, esperado) in [
        (30, 2),
        (60, 3),
        (120, 4),
        (300, 5),
      ]) {
        await tester.pump(Duration(seconds: duracao - 15));
        await tester.pump();
        expect(tentativas, esperado - 1);
        await tester.pump(const Duration(seconds: 15));
        await tester.pump();
        expect(tentativas, esperado);
      }
      c.viewModel.pararLocalizacao();
      await tester.pump();
    },
  );

  testWidgets('GPS indisponível tem backoff e não impede ficar online', (
    tester,
  ) async {
    final c = _preparar(tester);
    c.gps.falhar = true;
    expect(
      await c.viewModel.alterarDisponibilidade(id: 'moto-1', disponivel: true),
      isTrue,
    );
    await tester.pump();
    expect(c.viewModel.disponivel, isTrue);
    expect(c.gps.capturas, 1);
    expect(c.publicacoes, isEmpty);
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(c.gps.capturas, 1);
    c.gps.falhar = false;
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(c.publicacoes, hasLength(1));
    c.viewModel.pararLocalizacao();
    await tester.pump();
  });

  testWidgets(
    'Disponibilidade deduplica requisição em voo e reutiliza o valor da sessão',
    (tester) async {
      final c = _preparar(tester);
      final resposta = Completer<Response<dynamic>>();
      when(
        () => c.dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) => resposta.future);
      final primeira = c.viewModel.consultarDisponibilidade(id: 'moto-1');
      final segunda = c.viewModel.consultarDisponibilidade(id: 'moto-1');
      expect(identical(primeira, segunda), isTrue);
      resposta.complete(
        Response(
          requestOptions: RequestOptions(path: '/mototaxistas/moto-1'),
          data: {'disponivel': false},
        ),
      );
      expect(await primeira, isFalse);
      expect(await c.viewModel.consultarDisponibilidade(id: 'moto-1'), isFalse);
      verify(
        () => c.dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
      expect(c.viewModel.disponivel, isFalse);
      var alteracoes = 0;
      c.viewModel.addListener(() => alteracoes++);
      c.viewModel.definirEmAtendimento(id: 'moto-1', emAtendimento: true);
      expect(c.viewModel.emAtendimento, isTrue);
      c.viewModel.definirEmAtendimento(id: 'moto-1', emAtendimento: true);
      expect(alteracoes, 1);
      c.viewModel.pararLocalizacao();
      await tester.pump();
      expect(c.viewModel.emAtendimento, isFalse);
    },
  );

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
      clock: tester.binding.clock.now,
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
          clock: tester.binding.clock.now,
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
