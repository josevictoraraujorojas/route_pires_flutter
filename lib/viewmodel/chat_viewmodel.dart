import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/model/mensagem.dart';
import 'package:route_pires_flutter/repositories/chat_repository.dart';
import 'package:route_pires_flutter/services/atualizacoes_service.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    required this.chatId,
    required this.encerrado,
    ChatRepository? chatRepository,
  }) : _repository = chatRepository ?? ChatRepository() {
    _eventos = AtualizacaoPorEvento(
      aceita: (e) => e.sincronizacao || (e.chats && e.chatId == chatId),
      atualizar: () => carregarMensagens(silenciosa: true),
      ocupado: () => _consultando || _enviando,
      habilitado: () => _inicializado,
    );
    AtualizacoesService().addListener(_sincronizarFallback);
  }

  final String chatId;
  final ChatRepository _repository;
  late final AtualizacaoPorEvento _eventos;
  Timer? _fallback;
  final List<Mensagem> _mensagens = [];
  bool encerrado;
  bool _carregandoMensagens = true;
  bool _consultando = false;
  bool _enviando = false;
  bool _inicializado = false;
  bool _disposed = false;
  String? _destinatarioId;
  String? _erro;

  bool get enviando => _enviando;
  List<Mensagem> get mensagens => List.unmodifiable(_mensagens);
  bool get carregandoMensagens => _carregandoMensagens;
  String? get erro => _erro;

  void _avisar() {
    if (!_disposed) notifyListeners();
  }

  Future<void> inicializar() async {
    if (_inicializado) return;
    _inicializado = true;
    await carregarMensagens();
    if (!_disposed) _sincronizarFallback();
  }

  void _sincronizarFallback() {
    _fallback?.cancel();
    _fallback = null;
    if (_disposed || encerrado || AtualizacoesService().porEventos) return;
    _fallback = Timer.periodic(const Duration(seconds: 15), (_) {
      if (AtualizacoesService().appAtivo) _eventos.solicitar();
    });
  }

  Future<void> carregarMensagens({bool silenciosa = false}) async {
    if (_disposed) return;
    if (_consultando) {
      _eventos.solicitar();
      return;
    }
    _consultando = true;
    if (!silenciosa) _carregandoMensagens = true;
    _erro = null;
    _avisar();
    try {
      final chat = await _repository.buscar(chatId);
      if (_disposed) return;
      encerrado = chat.encerrado;
      final meuId = AtualizacoesService().usuarioId;
      _destinatarioId = null;
      if (meuId != null) {
        for (final id in chat.participantes) {
          if (id != meuId) {
            _destinatarioId = id;
            break;
          }
        }
      }
      final carregadas = await _repository.listarMensagens(chatId);
      if (_disposed) return;
      _mensagens
        ..clear()
        ..addAll(carregadas);
      final recebidas = carregadas.any(
        (m) => m.remetente.split('/').last != meuId && m.status == 'ENVIADA',
      );
      if (recebidas) {
        await marcarMensagensVisualizadas();
      }
      _sincronizarFallback();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) encerrado = true;
      _erro = 'Não foi possível carregar a conversa.';
    } catch (_) {
      _erro = 'Não foi possível carregar as mensagens.';
    } finally {
      _consultando = false;
      _carregandoMensagens = false;
      _avisar();
    }
  }

  Future<void> marcarMensagensVisualizadas() async {
    try {
      await _repository.marcarMensagensVisualizadas(chatId);
    } catch (_) {
      debugPrint('Não foi possível confirmar a leitura.');
    }
  }

  Future<bool> enviarMensagem(String conteudo) async {
    final texto = conteudo.trim();
    final destinatario = _destinatarioId;
    if (encerrado || _enviando || texto.isEmpty || destinatario == null) {
      return false;
    }
    _enviando = true;
    _erro = null;
    _avisar();
    try {
      final mensagem = await _repository.enviarMensagem(
        chatId: chatId,
        destinatario: destinatario,
        conteudo: texto,
      );
      if (_disposed) return false;
      final indice = _mensagens.indexWhere((m) => m.id == mensagem.id);
      if (indice < 0) {
        _mensagens.add(mensagem);
      } else {
        _mensagens[indice] = mensagem;
      }
      return true;
    } catch (_) {
      _erro = 'Não foi possível enviar a mensagem. Tente novamente.';
      return false;
    } finally {
      _enviando = false;
      _avisar();
    }
  }

  bool ehMinhaMensagem(Mensagem mensagem) =>
      AtualizacoesService().usuarioId != null &&
      mensagem.remetente.split('/').last == AtualizacoesService().usuarioId;

  @override
  void dispose() {
    _disposed = true;
    _eventos.dispose();
    _fallback?.cancel();
    AtualizacoesService().removeListener(_sincronizarFallback);
    super.dispose();
  }
}
