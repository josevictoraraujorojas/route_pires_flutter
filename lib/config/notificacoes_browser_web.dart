import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

void ouvirAbertura(void Function(Map<String, dynamic>) abrir) {
  final uri = Uri.base;
  final inicial = uri.queryParameters['notificacao'];
  if (inicial != null) {
    try {
      abrir(Map<String, dynamic>.from(jsonDecode(inicial) as Map));
    } catch (_) {
      /* URL sem um evento válido. */
    }
    final parametros = Map<String, String>.of(uri.queryParameters)
      ..remove('notificacao');
    web.window.history.replaceState(
      null,
      '',
      uri.replace(queryParameters: parametros).toString(),
    );
  }
  web.window.navigator.serviceWorker.addEventListener(
    'message',
    ((web.MessageEvent event) {
      final mensagem = event.data.dartify();
      if (mensagem is Map &&
          mensagem['tipo'] == 'ROUTEPIRES_NOTIFICACAO' &&
          mensagem['dados'] is Map) {
        abrir(Map<String, dynamic>.from(mensagem['dados'] as Map));
      }
    }).toJS,
  );
}

void mostrarAlerta(String titulo, String corpo, void Function() abrir) {
  if (web.Notification.permission != 'granted') return;
  final notification = web.Notification(
    titulo,
    web.NotificationOptions(
      body: corpo,
      icon: Uri.base.resolve('icons/Icon-192.png').toString(),
    ),
  );
  notification.addEventListener(
    'click',
    ((web.Event _) {
      notification.close();
      abrir();
    }).toJS,
  );
}
