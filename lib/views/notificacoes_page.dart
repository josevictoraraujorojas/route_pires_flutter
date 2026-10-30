import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/services/notificacoes_service.dart';

class NotificacoesPage extends StatelessWidget {
  const NotificacoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificacoes = NotificacoesService();
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Notificações')),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: notificacoes,
          builder: (context, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.bell, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    notificacoes.ativo
                        ? 'Os alertas de corridas e mensagens estão ativados.'
                        : notificacoes.disponivel
                        ? 'Ative os alertas para receber novidades sobre suas corridas e mensagens.'
                        : 'Os alertas ainda não estão disponíveis neste dispositivo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (notificacoes.ativando)
                    const CupertinoActivityIndicator()
                  else if (notificacoes.disponivel && !notificacoes.ativo)
                    CupertinoButton.filled(
                      onPressed: notificacoes.ativar,
                      child: const Text('Ativar notificações'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
