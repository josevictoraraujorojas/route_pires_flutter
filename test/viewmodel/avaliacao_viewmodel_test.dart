import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/repositories/avaliacao_repository.dart';
import 'package:route_pires_flutter/viewmodel/avaliacao_viewmodel.dart';

class _Repository extends Mock implements AvaliacaoRepository {}

void main() {
  late _Repository repository;
  late AvaliacaoViewModel viewModel;

  When<Future<void>> envio() => when(
    () => repository.avaliar(
      corridaId: any(named: 'corridaId'),
      doMototaxista: any(named: 'doMototaxista'),
      nota: any(named: 'nota'),
      comentario: any(named: 'comentario'),
    ),
  );

  DioException erroDaApi(int status, String mensagem) {
    final requisicao = RequestOptions(path: '');
    return DioException(
      requestOptions: requisicao,
      response: Response<dynamic>(
        requestOptions: requisicao,
        statusCode: status,
        data: {'message': mensagem},
      ),
    );
  }

  Future<bool> avaliar({int nota = 5, String? comentario}) => viewModel.avaliar(
    corridaId: 'corrida-1',
    doMototaxista: false,
    nota: nota,
    comentario: comentario,
  );

  setUp(() {
    repository = _Repository();
    viewModel = AvaliacaoViewModel(repository: repository);
  });

  test('Envia a avaliação e trata comentário em branco como ausente', () async {
    envio().thenAnswer((_) async {});

    expect(await avaliar(nota: 4, comentario: '   '), isTrue);

    expect(viewModel.avaliada, isTrue);
    expect(viewModel.erro, isNull);
    expect(viewModel.enviando, isFalse);
    verify(
      () => repository.avaliar(
        corridaId: 'corrida-1',
        doMototaxista: false,
        nota: 4,
        comentario: null,
      ),
    ).called(1);
  });

  test('Nota fora de 1 a 5 não chega à API', () async {
    expect(await avaliar(nota: 0), isFalse);

    expect(viewModel.erro, 'Escolha uma nota de 1 a 5 estrelas');
    verifyNever(
      () => repository.avaliar(
        corridaId: any(named: 'corridaId'),
        doMototaxista: any(named: 'doMototaxista'),
        nota: any(named: 'nota'),
        comentario: any(named: 'comentario'),
      ),
    );
  });

  test('Erro da API vira mensagem e permite tentar de novo', () async {
    envio().thenThrow(
      erroDaApi(400, 'Corrida não finalizada, não é possível avaliar.'),
    );

    expect(await avaliar(), isFalse);
    expect(viewModel.erro, 'Corrida não finalizada, não é possível avaliar.');
    expect(viewModel.avaliada, isFalse);

    envio().thenAnswer((_) async {});

    expect(await avaliar(), isTrue);
    expect(viewModel.erro, isNull);
  });

  test('Corrida já avaliada não permite novo envio', () async {
    envio().thenThrow(
      erroDaApi(400, 'Esta corrida já possui avaliação de mototaxista'),
    );

    expect(await avaliar(), isFalse);
    expect(viewModel.avaliada, isTrue);
    expect(viewModel.erro, 'Esta corrida já foi avaliada');

    expect(await avaliar(), isFalse);
    verify(
      () => repository.avaliar(
        corridaId: any(named: 'corridaId'),
        doMototaxista: any(named: 'doMototaxista'),
        nota: any(named: 'nota'),
        comentario: any(named: 'comentario'),
      ),
    ).called(1);
  });
}
