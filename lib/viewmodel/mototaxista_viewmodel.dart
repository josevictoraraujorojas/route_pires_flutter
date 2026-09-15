import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/config/validacao.dart';
import 'package:route_pires_flutter/model/mototaxista_cadastro.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';

class MototaxistaViewModel extends ChangeNotifier {
  final MototaxistaRepository _repository;

  MototaxistaViewModel({MototaxistaRepository? repository})
    : _repository = repository ?? MototaxistaRepository();

  bool _carregando = false;
  bool _disposed = false;
  String? _erro;

  bool get carregando => _carregando;
  String? get erro => _erro;

  void _avisar() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> cadastrar(MototaxistaCadastro mototaxista) async {
    if (!senhaValida(mototaxista.senha)) {
      _erro = mensagemSenhaInvalida;
      _avisar();
      return false;
    }
    if (int.tryParse(mototaxista.ano) == null) {
      _erro = 'Informe um ano válido';
      _avisar();
      return false;
    }

    _carregando = true;
    _erro = null;
    _avisar();

    try {
      await _repository.cadastrar(mototaxista);
      return true;
    } on DioException catch (error) {
      _erro = _tratarErro(error);
      return false;
    } catch (_) {
      _erro = 'Ocorreu um erro inesperado ao realizar o cadastro';
      return false;
    } finally {
      _carregando = false;
      _avisar();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  String _tratarErro(DioException error) {
    final statusCode = error.response?.statusCode;

    if (statusCode == 400) {
      return 'Os dados informados são inválidos';
    }
    if (statusCode == 409) {
      return 'Já existe um cadastro com estes dados';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'O servidor não conseguiu concluir o cadastro';
    }
    if (statusCode != null) {
      return 'Não foi possível concluir o cadastro';
    }

    return 'Não foi possível conectar ao servidor';
  }
}
