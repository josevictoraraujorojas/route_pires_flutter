import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_pires_flutter/config/api_retry.dart';

void main() {
  test('Falhas sucessivas espaçam tentativas e sucesso reinicia intervalo', () {
    var agora = DateTime.utc(2026, 10, 2);
    final gate = ApiRetryGate(clock: () => agora);
    for (final segundos in [30, 60, 120, 300, 300]) {
      gate.failed(StateError('offline'));
      expect(gate.canAttempt, isFalse);
      expect(gate.nextAttempt, agora.add(Duration(seconds: segundos)));
      agora = agora.add(Duration(seconds: segundos));
      expect(gate.canAttempt, isTrue);
    }
    gate.succeeded();
    gate.failed(StateError('offline'));
    expect(gate.nextAttempt, agora.add(const Duration(seconds: 30)));
  });

  test('Retry-After é respeitado como espera mínima em quota 503', () {
    final agora = DateTime.utc(2026, 10, 2);
    final gate = ApiRetryGate(clock: () => agora);
    final request = RequestOptions(path: '/corridas-passageiro');
    gate.failed(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 503,
          headers: Headers.fromMap({
            'retry-after': ['300'],
          }),
        ),
      ),
    );
    expect(gate.nextAttempt, agora.add(const Duration(minutes: 5)));
  });

  test('Retry-After aceita data HTTP UTC', () {
    final agora = DateTime.utc(2026, 10, 2);
    final gate = ApiRetryGate(clock: () => agora);
    final request = RequestOptions(path: '/corridas-passageiro');
    gate.failed(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 429,
          headers: Headers.fromMap({
            'retry-after': ['Fri, 02 Oct 2026 00:03:00 GMT'],
          }),
        ),
      ),
    );
    expect(gate.nextAttempt, DateTime.utc(2026, 10, 2, 0, 3));
  });
}
