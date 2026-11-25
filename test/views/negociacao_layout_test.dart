import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/views/fluxo_corrida_page.dart';

void main() {
  const ponto = LocalizacaoPonto(
    latitude: -17.3,
    longitude: -48.2,
    rotulo: 'Centro',
  );
  const telas = [Size(360, 640), Size(360, 740), Size(412, 915)];
  const escalas = [1.0, 1.3];

  for (final tela in telas) {
    for (final escala in escalas) {
      testWidgets(
        'Ações não se sobrepõem em ${tela.width}x${tela.height} com texto x$escala',
        (tester) async {
          final backend = InterceptorsWrapper(
            onRequest: (request, handler) {
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: request.path == '/mototaxistas/disponiveis'
                      ? [
                          {
                            'id': 'm-1',
                            'nome': 'Ana',
                            'disponivel': true,
                            'precoZonaUrbana': 10.0,
                            'precoBairrosAfastados': 15.0,
                            'precoBandeira2': 20.0,
                          },
                        ]
                      : [],
                ),
              );
            },
          );
          ApiClient().dio.interceptors.add(backend);
          addTearDown(() => ApiClient().dio.interceptors.remove(backend));
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = tela * 3;
          tester.view.padding = const FakeViewPadding(top: 72, bottom: 144);
          tester.platformDispatcher.textScaleFactorTestValue = escala;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await tester.pumpWidget(
            const CupertinoApp(
              home: FluxoCorridaPage(
                passageiroId: 'p-1',
                categoria: CategoriaCorrida.corrida,
                origem: ponto,
                destino: ponto,
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 10));
          await tester.pump(const Duration(milliseconds: 10));
          await tester.tap(find.text('Ana'));
          await tester.pump();

          expect(tester.takeException(), isNull);
          final cancelar = tester.getRect(
            find.widgetWithText(CupertinoButton, 'Cancelar busca'),
          );
          for (final acao in ['Voltar', 'Confirmar']) {
            final botao = tester.getRect(
              find.widgetWithText(CupertinoButton, acao),
            );
            expect(botao.bottom, lessThanOrEqualTo(cancelar.top));
            expect(botao.bottom, lessThanOrEqualTo(tela.height));
          }

          await tester.tap(find.text('Voltar'));
          await tester.pump();
          expect(find.text('Ana'), findsOneWidget);
          expect(find.text('Confirmar'), findsNothing);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
