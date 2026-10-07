import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/model/chat.dart';
import 'package:route_pires_flutter/repositories/chat_repository.dart';

class ChatListViewModel extends ChangeNotifier {
  final ChatRepository _repository;

  ChatListViewModel({ChatRepository? repository})
    : _repository = repository ?? ChatRepository();

  List<Chat> _chats = [];

  bool _carregando = false;

  String? _erro;

  List<Chat> get chats => _chats;

  bool get carregando => _carregando;

  String? get erro => _erro;

  Future<void> carregarChats() async {
    _carregando = true;
    _erro = null;

    notifyListeners();

    try {
      _chats = await _repository.listar();
    } catch (e) {
      _erro = 'Não foi possível carregar os chats.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}
