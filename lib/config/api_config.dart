class ApiConfig {
  /// Só use dart-define se a API publicada estiver fora do ar.
  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) {
      return _fromEnv;
    }
    return 'https://routepires.otavio.win';
  }

  static const String health = '/actuator/health/liveness';
  static const String passageiros = '/passageiros';
  static const String mototaxistas = '/mototaxistas';
}
