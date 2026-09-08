class ApiConfig {
  /// Override at run time:
  /// flutter run --dart-define=API_BASE_URL=https://routepires.otavio.win
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String health = '/actuator/health/liveness';
  static const String passageiros = '/passageiros';
}
