import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/model/usuario_response.dart';
import 'package:route_pires_flutter/repositories/avaliacao_repository.dart';
import 'package:route_pires_flutter/services/atualizacoes_service.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/views/avaliacoes_recebidas_page.dart';

class _Dio extends Mock implements Dio {}

class _Repository extends Mock implements AvaliacaoRepository {}

class _Login extends Mock implements LoginViewModel {}

class _Usuario extends Mock implements UsuarioResponse {}

void main() {
  group('listarRecebidas', () {
    Future<List<AvaliacaoRecebida>> listar(
      Object? corpo, {
      required bool doMototaxista,
      required String rota,
    }) async {
      final dio = _Dio();
      when(() => dio.get<dynamic>(rota)).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: rota),
          data: corpo,
        ),
      );
      return AvaliacaoRepository(dio: dio)
          .listarRecebidas(usuarioId: 'u1', doMototaxista: doMototaxista);
    }

    test(
      'Mototaxista lê a própria rota, da mais nova para a mais antiga',
      () async {
        final lista = await listar(
          [
            {
              'nota': 5,
              'comentario': ' Ótimo ',
              'data': '2026-11-01T10:00:00Z',
            },
            {'nota': 2, 'comentario': null, 'data': '2026-11-09T10:00:00Z'},
          ],
          doMototaxista: true,
          rota: '/avaliacoes-mototaxista/mototaxista/u1',
        );

        expect(lista.map((a) => a.nota), [2, 5]);
        expect(lista.last.comentario, 'Ótimo');
      },
    );

    test('Passageiro sem avaliações recebe 204 e a lista fica vazia', () async {
      final lista = await listar(
        '',
        doMototaxista: false,
        rota: '/avaliacoes-passageiro/avaliado/u1',
      );

      expect(lista, isEmpty);
    });
  });

  group('aba Avaliações', () {
    late _Repository repository;

    Future<void> abrir(WidgetTester tester) async {
      final usuario = _Usuario();
      when(() => usuario.id).thenReturn('u1');
      final login = _Login();
      when(() => login.usuario).thenReturn(usuario);
      await tester.pumpWidget(
        ChangeNotifierProvider<LoginViewModel>.value(
          value: login,
          child: CupertinoApp(
            home: AvaliacoesRecebidasPage(
              doMototaxista: true,
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    When<Future<List<AvaliacaoRecebida>>> lista() => when(
      () => repository.listarRecebidas(usuarioId: 'u1', doMototaxista: true),
    );

    setUp(() => repository = _Repository());

    testWidgets('Mostra média, quantidade e comentários', (tester) async {
      lista().thenAnswer(
        (_) async => [
          (
            nota: 5,
            comentario: 'Pilotou com cuidado',
            data: DateTime(2026, 11, 9),
          ),
          (nota: 2, comentario: null, data: null),
        ],
      );

      await abrir(tester);

      expect(find.text('3,5'), findsOneWidget);
      expect(find.text('2 avaliações'), findsOneWidget);
      expect(find.text('Pilotou com cuidado'), findsOneWidget);
      expect(find.text('09/11/2026'), findsOneWidget);
      expect(find.bySemanticsLabel('2 estrelas de 5'), findsOneWidget);
    });

    testWidgets('Sem avaliações explica quando elas aparecem', (tester) async {
      lista().thenAnswer((_) async => []);

      await abrir(tester);

      expect(
        find.textContaining('ainda não recebeu avaliações'),
        findsOneWidget,
      );
    });

    testWidgets('Aviso de corrida avaliada recarrega a lista', (tester) async {
      lista().thenAnswer((_) async => []);
      await abrir(tester);

      lista().thenAnswer(
        (_) async => [(nota: 5, comentario: null, data: null)],
      );
      AtualizacoesService().publicar(const {
        'tipo': 'CORRIDAS_ATUALIZADAS',
        'acao': 'ATUALIZADA',
      });
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1 avaliação'), findsNothing);

      AtualizacoesService().publicar(const {
        'tipo': 'CORRIDAS_ATUALIZADAS',
        'acao': 'AVALIADA',
      });
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('1 avaliação'), findsOneWidget);
    });

    testWidgets('Erro permite tentar de novo', (tester) async {
      lista().thenThrow(Exception('rede'));
      await abrir(tester);
      expect(
        find.text('Não foi possível carregar as avaliações'),
        findsOneWidget,
      );

      lista().thenAnswer(
        (_) async => [(nota: 4, comentario: null, data: null)],
      );
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('1 avaliação'), findsOneWidget);
    });
  });
}
