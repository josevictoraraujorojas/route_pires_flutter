import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/repositories/login_repository.dart';

import '../model/usuario_response.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginRepository _repository;

  LoginViewModel({LoginRepository? repository})
    : _repository = repository ?? LoginRepository();

  bool _carregando = false;
  String? _erro;
  UsuarioResponse? _usuario;

  bool get Carregando => _carregando;

  String? get erro => _erro;

  UsuarioResponse? get usuario => _usuario;

  Future<bool> realizarLogin({
    required String email,
    required String senha,
  }) async {
    _carregando = true;
    _erro = null;

    notifyListeners();

    try {
      _usuario = await _repository.logar(email: email, senha: senha);

      return true;
    } on DioException catch (e) {
      _erro = _tratarErroDio(e);
      return false;
    } catch (e) {
      _erro = 'Ocorreu um erro inesperado';
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  String _tratarErroDio(DioException e) {
    if (e.response != null) {
      switch (e.response?.statusCode) {
        case 400:
          return 'Dados inválidos';
        case 401:
          return 'Email ou senha incorretos';
        case 404:
          return 'Usuário não encontrado';
        case 500:
          return 'Erro interno no servidor';
        default:
          return 'Erro ao realizar login';
      }
    }

    return 'Não foi possível conectar ao servidor';
  }
}
