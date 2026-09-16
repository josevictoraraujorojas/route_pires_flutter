import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/config/safe_change_notifier.dart';
import 'package:route_pires_flutter/config/validacao.dart';
import 'package:route_pires_flutter/repositories/cadastro_passageiro_repository.dart';

class CadastroPassageiroViewModel extends ChangeNotifier
    with SafeChangeNotifier {
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
    final emailLimpo = emailNormalizado(email);

    if (!senhaValida(senha)) {
      _erro = mensagemSenhaInvalida;
      avisar();
      return false;
    }

    if (telefoneDigitos.length < 10 || telefoneDigitos.length > 11) {
      _erro = 'Informe um telefone com DDD (10 ou 11 dígitos).';
      avisar();
      return false;
    }

    _carregando = true;
    _erro = null;
    avisar();

    try {
      await _repository.cadastrar(
        nome: nome.trim(),
        email: emailLimpo,
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
      avisar();
    }
  }
}
