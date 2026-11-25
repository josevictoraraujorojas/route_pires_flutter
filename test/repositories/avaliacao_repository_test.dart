import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/repositories/avaliacao_repository.dart';

class _Dio extends Mock implements Dio {}

void main() {
  Future<List<dynamic>> envioDe({
    required bool doMototaxista,
    String? comentario,
  }) async {
    final dio = _Dio();
    when(() => dio.post<dynamic>(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response<dynamic>(requestOptions: RequestOptions(path: '')),
    );

    await AvaliacaoRepository(dio: dio).avaliar(
      corridaId: 'corrida-1',
      doMototaxista: doMototaxista,
      nota: 4,
      comentario: comentario,
    );

    return verify(
      () => dio.post<dynamic>(captureAny(), data: captureAny(named: 'data')),
    ).captured;
  }

  test('Passageiro avalia o mototaxista na rota de mototaxista', () async {
    expect(await envioDe(doMototaxista: false, comentario: 'Ótimo'), [
      '/avaliacoes-mototaxista',
      {'corrida': 'corrida-1', 'nota': 4, 'comentario': 'Ótimo'},
    ]);
  });

  test('Mototaxista avalia o passageiro sem comentário', () async {
    expect(await envioDe(doMototaxista: true), [
      '/avaliacoes-passageiro',
      {'corrida': 'corrida-1', 'nota': 4},
    ]);
  });

  test('Só corrida finalizada e sem avaliação do lado pode ser avaliada', () {
    SolicitacaoCorrida corrida(String status, {String? avaliacaoPassageiroId}) {
      return SolicitacaoCorrida.fromJson({
        'id': 'corrida-1',
        'status': status,
        'avaliacaoPassageiroId': avaliacaoPassageiroId,
      }, categoria: CategoriaCorrida.corrida);
    }

    final finalizada = corrida('FINALIZADO', avaliacaoPassageiroId: 'corrida-1P');

    expect(finalizada.podeAvaliar(doMototaxista: false), isTrue);
    expect(finalizada.podeAvaliar(doMototaxista: true), isFalse);
    expect(corrida('CANCELADO').podeAvaliar(doMototaxista: true), isFalse);
    expect(corrida('ANDAMENTO').podeAvaliar(doMototaxista: false), isFalse);
  });
}
