import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Override at run time:
  /// flutter run --dart-define=API_BASE_URL=https://routepires.otavio.win
  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) {
      return _fromEnv;
    }
    if (kIsWeb) {
      return 'https://routepires.otavio.win';
    }
    return 'http://10.0.2.2:8080';
  }

  static const String health = '/actuator/health/liveness';
  static const String passageiros = '/passageiros';
}
