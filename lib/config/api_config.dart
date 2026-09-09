class ApiConfig {
  /// Override at run time, e.g. API no PC:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) {
      return _fromEnv;
    }
    return 'https://routepires.otavio.win';
  }

  static const String health = '/actuator/health/liveness';
  static const String passageiros = '/passageiros';
}
