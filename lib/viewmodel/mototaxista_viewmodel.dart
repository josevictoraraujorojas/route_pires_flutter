import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/model/mototaxista_cadastro.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';

class MototaxistaViewModel extends ChangeNotifier {
  final MototaxistaRepository _repository;

  MototaxistaViewModel({MototaxistaRepository? repository})
    : _repository = repository ?? MototaxistaRepository();

  bool _carregando = false;
  String? _erro;

  bool get carregando => _carregando;
  String? get erro => _erro;

  Future<bool> cadastrar(MototaxistaCadastro mototaxista) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

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
      notifyListeners();
    }
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