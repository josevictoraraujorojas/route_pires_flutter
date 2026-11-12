import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/repositories/avaliacao_repository.dart';
import 'package:route_pires_flutter/viewmodel/avaliacao_viewmodel.dart';
import 'package:route_pires_flutter/views/avaliacao_dialog.dart';

class _Repository extends Mock implements AvaliacaoRepository {}

void main() {
  late _Repository repository;
  bool? avaliada;

  When<Future<void>> envio() => when(
    () => repository.avaliar(
      corridaId: any(named: 'corridaId'),
      doMototaxista: any(named: 'doMototaxista'),
      nota: any(named: 'nota'),
      comentario: any(named: 'comentario'),
    ),
  );

  Future<void> abrir(WidgetTester tester) async {
    avaliada = null;
    final viewModel = AvaliacaoViewModel(repository: repository);
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoPageScaffold(
            child: Center(
              child: CupertinoButton(
                onPressed: () async {
                  avaliada = await avaliarCorrida(
                    context,
                    corridaId: 'corrida-1',
                    doMototaxista: true,
                    nome: 'Ana',
                    viewModel: viewModel,
                  );
                },
                child: const Text('Abrir avaliação'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir avaliação'));
    await tester.pumpAndSettle();
  }

  VoidCallback? acao(WidgetTester tester, String texto) => tester
      .widget<CupertinoDialogAction>(
        find.widgetWithText(CupertinoDialogAction, texto),
      )
      .onPressed;

  setUp(() => repository = _Repository());

  testWidgets('Enviar exige nota e manda estrelas e comentário', (
    tester,
  ) async {
    envio().thenAnswer((_) async {});
    await abrir(tester);

    expect(find.text('Avaliar passageiro'), findsOneWidget);
    expect(find.bySemanticsLabel('1 estrela'), findsOneWidget);
    expect(find.bySemanticsLabel('5 estrelas'), findsOneWidget);
    expect(acao(tester, 'Enviar'), isNull);

    await tester.tap(find.byKey(const ValueKey('estrela-4')));
    await tester.enterText(find.byType(CupertinoTextField), ' Pontual ');
    await tester.pump();
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(avaliada, isTrue);
    verify(
      () => repository.avaliar(
        corridaId: 'corrida-1',
        doMototaxista: true,
        nota: 4,
        comentario: 'Pontual',
      ),
    ).called(1);
  });

  testWidgets('Estrelas cabem em tela estreita com fonte ampliada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await abrir(tester);

    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('estrela-5')));
    await tester.pump();
    expect(acao(tester, 'Enviar'), isNotNull);
  });

  testWidgets('Agora não fecha sem enviar', (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();

    expect(avaliada, isFalse);
    verifyZeroInteractions(repository);
  });

  testWidgets('Voltar do sistema não fecha o diálogo durante o envio', (
    tester,
  ) async {
    final resposta = Completer<void>();
    envio().thenAnswer((_) => resposta.future);
    await abrir(tester);

    await tester.tap(find.byKey(const ValueKey('estrela-5')));
    await tester.pump();
    await tester.tap(find.text('Enviar'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Enviando...'), findsOneWidget);
    expect(avaliada, isNull);

    resposta.complete();
    await tester.pumpAndSettle();
    expect(avaliada, isTrue);
  });

  testWidgets('Corrida já avaliada mostra a mensagem e bloqueia o envio', (
    tester,
  ) async {
    final requisicao = RequestOptions(path: '');
    envio().thenThrow(
      DioException(
        requestOptions: requisicao,
        response: Response<dynamic>(
          requestOptions: requisicao,
          statusCode: 400,
          data: {'message': 'Esta corrida já possui avaliação de passageiro'},
        ),
      ),
    );
    await abrir(tester);

    await tester.tap(find.byKey(const ValueKey('estrela-5')));
    await tester.pump();
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Esta corrida já foi avaliada'), findsOneWidget);
    expect(acao(tester, 'Enviar'), isNull);

    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();

    expect(avaliada, isTrue);
  });
}
