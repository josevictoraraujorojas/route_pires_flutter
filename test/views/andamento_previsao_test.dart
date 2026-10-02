import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/views/andamento_corrida_page.dart';

void main() {
  late Map<String, dynamic> resposta;
  late Interceptor backend;
  var consultas = 0;

  setUp(() {
    consultas = 0;
    resposta = {
      'id': 'corrida-1',
      'status': 'ANDAMENTO',
      'mototaxistaId': 'moto-1',
      'passageiro': 'passageiro-1',
      'origem': {
        'latitude': -17.3,
        'longitude': -48.2,
        'rotulo': 'Rua das Flores, 42',
      },
      'destino': {
        'latitude': -17.31,
        'longitude': -48.21,
        'rotulo': 'Avenida Brasil, 10',
      },
      'tempoRestanteSegundos': 61,
      'distanciaRestanteMetros': 900.0,
      'pontoAtual': 0,
      'estimativaAtualizadaEm': DateTime.now().toUtc().toIso8601String(),
    };
    backend = InterceptorsWrapper(
      onRequest: (request, handler) {
        if (request.path.endsWith('/corrida-1')) consultas++;
        handler.resolve(
          Response(
            requestOptions: request,
            data: request.path.endsWith('/corrida-1')
                ? Map<String, dynamic>.from(resposta)
                : {'nome': 'Ana', 'disponivel': true},
          ),
        );
      },
    );
    ApiClient().dio.interceptors.add(backend);
  });

  tearDown(() => ApiClient().dio.interceptors.remove(backend));

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: AndamentoCorridaPage(
          corridaInicial: SolicitacaoCorrida.fromJson(
            resposta,
            categoria: CategoriaCorrida.corrida,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('Polling atualiza previsão quando somente as métricas mudam', (
    tester,
  ) async {
    await abrir(tester);
    await tester.pump(const Duration(seconds: 14));
    await tester.pump();
    expect(consultas, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(consultas, 1);
    expect(find.text('2 min • 900 m'), findsOneWidget);
    expect(find.text('Google Maps'), findsOneWidget);

    resposta['tempoRestanteSegundos'] = 60;
    resposta['distanciaRestanteMetros'] = 400.0;
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(find.text('1 min • 400 m'), findsOneWidget);
    expect(find.text('2 min • 900 m'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Previsão ausente ou com mais de 120 segundos não mostra valor antigo',
    (tester) async {
      resposta['estimativaAtualizadaEm'] = DateTime.now()
          .toUtc()
          .subtract(const Duration(seconds: 121))
          .toIso8601String();
      await abrir(tester);
      expect(find.text('Aguardando previsão'), findsOneWidget);
      expect(find.text('2 min • 900 m'), findsNothing);

      resposta['estimativaAtualizadaEm'] = null;
      await tester.pump(const Duration(seconds: 15));
      await tester.pump();
      expect(find.text('Aguardando previsão'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Destino final encerra previsão de chegada ao embarque', (
    tester,
  ) async {
    resposta['pontoAtual'] = 1;
    await abrir(tester);
    expect(find.text('2 min • 900 m'), findsNothing);
    expect(find.text('Em viagem para o destino'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Previsão com timestamp no futuro não permanece válida', (
    tester,
  ) async {
    resposta['estimativaAtualizadaEm'] = DateTime.now()
        .toUtc()
        .add(const Duration(days: 1))
        .toIso8601String();
    await abrir(tester);
    expect(find.text('Aguardando previsão'), findsOneWidget);
    expect(find.text('2 min • 900 m'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Finalização encerra polling e remove previsão', (tester) async {
    await abrir(tester);
    resposta['status'] = 'FINALIZADO';
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    final antes = consultas;
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(consultas, antes);
    expect(find.text('2 min • 900 m'), findsNothing);
    expect(find.text('Aguardando previsão'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Acompanhamento pausa no background e em outra rota', (
    tester,
  ) async {
    await abrir(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(consultas, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 1));
    final antes = consultas;
    final context = tester.element(find.byType(AndamentoCorridaPage));
    final navigator = Navigator.of(context);
    navigator.push(
      CupertinoPageRoute<void>(builder: (_) => const Text('Outra tela')),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(consultas, antes);
    navigator.pop();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(consultas, greaterThan(antes));
    await tester.pumpWidget(const SizedBox());
  });
}
