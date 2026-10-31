import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';
import 'package:route_pires_flutter/services/atualizacoes_service.dart';
import 'package:route_pires_flutter/viewmodel/solicitacoes_viewmodel.dart';

class _Dio extends Mock implements Dio {}

void _avisarCorrida() => AtualizacoesService().publicar(const {
  'tipo': 'CORRIDAS_ATUALIZADAS',
  'corridaId': 'c-1',
});

Future<void> _aguardarEvento(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

void main() {
  testWidgets('Offline faz bootstrap uma vez; online só consulta por evento', (
    tester,
  ) async {
    final dio = _Dio();
    var chamadas = 0;
    when(
      () => dio.get<dynamic>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((call) async {
      chamadas++;
      return Response(
        requestOptions: RequestOptions(path: ''),
        data: [],
      );
    });
    final vm = SolicitacoesViewModel(
      mototaxistaId: 'm-1',
      repository: CorridaRepository(dio: dio),
    );

    vm.configurarConsultas(online: false);
    await vm.carregar();
    await tester.pump(const Duration(seconds: 45));
    expect(chamadas, 2);
    _avisarCorrida();
    await _aguardarEvento(tester);
    expect(chamadas, 2);
    vm.configurarConsultas(online: true);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(chamadas, 4);
    await tester.pump(const Duration(minutes: 5));
    expect(chamadas, 4);
    _avisarCorrida();
    await _aguardarEvento(tester);
    expect(chamadas, 6);
    vm.configurarConsultas(online: true, ativa: false);
    _avisarCorrida();
    await tester.pump(const Duration(seconds: 30));
    expect(chamadas, 6);
    vm.dispose();
  });

  testWidgets(
    'Bootstrap retoma atendimento offline e só consulta de novo por evento',
    (tester) async {
      final dio = _Dio();
      var chamadas = 0;
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((call) async {
        chamadas++;
        return Response(
          requestOptions: RequestOptions(path: ''),
          data: call.positionalArguments.first == '/corridas-passageiro'
              ? [
                  {
                    'id': 'c-1',
                    'status': 'ANDAMENTO',
                    'mototaxistaId': 'm-1',
                    'passageiro': '',
                  },
                ]
              : [],
        );
      });
      final vm = SolicitacoesViewModel(
        mototaxistaId: 'm-1',
        repository: CorridaRepository(dio: dio),
      );

      vm.configurarConsultas(online: false);
      await vm.carregar();
      await tester.pump(const Duration(minutes: 5));
      expect(chamadas, 2);
      _avisarCorrida();
      await _aguardarEvento(tester);
      expect(chamadas, 4);
      vm.dispose();
    },
  );

  testWidgets('Retomar e atualizar respeitam Retry-After após 503 de quota', (
    tester,
  ) async {
    final dio = _Dio();
    var chamadas = 0;
    when(
      () => dio.get<dynamic>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((call) async {
      chamadas++;
      final request = RequestOptions(path: '');
      throw DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 503,
          headers: Headers.fromMap({
            'retry-after': ['300'],
          }),
        ),
      );
    });
    final vm = SolicitacoesViewModel(
      mototaxistaId: 'm-1',
      repository: CorridaRepository(dio: dio),
    );

    vm.configurarConsultas(online: true);
    await vm.carregar();
    vm.configurarConsultas(online: true, ativa: false);
    vm.configurarConsultas(online: true);
    await vm.carregar(silenciosa: true);
    await vm.carregar();
    expect(chamadas, 2);
    vm.dispose();
  });

  testWidgets('Consulta que falhou tenta de novo até dar certo e para', (
    tester,
  ) async {
    final dio = _Dio();
    var chamadas = 0;
    var agora = DateTime(2026);
    when(
      () => dio.get<dynamic>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((call) async {
      chamadas++;
      final request = RequestOptions(path: '');
      if (chamadas <= 2) {
        throw DioException(
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: 500),
        );
      }
      return Response(requestOptions: request, data: []);
    });
    final vm = SolicitacoesViewModel(
      mototaxistaId: 'm-1',
      repository: CorridaRepository(dio: dio),
      clock: () => agora,
    );
    vm.configurarConsultas(online: true);
    await vm.carregar();
    expect(vm.erro, isNotNull);
    await tester.pump(const Duration(seconds: 29));
    expect(chamadas, 2);
    agora = agora.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(chamadas, 4);
    expect(vm.erro, isNull);
    agora = agora.add(const Duration(minutes: 10));
    await tester.pump(const Duration(minutes: 10));
    expect(chamadas, 4);
    vm.dispose();
  });

  testWidgets(
    'Evento não inicia outra consulta enquanto a anterior aguarda a rede',
    (tester) async {
      final dio = _Dio();
      var consultas = 0;
      final inicial = Completer<Response<dynamic>>();
      final proxima = Completer<Response<dynamic>>();
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) {
        consultas++;
        return consultas <= 2 ? inicial.future : proxima.future;
      });
      final vm = SolicitacoesViewModel(
        mototaxistaId: 'm-1',
        repository: CorridaRepository(dio: dio),
      );
      vm.configurarConsultas(online: true);
      final primeira = vm.carregar();
      await tester.pump();
      await vm.carregar();
      expect(consultas, 2);
      _avisarCorrida();
      await tester.pump(const Duration(seconds: 15));
      expect(consultas, 2);
      inicial.complete(
        Response(
          requestOptions: RequestOptions(path: ''),
          data: [],
        ),
      );
      await primeira;
      await _aguardarEvento(tester);
      expect(consultas, 4);
      _avisarCorrida();
      await tester.pump(const Duration(seconds: 30));
      expect(consultas, 4);
      proxima.complete(
        Response(
          requestOptions: RequestOptions(path: ''),
          data: [],
        ),
      );
      await tester.pump();
      vm.dispose();
    },
  );

  testWidgets(
    'Quota ao confirmar uma ausência também interrompe novas consultas',
    (tester) async {
      final dio = _Dio();
      var chamadas = 0;
      var vazia = false;
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((call) async {
        chamadas++;
        final path = call.positionalArguments.first as String;
        final request = RequestOptions(path: path);
        if (path == '/corridas-passageiro/c-1') {
          throw DioException(
            requestOptions: request,
            response: Response(
              requestOptions: request,
              statusCode: 503,
              headers: Headers.fromMap({
                'retry-after': ['300'],
              }),
            ),
          );
        }
        return Response(
          requestOptions: request,
          data: !vazia && path == '/corridas-passageiro'
              ? [
                  {
                    'id': 'c-1',
                    'status': 'PENDENTE',
                    'mototaxistaId': 'm-1',
                    'passageiro': '',
                  },
                ]
              : [],
        );
      });
      final vm = SolicitacoesViewModel(
        mototaxistaId: 'm-1',
        repository: CorridaRepository(dio: dio),
      );
      vm.configurarConsultas(online: true);
      await vm.carregar();
      vazia = true;
      await vm.carregar(silenciosa: true);
      expect(chamadas, 5);
      await vm.carregar(silenciosa: true);
      expect(chamadas, 5);
      expect(vm.solicitacoes.single.id, 'c-1');
      vm.dispose();
    },
  );
}
