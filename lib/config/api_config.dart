import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Só use dart-define se a API publicada estiver fora do ar.
  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) {
      return _fromEnv;
    }
    if (kIsWeb) {
      return 'https://routepires.otavio.win';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080';
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:8080';
      default:
        return 'https://routepires.otavio.win';
    }
  }

  static const String health = '/actuator/health/liveness';
  static const String passageiros = '/passageiros';
  static const String mototaxistas = '/mototaxistas';
  static const String corridasPassageiro = '/corridas-passageiro';
  static const String corridaFrete = '/corrida-frete';
}
