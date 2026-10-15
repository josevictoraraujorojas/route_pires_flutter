import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/token_storage.dart';
import 'package:route_pires_flutter/model/login_response.dart';
import 'package:route_pires_flutter/model/usuario_response.dart';
import 'package:route_pires_flutter/repositories/login_repository.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';

class MockLoginRepository extends Mock implements LoginRepository {}

class MemoryTokenStorage implements TokenStorage {
  String? token;
  int writes = 0;
  int deletes = 0;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async {
    token = value;
    writes++;
  }

  @override
  Future<void> delete() async {
    token = null;
    deletes++;
  }
}

void main() {
  late MockLoginRepository repository;
  late MemoryTokenStorage storage;
  late LoginViewModel viewModel;

  final usuario = UsuarioResponse(
    id: '123',
    nome: 'João Teste',
    email: 'teste@teste.com',
    telefone: '123456789',
    tipo: 'PASSAGEIRO',
    historicoCorridas: [],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockLoginRepository();
    storage = MemoryTokenStorage();
    viewModel = LoginViewModel(
      repository: repository,
      tokenStorage: storage,
      isWeb: false,
      autoBootstrap: false,
    );
  });

  tearDown(() {
    ApiClient().clearSession();
    ApiClient().onUnauthorized = null;
    viewModel.dispose();
  });

  test('login mobile persiste apenas token e ativa o perfil', () async {
    when(() => repository.logar(email: 'teste@teste.com', senha: 'abc  '))
        .thenAnswer(
          (_) async => LoginResponse(usuario: usuario, accessToken: 'jwt'),
        );

    final sucesso = await viewModel.realizarLogin(
      email: 'teste@teste.com',
      senha: 'abc  ',
    );

    expect(sucesso, isTrue);
    expect(storage.token, 'jwt');
    expect(storage.writes, 1);
    expect(viewModel.usuario, same(usuario));
  });

  test('login mobile sem token não autentica nem persiste perfil', () async {
    when(() => repository.logar(email: 'teste@teste.com', senha: '123'))
        .thenAnswer((_) async => LoginResponse(usuario: usuario));

    expect(
      await viewModel.realizarLogin(email: 'teste@teste.com', senha: '123'),
      isFalse,
    );
    expect(storage.token, isNull);
    expect(viewModel.usuario, isNull);
  });

  test('bootstrap mobile exige token e valida perfil em /auth/me', () async {
    storage.token = 'jwt-salvo';
    when(() => repository.usuarioAtual()).thenAnswer((_) async => usuario);

    await viewModel.carregarUsuarioSalvo();

    expect(viewModel.inicializando, isFalse);
    expect(viewModel.usuario, same(usuario));
    verify(() => repository.usuarioAtual()).called(1);
  });

  test('bootstrap sem token não restaura perfil', () async {
    await viewModel.carregarUsuarioSalvo();

    expect(viewModel.usuario, isNull);
    verifyNever(() => repository.usuarioAtual());
  });

  test('bootstrap remove perfil legado salvo em texto puro', () async {
    SharedPreferences.setMockInitialValues({
      'usuario_logado': '{"id":"antigo"}',
    });

    await viewModel.carregarUsuarioSalvo();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('usuario_logado'), isNull);
  });

  test('401 no bootstrap apaga token e volta ao estado anônimo', () async {
    storage.token = 'expirado';
    final options = RequestOptions(path: '/auth/me');
    when(() => repository.usuarioAtual()).thenThrow(
      DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
      ),
    );

    await viewModel.carregarUsuarioSalvo();

    expect(storage.token, isNull);
    expect(viewModel.usuario, isNull);
    expect(viewModel.erroInicializacao, isNull);
  });

  test('falha de rede mantém token para tentar bootstrap novamente', () async {
    storage.token = 'jwt-salvo';
    when(() => repository.usuarioAtual()).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        type: DioExceptionType.connectionError,
      ),
    );

    await viewModel.carregarUsuarioSalvo();

    expect(storage.token, 'jwt-salvo');
    expect(viewModel.usuario, isNull);
    expect(viewModel.erroInicializacao, isNotNull);
  });

  test('logout mobile remove token e perfil', () async {
    when(() => repository.logar(email: 'teste@teste.com', senha: '123'))
        .thenAnswer(
          (_) async => LoginResponse(usuario: usuario, accessToken: 'jwt'),
        );
    await viewModel.realizarLogin(email: 'teste@teste.com', senha: '123');

    expect(await viewModel.sair(), isTrue);
    expect(storage.token, isNull);
    expect(viewModel.usuario, isNull);
  });

  test('login Web usa CSRF em memória e não escreve token', () async {
    final web = LoginViewModel(
      repository: repository,
      tokenStorage: storage,
      isWeb: true,
      autoBootstrap: false,
    );
    addTearDown(web.dispose);
    when(() => repository.logar(email: 'teste@teste.com', senha: '123'))
        .thenAnswer((_) async => LoginResponse(usuario: usuario));
    when(() => repository.obterCsrf()).thenAnswer(
      (_) async =>
          const CsrfResponse(token: 'csrf', headerName: 'X-CSRF-TOKEN'),
    );

    expect(
      await web.realizarLogin(email: 'teste@teste.com', senha: '123'),
      isTrue,
    );
    expect(web.usuario, same(usuario));
    expect(storage.writes, 0);
  });

  test(
    'bootstrap e logout Web validam cookie e chamam logout da API',
    () async {
      final web = LoginViewModel(
        repository: repository,
        tokenStorage: storage,
        isWeb: true,
        autoBootstrap: false,
      );
      addTearDown(web.dispose);
      when(() => repository.usuarioAtual()).thenAnswer((_) async => usuario);
      when(() => repository.obterCsrf()).thenAnswer(
        (_) async =>
            const CsrfResponse(token: 'csrf', headerName: 'X-CSRF-TOKEN'),
      );
      when(() => repository.sairWeb()).thenAnswer((_) async {});

      await web.carregarUsuarioSalvo();
      expect(web.usuario, same(usuario));
      expect(storage.writes, 0);

      expect(await web.sair(), isTrue);
      verify(() => repository.sairWeb()).called(1);
      expect(web.usuario, isNull);
    },
  );

  test('login inválido mantém mensagem 401 sem sessão', () async {
    final options = RequestOptions(path: '/login');
    when(() => repository.logar(email: 'errado', senha: '123')).thenThrow(
      DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
      ),
    );

    expect(
      await viewModel.realizarLogin(email: 'errado', senha: '123'),
      isFalse,
    );
    expect(viewModel.erro, 'Email ou senha incorretos');
    expect(viewModel.usuario, isNull);
  });
}
