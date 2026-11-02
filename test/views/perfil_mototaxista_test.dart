import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/model/usuario_response.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';
import 'package:route_pires_flutter/views/perfil_mototaxista.dart';

class _Repository extends Mock implements MototaxistaRepository {}

void main() {
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
            create: (_) => MototaxistaViewModel(repository: repository),
          ),
        ],
        child: const CupertinoApp(home: PerfilMototaxista()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Mostra dados do usuário, disponibilidade e menus', (
    tester,
  ) async {
    final repository = _Repository();
    when(
      () => repository.obterDisponibilidade(id: 'm-1'),
    ).thenAnswer((_) async => false);

    await abrir(tester, repository);

    expect(find.text('Carlos'), findsOneWidget);
    expect(find.text('carlos@teste.com'), findsOneWidget);
    expect(find.byType(CupertinoSwitch), findsOneWidget);
    for (final menu in [
      'Editar perfil',
      'Veículo ou Placa',
      'Histórico de corridas',
      'Notificações',
      'Sair da conta',
    ]) {
      expect(find.text(menu), findsOneWidget);
    }
  });

  testWidgets('Falha na disponibilidade oferece nova tentativa', (
    tester,
  ) async {
    final repository = _Repository();
    when(
      () => repository.obterDisponibilidade(id: 'm-1'),
    ).thenAnswer((_) async => throw Exception('falha'));

    await abrir(tester, repository);

    expect(find.byType(CupertinoSwitch), findsNothing);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Sair da conta'), findsOneWidget);
  });
}
