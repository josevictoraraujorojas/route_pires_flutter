import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_pires_flutter/views/motivo_cancelamento_dialog.dart';

void main() {
  testWidgets('Outros exige descrição e devolve o motivo digitado', (
    tester,
  ) async {
    String? motivoEscolhido;
    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoPageScaffold(
            child: Center(
              child: CupertinoButton(
                onPressed: () async {
                  motivoEscolhido = await solicitarMotivoCancelamento(
                    context,
                    mototaxista: false,
                  );
                },
                child: const Text('Abrir cancelamento'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir cancelamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outros'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<CupertinoDialogAction>(
            find.widgetWithText(
              CupertinoDialogAction,
              'Confirmar cancelamento',
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byType(CupertinoTextField),
      '  Mudança de rota  ',
    );
    await tester.pump();
    await tester.tap(find.text('Confirmar cancelamento'));
    await tester.pumpAndSettle();

    expect(motivoEscolhido, 'Mudança de rota');
  });
}
