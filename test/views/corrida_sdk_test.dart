import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as gps;
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:google_navigation_flutter/src/google_navigation_flutter_platform_interface.dart';
import 'package:google_navigation_flutter/src/method_channel/method_channel.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/model/usuario_response.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';
import 'package:route_pires_flutter/views/corrida_mobile.dart';
import 'package:route_pires_flutter/views/corrida_web.dart' as web;
import 'package:route_pires_flutter/views/principal_page_mototaxista.dart';

class _Gps extends gps.GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<gps.LocationPermission> checkPermission() async =>
      gps.LocationPermission.whileInUse;
  @override
  Future<gps.Position> getCurrentPosition({
    gps.LocationSettings? locationSettings,
  }) async => gps.Position(
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

class _Login extends LoginViewModel {
  _Login() : super(autoBootstrap: false);
  UsuarioResponse? perfil = UsuarioResponse(
    id: 'moto-1',
    nome: 'João',
    email: 'moto@example.test',
    telefone: '64999999999',
    tipo: 'MOTOTAXISTA',
    historicoCorridas: [],
  );
  @override
  UsuarioResponse? get usuario => perfil;
  void encerrar() {
    perfil = null;
    notifyListeners();
  }
}

class _Session extends NavigationSessionAPIImpl {
  final remaining =
      StreamController<RemainingTimeOrDistanceChangedEvent>.broadcast();
  final arrival = StreamController<OnArrivalEvent>.broadcast();
  double time = 120;
  double distance = 900;
  Completer<NavigationTimeAndDistance>? leituraPendente;
  Completer<void>? paradaPendente;
  Completer<ContinueToNextDestinationResponse>? avancoPendente;
  int consultas = 0;
  bool falhaAoAvancar = false;
  @override
  Future<bool> areTermsAccepted() async => true;
  @override
  Future<void> createNavigationSession(
    bool abnormalTerminationReportingEnabled,
    TaskRemovedBehavior taskRemovedBehavior,
    NavigationNotificationOptions? notificationOptions,
  ) async {}
  @override
  Future<void> registerRemainingTimeOrDistanceChangedListener(
    int remainingTimeThresholdSeconds,
    int remainingDistanceThresholdMeters,
  ) async {}
  @override
  Stream<RemainingTimeOrDistanceChangedEvent>
  getNavigationRemainingTimeOrDistanceChangedEventStream() => remaining.stream;
  @override
  Stream<OnArrivalEvent> getNavigationOnArrivalEventStream() => arrival.stream;
  @override
  Future<NavigationRouteStatus> setDestinations(Destinations msg) async =>
      NavigationRouteStatus.statusOk;
  @override
  Future<void> startGuidance() async {}
  @override
  Future<void> stopGuidance() => paradaPendente?.future ?? Future.value();
  @override
  Future<void> clearDestinations() async {}
  @override
  Future<void> cleanup({bool resetSession = true}) async {}
  @override
  Future<NavigationTimeAndDistance> getCurrentTimeAndDistance() {
    consultas++;
    return leituraPendente?.future ??
        Future.value(
          NavigationTimeAndDistance(
            time: time,
            distance: distance,
            delaySeverity: TrafficDelaySeverity.light,
          ),
        );
  }

  @override
  Future<ContinueToNextDestinationResponse> continueToNextDestination() async {
    if (falhaAoAvancar) throw StateError('SDK indisponível');
    final resposta =
        await (avancoPendente?.future ??
            Future.value(ContinueToNextDestinationResponse()));
    time = 180;
    distance = 1200;
    return resposta;
  }
}

class _Platform extends GoogleMapsNavigationPlatform {
  _Platform(_Session session)
    : super(
        session,
        MapViewAPIImpl(),
        ImageRegistryAPIImpl(),
        AutoMapViewAPIImpl(),
      );
  @override
  Widget buildNavigationView({
    required MapViewInitializationOptions initializationOptions,
    required PlatformViewCreatedCallback onPlatformViewCreated,
    required MapReadyCallback onMapReady,
  }) => const SizedBox();
  @override
  Widget buildMapView({
    required MapViewInitializationOptions initializationOptions,
    required PlatformViewCreatedCallback onPlatformViewCreated,
    required MapReadyCallback onMapReady,
  }) => const SizedBox();
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<({_Login login, MototaxistaViewModel moto})> _iniciarHome(
  WidgetTester tester,
  InterceptorsWrapper interceptor,
) async {
  final session = _Session();
  GoogleMapsNavigationPlatform.instance = _Platform(session);
  final gpsAnterior = gps.GeolocatorPlatform.instance;
  gps.GeolocatorPlatform.instance = _Gps();
  final login = _Login();
  final moto = MototaxistaViewModel(clock: tester.binding.clock.now);
  ApiClient().dio.interceptors.add(interceptor);
  addTearDown(() async {
    ApiClient().dio.interceptors.remove(interceptor);
    gps.GeolocatorPlatform.instance = gpsAnterior;
    login.dispose();
    moto.dispose();
    await session.remaining.close();
    await session.arrival.close();
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LoginViewModel>.value(value: login),
        ChangeNotifierProvider<MototaxistaViewModel>.value(value: moto),
      ],
      child: const CupertinoApp(home: PrincipalPageMototaxista()),
    ),
  );
  await _flush(tester);
  return (login: login, moto: moto);
}

Future<List<Map<String, dynamic>>> _iniciarSdk(
  WidgetTester tester,
  _Session session,
) async {
  GoogleMapsNavigationPlatform.instance = _Platform(session);
  final gpsAnterior = gps.GeolocatorPlatform.instance;
  gps.GeolocatorPlatform.instance = _Gps();
  addTearDown(() async {
    gps.GeolocatorPlatform.instance = gpsAnterior;
    await session.remaining.close();
    await session.arrival.close();
  });
  var status = 'ANDAMENTO';
  final envios = <Map<String, dynamic>>[];
  Map<String, dynamic> corrida() => {
    'id': 'corrida-1',
    'mototaxistaId': 'moto-1',
    'passageiro': 'passageiro-1',
    'passageiroNome': 'Maria',
    'status': status,
    'formaPagamento': 'PIX',
    'origem': {
      'localizacao': {'latitude': -17.3, 'longitude': -48.28},
    },
    'destino': {
      'localizacao': {'latitude': -17.29, 'longitude': -48.27},
    },
  };
  final interceptor = InterceptorsWrapper(
    onRequest: (options, handler) {
      dynamic data;
      if (options.method == 'PUT') {
        final body = Map<String, dynamic>.from(options.data as Map);
        if (body['status'] case final String novoStatus) status = novoStatus;
        if (body.containsKey('tempoRestanteSegundos')) envios.add(body);
        data = corrida();
      } else if (options.path == '/corridas-passageiro') {
        data = status == 'ANDAMENTO' ? [corrida()] : [];
      } else if (options.path.startsWith('/passageiros')) {
        data = {'id': 'passageiro-1', 'nome': 'Maria'};
      } else {
        data = [];
      }
      handler.resolve(Response(requestOptions: options, data: data));
    },
  );
  ApiClient().dio.interceptors.add(interceptor);
  addTearDown(() => ApiClient().dio.interceptors.remove(interceptor));
  await tester.pumpWidget(
    CupertinoApp(
      home: Corrida(mototaxistaId: 'moto-1', onTituloChanged: (_) {}),
    ),
  );
  await _flush(tester);
  await tester.tap(find.text('Maria'));
  await _flush(tester);
  await tester.tap(find.text('Iniciar navegação'));
  await _flush(tester);
  expect(envios.single['pontoAtual'], 0);
  return envios;
}

OnArrivalEvent _chegadaEmbarque() => OnArrivalEvent(
  waypoint: NavigationWaypoint.withLatLngTarget(
    title: 'Embarque',
    target: const LatLng(latitude: -17.3, longitude: -48.28),
  ),
);

void main() {
  for (final online in [true, false]) {
    testWidgets(
      'Perfil acompanha recuperação ${online ? 'online' : 'offline'} após falha inicial',
      (tester) async {
        var consultasDisponibilidade = 0;
        var consultasCorridas = 0;
        var falharAlteracao = true;
        final home = await _iniciarHome(
          tester,
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.method == 'PATCH' &&
                  (options.data as Map).containsKey('disponivel') &&
                  falharAlteracao) {
                falharAlteracao = false;
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.badResponse,
                    response: Response(
                      requestOptions: options,
                      statusCode: 503,
                    ),
                  ),
                );
                return;
              }
              if (options.method == 'GET' &&
                  options.path == '/mototaxistas/moto-1') {
                consultasDisponibilidade++;
                if (consultasDisponibilidade == 1) {
                  handler.reject(
                    DioException(
                      requestOptions: options,
                      type: DioExceptionType.badResponse,
                      response: Response(
                        requestOptions: options,
                        statusCode: 503,
                        headers: Headers.fromMap({
                          'retry-after': ['60'],
                        }),
                      ),
                    ),
                  );
                  return;
                }
              }
              final perfil = options.path == '/mototaxistas/moto-1';
              if (!perfil) consultasCorridas++;
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: perfil ? {'disponivel': online} : [],
                ),
              );
            },
          ),
        );
        expect(consultasDisponibilidade, 1);
        expect(consultasCorridas, 2);
        await tester.tap(find.text('Perfil'));
        await _flush(tester);
        expect(find.byType(CupertinoSwitch), findsNothing);
        expect(find.text('Tentar novamente'), findsOneWidget);
        await tester.pump(const Duration(seconds: 30));
        await _flush(tester);
        expect(consultasDisponibilidade, 1, reason: 'Respeita Retry-After');
        expect(consultasCorridas, 2);

        await tester.pump(const Duration(seconds: 31));
        await _flush(tester);
        expect(consultasDisponibilidade, 2);
        expect(home.moto.disponivel, online);
        expect(find.text('Tentar novamente'), findsNothing);
        expect(
          tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
          online,
        );
        await tester.tap(find.text('Corrida'));
        await _flush(tester);
        expect(tester.widget<Corrida>(find.byType(Corrida)).online, online);
        await tester.pump(const Duration(seconds: 15));
        await _flush(tester);
        expect(consultasCorridas, online ? 4 : 2);
        expect(consultasDisponibilidade, 2);
        await tester.tap(find.text('Perfil'));
        await _flush(tester);
        await tester.tap(find.byType(CupertinoSwitch));
        await _flush(tester);
        expect(find.byType(CupertinoAlertDialog), findsOneWidget);
        expect(home.moto.disponivel, online);
        await tester.tap(find.text('OK'));
        await _flush(tester);
        expect(
          tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
          online,
        );
        await tester.tap(find.byType(CupertinoSwitch));
        await _flush(tester);
        expect(home.moto.disponivel, !online);
        expect(
          tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
          !online,
        );
        expect(consultasDisponibilidade, 2);
        await tester.pumpWidget(const SizedBox());
        await _flush(tester);
      },
    );
  }

  testWidgets(
    'Home pausa a recuperação sem antecipar Retry-After na retomada',
    (tester) async {
      var consultasDisponibilidade = 0;
      final home = await _iniciarHome(
        tester,
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final perfil = options.path == '/mototaxistas/moto-1';
            if (perfil && options.method == 'GET') {
              consultasDisponibilidade++;
              if (consultasDisponibilidade == 1) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.badResponse,
                    response: Response(
                      requestOptions: options,
                      statusCode: 503,
                      headers: Headers.fromMap({
                        'retry-after': ['60'],
                      }),
                    ),
                  ),
                );
                return;
              }
            }
            handler.resolve(
              Response(
                requestOptions: options,
                data: perfil ? {'disponivel': true} : [],
              ),
            );
          },
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 20));
      await _flush(tester);
      expect(consultasDisponibilidade, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _flush(tester);
      expect(consultasDisponibilidade, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 45));
      await _flush(tester);
      expect(consultasDisponibilidade, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _flush(tester);
      expect(consultasDisponibilidade, 2);
      expect(home.moto.disponivel, isTrue);
      await tester.pumpWidget(const SizedBox());
      await _flush(tester);
    },
  );

  testWidgets('Home encerra a recuperação de disponibilidade no logout', (
    tester,
  ) async {
    var consultasDisponibilidade = 0;
    final home = await _iniciarHome(
      tester,
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/mototaxistas/moto-1') {
            consultasDisponibilidade++;
            handler.reject(
              DioException(requestOptions: options, error: 'Sem conexão'),
            );
          } else {
            handler.resolve(Response(requestOptions: options, data: []));
          }
        },
      ),
    );
    home.login.encerrar();
    await tester.pump(const Duration(minutes: 5));
    await _flush(tester);
    expect(consultasDisponibilidade, 1);
    await tester.pumpWidget(const SizedBox());
    await _flush(tester);
  });

  testWidgets('Perfil propaga disponibilidade para a aba Corrida já aberta', (
    tester,
  ) async {
    final session = _Session();
    GoogleMapsNavigationPlatform.instance = _Platform(session);
    final gpsAnterior = gps.GeolocatorPlatform.instance;
    gps.GeolocatorPlatform.instance = _Gps();
    final login = _Login();
    final moto = MototaxistaViewModel(clock: tester.binding.clock.now);
    var disponivel = false;
    var consultasCorridas = 0;
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        dynamic data;
        if (options.path == '/corridas-passageiro' ||
            options.path == '/corrida-frete') {
          consultasCorridas++;
          data = [];
        } else if (options.path == '/mototaxistas/moto-1') {
          if (options.method == 'PATCH') {
            final body = options.data as Map;
            if (body['disponivel'] case final bool valor) disponivel = valor;
          }
          data = {'disponivel': disponivel};
        } else {
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Requisição inesperada ${options.path}',
            ),
          );
          return;
        }
        handler.resolve(Response(requestOptions: options, data: data));
      },
    );
    ApiClient().dio.interceptors.add(interceptor);
    addTearDown(() async {
      ApiClient().dio.interceptors.remove(interceptor);
      gps.GeolocatorPlatform.instance = gpsAnterior;
      login.dispose();
      moto.dispose();
      await session.remaining.close();
      await session.arrival.close();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LoginViewModel>.value(value: login),
          ChangeNotifierProvider<MototaxistaViewModel>.value(value: moto),
        ],
        child: const CupertinoApp(home: PrincipalPageMototaxista()),
      ),
    );
    await _flush(tester);
    final estadoCorrida = tester.state(find.byType(Corrida));
    expect(consultasCorridas, 2);

    await tester.tap(find.text('Perfil'));
    await _flush(tester);
    expect(
      tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
      isFalse,
    );
    await tester.tap(find.byType(CupertinoSwitch));
    await _flush(tester);
    expect(moto.disponivel, isTrue);
    await tester.tap(find.text('Corrida'));
    await _flush(tester);
    expect(tester.state(find.byType(Corrida)), same(estadoCorrida));
    await tester.pump(const Duration(seconds: 15));
    await _flush(tester);
    expect(consultasCorridas, 4);

    await tester.tap(find.text('Perfil'));
    await _flush(tester);
    await tester.tap(find.byType(CupertinoSwitch));
    await _flush(tester);
    expect(moto.disponivel, isFalse);
    await tester.tap(find.text('Corrida'));
    await _flush(tester);
    final antes = consultasCorridas;
    await tester.pump(const Duration(seconds: 30));
    await _flush(tester);
    expect(consultasCorridas, antes);
    expect(tester.state(find.byType(Corrida)), same(estadoCorrida));
    await tester.pumpWidget(const SizedBox());
    await _flush(tester);
  });

  testWidgets('Web informa atendimento mesmo antes de selecionar corrida', (
    tester,
  ) async {
    final atendimento = <bool>[];
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(
            requestOptions: options,
            data: options.path == '/corridas-passageiro'
                ? [
                    {
                      'id': 'corrida-1',
                      'mototaxistaId': 'moto-1',
                      'passageiro': 'passageiro-1',
                      'status': 'ANDAMENTO',
                      'origem': {
                        'localizacao': {'latitude': -17.3, 'longitude': -48.28},
                      },
                      'destino': {
                        'localizacao': {
                          'latitude': -17.29,
                          'longitude': -48.27,
                        },
                      },
                    },
                  ]
                : options.path.startsWith('/passageiros')
                ? {'nome': 'Maria'}
                : [],
          ),
        );
      },
    );
    ApiClient().dio.interceptors.add(interceptor);
    addTearDown(() => ApiClient().dio.interceptors.remove(interceptor));
    await tester.pumpWidget(
      CupertinoApp(
        home: web.Corrida(
          mototaxistaId: 'moto-1',
          onTituloChanged: (_) {},
          onAtendimentoChanged: atendimento.add,
        ),
      ),
    );
    await _flush(tester);
    expect(atendimento, contains(true));
    await tester.pumpWidget(const SizedBox());
    await _flush(tester);
  });

  testWidgets('Home inicia GPS do disponível e interrompe em pausa/logout', (
    tester,
  ) async {
    final session = _Session();
    GoogleMapsNavigationPlatform.instance = _Platform(session);
    final previousGps = gps.GeolocatorPlatform.instance;
    gps.GeolocatorPlatform.instance = _Gps();
    final login = _Login();
    final moto = MototaxistaViewModel(clock: tester.binding.clock.now);
    final gpsEnvios = <Map<String, dynamic>>[];
    var consultasDisponibilidade = 0;
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.method == 'GET' &&
            options.path.startsWith('/mototaxistas/')) {
          consultasDisponibilidade++;
        }
        if (options.method == 'PATCH') {
          gpsEnvios.add(Map<String, dynamic>.from(options.data as Map));
        }
        handler.resolve(
          Response(
            requestOptions: options,
            data: options.path.startsWith('/mototaxistas/')
                ? {'disponivel': true}
                : [],
          ),
        );
      },
    );
    ApiClient().dio.interceptors.add(interceptor);
    addTearDown(() async {
      ApiClient().dio.interceptors.remove(interceptor);
      gps.GeolocatorPlatform.instance = previousGps;
      login.dispose();
      moto.dispose();
      await session.remaining.close();
      await session.arrival.close();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LoginViewModel>.value(value: login),
          ChangeNotifierProvider<MototaxistaViewModel>.value(value: moto),
        ],
        child: const CupertinoApp(home: PrincipalPageMototaxista()),
      ),
    );
    await _flush(tester);
    expect(gpsEnvios, [
      {'latitude': -17.3, 'longitude': -48.28},
    ]);
    await tester.tap(find.text('Perfil'));
    await _flush(tester);
    expect(
      consultasDisponibilidade,
      1,
      reason: 'O perfil reutiliza a disponibilidade consultada pela home',
    );
    expect(find.textContaining('mantenha o aplicativo aberto'), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
    await _flush(tester);
    expect(gpsEnvios, hasLength(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 30));
    await _flush(tester);
    expect(gpsEnvios, hasLength(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _flush(tester);
    expect(gpsEnvios, hasLength(1));
    login.encerrar();
    await tester.pump(const Duration(seconds: 30));
    await _flush(tester);
    expect(gpsEnvios, hasLength(1));
    await tester.pumpWidget(const SizedBox());
    await _flush(tester);
  });

  testWidgets(
    'Resume durante avanço não registra listeners da etapa anterior',
    (tester) async {
      final session = _Session();
      final envios = await _iniciarSdk(tester, session);
      session.avancoPendente = Completer<ContinueToNextDestinationResponse>();
      session.arrival.add(_chegadaEmbarque());
      await _flush(tester);
      final consultas = session.consultas;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _flush(tester);
      expect(session.remaining.hasListener, isFalse);
      expect(session.arrival.hasListener, isFalse);
      expect(session.consultas, consultas);
      expect(envios, hasLength(1));

      session.avancoPendente!.complete(ContinueToNextDestinationResponse());
      await _flush(tester);
      expect(envios.last, {
        'tempoRestanteSegundos': 180,
        'distanciaRestanteMetros': 1200.0,
        'pontoAtual': 1,
      });
      expect(session.remaining.hasListener, isTrue);
      await tester.pumpWidget(const SizedBox());
      await _flush(tester);
    },
  );

  testWidgets(
    'Leitura antiga do embarque não publica métricas na segunda etapa',
    (tester) async {
      final session = _Session();
      final envios = await _iniciarSdk(tester, session);
      final leitura = Completer<NavigationTimeAndDistance>();
      session.leituraPendente = leitura;
      await tester.pump(const Duration(seconds: 30));
      await _flush(tester);
      session.arrival.add(_chegadaEmbarque());
      await _flush(tester);
      expect(
        envios,
        hasLength(1),
        reason: 'A leitura da nova etapa espera a anterior terminar',
      );
      session.leituraPendente = null;
      leitura.complete(
        NavigationTimeAndDistance(
          time: 10,
          distance: 50,
          delaySeverity: TrafficDelaySeverity.light,
        ),
      );
      await _flush(tester);
      expect(envios, hasLength(2));
      expect(envios.last, {
        'tempoRestanteSegundos': 180,
        'distanciaRestanteMetros': 1200.0,
        'pontoAtual': 1,
      });
      await tester.pumpWidget(const SizedBox());
      await _flush(tester);
    },
  );

  for (final cancelar in [false, true]) {
    testWidgets(
      '${cancelar ? 'Cancelar' : 'Finalizar'} durante avanço descarta resposta tardia do SDK',
      (tester) async {
        final session = _Session();
        final envios = await _iniciarSdk(tester, session);
        session.avancoPendente = Completer<ContinueToNextDestinationResponse>();
        session.arrival.add(_chegadaEmbarque());
        await _flush(tester);
        if (cancelar) {
          await tester.tap(find.text('Cancelar corrida'));
          await _flush(tester);
          await tester.tap(find.text('Problema com o veículo'));
        } else {
          await tester.tap(find.text('Finalizar corrida'));
        }
        await _flush(tester);
        final consultas = session.consultas;
        session.avancoPendente!.complete(ContinueToNextDestinationResponse());
        await _flush(tester);
        final dynamic estado = tester.state(find.byType(Corrida));
        expect(estado.navegacaoAtiva, isFalse);
        expect(estado.pontoAtual, 0);
        expect(envios, hasLength(1));
        expect(session.consultas, consultas);
        expect(session.remaining.hasListener, isFalse);
        expect(session.arrival.hasListener, isFalse);
        await tester.pumpWidget(const SizedBox());
        await _flush(tester);
      },
    );
  }

  testWidgets('SDK publica após aceite, troca etapa e encerra assinaturas', (
    tester,
  ) async {
    final session = _Session();
    GoogleMapsNavigationPlatform.instance = _Platform(session);
    final previousGps = gps.GeolocatorPlatform.instance;
    gps.GeolocatorPlatform.instance = _Gps();
    addTearDown(() async {
      gps.GeolocatorPlatform.instance = previousGps;
      await session.remaining.close();
      await session.arrival.close();
    });
    var status = 'PENDENTE';
    final envios = <Map<String, dynamic>>[];
    Map<String, dynamic> corrida() => {
      'id': 'corrida-1',
      'mototaxistaId': 'moto-1',
      'passageiro': 'passageiro-1',
      'status': status,
      'passageiroNome': 'Maria',
      'formaPagamento': 'PIX',
      'origem': {
        'localizacao': {'latitude': -17.3, 'longitude': -48.28},
        'rotulo': 'Embarque',
      },
      'destino': {
        'localizacao': {'latitude': -17.29, 'longitude': -48.27},
        'rotulo': 'Destino',
      },
    };
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        dynamic data;
        if (options.method == 'PUT') {
          final body = Map<String, dynamic>.from(options.data as Map);
          if (body['status'] case final String nextStatus) status = nextStatus;
          if (body.containsKey('tempoRestanteSegundos')) envios.add(body);
          data = corrida();
        } else if (options.path == '/corridas-passageiro') {
          data = [corrida()];
        } else if (options.path.startsWith('/corrida-frete')) {
          data = [];
        } else if (options.path.startsWith('/passageiros')) {
          data = {'id': 'passageiro-1', 'nome': 'Maria'};
        } else {
          data = corrida();
        }
        handler.resolve(Response(requestOptions: options, data: data));
      },
    );
    ApiClient().dio.interceptors.add(interceptor);
    addTearDown(() => ApiClient().dio.interceptors.remove(interceptor));

    await tester.pumpWidget(
      CupertinoApp(
        home: Corrida(mototaxistaId: 'moto-1', onTituloChanged: (_) {}),
      ),
    );
    await _flush(tester);
    expect(
      find.text('Maria'),
      findsOneWidget,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .toList()
          .toString(),
    );
    session.remaining.add(
      RemainingTimeOrDistanceChangedEvent(
        remainingTime: 120,
        remainingDistance: 900,
        delaySeverity: TrafficDelaySeverity.light,
      ),
    );
    await _flush(tester);
    expect(envios, isEmpty);
    await tester.tap(find.text('Maria'));
    await _flush(tester);
    await tester.tap(find.text('Iniciar corrida'));
    await _flush(tester);
    expect(status, 'ANDAMENTO');
    expect(envios, [
      {
        'tempoRestanteSegundos': 120,
        'distanciaRestanteMetros': 900.0,
        'pontoAtual': 0,
      },
    ]);

    final chegada = OnArrivalEvent(
      waypoint: NavigationWaypoint.withLatLngTarget(
        title: 'Embarque',
        target: const LatLng(latitude: -17.3, longitude: -48.28),
      ),
    );
    session.falhaAoAvancar = true;
    session.arrival.add(chegada);
    await _flush(tester);
    await tester.pump(const Duration(seconds: 30));
    await _flush(tester);
    expect(envios.last, {
      'tempoRestanteSegundos': 120,
      'distanciaRestanteMetros': 900.0,
      'pontoAtual': 0,
    });
    session.falhaAoAvancar = false;
    session.avancoPendente = Completer<ContinueToNextDestinationResponse>();
    session.arrival.add(chegada);
    await _flush(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _flush(tester);
    session.avancoPendente!.complete(ContinueToNextDestinationResponse());
    await _flush(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _flush(tester);
    await tester.pump(const Duration(seconds: 30));
    await _flush(tester);
    expect(envios.last, {
      'tempoRestanteSegundos': 180,
      'distanciaRestanteMetros': 1200.0,
      'pontoAtual': 1,
    });

    session.leituraPendente = Completer<NavigationTimeAndDistance>();
    await tester.pump(const Duration(seconds: 30));
    await _flush(tester);
    final consultasAntesFinal = session.consultas;
    final totalAntesFinal = envios.length;
    session.paradaPendente = Completer<void>();
    await tester.tap(find.text('Finalizar corrida'));
    await _flush(tester);
    expect(status, 'FINALIZADO');
    session.leituraPendente!.complete(
      NavigationTimeAndDistance(
        time: 100,
        distance: 700,
        delaySeverity: TrafficDelaySeverity.light,
      ),
    );
    await _flush(tester);
    expect(
      session.consultas,
      consultasAntesFinal,
      reason: 'Não reinicia a leitura cancelada enquanto o SDK encerra',
    );
    expect(envios, hasLength(totalAntesFinal));
    session.paradaPendente!.complete();
    await _flush(tester);

    await tester.pumpWidget(const SizedBox());
    await _flush(tester);
    expect(session.remaining.hasListener, isFalse);
    expect(session.arrival.hasListener, isFalse);
    final total = envios.length;
    await tester.pump(const Duration(seconds: 30));
    expect(envios, hasLength(total));
  });
}
