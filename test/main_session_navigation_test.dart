import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/token_storage.dart';
import 'package:route_pires_flutter/main.dart';
import 'package:route_pires_flutter/model/login_response.dart';
import 'package:route_pires_flutter/model/usuario_response.dart';
import 'package:route_pires_flutter/repositories/login_repository.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';

class MockLoginRepository extends Mock implements LoginRepository {}

class TestTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> delete() async {
    token = null;
  }
}

class UnauthorizedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('{}', 401);

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('401 em tela interna limpa sessão e volta à rota inicial', (
    tester,
  ) async {
    final repository = MockLoginRepository();
    final storage = TestTokenStorage();
    final usuario = UsuarioResponse(
      id: '123',
      nome: 'Ana',
      email: 'ana@teste.com',
      telefone: '123456789',
      tipo: 'PASSAGEIRO',
      historicoCorridas: [],
    );
    when(() => repository.logar(email: 'ana@teste.com', senha: 'senha'))
        .thenAnswer(
          (_) async => LoginResponse(usuario: usuario, accessToken: 'jwt'),
        );
    final login = LoginViewModel(
      repository: repository,
      tokenStorage: storage,
      isWeb: false,
      autoBootstrap: false,
    );
    await login.realizarLogin(email: 'ana@teste.com', senha: 'senha');

    final navigatorKey = GlobalKey<NavigatorState>();
    bindSessionNavigator(login, navigatorKey);
    final api = ApiClient();
    final previousAdapter = api.dio.httpClientAdapter;
    api.dio.httpClientAdapter = UnauthorizedAdapter();
    api.onUnauthorized = login.invalidarSessao;
    addTearDown(() {
      api.dio.httpClientAdapter = previousAdapter;
      api.onUnauthorized = null;
      api.clearSession();
      login.dispose();
    });

    await tester.pumpWidget(
      CupertinoApp(
        navigatorKey: navigatorKey,
        home: const CupertinoPageScaffold(child: Center(child: Text('Home'))),
      ),
    );
    navigatorKey.currentState!.push(
      CupertinoPageRoute<void>(
        builder: (_) => const CupertinoPageScaffold(
          child: Center(child: Text('Tela interna')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Tela interna'), findsOneWidget);

    await tester.runAsync(() async {
      await expectLater(api.dio.get('/auth/me'), throwsA(isA<DioException>()));
    });
    await tester.pumpAndSettle();

    expect(storage.token, isNull);
    expect(login.usuario, isNull);
    expect(find.text('Tela interna'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });
}
