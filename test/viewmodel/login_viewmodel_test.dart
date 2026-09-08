import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';

import 'package:route_pires_flutter/model/usuario_response.dart';
import 'package:route_pires_flutter/repositories/login_repository.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';

// 1. Cria um Mock do repositório
class MockLoginRepository extends Mock implements LoginRepository {}

void main() {
  late LoginViewModel viewModel;
  late MockLoginRepository mockRepository;

  setUp(() {
    mockRepository = MockLoginRepository();
    // Injetamos o Mock no ViewModel em vez do repositório real
    viewModel = LoginViewModel(repository: mockRepository);
  });

  // Objeto de usuário fake para usar na simulação de sucesso
  final usuarioFake = UsuarioResponse(
    id: '123',
    nome: 'João Teste',
    email: 'teste@teste.com',
    telefone: '123456789',
    tipo: 'PASSAGEIRO',
    historicoCorridas: [],
  );

  group('LoginViewModel Tests |', () {
    
    test('Deve realizar login com sucesso e salvar o usuário na variável', () async {
      // Arrange : Ensina o Mock a retornar o usuarioFake quando chamado
      when(() => mockRepository.logar(email: 'teste@teste.com', senha: '123'))
          .thenAnswer((_) async => usuarioFake);

      // Act : Chama o método do ViewModel
      final resultado = await viewModel.realizarLogin(
        email: 'teste@teste.com',
        senha: '123',
      );

      // Assert : Confere se as variáveis de estado mudaram como o esperado
      expect(resultado, isTrue); 
      expect(viewModel.usuario, equals(usuarioFake)); 
      expect(viewModel.erro, isNull); 
      expect(viewModel.Carregando, isFalse); 
    });

    test('Deve retornar erro 400 e preencher a variável erro com "Dados inválidos"', () async {
      final erroDio400 = DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(requestOptions: RequestOptions(path: '/login'), statusCode: 400),
      );

      when(() => mockRepository.logar(email: 'invalido', senha: '123'))
          .thenThrow(erroDio400);

      final resultado = await viewModel.realizarLogin(email: 'invalido', senha: '123');

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Dados inválidos'));
    });


    test('Deve retornar erro 401 e preencher a variável erro quando credenciais forem inválidas', () async {
      // Simula a exceção do Dio com status 401
      final erroDio401 = DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/login'),
          statusCode: 401,
        ),
      );

      when(() => mockRepository.logar(email: 'errado@teste.com', senha: '123'))
          .thenThrow(erroDio401);

      // Act
      final resultado = await viewModel.realizarLogin(
        email: 'errado@teste.com',
        senha: '123',
      );

      // Assert
      expect(resultado, isFalse);
      expect(viewModel.usuario, isNull);
      expect(viewModel.erro, equals('Email ou senha incorretos'));
      expect(viewModel.Carregando, isFalse);
    });

    
    test('Deve retornar erro 404 e preencher a variável erro com "Usuário não encontrado"', () async {
      final erroDio404 = DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(requestOptions: RequestOptions(path: '/login'), statusCode: 404),
      );

      when(() => mockRepository.logar(email: 'naoexiste@teste.com', senha: '123'))
          .thenThrow(erroDio404);

      final resultado = await viewModel.realizarLogin(email: 'naoexiste@teste.com', senha: '123');

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Usuário não encontrado'));
    });

    test('Deve retornar erro 500 e preencher a variável erro com "Erro interno no servidor"', () async {
      final erroDio500 = DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(requestOptions: RequestOptions(path: '/login'), statusCode: 500),
      );

      when(() => mockRepository.logar(email: 'teste@teste.com', senha: '123'))
          .thenThrow(erroDio500);

      final resultado = await viewModel.realizarLogin(email: 'teste@teste.com', senha: '123');

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Erro interno no servidor'));
    });

    test('Deve retornar erro de conexão quando não houver resposta do servidor (ex: sem internet)', () async {
      // Aqui criamos um erro do Dio SEM o objeto response
      final erroSemConexao = DioException(
        requestOptions: RequestOptions(path: '/login'),
        type: DioExceptionType.connectionError, 
      );

      when(() => mockRepository.logar(email: 'teste@teste.com', senha: '123'))
          .thenThrow(erroSemConexao);

      final resultado = await viewModel.realizarLogin(email: 'teste@teste.com', senha: '123');

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Não foi possível conectar ao servidor'));
    });

    test('Deve retornar "Ocorreu um erro inesperado" para exceções genéricas', () async {
      // Lançamos uma exceção comum do Dart, não relacionada ao Dio
      when(() => mockRepository.logar(email: 'teste@teste.com', senha: '123'))
          .thenThrow(Exception('Falha bizarra no sistema'));

      final resultado = await viewModel.realizarLogin(email: 'teste@teste.com', senha: '123');

      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Ocorreu um erro inesperado'));
    });

  });
}