class ApiConfig {
<<<<<<< HEAD
  /// Override at run time, e.g. API no PC:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
=======
  /// Só use dart-define se a API publicada estiver fora do ar.
>>>>>>> 0284b5f339017158619f108eb15a4d6ec1db26f6
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
