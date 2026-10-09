import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/model/mensagem.dart';
import 'package:route_pires_flutter/viewmodel/chat_viewmodel.dart';

class ChatView extends StatelessWidget {
  final String chatId;
  final String nomeParticipante;
  final DateTime? dataCriacao;
  final DateTime? dataEncerramento;

  const ChatView({
    super.key,
    required this.chatId,
    required this.nomeParticipante,
    this.dataCriacao,
    this.dataEncerramento,
  });

  bool get encerrado => dataEncerramento != null;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatViewModel>(
      create: (_) =>
          ChatViewModel(chatId: chatId, encerrado: encerrado)..inicializar(),
      child: _ChatViewContent(
        nomeParticipante: nomeParticipante,
        dataCriacao: dataCriacao,
        dataEncerramento: dataEncerramento,
      ),
    );
  }
}

class _ChatViewContent extends StatefulWidget {
  final String nomeParticipante;
  final DateTime? dataCriacao;
  final DateTime? dataEncerramento;

  const _ChatViewContent({
    required this.nomeParticipante,
    this.dataCriacao,
    this.dataEncerramento,
  });

  @override
  State<_ChatViewContent> createState() => _ChatViewContentState();
}

class _ChatViewContentState extends State<_ChatViewContent> {
  final TextEditingController _mensagemController = TextEditingController();

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  String _formatarData(DateTime? data) {
    if (data == null) {
      return '';
    }

    final local = data.toLocal();

    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final ano = local.year.toString();
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano $hora:$minuto';
  }

  void _enviarMensagem() {
    final viewModel = context.read<ChatViewModel>();

    final enviada = viewModel.enviarMensagem(_mensagemController.text);

    if (enviada) {
      _mensagemController.clear();
    }
  }

  IconData _iconeStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        return Icons.access_time;

      case 'VISUALIZADA':
        return Icons.done_all;

      case 'ENVIADA':
      default:
        return Icons.done;
    }
  }

  Color _corStatus(String status) {
    if (status.toUpperCase() == 'VISUALIZADA') {
      return const Color(0xFFB3E5FC);
    }

    return CupertinoColors.white.withOpacity(0.75);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();

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
            _buildInformacoesChat(),
            Expanded(child: _buildMensagens(viewModel)),
            if (viewModel.encerrado)
              _buildChatEncerrado()
            else
              _buildCampoMensagem(),
          ],
        ),
      ),
    );
  }

  Widget _buildInformacoesChat() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          if (widget.dataCriacao != null)
            Text(
              'Chat criado em '
              '${_formatarData(widget.dataCriacao)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          if (widget.dataEncerramento != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Chat encerrado em '
                '${_formatarData(widget.dataEncerramento)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMensagens(ChatViewModel viewModel) {
    if (viewModel.carregandoMensagens) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (viewModel.erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(viewModel.erro!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: () {
                  context.read<ChatViewModel>().carregarMensagens();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final mensagens = viewModel.mensagens;

    if (mensagens.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma mensagem ainda',
          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: mensagens.length,
      itemBuilder: (context, index) {
        return _buildMensagem(mensagens[index], viewModel);
      },
    );
  }

  Widget _buildMensagem(Mensagem mensagem, ChatViewModel viewModel) {
    final minhaMensagem = viewModel.ehMinhaMensagem(mensagem);

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
        child: Column(
          crossAxisAlignment: minhaMensagem
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensagem.conteudo,
              style: TextStyle(
                fontSize: 16,
                color: minhaMensagem
                    ? CupertinoColors.white
                    : CupertinoColors.label,
              ),
            ),
            if (minhaMensagem)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  _iconeStatus(mensagem.status),
                  size: 14,
                  color: _corStatus(mensagem.status),
                ),
              ),
          ],
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
              onSubmitted: (_) => _enviarMensagem(),
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

  Widget _buildChatEncerrado() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Esta conversa foi encerrada.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
      ),
    );
  }
}
