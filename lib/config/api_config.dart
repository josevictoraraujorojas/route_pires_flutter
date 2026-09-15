class ApiConfig {
  /// Default é a API publicada. Use dart-define só para apontar para o PC.
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
  static const String corridasPassageiro = '/corridas-passageiro';
  static const String corridaFrete = '/corrida-frete';
}
