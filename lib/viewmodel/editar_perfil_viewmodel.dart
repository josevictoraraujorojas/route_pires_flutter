import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:route_pires_flutter/repositories/editar_perfil_repository.dart';

class EditarPerfilViewModel extends ChangeNotifier {
  final EditarPerfilRepository _repository;

  EditarPerfilViewModel({EditarPerfilRepository? repository})
      : _repository = repository ?? EditarPerfilRepository();

  bool _carregando = false;
  String? _erro;

  bool get carregando => _carregando;
  String? get erro => _erro;

  Future<bool> atualizarPerfil({
    required String id,
    required String nome,
    required String email,
    required String telefone,
    String? senha,
  }) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      await _repository.atualizarPerfil(
        id: id,
        nome: nome,
        email: email,
        telefone: telefone,
        senha: senha,
      );
      
      return true;
    } on DioException catch (e) {
      debugPrint('Erro da API: ${e.response?.data}'); 
      if (e.response?.statusCode == 400) {
        _erro = 'Dados inválidos. Verifique as informações.';
      } else {
        _erro = 'Erro ao atualizar dados. Tente novamente.';
      }
      return false;
    } catch (e) {
      _erro = 'Ocorreu um erro inesperado.';
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}