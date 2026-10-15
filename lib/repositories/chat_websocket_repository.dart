import 'dart:convert';

import 'package:route_pires_flutter/config/api_config.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class ChatWebSocketRepository {
  StompClient? _stompClient;

  String get _webSocketUrl {
    final uri = Uri.parse(ApiConfig.baseUrl);

    final esquema = switch (uri.scheme) {
      'https' => 'wss',
      'http' => 'ws',
      _ => throw ArgumentError(
        'Protocolo não suportado para WebSocket: ${uri.scheme}',
      ),
    };

    return uri.replace(scheme: esquema, path: '/ws').toString();
  }

  void conectar({
    required String token,
    required String chatId,
    required Function(Map<String, dynamic>) onMensagem,
  }) {
    // Evita manter uma conexão anterior ao iniciar outra.
    desconectar();

    _stompClient = StompClient(
      config: StompConfig(
        url: _webSocketUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (StompFrame frame) {
          print('WEBSOCKET CONECTADO');

          _stompClient?.subscribe(
            destination: '/topic/chat/$chatId',
            callback: (StompFrame frame) {
              if (frame.body == null) return;

              try {
                final mensagem = jsonDecode(frame.body!);

                if (mensagem is Map<String, dynamic>) {
                  onMensagem(mensagem);
                } else {
                  print('Formato de mensagem WebSocket inválido');
                }
              } catch (e) {
                print('Erro ao interpretar mensagem WebSocket: $e');
              }
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
