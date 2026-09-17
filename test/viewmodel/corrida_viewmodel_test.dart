import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/corrida_response.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/model/mototaxista_resumo.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';
import 'package:route_pires_flutter/viewmodel/corrida_viewmodel.dart';

class MockMototaxistaRepository extends Mock implements MototaxistaRepository {}

class MockCorridaRepository extends Mock implements CorridaRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const LocalizacaoPonto(latitude: 0, longitude: 0, rotulo: ''),
    );
    registerFallbackValue(CancelToken());
    registerFallbackValue(CategoriaCorrida.corrida);
  });

  late CorridaViewModel viewModel;
  late MockMototaxistaRepository mototaxistaRepository;
  late MockCorridaRepository corridaRepository;

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

  const joa = MototaxistaResumo(
    id: 'whNwxmCOZ2xiCNEE9jud',
    nome: 'joa',
    avaliacaoMedia: 0,
  );

  final corridaCriada = CorridaResponse(
    id: 'corrida-1',
    mototaxistaId: joa.id,
    passageiroId: 'passageiro-1',
    status: 'ANDAMENTO',
  );

  CorridaViewModel criarViewModel({
    CategoriaCorrida categoria = CategoriaCorrida.corrida,
  }) {
    return CorridaViewModel(
      passageiroId: 'passageiro-1',
      categoria: categoria,
      origem: origem,
      destino: destino,
      mototaxistaRepository: mototaxistaRepository,
      corridaRepository: corridaRepository,
    );
  }

  void mockListar([List<MototaxistaResumo>? motoristas]) {
    when(
      () =>
          mototaxistaRepository.listar(cancelToken: any(named: 'cancelToken')),
    ).thenAnswer((_) async => motoristas ?? [joa]);
  }

  void mockCriar({CorridaResponse? resposta, Object? erro}) {
    final whenCriar = when(
      () => corridaRepository.criar(
        categoria: any(named: 'categoria'),
        passageiroId: any(named: 'passageiroId'),
        mototaxistaId: any(named: 'mototaxistaId'),
        origem: any(named: 'origem'),
        destino: any(named: 'destino'),
        cancelToken: any(named: 'cancelToken'),
      ),
    );
    if (erro != null) {
      whenCriar.thenThrow(erro);
    } else {
      whenCriar.thenAnswer((_) async => resposta ?? corridaCriada);
    }
  }

  setUp(() {
    mototaxistaRepository = MockMototaxistaRepository();
    corridaRepository = MockCorridaRepository();
    viewModel = criarViewModel();
  });

  group('CorridaViewModel Tests |', () {
    test('Deve buscar motoristas e ir para a lista', () async {
      mockListar();

      await viewModel.buscarMotoristas();

      expect(viewModel.etapa, EtapaCorrida.motoristas);
      expect(viewModel.motoristas, [joa]);
      expect(viewModel.erro, isNull);
      expect(viewModel.carregando, isFalse);
    });

    test(
      'Deve omitir mototaxistas indisponíveis da lista da corrida',
      () async {
        const indisponivel = MototaxistaResumo(
          id: 'offline-1',
          nome: 'Offline',
          disponivel: false,
        );
        mockListar([joa, indisponivel]);

        await viewModel.buscarMotoristas();

        expect(viewModel.motoristas, [joa]);
      },
    );

    test(
      'Deve ir para a lista vazia quando a API não retornar motoristas',
      () async {
        mockListar([]);

        await viewModel.buscarMotoristas();

        expect(viewModel.etapa, EtapaCorrida.motoristas);
        expect(viewModel.motoristas, isEmpty);
        expect(viewModel.erro, isNull);
      },
    );

    test('Deve preencher erro quando o GET de motoristas falhar', () async {
      when(
        () => mototaxistaRepository.listar(
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/mototaxistas'),
          response: Response(
            requestOptions: RequestOptions(path: '/mototaxistas'),
            statusCode: 500,
          ),
        ),
      );

      await viewModel.buscarMotoristas();

      expect(viewModel.etapa, EtapaCorrida.motoristas);
      expect(viewModel.motoristas, isEmpty);
      expect(viewModel.erro, equals('Erro interno no servidor'));
      expect(viewModel.carregando, isFalse);
    });

    test('Deve ir para negociação ao selecionar um motorista', () {
      viewModel.selecionarMotorista(joa);

      expect(viewModel.etapa, EtapaCorrida.negociacao);
      expect(viewModel.motoristaSelecionado, joa);
    });

    test('Deve voltar à lista ao recusar a negociação sem criar corrida', () {
      viewModel.selecionarMotorista(joa);
      viewModel.recusarNegociacao();

      expect(viewModel.etapa, EtapaCorrida.motoristas);
      expect(viewModel.motoristaSelecionado, isNull);
      verifyNever(
        () => corridaRepository.criar(
          categoria: any(named: 'categoria'),
          passageiroId: any(named: 'passageiroId'),
          mototaxistaId: any(named: 'mototaxistaId'),
          origem: any(named: 'origem'),
          destino: any(named: 'destino'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    });

    test(
      'Deve criar corrida de passageiro ao confirmar a negociação',
      () async {
        mockCriar();

        viewModel.selecionarMotorista(joa);
        final ok = await viewModel.confirmarNegociacao();

        expect(ok, isTrue);
        expect(viewModel.corridaCriada, corridaCriada);
        expect(viewModel.erroCriacao, isNull);
        verify(
          () => corridaRepository.criar(
            categoria: CategoriaCorrida.corrida,
            passageiroId: 'passageiro-1',
            mototaxistaId: joa.id,
            origem: origem,
            destino: destino,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
      },
    );

    test('Deve criar frete simples ao confirmar a negociação', () async {
      viewModel = criarViewModel(categoria: CategoriaCorrida.freteSimples);
      mockCriar();

      viewModel.selecionarMotorista(joa);
      final ok = await viewModel.confirmarNegociacao();

      expect(ok, isTrue);
      verify(
        () => corridaRepository.criar(
          categoria: CategoriaCorrida.freteSimples,
          passageiroId: 'passageiro-1',
          mototaxistaId: joa.id,
          origem: origem,
          destino: destino,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test('Deve criar frete ao confirmar a negociação', () async {
      viewModel = criarViewModel(categoria: CategoriaCorrida.frete);
      mockCriar();

      viewModel.selecionarMotorista(joa);
      final ok = await viewModel.confirmarNegociacao();

      expect(ok, isTrue);
      verify(
        () => corridaRepository.criar(
          categoria: CategoriaCorrida.frete,
          passageiroId: 'passageiro-1',
          mototaxistaId: joa.id,
          origem: origem,
          destino: destino,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test('Não deve criar corrida sem motorista selecionado', () async {
      final ok = await viewModel.confirmarNegociacao();

      expect(ok, isFalse);
      expect(viewModel.erroCriacao, equals('Selecione um mototaxista'));
      expect(viewModel.erro, isNull);
      verifyNever(
        () => corridaRepository.criar(
          categoria: any(named: 'categoria'),
          passageiroId: any(named: 'passageiroId'),
          mototaxistaId: any(named: 'mototaxistaId'),
          origem: any(named: 'origem'),
          destino: any(named: 'destino'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    });

    test('Deve mapear erro 400 ao criar corrida', () async {
      mockCriar(
        erro: DioException(
          requestOptions: RequestOptions(path: '/corridas-passageiro'),
          response: Response(
            requestOptions: RequestOptions(path: '/corridas-passageiro'),
            statusCode: 400,
          ),
        ),
      );

      viewModel.selecionarMotorista(joa);
      final ok = await viewModel.confirmarNegociacao();

      expect(ok, isFalse);
      expect(viewModel.erroCriacao, equals('Dados inválidos'));
      expect(viewModel.erro, isNull);
      expect(viewModel.corridaCriada, isNull);
    });

    test('Deve mapear erro de conexão ao criar corrida', () async {
      mockCriar(
        erro: DioException(
          requestOptions: RequestOptions(path: '/corridas-passageiro'),
          type: DioExceptionType.connectionError,
        ),
      );

      viewModel.selecionarMotorista(joa);
      final ok = await viewModel.confirmarNegociacao();

      expect(ok, isFalse);
      expect(
        viewModel.erroCriacao,
        equals('Não foi possível conectar ao servidor'),
      );
      expect(viewModel.erro, isNull);
    });

    test('Erro do POST não deve esconder a lista ao recusar', () async {
      mockListar();
      mockCriar(
        erro: DioException(
          requestOptions: RequestOptions(path: '/corridas-passageiro'),
          response: Response(
            requestOptions: RequestOptions(path: '/corridas-passageiro'),
            statusCode: 400,
          ),
        ),
      );

      await viewModel.buscarMotoristas();
      viewModel.selecionarMotorista(joa);
      await viewModel.confirmarNegociacao();
      viewModel.recusarNegociacao();

      expect(viewModel.etapa, EtapaCorrida.motoristas);
      expect(viewModel.motoristas, [joa]);
      expect(viewModel.erro, isNull);
      expect(viewModel.erroCriacao, isNull);
    });

    test('Não deve notificar depois do dispose no meio do GET', () async {
      final pendente = Completer<List<MototaxistaResumo>>();
      when(
        () => mototaxistaRepository.listar(
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) => pendente.future);

      final busca = viewModel.buscarMotoristas();
      viewModel.dispose();
      pendente.complete([joa]);

      await expectLater(busca, completes);
    });

    test('Não deve criar duas corridas se Sim for tocado de novo', () async {
      final pendente = Completer<CorridaResponse>();
      when(
        () => corridaRepository.criar(
          categoria: any(named: 'categoria'),
          passageiroId: any(named: 'passageiroId'),
          mototaxistaId: any(named: 'mototaxistaId'),
          origem: any(named: 'origem'),
          destino: any(named: 'destino'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) => pendente.future);

      viewModel.selecionarMotorista(joa);
      final primeira = viewModel.confirmarNegociacao();
      final segunda = await viewModel.confirmarNegociacao();
      pendente.complete(corridaCriada);
      final ok = await primeira;

      expect(ok, isTrue);
      expect(segunda, isFalse);
      verify(
        () => corridaRepository.criar(
          categoria: any(named: 'categoria'),
          passageiroId: any(named: 'passageiroId'),
          mototaxistaId: any(named: 'mototaxistaId'),
          origem: any(named: 'origem'),
          destino: any(named: 'destino'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test('Não deve criar de novo depois do POST com sucesso', () async {
      mockCriar();

      viewModel.selecionarMotorista(joa);
      expect(await viewModel.confirmarNegociacao(), isTrue);
      expect(await viewModel.confirmarNegociacao(), isTrue);
      expect(viewModel.carregandoCriacao, isTrue);
      verify(
        () => corridaRepository.criar(
          categoria: any(named: 'categoria'),
          passageiroId: any(named: 'passageiroId'),
          mototaxistaId: any(named: 'mototaxistaId'),
          origem: any(named: 'origem'),
          destino: any(named: 'destino'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });
  });
}
