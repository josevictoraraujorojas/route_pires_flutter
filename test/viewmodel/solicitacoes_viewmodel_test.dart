import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
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
    status: 'ANDAMENTO',
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
    test('Deve carregar solicitações pendentes do mototaxista', () async {
      mockCarregar();

      await viewModel.carregar();

      expect(viewModel.solicitacoes, [solicitacao]);
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

    test(
      'Deve aceitar solicitação e atualizar status para ANDAMENTO',
      () async {
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

        final ok = await viewModel.aceitar(solicitacao);

        expect(ok, isTrue);
        expect(viewModel.solicitacoes, isEmpty);
        expect(viewModel.erro, isNull);
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
