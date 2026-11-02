import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/config/safe_change_notifier.dart';
import 'package:route_pires_flutter/model/veiculo.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';

class VeiculoViewModel extends ChangeNotifier with SafeChangeNotifier {
  final MototaxistaRepository _repository;

  VeiculoViewModel({MototaxistaRepository? repository})
    : _repository = repository ?? MototaxistaRepository();

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;
  Veiculo? _veiculo;

  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;
  Veiculo? get veiculo => _veiculo;

  Future<void> carregar(String id) async {
    _carregando = true;
    _erro = null;
    avisar();

    try {
      _veiculo = await _repository.buscarVeiculo(id: id);
    } on DioException catch (e) {
      _erro = mensagemErroDio(
        e,
        fallback: 'Não foi possível carregar os dados do veículo',
        porStatus: const {404: 'Mototaxista não encontrado'},
      );
    } catch (_) {
      _erro = 'Não foi possível carregar os dados do veículo';
    } finally {
      _carregando = false;
      avisar();
    }
  }

  Future<bool> salvar({required String id, required Veiculo veiculo}) async {
    if (_salvando) return false;

    _salvando = true;
    _erro = null;
    avisar();

    try {
      await _repository.atualizarVeiculo(id: id, veiculo: veiculo);
      _veiculo = veiculo;
      return true;
    } on DioException catch (e) {
      _erro = mensagemErroDio(
        e,
        fallback: 'Não foi possível atualizar o veículo',
        porStatus: const {
          400: 'Dados inválidos. Verifique as informações.',
          404: 'Mototaxista não encontrado',
          409: 'Já existe um cadastro com estes dados',
        },
      );
      return false;
    } catch (_) {
      _erro = 'Não foi possível atualizar o veículo';
      return false;
    } finally {
      _salvando = false;
      avisar();
    }
  }
}
