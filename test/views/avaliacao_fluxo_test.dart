import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/repositories/login_repository.dart';
import 'package:route_pires_flutter/services/atualizacoes_service.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/views/andamento_corrida_page.dart';
import 'package:route_pires_flutter/views/minhas_corridas_page.dart';

/// Pontos em que o passageiro é chamado a avaliar o mototaxista.
void main() {
  late Interceptor backend;
  late LoginViewModel login;
  late String status;

  Map<String, dynamic> corrida({String? avaliacaoMototaxistaId}) => {
    'id': 'corrida-1',
    'status': status,
    'mototaxistaId': 'moto-1',
    'passageiro': 'p-1',
    'origem': {'latitude': -17.3, 'longitude': -48.2, 'rotulo': 'Origem'},
    'destino': {'latitude': -17.31, 'longitude': -48.21, 'rotulo': 'Destino'},
    'avaliacaoMototaxistaId': ?avaliacaoMototaxistaId,
  };

  SolicitacaoCorrida modelo(Map<String, dynamic> json) =>
      SolicitacaoCorrida.fromJson(json, categoria: CategoriaCorrida.corrida);

  void avisarCorrida() => AtualizacoesService().publicar(const {
    'tipo': 'CORRIDAS_ATUALIZADAS',
    'corridaId': 'corrida-1',
  });

  Future<void> aguardarEvento(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder botao(String texto) => find.widgetWithText(CupertinoButton, texto);

  setUp(() async {
    status = 'ANDAMENTO';
    backend = InterceptorsWrapper(
      onRequest: (request, handler) {
        final filtro = request.queryParameters['status'] as String?;
        dynamic data;
        if (request.path == '/auth/web/login') {
          data = {'id': 'p-1', 'tipo': 'PASSAGEIRO', 'nome': 'Maria'};
        } else if (request.path == '/auth/web/csrf') {
          data = {'token': 'teste', 'headerName': 'X-CSRF-TOKEN'};
        } else if (request.path == '/corridas-passageiro') {
          data = [
            if (filtro != null && filtro.split(',').contains(status)) corrida(),
            if (filtro == 'FINALIZADO,CANCELADO')
              {
                ...corrida(avaliacaoMototaxistaId: 'antigaM'),
                'id': 'antiga',
                'status': 'FINALIZADO',
              },
          ];
        } else if (request.path == '/corrida-frete') {
          data = [];
        } else if (request.path.endsWith('/corrida-1')) {
          data = corrida();
        } else {
          data = {'nome': 'Ana', 'disponivel': true};
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

  test('Corrida lê os ids de avaliação e só finalizada sem nota pede uma', () {
    status = 'FINALIZADO';
    final semNota = modelo(corrida());
    expect(semNota.podeAvaliar(doMototaxista: false), isTrue);
    expect(semNota.podeAvaliar(doMototaxista: true), isTrue);

    final avaliada = modelo({
      ...corrida(avaliacaoMototaxistaId: 'corrida-1M'),
      'avaliacaoPassageiroId': 'corrida-1P',
    }).copyWith(passageiroNome: 'Maria');
    expect(avaliada.avaliacaoMototaxistaId, 'corrida-1M');
    expect(avaliada.avaliacaoPassageiroId, 'corrida-1P');
    expect(avaliada.podeAvaliar(doMototaxista: false), isFalse);
    expect(avaliada.podeAvaliar(doMototaxista: true), isFalse);

    for (final outro in ['PENDENTE', 'ANDAMENTO', 'CANCELADO']) {
      status = outro;
      expect(modelo(corrida()).podeAvaliar(doMototaxista: false), isFalse);
    }
  });

  group('Acompanhar corrida', () {
    Future<void> abrir(WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: AndamentoCorridaPage(corridaInicial: modelo(corrida())),
        ),
      );
      await aguardarEvento(tester);
    }

    testWidgets('Finalizada pede a avaliação e mantém o botão após Agora não', (
      tester,
    ) async {
      await abrir(tester);
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(botao('Avaliar mototaxista'), findsNothing);

      status = 'FINALIZADO';
      avisarCorrida();
      await aguardarEvento(tester);
      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.text('Como foi a corrida com Ana?'), findsOneWidget);

      await tester.tap(find.text('Agora não'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(botao('Avaliar mototaxista'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Cancelada não pede avaliação', (tester) async {
      await abrir(tester);
      status = 'CANCELADO';
      avisarCorrida();
      await aguardarEvento(tester);
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(botao('Avaliar mototaxista'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Minhas corridas pede a avaliação quando a corrida termina', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<LoginViewModel>.value(
        value: login,
        child: const CupertinoApp(home: MinhasCorridasPage()),
      ),
    );
    await aguardarEvento(tester);
    // A corrida antiga já foi avaliada e a atual ainda está em andamento.
    expect(find.text('CORRIDA · ANDAMENTO'), findsOneWidget);
    expect(find.text('CORRIDA · FINALIZADO'), findsOneWidget);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(botao('Avaliar mototaxista'), findsNothing);

    status = 'FINALIZADO';
    avisarCorrida();
    await aguardarEvento(tester);
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);

    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();
    expect(botao('Avaliar mototaxista'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
