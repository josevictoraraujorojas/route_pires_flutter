import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/config/token_storage.dart';
import 'package:route_pires_flutter/repositories/chat_websocket_repository.dart';

class WebSocketTestPage extends StatefulWidget {
  const WebSocketTestPage({super.key});

  @override
  State<WebSocketTestPage> createState() => _WebSocketTestPageState();
}

class _WebSocketTestPageState extends State<WebSocketTestPage> {
  final TokenStorage _tokenStorage = createTokenStorage();

  final ChatWebSocketRepository _webSocket = ChatWebSocketRepository();

  final TextEditingController _chatIdController = TextEditingController();

  final TextEditingController _mensagemController = TextEditingController();

  String _status = 'Desconectado';

  Future<void> conectar() async {
    final token = await _tokenStorage.read();

    if (token == null || token.isEmpty) {
      setState(() {
        _status = 'JWT não encontrado';
      });

      print('JWT não encontrado');
      return;
    }

    print('JWT encontrado');
    print('Tamanho do JWT: ${token.length}');

    final chatId = _chatIdController.text.trim();

    if (chatId.isEmpty) {
      setState(() {
        _status = 'Informe o ID do chat';
      });
      return;
    }

    _webSocket.conectar(
      token: token,
      chatId: chatId,
      onMensagem: (mensagem) {
        print('MENSAGEM RECEBIDA: $mensagem');

        if (!mounted) return;

        setState(() {
          _status = 'Mensagem recebida';
        });
      },
    );

    setState(() {
      _status = 'Conectando...';
    });
  }

  void enviarMensagem() {
    final chatId = _chatIdController.text.trim();
    final conteudo = _mensagemController.text.trim();

    if (chatId.isEmpty || conteudo.isEmpty) {
      return;
    }

    _webSocket.enviarMensagem(chatId: chatId, conteudo: conteudo);

    _mensagemController.clear();
  }

  @override
  void dispose() {
    _webSocket.desconectar();
    _chatIdController.dispose();
    _mensagemController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Teste WebSocket'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _chatIdController,
                placeholder: 'ID do Chat',
              ),

              const SizedBox(height: 16),

              CupertinoButton.filled(
                onPressed: conectar,
                child: const Text('Conectar'),
              ),

              const SizedBox(height: 16),

              Text(_status),

              const SizedBox(height: 30),

              CupertinoTextField(
                controller: _mensagemController,
                placeholder: 'Mensagem',
              ),

              const SizedBox(height: 16),

              CupertinoButton.filled(
                onPressed: enviarMensagem,
                child: const Text('Enviar mensagem'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
