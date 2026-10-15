import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/repositories/login_repository.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/views/minhas_corridas_page.dart';

void main() {
  late Interceptor backend;
  late LoginViewModel login;
  late List<RequestOptions> consultas;

  setUp(() async {
    consultas = [];
    backend = InterceptorsWrapper(
      onRequest: (request, handler) {
        dynamic data;
        if (request.path == '/auth/web/login') {
          data = {'id': 'p-1', 'tipo': 'PASSAGEIRO', 'nome': 'Maria'};
        } else if (request.path == '/auth/web/csrf') {
          data = {'token': 'teste', 'headerName': 'X-CSRF-TOKEN'};
        } else if (request.path == '/corridas-passageiro' ||
            request.path == '/corrida-frete') {
          consultas.add(request);
          final historico =
              request.queryParameters['status'] == 'FINALIZADO,CANCELADO';
          final limite = request.queryParameters['limite'] as int? ?? 50;
          final cursor = request.queryParameters['aposId'] as String?;
          final apos = cursor == null ? 31 : int.parse(cursor.substring(1));
          final inicio = request.path == '/corridas-passageiro' ? 30 : 29;
          data = [
            for (var i = inicio; i > 0; i -= 2)
              if ((!historico || i < apos))
                {
                  'id':
                      '${i.isEven ? 'p' : 'f'}${i.toString().padLeft(2, '0')}',
                  'status': 'FINALIZADO',
                  'passageiro': 'p-1',
                  'solicitanteId': 'p-1',
                  'origem': {
                    'latitude': -17.3,
                    'longitude': -48.2,
                    'rotulo': 'Origem $i',
                  },
                  'destino': {
                    'latitude': -17.31,
                    'longitude': -48.21,
                    'rotulo': 'Destino $i',
                  },
                  'dataHoraSolicitacao': DateTime.utc(
                    2026,
                    10,
                    1,
                    0,
                    i,
                  ).toIso8601String(),
                },
          ].take(limite).toList();
          if (!historico && request.queryParameters['status'] != null) {
            data = [];
          }
        } else {
          handler.reject(
            DioException(
              requestOptions: request,
              error: 'Requisição inesperada ${request.path}',
            ),
          );
          return;
        }
        handler.resolve(Response(requestOptions: request, data: data));
      },
    );
    ApiClient().dio.interceptors.add(backend);
    login = LoginViewModel(
      repository: LoginRepository(isWeb: true),
      isWeb: true,
      autoBootstrap: false,
    );
    expect(
      await login.realizarLogin(email: 'teste@example.test', senha: 'teste'),
      isTrue,
    );
  });
  tearDown(() {
    ApiClient().dio.interceptors.remove(backend);
    ApiClient().clearSession();
    login.dispose();
  });

  testWidgets(
    'Histórico exibe dez e Carregar mais busca a próxima página dos dois tipos',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LoginViewModel>.value(
          value: login,
          child: const CupertinoApp(home: MinhasCorridasPage()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 10));
      expect(consultas.length, 4);
      final iniciais = consultas
          .where((r) => r.queryParameters['limite'] != null)
          .toList();
      expect(iniciais.length, 2);
      expect(iniciais.every((r) => r.queryParameters['limite'] == 10), isTrue);
      expect(find.text('Origem: Origem 30'), findsOneWidget);
      final mais = find.textContaining('Carregar mais');
      await tester.scrollUntilVisible(
        mais,
        600,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(mais);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();
      expect(consultas.length, 6);
      expect(
        consultas.skip(4).every((r) => r.queryParameters['aposId'] == 'f21'),
        isTrue,
      );
      expect(
        consultas.skip(4).every((r) => r.queryParameters['limite'] == 10),
        isTrue,
      );
      await tester.scrollUntilVisible(
        find.text('Origem: Origem 20'),
        -300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Origem: Origem 20'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
