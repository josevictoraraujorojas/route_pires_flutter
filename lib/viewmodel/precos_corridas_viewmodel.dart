import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';

class PrecosCorridasViewModel extends ChangeNotifier {
  final MototaxistaRepository _repository;

  PrecosCorridasViewModel({MototaxistaRepository? repository})
    : _repository = repository ?? MototaxistaRepository();

  bool _carregando = false;
  bool _salvando = false;
  String? _erro;

  double precoZonaUrbana = 0;
  double precoBairrosAfastados = 0;
  double precoBandeira2 = 0;

  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;

  double _converterPreco(dynamic valor) {
    if (valor == null) return 0;

    if (valor is num) {
      return valor.toDouble();
    }

    if (valor is String) {
      return double.tryParse(valor.replaceAll(',', '.')) ?? 0;
    }

    return 0;
  }

  Future<void> carregarPrecos({required String id}) async {
    if (id.trim().isEmpty) {
      _erro = 'Identificação do mototaxista inválida.';
      notifyListeners();
      return;
    }

    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final dados = await _repository.buscarPrecos(id: id);

      precoZonaUrbana = _converterPreco(dados['precoZonaUrbana']);
      precoBairrosAfastados = _converterPreco(dados['precoBairrosAfastados']);
      precoBandeira2 = _converterPreco(dados['precoBandeira2']);
    } on DioException catch (e) {
      debugPrint('Erro ao carregar preços: ${e.response?.data}');
      _erro = 'Não foi possível carregar os preços.';
    } catch (e) {
      debugPrint('Erro inesperado ao carregar preços: $e');
      _erro = 'Ocorreu um erro ao carregar os preços.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<bool> salvarPrecos({
    required String id,
    required double precoZonaUrbana,
    required double precoBairrosAfastados,
    required double precoBandeira2,
  }) async {
    if (id.trim().isEmpty) {
      _erro = 'Identificação do mototaxista inválida.';
      notifyListeners();
      return false;
    }

    _salvando = true;
    _erro = null;
    notifyListeners();

    try {
      await _repository.atualizarPrecos(
        id: id,
        precoZonaUrbana: precoZonaUrbana,
        precoBairrosAfastados: precoBairrosAfastados,
        precoBandeira2: precoBandeira2,
      );

      this.precoZonaUrbana = precoZonaUrbana;
      this.precoBairrosAfastados = precoBairrosAfastados;
      this.precoBandeira2 = precoBandeira2;

      return true;
    } on DioException catch (e) {
      debugPrint('Erro ao atualizar preços: ${e.response?.data}');
      _erro = 'Não foi possível salvar os preços.';
      return false;
    } catch (e) {
      debugPrint('Erro inesperado ao salvar preços: $e');
      _erro = 'Ocorreu um erro inesperado.';
      return false;
    } finally {
      _salvando = false;
      notifyListeners();
    }
  }
}
