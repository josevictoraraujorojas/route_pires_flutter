import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/viewmodel/chat_list_viewmodel.dart';
import 'package:route_pires_flutter/views/chat_view.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  late final ChatListViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    _viewModel = ChatListViewModel();

    _viewModel.carregarChats();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        if (_viewModel.carregando) {
          return const Center(child: CupertinoActivityIndicator());
        }

        if (_viewModel.erro != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle, size: 40),
                const SizedBox(height: 12),
                Text(_viewModel.erro!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                CupertinoButton(
                  onPressed: _viewModel.carregarChats,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        if (_viewModel.chats.isEmpty) {
          return const Center(child: Text('Você ainda não possui conversas.'));
        }

        return Column(
          children: [
            _buildCabecalho(),

            _buildBusca(),

            const SizedBox(height: 14),

            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _viewModel.chats.length,
                itemBuilder: (context, index) {
                  final chat = _viewModel.chats[index];

                  return _buildChatItem(chat);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCabecalho() {
    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Negociações',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),

          const Positioned(
            left: 16,
            child: Text(
              'Editar',
              style: TextStyle(fontSize: 16, color: CupertinoColors.systemBlue),
            ),
          ),

          const Positioned(
            right: 16,
            child: Icon(
              CupertinoIcons.square_pencil,
              size: 24,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusca() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          children: [
            SizedBox(width: 14),

            Icon(
              CupertinoIcons.search,
              size: 20,
              color: CupertinoColors.systemGrey,
            ),

            SizedBox(width: 12),

            Text(
              'Search',
              style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(dynamic chat) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => ChatView(
              chatId: chat.id,
              nomeParticipante: chat.nomeOutroParticipante,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8F2FF),
              ),
              child: const Icon(
                CupertinoIcons.person_fill,
                size: 23,
                color: Color(0xFF9DCCF8),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                chat.nomeOutroParticipante,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
