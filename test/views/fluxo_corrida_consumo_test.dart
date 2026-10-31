import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/services/atualizacoes_service.dart';
import 'package:route_pires_flutter/views/fluxo_corrida_page.dart';

void main() {
  late Interceptor backend;
  var consultas = 0;
  var criada = false;
  var status = 'ANDAMENTO';
  const ponto = LocalizacaoPonto(
    latitude: -17.3,
    longitude: -48.2,
    rotulo: 'Centro',
  );
  Map<String, dynamic> corrida() => {
    'id': 'c-1',
    'status': status,
    'passageiro': 'p-1',
    'mototaxistaId': 'm-1',
    'origem': {'latitude': -17.3, 'longitude': -48.2},
    'destino': {'latitude': -17.31, 'longitude': -48.21},
  };

  setUp(() {
    consultas = 0;
    criada = true;
    status = 'ANDAMENTO';
    backend = InterceptorsWrapper(
      onRequest: (request, handler) {
        dynamic data;
        if (request.path == '/corridas-passageiro/c-1') {
          consultas++;
          data = corrida();
        } else if (request.path == '/corridas-passageiro') {
          if (request.method == 'POST') {
            criada = true;
            data = corrida();
          } else {
            data = criada ? [corrida()] : [];
          }
        } else if (request.path == '/corrida-frete') {
          data = [];
        } else if (request.path == '/mototaxistas/disponiveis') {
          data = [
            {'id': 'm-1', 'nome': 'Ana', 'disponivel': true},
          ];
        } else {
          handler.reject(
            DioException(
              requestOptions: request,
              error: 'Requisição inesperada',
            ),
          );
          return;
        }
        handler.resolve(Response(requestOptions: request, data: data));
      },
    );
    ApiClient().dio.interceptors.add(backend);
  });
  tearDown(() => ApiClient().dio.interceptors.remove(backend));
  Future<void> abrir(WidgetTester tester, {bool visivel = true}) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: TickerMode(
          enabled: visivel,
          child: const FluxoCorridaPage(
            passageiroId: 'p-1',
            categoria: CategoriaCorrida.corrida,
            origem: ponto,
            destino: ponto,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
  }

  void avisarCorrida() => AtualizacoesService().publicar(const {
    'tipo': 'CORRIDAS_ATUALIZADAS',
    'corridaId': 'c-1',
  });

  Future<void> aguardarEvento(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets(
    'Aceita só consulta por evento e pausa em background e aba oculta',
    (tester) async {
      await abrir(tester);
      final inicial = consultas;
      expect(inicial, 1);
      await tester.pump(const Duration(seconds: 30));
      await tester.pump(const Duration(milliseconds: 1));
      expect(consultas, inicial);
      avisarCorrida();
      await aguardarEvento(tester);
      expect(consultas, inicial + 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      avisarCorrida();
      await tester.pump(const Duration(seconds: 30));
      await tester.pump(const Duration(milliseconds: 1));
      expect(consultas, inicial + 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 1));
      await abrir(tester, visivel: false);
      final ocultas = consultas;
      avisarCorrida();
      await tester.pump(const Duration(seconds: 30));
      await tester.pump(const Duration(milliseconds: 1));
      expect(consultas, ocultas);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('O próprio diálogo de espera só consulta ao receber evento', (
    tester,
  ) async {
    criada = false;
    status = 'PENDENTE';
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await abrir(tester);
    await tester.tap(find.text('Ana'));
    await tester.pump();
    await tester.tap(find.text('Confirmar'));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Aguardando Ana'), findsOneWidget);
    final antes = consultas;
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 1));
    expect(consultas, antes);
    avisarCorrida();
    await aguardarEvento(tester);
    expect(consultas, antes + 1);
    await tester.pumpWidget(const SizedBox());
  });
}
