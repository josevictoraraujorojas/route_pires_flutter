import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:route_pires_flutter/config/token_storage.dart';
import 'package:route_pires_flutter/model/mensagem.dart';
import 'package:route_pires_flutter/repositories/chat_repository.dart';
import 'package:route_pires_flutter/repositories/chat_websocket_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final String chatId;
  final bool encerrado;

  final ChatRepository _chatRepository;
  final ChatWebSocketRepository _webSocket;
  final TokenStorage _tokenStorage;

  ChatViewModel({
    required this.chatId,
    required this.encerrado,
    ChatRepository? chatRepository,
    ChatWebSocketRepository? webSocket,
    TokenStorage? tokenStorage,
  }) : _chatRepository = chatRepository ?? ChatRepository(),
       _webSocket = webSocket ?? ChatWebSocketRepository(),
       _tokenStorage = tokenStorage ?? createTokenStorage();

  final List<Mensagem> _mensagens = [];

  bool _carregandoMensagens = true;
  bool _inicializado = false;
  bool _disposed = false;

  String? _meuUsuarioId;
  String? _erro;

  List<Mensagem> get mensagens => List.unmodifiable(_mensagens);

  bool get carregandoMensagens => _carregandoMensagens;

  String? get erro => _erro;

  void _notificarListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  String? _normalizarId(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }

    return id.split('/').last;
  }

  Future<void> inicializar() async {
    if (_inicializado) return;

    _inicializado = true;

    String? token;

    try {
      token = await _tokenStorage.read();

      if (token != null && token.isNotEmpty) {
        final payload = JwtDecoder.decode(token);
        _meuUsuarioId = _normalizarId(payload['sub']?.toString());
      }
    } catch (e) {
      debugPrint('Erro ao recuperar o usuário autenticado: $e');
      token = null;
    }

    if (_disposed) return;

    await carregarMensagens();

    if (_disposed || token == null || token.isEmpty) {
      return;
    }

    if (!encerrado) {
      _conectar(token);
    }

    await marcarMensagensVisualizadas();
  }

  Future<void> carregarMensagens() async {
    _carregandoMensagens = true;
    _erro = null;
    _notificarListeners();

    try {
      final mensagensCarregadas = await _chatRepository.listarMensagens(chatId);

      if (_disposed) return;

      _mensagens
        ..clear()
        ..addAll(mensagensCarregadas);
    } catch (e) {
      if (_disposed) return;

      _erro = 'Não foi possível carregar as mensagens.';
      debugPrint('Erro ao carregar mensagens: $e');
    } finally {
      _carregandoMensagens = false;
      _notificarListeners();
    }
  }

  void _conectar(String token) {
    try {
      _webSocket.conectar(
        token: token,
        chatId: chatId,
        onMensagem: (dados) {
          _processarMensagem(dados);
        },
      );
    } catch (e) {
      debugPrint('Erro ao conectar ao WebSocket: $e');
    }
  }

  void _processarMensagem(dynamic dados) {
    if (_disposed || dados is! Map<String, dynamic>) {
      return;
    }

    try {
      final novaMensagem = Mensagem.fromJson(dados);
      final remetenteId = _normalizarId(novaMensagem.remetente);

      final indice = novaMensagem.id.isEmpty
          ? -1
          : _mensagens.indexWhere((mensagem) => mensagem.id == novaMensagem.id);

      if (indice >= 0) {
        _mensagens[indice] = novaMensagem;
      } else {
        _mensagens.add(novaMensagem);
      }

      _notificarListeners();

      final mensagemRecebida =
          remetenteId != null &&
          remetenteId != _meuUsuarioId &&
          novaMensagem.status.toUpperCase() == 'ENVIADA';

      if (!encerrado && mensagemRecebida) {
        unawaited(marcarMensagensVisualizadas());
      }
    } catch (e) {
      debugPrint('Erro ao processar mensagem recebida: $e');
    }
  }

  Future<void> marcarMensagensVisualizadas() async {
    try {
      await _chatRepository.marcarMensagensVisualizadas(chatId);
    } catch (e) {
      debugPrint('Erro ao marcar mensagens como visualizadas: $e');
    }
  }

  bool enviarMensagem(String conteudo) {
    if (encerrado) {
      return false;
    }

    final texto = conteudo.trim();

    if (texto.isEmpty) {
      return false;
    }

    _webSocket.enviarMensagem(chatId: chatId, conteudo: texto);

    return true;
  }

  bool ehMinhaMensagem(Mensagem mensagem) {
    final remetenteId = _normalizarId(mensagem.remetente);

    return _meuUsuarioId != null && remetenteId == _meuUsuarioId;
  }

  @override
  void dispose() {
    _disposed = true;
    _webSocket.desconectar();
    super.dispose();
  }
}
