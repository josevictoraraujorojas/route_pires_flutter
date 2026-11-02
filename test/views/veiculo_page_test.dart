import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/model/usuario_response.dart';
import 'package:route_pires_flutter/model/veiculo.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/veiculo_viewmodel.dart';
import 'package:route_pires_flutter/views/veiculo_page.dart';

class _Repository extends Mock implements MototaxistaRepository {}

void main() {
  const veiculo = Veiculo(
    placa: 'ABC1D23',
    renavam: '12345678901',
    modelo: 'Honda CG 160',
    ano: '2024',
  );

  setUpAll(() => registerFallbackValue(veiculo));

  Future<void> abrir(WidgetTester tester, _Repository repository) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final login = LoginViewModel(autoBootstrap: false, isWeb: true)
      ..atualizarUsuarioLocal(
        UsuarioResponse(
          id: 'm-1',
          nome: 'Carlos',
          email: 'carlos@teste.com',
          telefone: '64999558833',
          tipo: 'MOTOTAXISTA',
          historicoCorridas: const [],
        ),
      );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: login),
          ChangeNotifierProvider(
            create: (_) => VeiculoViewModel(repository: repository),
          ),
        ],
        child: const CupertinoApp(home: VeiculoPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Preenche o formulário e envia os dados alterados', (
    tester,
  ) async {
    final repository = _Repository();
    when(
      () => repository.buscarVeiculo(id: 'm-1'),
    ).thenAnswer((_) async => veiculo);
    when(
      () => repository.atualizarVeiculo(
        id: 'm-1',
        veiculo: any(named: 'veiculo'),
      ),
    ).thenAnswer((_) async {});

    await abrir(tester, repository);
    final placa = find.byType(CupertinoTextField).first;
    expect(
      tester.widget<CupertinoTextField>(placa).controller?.text,
      'ABC1D23',
    );

    await tester.enterText(placa, 'xyz-9a87');
    await tester.tap(find.text('Atualizar'));
    await tester.pumpAndSettle();

    final enviado =
        verify(
              () => repository.atualizarVeiculo(
                id: 'm-1',
                veiculo: captureAny(named: 'veiculo'),
              ),
            ).captured.single
            as Veiculo;
    expect(enviado.placa, 'XYZ9A87');
    expect(enviado.toJson()['ano'], 2024);
    expect(find.text('Veículo atualizado com sucesso!'), findsOneWidget);
  });

  testWidgets('Dados inválidos não são enviados', (tester) async {
    final repository = _Repository();
    when(
      () => repository.buscarVeiculo(id: 'm-1'),
    ).thenAnswer((_) async => veiculo);

    await abrir(tester, repository);
    await tester.enterText(find.text('12345678901'), '123');
    await tester.tap(find.text('Atualizar'));
    await tester.pumpAndSettle();

    expect(find.text('O RENAVAM deve possuir 11 números'), findsOneWidget);
    verifyNever(
      () => repository.atualizarVeiculo(
        id: any(named: 'id'),
        veiculo: any(named: 'veiculo'),
      ),
    );
  });

  testWidgets('Falha ao carregar não mostra formulário vazio', (tester) async {
    final repository = _Repository();
    when(
      () => repository.buscarVeiculo(id: 'm-1'),
    ).thenAnswer((_) async => throw const FormatException('sem veículo'));

    await abrir(tester, repository);

    expect(find.text('Atualizar'), findsNothing);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
