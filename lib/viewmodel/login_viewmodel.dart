import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/repositories/login_repository.dart';

import '../model/usuario_response.dart';

class LoginViewModel extends ChangeNotifier {
  static const _usuarioKey = 'usuario_logado';

  final LoginRepository _repository;

  LoginViewModel({LoginRepository? repository})
    : _repository = repository ?? LoginRepository() {
    carregarUsuarioSalvo();
  }

  bool _carregando = false;
  String? _erro;
  UsuarioResponse? _usuario;

  bool get Carregando => _carregando;

  String? get erro => _erro;

  UsuarioResponse? get usuario => _usuario;

  Future<void> carregarUsuarioSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_usuarioKey);
    if (json == null || json.isEmpty) return;

    try {
      final map = Map<String, dynamic>.from(
        jsonDecode(json) as Map? ?? const {},
      );
      _usuario = UsuarioResponse.fromJson(map);
      notifyListeners();
    } catch (_) {
      await prefs.remove(_usuarioKey);
    }
  }

  Future<void> _salvarUsuario(UsuarioResponse usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usuarioKey, jsonEncode(usuario.toJson()));
  }

  Future<void> sair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usuarioKey);
    _usuario = null;
    _erro = null;
    notifyListeners();
  }

  Future<bool> realizarLogin({
    required String email,
    required String senha,
  }) async {
    _carregando = true;
    _erro = null;

    notifyListeners();

    try {
      _usuario = await _repository.logar(email: email, senha: senha);
      await _salvarUsuario(_usuario!);

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
    } catch (e) {
      _erro = 'Ocorreu um erro inesperado';
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}
