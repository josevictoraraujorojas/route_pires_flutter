import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';
import 'package:route_pires_flutter/viewmodel/solicitacoes_viewmodel.dart';

class _Dio extends Mock implements Dio {}

void main() {
  testWidgets('Offline faz bootstrap uma vez e online consulta a cada 15 s', (
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

    vm.configurarPolling(online: false);
    await vm.carregar();
    vm.iniciarAtualizacaoAutomatica();
    await tester.pump(const Duration(seconds: 45));
    expect(chamadas, 2);
    vm.configurarPolling(online: true);
    await tester.pump(const Duration(seconds: 14));
    expect(chamadas, 2);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(chamadas, 4);
    vm.configurarPolling(online: true, ativa: false);
    await tester.pump(const Duration(seconds: 30));
    expect(chamadas, 4);
    vm.dispose();
  });

  testWidgets(
    'Bootstrap retoma atendimento offline e consulta apenas a cada 30 s',
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

      vm.configurarPolling(online: false);
      await vm.carregar();
      await tester.pump(const Duration(seconds: 29));
      expect(chamadas, 2);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
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

    vm.configurarPolling(online: true);
    await vm.carregar();
    vm.pararAtualizacaoAutomatica();
    vm.configurarPolling(online: true);
    await vm.carregar(silenciosa: true);
    await vm.carregar();
    expect(chamadas, 2);
    vm.dispose();
  });

  testWidgets(
    'Polling não inicia outra consulta enquanto a anterior aguarda a rede',
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
      vm.configurarPolling(online: true);
      final primeira = vm.carregar();
      await tester.pump();
      await vm.carregar();
      expect(consultas, 2);
      inicial.complete(
        Response(
          requestOptions: RequestOptions(path: ''),
          data: [],
        ),
      );
      await primeira;
      await tester.pump(const Duration(seconds: 15));
      expect(consultas, 4);
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
      vm.configurarPolling(online: true);
      await vm.carregar();
      vazia = true;
      await vm.carregar(silenciosa: true);
      await vm.carregar(silenciosa: true);
      expect(chamadas, 7);
      await vm.carregar(silenciosa: true);
      expect(chamadas, 7);
      expect(vm.solicitacoes.single.id, 'c-1');
      vm.dispose();
    },
  );
}
