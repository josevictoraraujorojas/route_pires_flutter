import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:route_pires_flutter/config/token_storage.dart';
import 'package:route_pires_flutter/model/chat.dart';
import 'package:route_pires_flutter/repositories/chat_repository.dart';

class ChatListViewModel extends ChangeNotifier {
  final ChatRepository _repository;
  final TokenStorage _tokenStorage;

  ChatListViewModel({ChatRepository? repository, TokenStorage? tokenStorage})
    : _repository = repository ?? ChatRepository(),
      _tokenStorage = tokenStorage ?? createTokenStorage();

  List<Chat> _chats = [];
  Map<String, int> _mensagensNaoLidas = {};

  bool _carregando = true;
  bool _disposed = false;
  String? _erro;

  List<Chat> get chats => List.unmodifiable(_chats);

  Map<String, int> get mensagensNaoLidas =>
      Map.unmodifiable(_mensagensNaoLidas);

  bool get carregando => _carregando;

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

  Future<void> carregarChatsEContagens() async {
    _carregando = true;
    _erro = null;
    _notificarListeners();

    try {
      final chatsCarregados = await _repository.listar();

      if (_disposed) return;

      _chats = chatsCarregados;

      await _carregarContagensNaoLidas(chatsCarregados);
    } catch (e) {
      if (_disposed) return;

      _erro = 'Não foi possível carregar os chats.';
      debugPrint('Erro ao carregar chats: $e');
    } finally {
      _carregando = false;
      _notificarListeners();
    }
  }

  // Mantém compatibilidade com chamadas antigas que usavam carregarChats().
  Future<void> carregarChats() => carregarChatsEContagens();

  Future<void> _carregarContagensNaoLidas(List<Chat> chats) async {
    _mensagensNaoLidas = {};

    try {
      final token = await _tokenStorage.read();

      if (_disposed) return;

      if (token == null || token.isEmpty) {
        return;
      }

      final payload = JwtDecoder.decode(token);
      final userId = _normalizarId(payload['sub']?.toString());

      if (userId == null) {
        return;
      }

      if (chats.isEmpty) {
        return;
      }

      final resultados = await Future.wait<MapEntry<String, int>>(
        chats.map((chat) async {
          try {
            final quantidade = await _repository.contarMensagensNaoLidas(
              chat.id,
              userId,
            );

            return MapEntry(chat.id, quantidade);
          } catch (e) {
            debugPrint(
              'Erro ao contar mensagens não lidas '
              'do chat ${chat.id}: $e',
            );

            return MapEntry(chat.id, 0);
          }
        }),
      );

      if (_disposed) return;

      _mensagensNaoLidas = Map.fromEntries(resultados);
    } catch (e) {
      debugPrint('Erro ao carregar contagens de mensagens: $e');
      _mensagensNaoLidas = {};
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
