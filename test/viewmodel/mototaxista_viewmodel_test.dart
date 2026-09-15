import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/model/mototaxista_cadastro.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';

class MockMototaxistaRepository extends Mock implements MototaxistaRepository {}

void main() {
  late MototaxistaViewModel viewModel;
  late MockMototaxistaRepository mockRepository;
  late MototaxistaCadastro mototaxista;

  setUp(() {
    mockRepository = MockMototaxistaRepository();
    viewModel = MototaxistaViewModel(repository: mockRepository);
    mototaxista = const MototaxistaCadastro(
      nome: 'Carlos Teste',
      email: 'carlos@teste.com',
      senha: 'senh4b0a',
      telefone: '64999558833',
      cnh: '12345678900',
      dataValidade: '24/10/2030',
      placa: 'ABC1D23',
      renavam: '12345678901',
      modelo: 'Honda CG 160',
      ano: '2024',
    );
  });

  group('MototaxistaViewModel Tests |', () {
    test(
      'Não deve chamar o repositório quando a senha for só letras',
      () async {
        final fraco = MototaxistaCadastro(
          nome: mototaxista.nome,
          email: mototaxista.email,
          senha: 'abcdefgh',
          telefone: mototaxista.telefone,
          cnh: mototaxista.cnh,
          dataValidade: mototaxista.dataValidade,
          placa: mototaxista.placa,
          renavam: mototaxista.renavam,
          modelo: mototaxista.modelo,
          ano: mototaxista.ano,
        );

        final resultado = await viewModel.cadastrar(fraco);

        expect(resultado, isFalse);
        expect(
          viewModel.erro,
          equals(
            'A senha deve ter no mínimo 8 caracteres, com letras e números.',
          ),
        );
        verifyZeroInteractions(mockRepository);
      },
    );

    test('Deve cadastrar com sucesso', () async {
      when(() => mockRepository.cadastrar(mototaxista))
          .thenAnswer((_) async {});

      final resultado = await viewModel.cadastrar(mototaxista);

      expect(resultado, isTrue);
      expect(viewModel.erro, isNull);
      expect(viewModel.carregando, isFalse);
    });

    test('Deve retornar dados inválidos no erro 400', () async {
      final erroDio400 = DioException(
        requestOptions: RequestOptions(path: '/mototaxistas'),
        response: Response(
          requestOptions: RequestOptions(path: '/mototaxistas'),
          statusCode: 400,
        ),
      );

      when(() => mockRepository.cadastrar(mototaxista)).thenThrow(erroDio400);

      final resultado = await viewModel.cadastrar(mototaxista);

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Os dados informados são inválidos'));
      expect(viewModel.carregando, isFalse);
    });

    test('Deve retornar erro de cadastro duplicado no 409', () async {
      final erroDio409 = DioException(
        requestOptions: RequestOptions(path: '/mototaxistas'),
        response: Response(
          requestOptions: RequestOptions(path: '/mototaxistas'),
          statusCode: 409,
        ),
      );

      when(() => mockRepository.cadastrar(mototaxista)).thenThrow(erroDio409);

      final resultado = await viewModel.cadastrar(mototaxista);

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Já existe um cadastro com estes dados'));
    });

    test('Deve retornar erro do servidor no 500', () async {
      final erroDio500 = DioException(
        requestOptions: RequestOptions(path: '/mototaxistas'),
        response: Response(
          requestOptions: RequestOptions(path: '/mototaxistas'),
          statusCode: 500,
        ),
      );

      when(() => mockRepository.cadastrar(mototaxista)).thenThrow(erroDio500);

      final resultado = await viewModel.cadastrar(mototaxista);

      expect(resultado, isFalse);
      expect(
        viewModel.erro,
        equals('O servidor não conseguiu concluir o cadastro'),
      );
    });

    test('Deve retornar erro genérico para outros status HTTP', () async {
      final erroDio403 = DioException(
        requestOptions: RequestOptions(path: '/mototaxistas'),
        response: Response(
          requestOptions: RequestOptions(path: '/mototaxistas'),
          statusCode: 403,
        ),
      );

      when(() => mockRepository.cadastrar(mototaxista)).thenThrow(erroDio403);

      final resultado = await viewModel.cadastrar(mototaxista);

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Não foi possível concluir o cadastro'));
    });

    test('Deve retornar erro de conexão quando não houver resposta', () async {
      final erroSemConexao = DioException(
        requestOptions: RequestOptions(path: '/mototaxistas'),
        type: DioExceptionType.connectionError,
      );

      when(() => mockRepository.cadastrar(mototaxista))
          .thenThrow(erroSemConexao);

      final resultado = await viewModel.cadastrar(mototaxista);

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Não foi possível conectar ao servidor'));
    });

    test('Deve retornar erro inesperado para exceções genéricas', () async {
      when(() => mockRepository.cadastrar(mototaxista))
          .thenThrow(Exception('falha'));

      final resultado = await viewModel.cadastrar(mototaxista);

      expect(resultado, isFalse);
      expect(
        viewModel.erro,
        equals('Ocorreu um erro inesperado ao realizar o cadastro'),
      );
    });
  });
}
