import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';
import 'package:route_pires_flutter/viewmodel/corrida_viewmodel.dart';

class _Dio extends Mock implements Dio {}

void main() {
  const ponto = LocalizacaoPonto(
    latitude: -17.3,
    longitude: -48.2,
    rotulo: 'Centro',
  );
  CorridaViewModel criar(Dio dio) => CorridaViewModel(
    passageiroId: 'p-1',
    categoria: CategoriaCorrida.corrida,
    origem: ponto,
    destino: ponto,
    corridaRepository: CorridaRepository(dio: dio),
    mototaxistaRepository: MototaxistaRepository(dio: dio),
  );

  test(
    '503 preserva Retry-After no acompanhamento e no cancelamento',
    () async {
      final dio = _Dio();
      var falha = false;
      var consultas = 0;
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((call) async {
        final path = call.positionalArguments.first as String;
        final request = RequestOptions(path: path);
        const corrida = {
          'id': 'c-1',
          'status': 'PENDENTE',
          'mototaxistaId': 'm-1',
          'passageiro': 'p-1',
        };
        if (path == '/corridas-passageiro/c-1') {
          consultas++;
          if (falha) {
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
          return Response(requestOptions: request, data: corrida);
        }
        return Response(
          requestOptions: request,
          data: path == '/corridas-passageiro' ? [corrida] : [],
        );
      });
      final vm = criar(dio);
      addTearDown(vm.dispose);
      await vm.iniciar();
      expect(vm.etapa, EtapaCorrida.aguardando);
      falha = true;
      await vm.atualizarSolicitacao();
      await vm.atualizarSolicitacao();
      await vm.encerrarEspera(porTempo: true);
      expect(consultas, 2);
      expect(vm.etapa, EtapaCorrida.aguardando);
    },
  );

  test(
    'Recuperação não repete listas ativas durante a pausa por quota',
    () async {
      final dio = _Dio();
      var consultas = 0;
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((call) async {
        consultas++;
        final request = RequestOptions(
          path: call.positionalArguments.first as String,
        );
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
      final vm = criar(dio);
      addTearDown(vm.dispose);
      await vm.iniciar();
      await vm.iniciar();
      expect(consultas, 2);
    },
  );
}
