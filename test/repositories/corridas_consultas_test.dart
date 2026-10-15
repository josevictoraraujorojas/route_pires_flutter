import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';

class _Dio extends Mock implements Dio {}

void main() {
  Map<String, dynamic> corrida(
    String id,
    String? data, {
    String status = 'FINALIZADO',
  }) => {
    'id': id,
    'status': status,
    'passageiro': 'p-1',
    'solicitanteId': 'p-1',
    'mototaxistaId': 'm-1',
    'dataHoraSolicitacao': data,
  };

  test(
    'Buscas ativas enviam status na API e preservam lista completa',
    () async {
      final dio = _Dio();
      final consultas = <Map<String, dynamic>?>[];
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((call) async {
        consultas.add(
          call.namedArguments[#queryParameters] as Map<String, dynamic>?,
        );
        return Response(
          requestOptions: RequestOptions(path: ''),
          data: [],
        );
      });
      final repo = CorridaRepository(dio: dio);
      await repo.listarMinhas(passageiroId: 'p-1');
      await repo.listarPendentes(mototaxistaId: 'm-1');
      expect(
        consultas,
        List.generate(4, (_) => {'status': 'PENDENTE,ANDAMENTO'}),
      );
    },
  );

  test('Histórico combina 10 + 10 com cursor compartilhado e datas nulas por último', () async {
    final dio = _Dio();
    final consultas = <Map<String, dynamic>?>[];
    final passageiros = List.generate(
      10,
      (i) => corrida(
        'p-$i',
        '2026-10-02T12:${(20 - i * 2).toString().padLeft(2, '0')}:00Z',
      ),
    );
    final fretes = List.generate(
      10,
      (i) => corrida(
        'f-$i',
        i == 9
            ? null
            : '2026-10-02T12:${(19 - i * 2).toString().padLeft(2, '0')}:00Z',
      ),
    );
    when(
      () => dio.get<dynamic>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((call) async {
      consultas.add(
        call.namedArguments[#queryParameters] as Map<String, dynamic>?,
      );
      return Response(
        requestOptions: RequestOptions(path: ''),
        data: call.positionalArguments.first == '/corridas-passageiro'
            ? passageiros
            : fretes,
      );
    });
    final pagina = await CorridaRepository(dio: dio)
        .listarHistorico(passageiroId: 'p-1', aposId: 'anterior');
    expect(consultas, [
      {'status': 'FINALIZADO,CANCELADO', 'limite': 10, 'aposId': 'anterior'},
      {'status': 'FINALIZADO,CANCELADO', 'limite': 10, 'aposId': 'anterior'},
    ]);
    expect(pagina.corridas.map((c) => c.id).toList(), [
      'p-0',
      'f-0',
      'p-1',
      'f-1',
      'p-2',
      'f-2',
      'p-3',
      'f-3',
      'p-4',
      'f-4',
    ]);
    expect(pagina.aposId, 'f-4');
    expect(pagina.temMais, isTrue);
  });

  test(
    'Histórico desempata data pelo ID desc e posiciona null depois das datas',
    () async {
      final dio = _Dio();
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (call) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: call.positionalArguments.first == '/corridas-passageiro'
              ? [corrida('a', null), corrida('c', '2026-10-02T12:00:00Z')]
              : [corrida('z', null), corrida('b', '2026-10-02T12:00:00Z')],
        ),
      );
      final pagina = await CorridaRepository(dio: dio)
          .listarHistorico(passageiroId: 'p-1');
      expect(pagina.corridas.map((c) => c.id).toList(), ['c', 'b', 'z', 'a']);
      expect(pagina.temMais, isFalse);
    },
  );

  test('Resumo com 503 não é consultado de novo em cada polling', () async {
    final dio = _Dio();
    var resumos = 0;
    when(
      () => dio.get<dynamic>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((call) async {
      final path = call.positionalArguments.first as String;
      if (path.contains('/resumo')) {
        resumos++;
        throw DioException(
          requestOptions: RequestOptions(path: path),
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 503,
            headers: Headers.fromMap({
              'retry-after': ['300'],
            }),
          ),
        );
      }
      return Response(
        requestOptions: RequestOptions(path: path),
        data: path == '/corridas-passageiro'
            ? [corrida('ativa', '2026-10-02T12:00:00Z', status: 'PENDENTE')]
            : [],
      );
    });
    final repo = CorridaRepository(dio: dio);
    await repo.listarPendentes(mototaxistaId: 'm-1');
    await repo.listarPendentes(mototaxistaId: 'm-1');
    expect(resumos, 1);
  });
}
