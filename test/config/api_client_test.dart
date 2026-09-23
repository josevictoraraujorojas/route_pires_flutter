import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_pires_flutter/config/api_client.dart';

class RecordingAdapter implements HttpClientAdapter {
  int statusCode = 200;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late ApiClient client;
  late RecordingAdapter adapter;
  late HttpClientAdapter previousAdapter;

  setUp(() {
    client = ApiClient();
    adapter = RecordingAdapter();
    previousAdapter = client.dio.httpClientAdapter;
    client.dio.httpClientAdapter = adapter;
    client.clearSession();
    client.onUnauthorized = null;
  });

  tearDown(() {
    client.dio.httpClientAdapter = previousAdapter;
    client.clearSession();
    client.onUnauthorized = null;
  });

  test(
    'credencial é enviada apenas ao backend e não no login público',
    () async {
      client.setAccessToken('jwt-secreto');
      client.setCsrf('csrf-secreto');

      await client.dio.get('/mototaxistas/disponiveis');
      await client.dio.post('/login', data: {'email': 'a', 'senha': 'b'});

      final protegido = adapter.requests.first.headers;
      final publico = adapter.requests.last.headers;
      if (kIsWeb) {
        expect(protegido['Authorization'], isNull);
      } else {
        expect(protegido['Authorization'], 'Bearer jwt-secreto');
      }
      expect(publico['Authorization'], isNull);
      expect(publico['X-CSRF-TOKEN'], isNull);
    },
  );

  test('Web envia CSRF apenas em escrita autenticada', () async {
    client.setCsrf('csrf-secreto');

    await client.dio.patch('/mototaxistas/123', data: {'disponivel': true});
    await client.dio.get('/auth/me');

    if (kIsWeb) {
      expect(adapter.requests.first.headers['X-CSRF-TOKEN'], 'csrf-secreto');
    } else {
      expect(adapter.requests.first.headers['X-CSRF-TOKEN'], isNull);
    }
    expect(adapter.requests.last.headers['X-CSRF-TOKEN'], isNull);
  });

  test('401 protegido encerra sessão; 403 e 401 de login não', () async {
    var invalido = 0;
    client.onUnauthorized = () async {
      invalido++;
    };
    adapter.statusCode = 401;

    await expectLater(client.dio.get('/auth/me'), throwsA(isA<DioException>()));
    await Future<void>.delayed(Duration.zero);
    expect(invalido, 1);

    await expectLater(
      client.dio.post('/login', data: {'email': 'a', 'senha': 'b'}),
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(invalido, 1);

    adapter.statusCode = 403;
    await expectLater(
      client.dio.get('/mototaxistas/disponiveis'),
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(invalido, 1);
  });
}
