import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Web usa a mesma origem da página; mobile aceita override para debug.
  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    if (_fromEnv.isNotEmpty) {
      return _fromEnv;
    }
    return 'https://siqs5nq4jauaxmdzdotn0jsj.62.171.158.2.sslip.io';
  }

  static const String health = '/actuator/health/liveness';
  static const String passageiros = '/passageiros';
  static const String mototaxistas = '/mototaxistas';
  static const String mototaxistasDisponiveis = '/mototaxistas/disponiveis';
  static String perfilMototaxistaParaPassageiro(String id) =>
      '$passageiros/mototaxista/$id/perfil';
  static String passageiroResumo(String id) => '$passageiros/$id/resumo';
  static const String corridasPassageiro = '/corridas-passageiro';
  static const String corridaFrete = '/corrida-frete';
}
