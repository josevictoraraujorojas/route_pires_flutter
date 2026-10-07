import 'package:flutter/cupertino.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:route_pires_flutter/config/token_storage.dart';
import 'package:route_pires_flutter/model/mensagem.dart';
import 'package:route_pires_flutter/repositories/chat_repository.dart';
import 'package:route_pires_flutter/repositories/chat_websocket_repository.dart';

class ChatView extends StatefulWidget {
  final String chatId;
  final String nomeParticipante;

  const ChatView({
    super.key,
    required this.chatId,
    required this.nomeParticipante,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TokenStorage _tokenStorage = createTokenStorage();

  final ChatRepository _chatRepository = ChatRepository();

  final ChatWebSocketRepository _webSocket = ChatWebSocketRepository();

  final TextEditingController _mensagemController = TextEditingController();

  final List<Mensagem> _mensagens = [];

  bool _carregandoMensagens = true;

  String? _meuUsuarioId;

  @override
  void initState() {
    super.initState();

    _carregarMensagens();
    _conectar();
  }

  Future<void> _carregarMensagens() async {
    try {
      final mensagens = await _chatRepository.listarMensagens(widget.chatId);

      if (!mounted) return;

      setState(() {
        _mensagens
          ..clear()
          ..addAll(mensagens);

        _carregandoMensagens = false;
      });
    } catch (e) {
      print('Erro ao carregar mensagens: $e');

      if (!mounted) return;

      setState(() {
        _carregandoMensagens = false;
      });
    }
  }

  Future<void> _conectar() async {
    final token = await _tokenStorage.read();

    if (token == null || token.isEmpty) {
      print('JWT não encontrado');
      return;
    }

    final payload = JwtDecoder.decode(token);

    _meuUsuarioId = payload['sub']?.toString();

    print('JWT encontrado');
    print('Usuário logado: $_meuUsuarioId');
    print('Conectando ao chat: ${widget.chatId}');

    _webSocket.conectar(
      token: token,
      chatId: widget.chatId,
      onMensagem: (mensagem) {
        print('MENSAGEM RECEBIDA: $mensagem');

        if (!mounted) return;

        final novaMensagem = Mensagem.fromJson(mensagem);

        setState(() {
          _mensagens.add(novaMensagem);
        });
      },
    );
  }

  void _enviarMensagem() {
    final conteudo = _mensagemController.text.trim();

    if (conteudo.isEmpty) {
      return;
    }

    _webSocket.enviarMensagem(chatId: widget.chatId, conteudo: conteudo);

    _mensagemController.clear();
  }

  @override
  void dispose() {
    _webSocket.desconectar();
    _mensagemController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.nomeParticipante,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMensagens()),
            _buildCampoMensagem(),
          ],
        ),
      ),
    );
  }

  Widget _buildMensagens() {
    if (_carregandoMensagens) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_mensagens.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma mensagem ainda',
          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _mensagens.length,
      itemBuilder: (context, index) {
        final mensagem = _mensagens[index];

        return _buildMensagem(mensagem);
      },
    );
  }

  Widget _buildMensagem(Mensagem mensagem) {
    final minhaMensagem = mensagem.remetente == _meuUsuarioId;

    return Align(
      alignment: minhaMensagem ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: minhaMensagem
              ? CupertinoColors.systemBlue
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          mensagem.conteudo,
          style: TextStyle(
            fontSize: 16,
            color: minhaMensagem
                ? CupertinoColors.white
                : CupertinoColors.label,
          ),
        ),
      ),
    );
  }

  Widget _buildCampoMensagem() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _mensagemController,
              placeholder: 'Mensagem',
              minLines: 1,
              maxLines: 4,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(20),
              ),
              onSubmitted: (_) {
                _enviarMensagem();
              },
            ),
          ),

          const SizedBox(width: 8),

          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _enviarMensagem,
            child: const Icon(
              CupertinoIcons.arrow_up_circle_fill,
              size: 32,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ],
      ),
    );
  }
}
