import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/views/solicitar_corrida_page.dart';

void main() {
  testWidgets('Oferece Corrida e Frete com seleção visual clara', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: SolicitarCorridaPage(
          inicioInicial: LocalizacaoPonto(
            latitude: -17.30,
            longitude: -48.28,
            rotulo: 'Rua das Flores, 42',
          ),
          destinoInicial: LocalizacaoPonto(
            latitude: -17.29,
            longitude: -48.27,
            rotulo: 'Avenida Brasil, 10',
          ),
        ),
      ),
    );

    expect(find.text('FRETE SIMPLES'), findsNothing);
    expect(_corOpcao(tester, 'CORRIDA'), const Color(0xFF0057D9));
    expect(_corOpcao(tester, 'FRETE'), const Color(0xFFF2F4F8));

    await tester.tap(find.text('FRETE'));
    await tester.pump();

    expect(_corOpcao(tester, 'CORRIDA'), const Color(0xFFF2F4F8));
    expect(_corOpcao(tester, 'FRETE'), const Color(0xFF0057D9));
    expect(find.text('Dados da carga'), findsOneWidget);
  });
}

Color? _corOpcao(WidgetTester tester, String texto) {
  final botao = tester.widget<CupertinoButton>(
    find.widgetWithText(CupertinoButton, texto),
  );
  final decoracao = (botao.child as Container).decoration! as BoxDecoration;
  return decoracao.color;
}
