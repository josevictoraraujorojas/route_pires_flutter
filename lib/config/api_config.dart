class ApiConfig {
  static const String _baseUrlConfigurada = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    return _baseUrlConfigurada.isNotEmpty
        ? _baseUrlConfigurada
        : 'https://routepires.otavio.win';
  }
}
