import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/repositories/cadastro_passageiro_repository.dart';
import 'package:route_pires_flutter/viewmodel/cadastro_passageiro_viewmodel.dart';

class MockCadastroPassageiroRepository extends Mock
    implements CadastroPassageiroRepository {}

void main() {
  late CadastroPassageiroViewModel viewModel;
  late MockCadastroPassageiroRepository mockRepository;

  setUp(() {
    mockRepository = MockCadastroPassageiroRepository();
    viewModel = CadastroPassageiroViewModel(repository: mockRepository);
  });

  group('CadastroPassageiroViewModel Tests |', () {
    test('Deve cadastrar com sucesso e enviar o email em minúsculo', () async {
      when(
        () => mockRepository.cadastrar(
          nome: 'Ana Teste',
          email: 'ana@teste.com',
          telefone: '64999558833',
          senha: 'senh4b0a',
        ),
      ).thenAnswer((_) async {});

      final resultado = await viewModel.cadastrar(
        nome: 'Ana Teste',
        email: 'Ana@Teste.com',
        telefone: '(64) 99955-8833',
        senha: 'senh4b0a',
      );

      expect(resultado, isTrue);
      expect(viewModel.erro, isNull);
      expect(viewModel.carregando, isFalse);
    });

    test('Não deve chamar o repositório quando a senha for fraca', () async {
      final resultado = await viewModel.cadastrar(
        nome: 'Ana Teste',
        email: 'ana@teste.com',
        telefone: '64999558833',
        senha: '123',
      );

      expect(resultado, isFalse);
      expect(
        viewModel.erro,
        equals('A senha deve ter no mínimo 8 caracteres, com letras e números.'),
      );
      expect(viewModel.carregando, isFalse);
      verifyZeroInteractions(mockRepository);
    });

    test('Não deve chamar o repositório quando o telefone for inválido', () async {
      final resultado = await viewModel.cadastrar(
        nome: 'Ana Teste',
        email: 'ana@teste.com',
        telefone: '123',
        senha: 'senh4b0a',
      );

      expect(resultado, isFalse);
      expect(
        viewModel.erro,
        equals('Informe um telefone com DDD (10 ou 11 dígitos).'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('Deve retornar erro 400 e usar a mensagem da API quando existir', () async {
      final erroDio400 = DioException(
        requestOptions: RequestOptions(path: '/passageiros'),
        response: Response(
          requestOptions: RequestOptions(path: '/passageiros'),
          statusCode: 400,
          data: {'message': 'Email já cadastrado'},
        ),
      );

      when(
        () => mockRepository.cadastrar(
          nome: 'Ana Teste',
          email: 'ana@teste.com',
          telefone: '64999558833',
          senha: 'senh4b0a',
        ),
      ).thenThrow(erroDio400);

      final resultado = await viewModel.cadastrar(
        nome: 'Ana Teste',
        email: 'ana@teste.com',
        telefone: '64999558833',
        senha: 'senh4b0a',
      );

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Email já cadastrado'));
    });

    test('Deve retornar "Dados inválidos" no 400 sem mensagem da API', () async {
      final erroDio400 = DioException(
        requestOptions: RequestOptions(path: '/passageiros'),
        response: Response(
          requestOptions: RequestOptions(path: '/passageiros'),
          statusCode: 400,
        ),
      );

      when(
        () => mockRepository.cadastrar(
          nome: 'Ana Teste',
          email: 'ana@teste.com',
          telefone: '64999558833',
          senha: 'senh4b0a',
        ),
      ).thenThrow(erroDio400);

      final resultado = await viewModel.cadastrar(
        nome: 'Ana Teste',
        email: 'ana@teste.com',
        telefone: '64999558833',
        senha: 'senh4b0a',
      );

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Dados inválidos'));
    });

    test('Deve retornar erro 500', () async {
      final erroDio500 = DioException(
        requestOptions: RequestOptions(path: '/passageiros'),
        response: Response(
          requestOptions: RequestOptions(path: '/passageiros'),
          statusCode: 500,
        ),
      );

      when(
        () => mockRepository.cadastrar(
          nome: 'Ana Teste',
          email: 'ana@teste.com',
          telefone: '64999558833',
          senha: 'senh4b0a',
        ),
      ).thenThrow(erroDio500);

      final resultado = await viewModel.cadastrar(
        nome: 'Ana Teste',
        email: 'ana@teste.com',
        telefone: '64999558833',
        senha: 'senh4b0a',
      );

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Erro interno no servidor'));
    });

    test('Deve retornar erro de conexão quando não houver resposta', () async {
      final erroSemConexao = DioException(
        requestOptions: RequestOptions(path: '/passageiros'),
        type: DioExceptionType.connectionError,
      );

      when(
        () => mockRepository.cadastrar(
          nome: 'Ana Teste',
          email: 'ana@teste.com',
          telefone: '64999558833',
          senha: 'senh4b0a',
        ),
      ).thenThrow(erroSemConexao);

      final resultado = await viewModel.cadastrar(
        nome: 'Ana Teste',
        email: 'ana@teste.com',
        telefone: '64999558833',
        senha: 'senh4b0a',
      );

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Não foi possível conectar ao servidor'));
    });

    test('Deve retornar erro inesperado para exceções genéricas', () async {
      when(
        () => mockRepository.cadastrar(
          nome: 'Ana Teste',
          email: 'ana@teste.com',
          telefone: '64999558833',
          senha: 'senh4b0a',
        ),
      ).thenThrow(Exception('falha'));

      final resultado = await viewModel.cadastrar(
        nome: 'Ana Teste',
        email: 'ana@teste.com',
        telefone: '64999558833',
        senha: 'senh4b0a',
      );

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Ocorreu um erro inesperado'));
    });
  });
}
