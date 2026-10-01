import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/corrida_response.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/model/mototaxista_resumo.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
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
        equals(
          'Não foi possível confirmar o envio. Verifique suas corridas antes de tentar novamente.',
        ),
      );
      expect(viewModel.criacaoIncerta, isTrue);
      expect(await viewModel.confirmarNegociacao(), isFalse);
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
      expect(viewModel.carregandoCriacao, isFalse);
      expect(viewModel.etapa, EtapaCorrida.aceita);
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

    test('Aguarda resposta e avança quando motorista aceita', () async {
      mockCriar(
        resposta: const CorridaResponse(id: 'corrida-1', status: 'PENDENTE'),
      );
      when(
        () => corridaRepository.buscarPorId(
          categoria: CategoriaCorrida.corrida,
          id: 'corrida-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async =>
            const CorridaResponse(id: 'corrida-1', status: 'ANDAMENTO'),
      );

      viewModel.selecionarMotorista(joa);
      expect(await viewModel.confirmarNegociacao(), isTrue);
      expect(viewModel.etapa, EtapaCorrida.aguardando);
      await viewModel.atualizarSolicitacao();
      expect(viewModel.etapa, EtapaCorrida.aceita);
    });

    test('Não libera nova escolha sem confirmação do cancelamento', () async {
      mockListar();
      mockCriar(
        resposta: const CorridaResponse(id: 'corrida-1', status: 'PENDENTE'),
      );
      when(
        () => corridaRepository.buscarPorId(
          categoria: CategoriaCorrida.corrida,
          id: 'corrida-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => const CorridaResponse(id: 'corrida-1', status: 'PENDENTE'),
      );
      when(
        () => corridaRepository.atualizarStatus(
          categoria: CategoriaCorrida.corrida,
          id: 'corrida-1',
          status: 'CANCELADO',
          motivoCancelamento: 'Tempo de aceite esgotado',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async {});

      viewModel.selecionarMotorista(joa);
      await viewModel.confirmarNegociacao();
      await viewModel.encerrarEspera(porTempo: true);

      // A consulta depois do PUT ainda retorna PENDENTE: não libera outra corrida.
      expect(viewModel.etapa, EtapaCorrida.aguardando);
      expect(
        viewModel.erroAcompanhamento,
        'Não foi possível confirmar o cancelamento',
      );
    });

    test(
      'Timeout confirmado volta à lista com motorista ainda disponível',
      () async {
        mockListar();
        mockCriar(
          resposta: const CorridaResponse(id: 'corrida-1', status: 'PENDENTE'),
        );
        var consultas = 0;
        when(
          () => corridaRepository.buscarPorId(
            categoria: CategoriaCorrida.corrida,
            id: 'corrida-1',
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => CorridaResponse(
            id: 'corrida-1',
            status: consultas++ == 0 ? 'PENDENTE' : 'CANCELADO',
          ),
        );
        when(
          () => corridaRepository.atualizarStatus(
            categoria: CategoriaCorrida.corrida,
            id: 'corrida-1',
            status: 'CANCELADO',
            motivoCancelamento: 'Tempo de aceite esgotado',
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {});

        viewModel.selecionarMotorista(joa);
        await viewModel.confirmarNegociacao();
        await viewModel.encerrarEspera(porTempo: true);

        expect(viewModel.etapa, EtapaCorrida.motoristas);
        expect(viewModel.corridaCriada, isNull);
        expect(viewModel.motoristas, [joa]);
      },
    );

    test(
      'Consulta em andamento não pisca cancelamento nem reverte seu resultado',
      () async {
        mockListar();
        mockCriar(
          resposta: const CorridaResponse(id: 'corrida-1', status: 'PENDENTE'),
        );
        final consultaAntiga = Completer<CorridaResponse>();
        var consultas = 0;
        when(
          () => corridaRepository.buscarPorId(
            categoria: CategoriaCorrida.corrida,
            id: 'corrida-1',
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) {
          switch (consultas++) {
            case 0:
              return consultaAntiga.future;
            case 1:
              return Future.value(
                const CorridaResponse(id: 'corrida-1', status: 'PENDENTE'),
              );
            default:
              return Future.value(
                const CorridaResponse(id: 'corrida-1', status: 'CANCELADO'),
              );
          }
        });
        when(
          () => corridaRepository.atualizarStatus(
            categoria: CategoriaCorrida.corrida,
            id: 'corrida-1',
            status: 'CANCELADO',
            motivoCancelamento: 'Cancelada pelo passageiro',
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {});

        viewModel.selecionarMotorista(joa);
        await viewModel.confirmarNegociacao();
        final consulta = viewModel.atualizarSolicitacao();
        expect(viewModel.atualizandoSolicitacao, isTrue);
        expect(viewModel.encerrandoEspera, isFalse);

        await viewModel.encerrarEspera();
        consultaAntiga.complete(
          const CorridaResponse(id: 'corrida-1', status: 'ANDAMENTO'),
        );
        await consulta;
        expect(viewModel.etapa, EtapaCorrida.motoristas);
        expect(viewModel.motoristas, [joa]);
      },
    );

    test('Aceite antes do cancelamento mantém corrida aceita', () async {
      mockCriar(
        resposta: const CorridaResponse(id: 'corrida-1', status: 'PENDENTE'),
      );
      when(
        () => corridaRepository.buscarPorId(
          categoria: CategoriaCorrida.corrida,
          id: 'corrida-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async =>
            const CorridaResponse(id: 'corrida-1', status: 'ANDAMENTO'),
      );

      viewModel.selecionarMotorista(joa);
      await viewModel.confirmarNegociacao();
      await viewModel.encerrarEspera();

      expect(viewModel.etapa, EtapaCorrida.aceita);
      verifyNever(
        () => corridaRepository.atualizarStatus(
          categoria: any(named: 'categoria'),
          id: any(named: 'id'),
          status: any(named: 'status'),
          motivoCancelamento: any(named: 'motivoCancelamento'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
    });

    test('Troca abre confirmação sem solicitar antes do novo toque', () async {
      const outro = MototaxistaResumo(id: 'moto-2', nome: 'Ana');
      mockListar([joa, outro]);
      final eventos = <String>[];
      var criacoes = 0;
      when(
        () => corridaRepository.criar(
          categoria: any(named: 'categoria'),
          passageiroId: any(named: 'passageiroId'),
          mototaxistaId: any(named: 'mototaxistaId'),
          origem: any(named: 'origem'),
          destino: any(named: 'destino'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        eventos.add('criar');
        return CorridaResponse(id: 'corrida-${++criacoes}', status: 'PENDENTE');
      });
      var consultas = 0;
      when(
        () => corridaRepository.buscarPorId(
          categoria: CategoriaCorrida.corrida,
          id: 'corrida-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => CorridaResponse(
          id: 'corrida-1',
          status: consultas++ == 0 ? 'PENDENTE' : 'CANCELADO',
        ),
      );
      when(
        () => corridaRepository.atualizarStatus(
          categoria: CategoriaCorrida.corrida,
          id: 'corrida-1',
          status: 'CANCELADO',
          motivoCancelamento: 'Cancelada pelo passageiro',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async {
        eventos.add('cancelar');
      });

      await viewModel.buscarMotoristas();
      viewModel.selecionarMotorista(joa);
      await viewModel.confirmarNegociacao();
      final etapasDuranteTroca = <EtapaCorrida>[];
      viewModel.addListener(() => etapasDuranteTroca.add(viewModel.etapa));
      final trocou = await viewModel.trocarMotorista(outro);

      expect(trocou, isTrue);
      expect(etapasDuranteTroca, isNot(contains(EtapaCorrida.motoristas)));
      expect(eventos, ['criar', 'cancelar']);
      expect(viewModel.etapa, EtapaCorrida.negociacao);
      expect(viewModel.motoristaSelecionado, outro);
      expect(viewModel.corridaCriada, isNull);
      expect(viewModel.motoristas, [joa, outro]);

      await viewModel.confirmarNegociacao();

      expect(eventos, ['criar', 'cancelar', 'criar']);
      expect(viewModel.etapa, EtapaCorrida.aguardando);
      expect(viewModel.corridaCriada?.id, 'corrida-2');
    });

    test('Não cria outra solicitação se a anterior foi aceita', () async {
      const outro = MototaxistaResumo(id: 'moto-2', nome: 'Ana');
      mockListar([joa, outro]);
      mockCriar(
        resposta: const CorridaResponse(id: 'corrida-1', status: 'PENDENTE'),
      );
      when(
        () => corridaRepository.buscarPorId(
          categoria: CategoriaCorrida.corrida,
          id: 'corrida-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async =>
            const CorridaResponse(id: 'corrida-1', status: 'ANDAMENTO'),
      );

      await viewModel.buscarMotoristas();
      viewModel.selecionarMotorista(joa);
      await viewModel.confirmarNegociacao();
      expect(await viewModel.trocarMotorista(outro), isFalse);
      expect(viewModel.etapa, EtapaCorrida.aceita);
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

    test('Corrida em andamento impede uma nova solicitação', () async {
      mockListar();
      when(
        () => corridaRepository.listarMinhas(
          passageiroId: 'passageiro-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => [
          SolicitacaoCorrida(
            id: 'corrida-ativa',
            categoria: CategoriaCorrida.corrida,
            status: 'ANDAMENTO',
            mototaxistaId: joa.id,
            passageiroId: 'passageiro-1',
            origem: origem,
            destino: destino,
          ),
        ],
      );
      when(
        () => corridaRepository.buscarPorId(
          categoria: CategoriaCorrida.corrida,
          id: 'corrida-ativa',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async =>
            const CorridaResponse(id: 'corrida-ativa', status: 'ANDAMENTO'),
      );

      await viewModel.iniciar();
      viewModel.selecionarMotorista(joa);

      expect(viewModel.etapa, EtapaCorrida.aceita);
      expect(viewModel.corridaCriada?.id, 'corrida-ativa');
      expect(viewModel.solicitacaoAtiva?.origem, origem);
      verifyNever(
        () => mototaxistaRepository.listar(
          cancelToken: any(named: 'cancelToken'),
        ),
      );
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

    test('Corrida finalizada não bloqueia uma nova busca', () async {
      mockListar();
      when(
        () => corridaRepository.listarMinhas(
          passageiroId: 'passageiro-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => [
          SolicitacaoCorrida(
            id: 'corrida-antiga',
            categoria: CategoriaCorrida.corrida,
            status: 'ANDAMENTO',
            mototaxistaId: joa.id,
            passageiroId: 'passageiro-1',
            origem: origem,
            destino: destino,
          ),
        ],
      );
      when(
        () => corridaRepository.buscarPorId(
          categoria: CategoriaCorrida.corrida,
          id: 'corrida-antiga',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async =>
            const CorridaResponse(id: 'corrida-antiga', status: 'FINALIZADO'),
      );

      await viewModel.iniciar();

      expect(viewModel.etapa, EtapaCorrida.motoristas);
      expect(viewModel.corridaCriada, isNull);
      expect(viewModel.motoristas, [joa]);
    });

    test('Retoma frete pendente antes de oferecer nova solicitação', () async {
      mockListar();
      when(
        () => corridaRepository.listarMinhas(
          passageiroId: 'passageiro-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => [
          SolicitacaoCorrida(
            id: 'frete-pendente',
            categoria: CategoriaCorrida.frete,
            status: 'PENDENTE',
            mototaxistaId: 'moto-2',
            passageiroId: 'passageiro-1',
            origem: origem,
            destino: destino,
            dataHoraSolicitacao: DateTime.now().subtract(
              const Duration(seconds: 20),
            ),
          ),
        ],
      );
      var consultas = 0;
      when(
        () => corridaRepository.buscarPorId(
          categoria: CategoriaCorrida.frete,
          id: 'frete-pendente',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => CorridaResponse(
          id: 'frete-pendente',
          status: consultas++ == 0 ? 'PENDENTE' : 'ANDAMENTO',
        ),
      );

      await viewModel.iniciar();
      expect(viewModel.etapa, EtapaCorrida.aguardando);
      expect(viewModel.segundosRestantes, inInclusiveRange(39, 40));
      await viewModel.atualizarSolicitacao();
      expect(viewModel.etapa, EtapaCorrida.aceita);
      verify(
        () => mototaxistaRepository.listar(
          cancelToken: any(named: 'cancelToken'),
        ),
      ).called(1);
    });

    test('Não mostra espera para pendência já cancelada ao entrar', () async {
      mockListar();
      when(
        () => corridaRepository.listarMinhas(
          passageiroId: 'passageiro-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => [
          SolicitacaoCorrida(
            id: 'corrida-antiga',
            categoria: CategoriaCorrida.corrida,
            status: 'PENDENTE',
            mototaxistaId: joa.id,
            passageiroId: 'passageiro-1',
            origem: origem,
            destino: destino,
          ),
        ],
      );
      when(
        () => corridaRepository.buscarPorId(
          categoria: CategoriaCorrida.corrida,
          id: 'corrida-antiga',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async =>
            const CorridaResponse(id: 'corrida-antiga', status: 'CANCELADO'),
      );
      final etapasAoEntrar = <EtapaCorrida>[];
      viewModel.addListener(() => etapasAoEntrar.add(viewModel.etapa));

      await viewModel.iniciar();

      expect(viewModel.etapa, EtapaCorrida.motoristas);
      expect(etapasAoEntrar, isNot(contains(EtapaCorrida.aguardando)));
      expect(viewModel.motoristas, [joa]);
    });

    test('Encerra pendência vencida antes de mostrar a lista', () async {
      mockListar();
      when(
        () => corridaRepository.listarMinhas(
          passageiroId: 'passageiro-1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => [
          SolicitacaoCorrida(
            id: 'corrida-vencida',
            categoria: CategoriaCorrida.corrida,
            status: 'PENDENTE',
            mototaxistaId: joa.id,
            passageiroId: 'passageiro-1',
            origem: origem,
            destino: destino,
            dataHoraSolicitacao: DateTime.now().subtract(
              const Duration(minutes: 2),
            ),
          ),
        ],
      );
      var consultas = 0;
      when(
        () => corridaRepository.buscarPorId(
          categoria: CategoriaCorrida.corrida,
          id: 'corrida-vencida',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => CorridaResponse(
          id: 'corrida-vencida',
          status: consultas++ == 2 ? 'CANCELADO' : 'PENDENTE',
        ),
      );
      when(
        () => corridaRepository.atualizarStatus(
          categoria: CategoriaCorrida.corrida,
          id: 'corrida-vencida',
          status: 'CANCELADO',
          motivoCancelamento: 'Tempo de aceite esgotado',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async {});

      await viewModel.iniciar();

      expect(viewModel.recuperando, isFalse);
      expect(viewModel.etapa, EtapaCorrida.motoristas);
      expect(viewModel.corridaCriada, isNull);
      expect(viewModel.motoristas, [joa]);
      expect(consultas, 3);
    });
  });
}
