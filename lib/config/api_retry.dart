import 'package:dio/dio.dart';

class ApiRetryGate {
  ApiRetryGate({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  int _falhas = 0;
  DateTime? _proxima;
  bool get canAttempt => _proxima == null || !_clock().isBefore(_proxima!);
  DateTime? get nextAttempt => _proxima;

  void failed(Object error) {
    if (error is DioException && error.type == DioExceptionType.cancel) return;
    final agora = _clock();
    final segundos = [30, 60, 120, 300][_falhas.clamp(0, 3)];
    _falhas++;
    var proxima = agora.add(Duration(seconds: segundos));
    if (error is DioException) {
      final header = error.response?.headers.value('retry-after');
      final espera = int.tryParse(header ?? '');
      final servidor = espera != null
          ? agora.add(Duration(seconds: espera))
          : _dataHttp(header);
      if (servidor != null && servidor.isAfter(proxima)) proxima = servidor;
    }
    _proxima = proxima;
  }

  void succeeded() {
    _falhas = 0;
    _proxima = null;
  }

  static DateTime? _dataHttp(String? header) {
    final partes = RegExp(
      r'^\w{3}, (\d{2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
    ).firstMatch(header ?? '');
    if (partes == null) return null;
    final mes = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ].indexOf(partes[2]!);
    if (mes < 0) return null;
    return DateTime.utc(
      int.parse(partes[3]!),
      mes + 1,
      int.parse(partes[1]!),
      int.parse(partes[4]!),
      int.parse(partes[5]!),
      int.parse(partes[6]!),
    );
  }
}
