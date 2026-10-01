import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/corrida_response.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';
import 'package:route_pires_flutter/viewmodel/solicitacoes_viewmodel.dart';

class MockCorridaRepository extends Mock implements CorridaRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(CategoriaCorrida.corrida);
    registerFallbackValue(CancelToken());
  });

  late SolicitacoesViewModel viewModel;
  late MockCorridaRepository repository;

  const origem = LocalizacaoPonto(
    latitude: -17.3037,
    longitude: -48.2855,
    rotulo: 'Rua Inicial - Setor Universitário',
  );

  const destino = LocalizacaoPonto(
    latitude: -17.2948,
    longitude: -48.2718,
    rotulo: 'Rua Final - Centro',
  );

  final solicitacao = SolicitacaoCorrida(
    id: 'solicitacao-1',
    categoria: CategoriaCorrida.corrida,
    status: 'PENDENTE',
    mototaxistaId: 'moto-1',
    passageiroId: 'passageiro-1',
    passageiroNome: 'Maria',
    origem: origem,
    destino: destino,
  );

  setUp(() {
    repository = MockCorridaRepository();
    viewModel = SolicitacoesViewModel(
      mototaxistaId: 'moto-1',
      repository: repository,
    );
  });

  void mockCarregar([List<SolicitacaoCorrida>? solicitacoes]) {
    when(
      () => repository.listarPendentes(
        mototaxistaId: any(named: 'mototaxistaId'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async => solicitacoes ?? [solicitacao]);
  }

  group('SolicitacoesViewModel Tests |', () {
    testWidgets('Atualiza a lista enquanto a tela do mototaxista está aberta', (
      tester,
    ) async {
      mockCarregar();
      await viewModel.carregar();
      var avisos = 0;
      viewModel.addListener(() => avisos++);
      viewModel.iniciarAtualizacaoAutomatica();

      await tester.pump(const Duration(seconds: 15));
      await tester.pump();

      verify(
        () => repository.listarPendentes(
          mototaxistaId: 'moto-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(2);
      expect(avisos, 0);
      expect(viewModel.revisaoLista, 1);
      viewModel.dispose();
    });

    test('Deve carregar solicitações pendentes do mototaxista', () async {
      mockCarregar();

      await viewModel.carregar();

      expect(viewModel.solicitacoes, [solicitacao]);
      expect(viewModel.revisaoLista, 1);
      expect(viewModel.erro, isNull);
      expect(viewModel.carregando, isFalse);
    });

    test(
      'Deve manter lista vazia quando a API não retornar solicitações',
      () async {
        mockCarregar([]);

        await viewModel.carregar();

        expect(viewModel.solicitacoes, isEmpty);
        expect(viewModel.erro, isNull);
        expect(viewModel.carregando, isFalse);
      },
    );

    test('Mantém o passageiro durante uma resposta vazia isolada', () async {
      var consulta = 0;
      when(
        () => repository.listarPendentes(
          mototaxistaId: any(named: 'mototaxistaId'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async {
        consulta++;
        return switch (consulta) {
          1 || 3 => [solicitacao],
          _ => <SolicitacaoCorrida>[],
        };
      });
      when(
        () => repository.buscarPorId(
          categoria: CategoriaCorrida.corrida,
          id: 'solicitacao-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async =>
            const CorridaResponse(id: 'solicitacao-1', status: 'CANCELADO'),
      );

      await viewModel.carregar();
      await viewModel.carregar(silenciosa: true);
      expect(viewModel.solicitacoes, hasLength(1));

      await viewModel.carregar(silenciosa: true);
      expect(viewModel.solicitacoes, hasLength(1));

      await viewModel.carregar(silenciosa: true);
      expect(viewModel.solicitacoes, hasLength(1));

      await viewModel.carregar(silenciosa: true);
      expect(viewModel.solicitacoes, isEmpty);
    });

    test('Confirma o status antes de remover passageiro da lista', () async {
      var consulta = 0;
      when(
        () => repository.listarPendentes(
          mototaxistaId: any(named: 'mototaxistaId'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => consulta++ == 0 ? [solicitacao] : []);
      when(
        () => repository.buscarPorId(
          categoria: CategoriaCorrida.corrida,
          id: 'solicitacao-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => const CorridaResponse(
          id: 'solicitacao-1',
          mototaxistaId: 'moto-1',
          status: 'ANDAMENTO',
        ),
      );

      await viewModel.carregar();
      await viewModel.carregar(silenciosa: true);
      await viewModel.carregar(silenciosa: true);

      expect(viewModel.solicitacoes, hasLength(1));
      verify(
        () => repository.buscarPorId(
          categoria: CategoriaCorrida.corrida,
          id: 'solicitacao-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test(
      'Deve preencher erro ao falhar o carregamento de solicitações',
      () async {
        when(
          () => repository.listarPendentes(
            mototaxistaId: any(named: 'mototaxistaId'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/corridas-passageiro'),
            response: Response(
              requestOptions: RequestOptions(path: '/corridas-passageiro'),
              statusCode: 500,
            ),
          ),
        );

        await viewModel.carregar();

        expect(viewModel.solicitacoes, isEmpty);
        expect(viewModel.erro, equals('Erro interno no servidor'));
        expect(viewModel.revisaoLista, 0);
        expect(viewModel.carregando, isFalse);
      },
    );

    test('Deve recusar solicitação no backend e remover da lista', () async {
      mockCarregar([solicitacao]);
      await viewModel.carregar();

      when(
        () => repository.atualizarStatus(
          categoria: any(named: 'categoria'),
          id: any(named: 'id'),
          status: any(named: 'status'),
          motivoCancelamento: any(named: 'motivoCancelamento'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async {});

      final ok = await viewModel.recusar(solicitacao);

      expect(ok, isTrue);
      expect(viewModel.solicitacoes, isEmpty);
      expect(viewModel.erro, isNull);
      verify(
        () => repository.atualizarStatus(
          categoria: CategoriaCorrida.corrida,
          id: 'solicitacao-1',
          status: 'CANCELADO',
          motivoCancelamento: 'Recusada pelo mototaxista',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test('Deve cancelar solicitação e remover da lista', () async {
      mockCarregar([solicitacao]);
      await viewModel.carregar();

      when(
        () => repository.atualizarStatus(
          categoria: any(named: 'categoria'),
          id: any(named: 'id'),
          status: any(named: 'status'),
          motivoCancelamento: any(named: 'motivoCancelamento'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async {});

      final ok = await viewModel.cancelar(solicitacao);

      expect(ok, isTrue);
      expect(viewModel.solicitacoes, isEmpty);
      expect(viewModel.erro, isNull);
      await viewModel.carregar(silenciosa: true);
      expect(viewModel.solicitacoes, isEmpty);
      verify(
        () => repository.atualizarStatus(
          categoria: CategoriaCorrida.corrida,
          id: 'solicitacao-1',
          status: 'CANCELADO',
          motivoCancelamento: 'Cancelada pelo mototaxista',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test(
      'Deve aceitar solicitação e atualizar status para ANDAMENTO',
      () async {
        mockCarregar([solicitacao]);
        await viewModel.carregar();

        when(
          () => repository.buscarPorId(
            categoria: CategoriaCorrida.corrida,
            id: 'solicitacao-1',
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async =>
              const CorridaResponse(id: 'solicitacao-1', status: 'PENDENTE'),
        );

        when(
          () => repository.atualizarStatus(
            categoria: any(named: 'categoria'),
            id: any(named: 'id'),
            status: any(named: 'status'),
            motivoCancelamento: any(named: 'motivoCancelamento'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {});

        final ok = await viewModel.aceitar(solicitacao);

        expect(ok, isTrue);
        expect(viewModel.solicitacoes, hasLength(1));
        expect(viewModel.solicitacoes.single.status, 'ANDAMENTO');
        expect(viewModel.erro, isNull);
        await viewModel.carregar(silenciosa: true);
        expect(viewModel.solicitacoes.single.status, 'ANDAMENTO');
        verify(
          () => repository.atualizarStatus(
            categoria: CategoriaCorrida.corrida,
            id: 'solicitacao-1',
            status: 'ANDAMENTO',
            motivoCancelamento: null,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
      },
    );

    test('Não aceita solicitação já cancelada pelo passageiro', () async {
      mockCarregar([solicitacao]);
      await viewModel.carregar();
      when(
        () => repository.buscarPorId(
          categoria: CategoriaCorrida.corrida,
          id: 'solicitacao-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async =>
            const CorridaResponse(id: 'solicitacao-1', status: 'CANCELADO'),
      );

      expect(await viewModel.aceitar(solicitacao), isFalse);
      expect(viewModel.erro, contains('não está mais pendente'));
      verifyNever(
        () => repository.atualizarStatus(
          categoria: any(named: 'categoria'),
          id: any(named: 'id'),
          status: any(named: 'status'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    });

    test('Deve mapear erro 404 ao cancelar solicitação', () async {
      when(
        () => repository.atualizarStatus(
          categoria: any(named: 'categoria'),
          id: any(named: 'id'),
          status: any(named: 'status'),
          motivoCancelamento: any(named: 'motivoCancelamento'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/corridas-passageiro/solicitacao-1',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/corridas-passageiro/solicitacao-1',
            ),
            statusCode: 404,
          ),
        ),
      );

      final ok = await viewModel.cancelar(solicitacao);

      expect(ok, isFalse);
      expect(viewModel.erro, equals('Solicitação não encontrada'));
      expect(viewModel.atualizandoStatus, isFalse);
    });

    test('Deve tratar erro genérico ao cancelar solicitação', () async {
      when(
        () => repository.atualizarStatus(
          categoria: any(named: 'categoria'),
          id: any(named: 'id'),
          status: any(named: 'status'),
          motivoCancelamento: any(named: 'motivoCancelamento'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(Exception('Falha no sistema'));

      final ok = await viewModel.cancelar(solicitacao);

      expect(ok, isFalse);
      expect(viewModel.erro, equals('Ocorreu um erro inesperado'));
      expect(viewModel.atualizandoStatus, isFalse);
    });
  });
}
