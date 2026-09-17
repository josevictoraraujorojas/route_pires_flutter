import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:route_pires_flutter/model/usuario_response.dart';
import 'package:route_pires_flutter/repositories/login_repository.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';

// Mock do repositório
class MockLoginRepository extends Mock implements LoginRepository {}

void main() {
  late LoginViewModel viewModel;
  late MockLoginRepository mockRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockRepository = MockLoginRepository();

    viewModel = LoginViewModel(repository: mockRepository);
  });

  // Usuário fake para os testes de sucesso
  final usuarioFake = UsuarioResponse(
    id: '123',
    nome: 'João Teste',
    email: 'teste@teste.com',
    telefone: '123456789',
    tipo: 'PASSAGEIRO',
    historicoCorridas: [],
  );

  group('LoginViewModel Tests |', () {
    // ============================================================
    // LOGIN COM SUCESSO
    // ============================================================

    test(
      'Deve realizar login com sucesso e salvar o usuário na variável',
      () async {
        // Arrange
        when(() => mockRepository.logar(email: 'teste@teste.com', senha: '123'))
            .thenAnswer((_) async => usuarioFake);

        // Act
        final resultado = await viewModel.realizarLogin(
          email: 'teste@teste.com',
          senha: '123',
        );

        // Assert
        expect(resultado, isTrue);
        expect(viewModel.usuario, equals(usuarioFake));
        expect(viewModel.erro, isNull);
        expect(viewModel.carregando, isFalse);
      },
    );

    // ============================================================
    // PERSISTÊNCIA DO USUÁRIO
    // ============================================================

    test('Deve persistir o usuário logado após o login com sucesso', () async {
      // Arrange
      when(() => mockRepository.logar(email: 'teste@teste.com', senha: '123'))
          .thenAnswer((_) async => usuarioFake);

      // Act
      final resultado = await viewModel.realizarLogin(
        email: 'teste@teste.com',
        senha: '123',
      );

      // Assert
      expect(resultado, isTrue);

      final prefs = await SharedPreferences.getInstance();

      final salvo = prefs.getString('usuario_logado');

      expect(salvo, isNotNull);
      expect(salvo, contains('"id":"123"'));
    });

    // ============================================================
    // RESTAURAR SESSÃO
    // ============================================================

    test('Deve restaurar a sessão salva do usuário ao abrir o app', () async {
      // Arrange
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'usuario_logado',
        jsonEncode({
          'id': '456',
          'nome': 'Maria',
          'email': 'maria@teste.com',
          'telefone': '3333',
          'tipo': 'MOTOTAXISTA',
          'historicoCorridas': <String>[],
        }),
      );

      final viewModelRestaurado = LoginViewModel(repository: mockRepository);

      // Act
      await viewModelRestaurado.carregarUsuarioSalvo();

      // Assert
      expect(viewModelRestaurado.usuario, isNotNull);

      expect(viewModelRestaurado.usuario!.id, equals('456'));

      expect(viewModelRestaurado.usuario!.tipo, equals('MOTOTAXISTA'));
    });

    // ============================================================
    // ERRO 400
    // ============================================================

    test('Deve retornar erro 400 e preencher a variável erro com "Dados inválidos"', () async {
      // Arrange
      final erroDio400 = DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/login'),
          statusCode: 400,
        ),
      );

      when(() => mockRepository.logar(email: 'invalido', senha: '123'))
          .thenThrow(erroDio400);

      // Act
      final resultado = await viewModel.realizarLogin(
        email: 'invalido',
        senha: '123',
      );

      // Assert
      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Dados inválidos'));
    });

    // ============================================================
    // ERRO 401
    // ============================================================

    test('Deve retornar erro 401 e preencher a variável erro quando credenciais forem inválidas', () async {
      // Arrange
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
      expect(viewModel.carregando, isFalse);
    });

    // ============================================================
    // ERRO 404
    // ============================================================

    test('Deve retornar erro 404 e preencher a variável erro com "Usuário não encontrado"', () async {
      // Arrange
      final erroDio404 = DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/login'),
          statusCode: 404,
        ),
      );

      when(
        () => mockRepository.logar(email: 'naoexiste@teste.com', senha: '123'),
      ).thenThrow(erroDio404);

      // Act
      final resultado = await viewModel.realizarLogin(
        email: 'naoexiste@teste.com',
        senha: '123',
      );

      // Assert
      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Usuário não encontrado'));
    });

    // ============================================================
    // ERRO 500
    // ============================================================

    test('Deve retornar erro 500 e preencher a variável erro com "Erro interno no servidor"', () async {
      // Arrange
      final erroDio500 = DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/login'),
          statusCode: 500,
        ),
      );

      when(() => mockRepository.logar(email: 'teste@teste.com', senha: '123'))
          .thenThrow(erroDio500);

      // Act
      final resultado = await viewModel.realizarLogin(
        email: 'teste@teste.com',
        senha: '123',
      );

      // Assert
      expect(resultado, isFalse);
      expect(viewModel.erro, equals('Erro interno no servidor'));
    });

    // ============================================================
    // ERRO DE CONEXÃO
    // ============================================================

    test(
      'Deve retornar erro de conexão quando não houver resposta do servidor',
      () async {
        // Arrange
        final erroSemConexao = DioException(
          requestOptions: RequestOptions(path: '/login'),
          type: DioExceptionType.connectionError,
        );

        when(() => mockRepository.logar(email: 'teste@teste.com', senha: '123'))
            .thenThrow(erroSemConexao);

        // Act
        final resultado = await viewModel.realizarLogin(
          email: 'teste@teste.com',
          senha: '123',
        );

        // Assert
        expect(resultado, isFalse);
        expect(viewModel.erro, equals('Não foi possível conectar ao servidor'));
      },
    );

    // ============================================================
    // EXCEÇÃO GENÉRICA
    // ============================================================

    test(
      'Deve retornar "Ocorreu um erro inesperado" para exceções genéricas',
      () async {
        // Arrange
        when(() => mockRepository.logar(email: 'teste@teste.com', senha: '123'))
            .thenThrow(Exception('Falha bizarra no sistema'));

        // Act
        final resultado = await viewModel.realizarLogin(
          email: 'teste@teste.com',
          senha: '123',
        );

        // Assert
        expect(resultado, isFalse);
        expect(viewModel.erro, equals('Ocorreu um erro inesperado'));
      },
    );
  });
}
