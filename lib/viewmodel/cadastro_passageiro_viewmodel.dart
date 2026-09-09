import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/repositories/cadastro_passageiro_repository.dart';

class CadastroPassageiroViewModel extends ChangeNotifier {
  final CadastroPassageiroRepository _repository;

  CadastroPassageiroViewModel({CadastroPassageiroRepository? repository})
    : _repository = repository ?? CadastroPassageiroRepository();

  bool _carregando = false;
  String? _erro;

  bool get carregando => _carregando;

  String? get erro => _erro;

  Future<bool> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    final telefoneDigitos = telefone.replaceAll(RegExp(r'\D'), '');
    final emailNormalizado = email.trim().toLowerCase();

    if (!_senhaValida(senha)) {
      _erro = 'A senha deve ter no mínimo 8 caracteres, com letras e números.';
      notifyListeners();
      return false;
    }

    if (telefoneDigitos.length < 10 || telefoneDigitos.length > 11) {
      _erro = 'Informe um telefone com DDD (10 ou 11 dígitos).';
      notifyListeners();
      return false;
    }

    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      await _repository.cadastrar(
        nome: nome.trim(),
        email: emailNormalizado,
        telefone: telefoneDigitos,
        senha: senha,
      );
      return true;
    } on DioException catch (e) {
      _erro = mensagemErroDio(
        e,
        fallback: 'Erro ao realizar cadastro',
        porStatus: const {
          400: 'Dados inválidos',
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

  bool _senhaValida(String senha) {
    if (senha.length < 8) {
      return false;
    }
    final temLetra = RegExp(r'[A-Za-z]').hasMatch(senha);
    final temNumero = RegExp(r'\d').hasMatch(senha);
    return temLetra && temNumero;
  }
}
