import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/model/chat.dart';
import 'package:route_pires_flutter/viewmodel/chat_list_viewmodel.dart';
import 'package:route_pires_flutter/views/chat_view.dart';

class ChatListView extends StatelessWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatListViewModel>(
      create: (_) => ChatListViewModel()..carregarChatsEContagens(),
      child: const _ChatListViewContent(),
    );
  }
}

class _ChatListViewContent extends StatefulWidget {
  const _ChatListViewContent();

  @override
  State<_ChatListViewContent> createState() => _ChatListViewContentState();
}

class _ChatListViewContentState extends State<_ChatListViewContent> {
  final TextEditingController _buscaController = TextEditingController();

  bool _encerradasExpandida = true;
  String _nomeBusca = '';

  DateTime? _dataCriacao;
  DateTime? _dataEncerramento;

  @override
  void dispose() {
    _buscaController.dispose();
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

  String _formatarApenasData(DateTime? data) {
    if (data == null) {
      return '';
    }

    final local = data.toLocal();

    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final ano = local.year.toString();

    return '$dia/$mes/$ano';
  }

  bool _mesmoDia(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }

    final dataA = a.toLocal();
    final dataB = b.toLocal();

    return dataA.year == dataB.year &&
        dataA.month == dataB.month &&
        dataA.day == dataB.day;
  }

  List<Chat> _filtrarChats(List<Chat> chats) {
    final nome = _nomeBusca.trim().toLowerCase();

    return chats.where((chat) {
      if (nome.isNotEmpty &&
          !chat.nomeOutroParticipante.toLowerCase().contains(nome)) {
        return false;
      }

      if (_dataCriacao != null && !_mesmoDia(chat.dataCriacao, _dataCriacao)) {
        return false;
      }

      if (_dataEncerramento != null &&
          !_mesmoDia(chat.dataEncerramento, _dataEncerramento)) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _selecionarData(bool criacao) async {
    DateTime selecionada =
        (criacao ? _dataCriacao : _dataEncerramento) ?? DateTime.now();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return Container(
          height: 280,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selecionada,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (data) {
                    selecionada = data;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    setState(() {
      if (criacao) {
        _dataCriacao = selecionada;
      } else {
        _dataEncerramento = selecionada;
      }
    });
  }

  Future<void> _recarregarChats() async {
    await context.read<ChatListViewModel>().carregarChatsEContagens();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatListViewModel>();

    if (viewModel.carregando) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (viewModel.erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Ocorreu um erro',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(viewModel.erro!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: _recarregarChats,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (viewModel.chats.isEmpty) {
      return const Center(child: Text('Você ainda não possui conversas.'));
    }

    final chatsFiltrados = _filtrarChats(viewModel.chats);

    final chatsAtivos = chatsFiltrados
        .where((chat) => !chat.encerrado)
        .toList();

    final chatsEncerrados = chatsFiltrados
        .where((chat) => chat.encerrado)
        .toList();

    return Column(
      children: [
        _buildCabecalho(),
        _buildBusca(),
        const SizedBox(height: 10),
        Expanded(child: _buildLista(chatsAtivos, chatsEncerrados)),
      ],
    );
  }

  Widget _buildLista(List<Chat> chatsAtivos, List<Chat> chatsEncerrados) {
    if (chatsAtivos.isEmpty && chatsEncerrados.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma conversa encontrada.',
          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 15),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (chatsAtivos.isNotEmpty) ...[
          _buildTituloSecao('Ativas'),
          ...chatsAtivos.map((chat) => _buildChatItem(chat, encerrado: false)),
        ],
        if (chatsEncerrados.isNotEmpty) ...[
          if (chatsAtivos.isNotEmpty) const SizedBox(height: 12),
          _buildTituloEncerradas(chatsEncerrados.length),
          if (_encerradasExpandida)
            ...chatsEncerrados.map(
              (chat) => _buildChatItem(chat, encerrado: true),
            ),
        ],
      ],
    );
  }

  Widget _buildCabecalho() {
    return const SizedBox(
      height: 58,
      child: Center(
        child: Text(
          'Negociações',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
      ),
    );
  }

  Widget _buildBusca() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          CupertinoTextField(
            controller: _buscaController,
            placeholder: 'Nome do participante',
            onChanged: (valor) {
              setState(() {
                _nomeBusca = valor;
              });
            },
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            suffix: _nomeBusca.isNotEmpty
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _buscaController.clear();

                      setState(() {
                        _nomeBusca = '';
                      });
                    },
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 17,
                      color: CupertinoColors.systemGrey,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildFiltroData(
                  'Criação',
                  _dataCriacao,
                  () => _selecionarData(true),
                  () {
                    setState(() {
                      _dataCriacao = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFiltroData(
                  'Encerramento',
                  _dataEncerramento,
                  () => _selecionarData(false),
                  () {
                    setState(() {
                      _dataEncerramento = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroData(
    String titulo,
    DateTime? data,
    VoidCallback onPressed,
    VoidCallback onClear,
  ) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minSize: 38,
              alignment: Alignment.centerLeft,
              onPressed: onPressed,
              child: Text(
                data == null ? titulo : '$titulo: ${_formatarApenasData(data)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.label,
                ),
              ),
            ),
          ),
          if (data != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 30,
              onPressed: onClear,
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 15,
                color: CupertinoColors.systemGrey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTituloSecao(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 6),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  Widget _buildTituloEncerradas(int quantidade) {
    return CupertinoButton(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 6),
      onPressed: () {
        setState(() {
          _encerradasExpandida = !_encerradasExpandida;
        });
      },
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Encerradas ($quantidade)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          Icon(
            _encerradasExpandida
                ? CupertinoIcons.chevron_up
                : CupertinoIcons.chevron_down,
            size: 16,
            color: CupertinoColors.systemGrey,
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Chat chat, {required bool encerrado}) {
    final quantidadeNaoLida = context.select<ChatListViewModel, int>(
      (viewModel) => viewModel.mensagensNaoLidas[chat.id] ?? 0,
    );

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () async {
        await Navigator.push<void>(
          context,
          CupertinoPageRoute<void>(
            builder: (_) => ChatView(
              chatId: chat.id,
              nomeParticipante: chat.nomeOutroParticipante,
              dataCriacao: chat.dataCriacao,
              dataEncerramento: chat.dataEncerramento,
            ),
          ),
        );

        if (!mounted) return;

        await _recarregarChats();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: encerrado
                    ? CupertinoColors.systemGrey5
                    : const Color(0xFFE8F2FF),
              ),
              child: Icon(
                CupertinoIcons.person_fill,
                size: 23,
                color: encerrado
                    ? CupertinoColors.systemGrey
                    : const Color(0xFF9DCCF8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.nomeOutroParticipante,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: encerrado
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.label,
                          ),
                        ),
                      ),
                      if (quantidadeNaoLida > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1677E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            quantidadeNaoLida > 99
                                ? '99+'
                                : '$quantidadeNaoLida',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (chat.dataCriacao != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'Criado: ${_formatarData(chat.dataCriacao)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  if (encerrado && chat.dataEncerramento != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Encerrado: '
                        '${_formatarData(chat.dataEncerramento)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
