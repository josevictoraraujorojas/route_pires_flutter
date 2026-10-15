import 'package:flutter/cupertino.dart';

class NotificacoesPage extends StatelessWidget {
  const NotificacoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> notificacoesMock = [
      {'nome': 'João', 'data': '20/03/2025'},
      {'nome': 'Dany', 'data': '20/03/2025'},
      {'nome': 'Rachel', 'data': '20/03/2025'},
      {'nome': 'Luan', 'data': '20/03/2025'},
      {'nome': 'Pedro', 'data': '20/03/2025'},
      {'nome': 'Ari', 'data': '20/03/2025'},
    ];

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        previousPageTitle: 'Voltar',
        middle: Text(
          'Notificações',
          style: TextStyle(fontWeight: FontWeight.w400),
        ),
        border: null,
      ),
      child: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          itemCount: notificacoesMock.length,
          separatorBuilder: (context, index) => Container(
            height: 1,
            color: CupertinoColors.systemGrey5,
            margin: const EdgeInsets.symmetric(vertical: 16),
          ),
          itemBuilder: (context, index) {
            final notificacao = notificacoesMock[index];
            
            return Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0066FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.exclamationmark,
                      color: CupertinoColors.white,
                      size: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notificacao['nome']!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notificacao['data']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}