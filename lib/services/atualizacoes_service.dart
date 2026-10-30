import 'dart:async';

import 'package:flutter/foundation.dart';

class EventoAtualizacao {
  const EventoAtualizacao(this.dados);
  final Map<String, dynamic> dados;
  String? get chatId => dados['chatId'] as String?;
  String? get corridaId => dados['corridaId'] as String?;
  bool get sincronizacao => dados['tipo'] == 'SINCRONIZAR';
  bool get corridas => sincronizacao || dados['tipo'] == 'CORRIDAS_ATUALIZADAS';
  bool get chats =>
      sincronizacao ||
      const {
        'CHATS_ATUALIZADOS',
        'MENSAGENS_ATUALIZADAS',
      }.contains(dados['tipo']);
}

/// Canal único para as telas; não depende de plugins nem de uma conversa aberta.
class AtualizacoesService extends ChangeNotifier {
  AtualizacoesService._();
  static final _instance = AtualizacoesService._();
  factory AtualizacoesService() => _instance;
  final _eventos = StreamController<EventoAtualizacao>.broadcast();
  Stream<EventoAtualizacao> get eventos => _eventos.stream;
  String? usuarioId;
  bool appAtivo = true;
  bool _porEventos = false;
  bool get porEventos => _porEventos;

  void definirRecebimento(bool ativo) {
    if (_porEventos == ativo) return;
    _porEventos = ativo;
    notifyListeners();
    sincronizar();
  }

  void publicar(Map<String, dynamic> dados) =>
      _eventos.add(EventoAtualizacao(dados));
  void sincronizar() => publicar(const {'tipo': 'SINCRONIZAR'});
}

/// Agrupa rajadas e preserva um aviso recebido enquanto há um GET em andamento.
class AtualizacaoPorEvento {
  AtualizacaoPorEvento({
    required bool Function(EventoAtualizacao) aceita,
    required this.atualizar,
    this.ocupado,
    this.habilitado,
    this.proximaTentativa,
  }) {
    _assinatura = AtualizacoesService().eventos
        .where(aceita)
        .listen((_) => solicitar());
  }
  final Future<void> Function() atualizar;
  final bool Function()? ocupado;
  final bool Function()? habilitado;
  final DateTime? Function()? proximaTentativa;
  late final StreamSubscription<EventoAtualizacao> _assinatura;
  Timer? _timer;
  bool _executando = false;
  bool _pendente = false;
  bool _disposed = false;

  void solicitar() {
    if (_disposed) return;
    _pendente = true;
    if (!_executando && _timer == null) {
      _timer = Timer(const Duration(milliseconds: 300), _executar);
    }
  }

  Future<void> _executar() async {
    _timer = null;
    if (_disposed || !_pendente || !AtualizacoesService().appAtivo) return;
    if (habilitado?.call() == false) {
      _timer = Timer(const Duration(seconds: 1), _executar);
      return;
    }
    final proxima = proximaTentativa?.call();
    if (proxima != null && proxima.isAfter(DateTime.now())) {
      _timer = Timer(proxima.difference(DateTime.now()), _executar);
      return;
    }
    if (ocupado?.call() == true) {
      _timer = Timer(const Duration(milliseconds: 200), _executar);
      return;
    }
    _pendente = false;
    _executando = true;
    try {
      await atualizar();
    } catch (_) {
      debugPrint('Não foi possível atualizar os dados após o aviso.');
    } finally {
      _executando = false;
      if (proximaTentativa?.call() case final proxima?
          when proxima.isAfter(DateTime.now())) {
        _pendente = true;
      }
      if (_pendente && !_disposed) solicitar();
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_assinatura.cancel());
  }
}
