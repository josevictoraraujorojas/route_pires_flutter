import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/config/token_storage.dart';
import 'package:route_pires_flutter/model/usuario_response.dart';
import 'package:route_pires_flutter/repositories/login_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({
    LoginRepository? repository,
    TokenStorage? tokenStorage,
    bool? isWeb,
    bool autoBootstrap = true,
  }) : _repository = repository ?? LoginRepository(isWeb: isWeb),
       _tokenStorage = tokenStorage ?? createTokenStorage(),
       _isWeb = isWeb ?? kIsWeb {
    if (autoBootstrap) {
      unawaited(carregarUsuarioSalvo());
    } else {
      _inicializando = false;
    }
  }

  final LoginRepository _repository;
  final TokenStorage _tokenStorage;
  final bool _isWeb;

  bool _carregando = false;
  bool _inicializando = true;
  String? _erro;
  String? _erroInicializacao;
  UsuarioResponse? _usuario;

  VoidCallback? onSessionEnded;

  bool get carregando => _carregando;
  bool get inicializando => _inicializando;
  String? get erro => _erro;
  String? get erroInicializacao => _erroInicializacao;
  UsuarioResponse? get usuario => _usuario;

  /// Restaura somente sessões aceitas pela API. O perfil salvo no aparelho não
  /// é usado como prova de autenticação.
  Future<void> carregarUsuarioSalvo() async {
    _inicializando = true;
    _erroInicializacao = null;
    notifyListeners();

    try {
      // Remove o perfil em texto puro deixado por versões anteriores.
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.remove('usuario_logado');
      } catch (_) {
        // A migração não deve bloquear a validação da sessão atual.
      }

      if (!_isWeb) {
        final token = await _tokenStorage.read();
        if (token == null || token.isEmpty) return;
        ApiClient().setAccessToken(token);
      }

      final usuarioAtual = await _repository.usuarioAtual();
      if (!_tipoSuportado(usuarioAtual)) {
        throw const FormatException('Tipo de usuário não suportado');
      }
      if (_isWeb) await _carregarCsrf();
      _usuario = usuarioAtual;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await invalidarSessao();
      } else {
        _erroInicializacao = mensagemErroDio(
          e,
          fallback: 'Não foi possível verificar a sessão',
        );
      }
    } catch (_) {
      _erroInicializacao = 'Não foi possível verificar a sessão';
    } finally {
      _inicializando = false;
      notifyListeners();
    }
  }

  Future<void> _carregarCsrf() async {
    final csrf = await _repository.obterCsrf();
    ApiClient().setCsrf(csrf.token, headerName: csrf.headerName);
  }

  Future<void> invalidarSessao() async {
    _usuario = null;
    _erro = null;
    ApiClient().clearSession();
    onSessionEnded?.call();
    notifyListeners();
    if (!_isWeb) {
      try {
        await _tokenStorage.delete();
      } catch (_) {
        // A próxima abertura também consultará /auth/me antes de exibir a home.
      }
    }
  }

  /// Logout Web revoga o cookie no servidor; no mobile remove o token seguro.
  Future<bool> sair() async {
    _erro = null;
    try {
      if (_isWeb) {
        await _repository.sairWeb();
      } else {
        await _tokenStorage.delete();
      }
      await invalidarSessao();
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await invalidarSessao();
        return true;
      }
      _erro = mensagemErroDio(e, fallback: 'Não foi possível sair da conta');
      notifyListeners();
      return false;
    } catch (_) {
      _erro = 'Não foi possível sair da conta';
      notifyListeners();
      return false;
    }
  }

  Future<bool> realizarLogin({
    required String email,
    required String senha,
  }) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final resposta = await _repository.logar(email: email, senha: senha);
      if (!_tipoSuportado(resposta.usuario)) {
        throw const FormatException('Tipo de usuário não suportado');
      }

      if (_isWeb) {
        await _carregarCsrf();
      } else {
        final token = resposta.accessToken;
        if (token == null || token.isEmpty) {
          throw const FormatException('Login sem token');
        }
        await _tokenStorage.write(token);
        ApiClient().setAccessToken(token);
      }

      _usuario = resposta.usuario;
      return true;
    } on DioException catch (e) {
      _erro = mensagemErroDio(
        e,
        fallback: 'Erro ao realizar login',
        porStatus: const {
          400: 'Dados inválidos',
          401: 'Email ou senha incorretos',
          404: 'Usuário não encontrado',
          500: 'Erro interno no servidor',
        },
      );
      return false;
    } catch (_) {
      _erro = 'Ocorreu um erro inesperado';
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  bool _tipoSuportado(UsuarioResponse usuario) =>
      usuario.id.isNotEmpty &&
      (usuario.tipo == 'PASSAGEIRO' || usuario.tipo == 'MOTOTAXISTA');
}
