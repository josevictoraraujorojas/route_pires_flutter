import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:route_pires_flutter/config/token_storage.dart';
import 'package:route_pires_flutter/model/chat.dart';
import 'package:route_pires_flutter/repositories/chat_repository.dart';
import 'package:route_pires_flutter/services/atualizacoes_service.dart';

class ChatListViewModel extends ChangeNotifier {
  final ChatRepository _repository;
  final TokenStorage _tokenStorage;

  ChatListViewModel({ChatRepository? repository, TokenStorage? tokenStorage})
    : _repository = repository ?? ChatRepository(),
      _tokenStorage = tokenStorage ?? createTokenStorage() {
    _eventos = AtualizacaoPorEvento(
      aceita: (evento) => evento.chats,
      atualizar: carregarChatsEContagens,
      ocupado: () => _atualizacaoEmAndamento,
    );
  }

  late final AtualizacaoPorEvento _eventos;

  List<Chat> _chats = [];
  Map<String, int> _mensagensNaoLidas = {};

  bool _carregando = true;
  bool _atualizacaoEmAndamento = false;
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
    // Evita requisições simultâneas.
    if (_atualizacaoEmAndamento || _disposed) return;

    _atualizacaoEmAndamento = true;

    // Só exibe o carregamento central na primeira consulta.
    if (_chats.isEmpty) {
      _carregando = true;
    }

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
      _atualizacaoEmAndamento = false;
      _carregando = false;
      _notificarListeners();
    }
  }

  // Mantém compatibilidade com chamadas antigas.
  Future<void> carregarChats() => carregarChatsEContagens();

  Future<void> _carregarContagensNaoLidas(List<Chat> chats) async {
    try {
      var userId = AtualizacoesService().usuarioId;
      final token = userId == null ? await _tokenStorage.read() : null;

      if (_disposed) return;

      if (userId == null && (token == null || token.isEmpty)) {
        _mensagensNaoLidas = {};
        return;
      }

      if (userId == null) {
        final payload = JwtDecoder.decode(token!);
        userId = _normalizarId(payload['sub']?.toString());
      }

      if (userId == null || chats.isEmpty) {
        _mensagensNaoLidas = {};
        return;
      }

      final resultados = await Future.wait<MapEntry<String, int>>(
        chats.map((chat) async {
          try {
            final quantidade = await _repository.contarMensagensNaoLidas(
              chat.id,
              userId!,
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

      // Preserva as contagens anteriores se a consulta falhar.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _eventos.dispose();
    super.dispose();
  }
}
