import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

class ChatWebSocketRepository {
  StompClient? _stompClient;

  void conectar({
    required String token,
    required String chatId,
    required Function(Map<String, dynamic>) onMensagem,
  }) {
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://10.0.2.2:8080/ws',

        stompConnectHeaders: {'Authorization': 'Bearer $token'},

        onConnect: (StompFrame frame) {
          print('WEBSOCKET CONECTADO');

          _stompClient!.subscribe(
            destination: '/topic/chat/$chatId',
            callback: (StompFrame frame) {
              if (frame.body == null) return;

              final mensagem = jsonDecode(frame.body!);
              onMensagem(mensagem);
            },
          );
        },

        onWebSocketError: (dynamic error) {
          print('ERRO WEBSOCKET: $error');
        },

        onStompError: (StompFrame frame) {
          print('ERRO STOMP: ${frame.body}');
        },

        onDisconnect: (StompFrame frame) {
          print('WEBSOCKET DESCONECTADO');
        },
      ),
    );

    _stompClient!.activate();
  }

  void enviarMensagem({required String chatId, required String conteudo}) {
    if (_stompClient == null || !_stompClient!.connected) {
      print('WebSocket não está conectado');
      return;
    }

    _stompClient!.send(
      destination: '/app/chat/$chatId/mensagem',
      body: jsonEncode({'conteudo': conteudo}),
    );

    print('Mensagem enviada: $conteudo');
  }

  void desconectar() {
    _stompClient?.deactivate();
    _stompClient = null;

    print('WebSocket desconectado manualmente');
  }
}
