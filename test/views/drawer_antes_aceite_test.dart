import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/views/drawer_corrida.dart';
import 'package:route_pires_flutter/views/drawer_entrega.dart';

void main() {
  const origem = LocalizacaoPonto(
    latitude: -17.30,
    longitude: -48.28,
    rotulo: 'Rua das Flores, 42',
  );
  const destino = LocalizacaoPonto(
    latitude: -17.29,
    longitude: -48.27,
    rotulo: 'Avenida Brasil, 10',
  );

  SolicitacaoCorrida pendente(CategoriaCorrida categoria) => SolicitacaoCorrida(
    id: 'corrida-1',
    categoria: categoria,
    status: 'PENDENTE',
    mototaxistaId: 'moto-1',
    passageiroId: 'passageiro-1',
    passageiroNome: 'Maria',
    origem: origem,
    destino: destino,
  );

  testWidgets('Antes do aceite, corrida mostra Iniciar e Voltar', (
    tester,
  ) async {
    var voltou = false;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: SizedBox(
            height: 500,
            child: DrawerCorrida(
              corrida: pendente(CategoriaCorrida.corrida),
              onIniciar: () {},
              onVoltar: () => voltou = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Iniciar corrida'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
    expect(find.textContaining('Cancelar'), findsNothing);
    expect(find.textContaining('Rua das Flores'), findsOneWidget);

    await tester.tap(find.text('Voltar'));
    expect(voltou, isTrue);
  });

  testWidgets('Antes do aceite, entrega mostra Iniciar e Voltar', (
    tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: SizedBox(
            height: 500,
            child: DrawerEntrega(
              entrega: pendente(CategoriaCorrida.frete),
              onIniciar: () {},
              onVoltar: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Iniciar entrega'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
    expect(find.textContaining('Cancelar'), findsNothing);
    expect(find.textContaining('Avenida Brasil'), findsOneWidget);
  });
}
