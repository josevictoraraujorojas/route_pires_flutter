import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/config/safe_change_notifier.dart';
import 'package:route_pires_flutter/config/validacao.dart';
import 'package:route_pires_flutter/model/mototaxista_cadastro.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';

class MototaxistaViewModel extends ChangeNotifier with SafeChangeNotifier {
  final MototaxistaRepository _repository;

  MototaxistaViewModel({MototaxistaRepository? repository})
    : _repository = repository ?? MototaxistaRepository();

  MototaxistaRascunho rascunho = MototaxistaRascunho();
  bool _carregando = false;
  String? _erro;

  bool get carregando => _carregando;
  String? get erro => _erro;

  void limparRascunho() {
    rascunho = MototaxistaRascunho();
    _erro = null;
    avisar();
  }

  Future<bool?> consultarDisponibilidade({required String id}) async {
    _erro = null;
    try {
      return await _repository.obterDisponibilidade(id: id);
    } on DioException catch (e) {
      _erro = mensagemErroDio(
        e,
        fallback: 'Não foi possível consultar sua disponibilidade',
        porStatus: const {
          403: 'Você não tem permissão para consultar este perfil',
          404: 'Mototaxista não encontrado',
        },
      );
      avisar();
      return null;
    } catch (_) {
      _erro = 'Não foi possível consultar sua disponibilidade';
      avisar();
      return null;
    }
  }

  Future<bool> alterarDisponibilidade({
    required String id,
    required bool disponivel,
  }) async {
    _erro = null;
    try {
      await _repository.atualizarDisponibilidade(
        id: id,
        disponivel: disponivel,
      );

      return true;
    } on DioException catch (e) {
      _erro = mensagemErroDio(
        e,
        fallback: 'Não foi possível alterar a disponibilidade',
        porStatus: const {
          400: 'Valor de disponibilidade inválido',
          404: 'Mototaxista não encontrado',
          500: 'Erro interno no servidor',
        },
      );

      avisar();
      return false;
    } catch (_) {
      _erro = 'Não foi possível alterar a disponibilidade';
      avisar();
      return false;
    }
  }

  Future<bool> cadastrar([MototaxistaCadastro? mototaxista]) async {
    if (_carregando) return false;
    final cadastro = mototaxista ?? rascunho.paraCadastro();
    if (!senhaValida(cadastro.senha)) {
      _erro = mensagemSenhaInvalida;
      avisar();
      return false;
    }
    if (int.tryParse(cadastro.ano) == null) {
      _erro = 'Informe um ano válido';
      avisar();
      return false;
    }

    _carregando = true;
    _erro = null;
    avisar();

    try {
      await _repository.cadastrar(cadastro);
      return true;
    } on DioException catch (error) {
      _erro = mensagemErroDio(
        error,
        fallback: 'Não foi possível concluir o cadastro',
        porStatus: const {
          400: 'Os dados informados são inválidos',
          409: 'Já existe um cadastro com estes dados',
          500: 'O servidor não conseguiu concluir o cadastro',
        },
      );
      return false;
    } catch (_) {
      _erro = 'Ocorreu um erro inesperado ao realizar o cadastro';
      return false;
    } finally {
      _carregando = false;
      avisar();
    }
  }
}
