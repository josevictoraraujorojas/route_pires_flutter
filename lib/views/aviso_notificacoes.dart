import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/services/notificacoes_service.dart';

/// Solicitações novas chegam só por notificação; avisa quem está online sem ela.
class AvisoNotificacoes extends StatelessWidget {
  const AvisoNotificacoes({super.key, required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final notificacoes = NotificacoesService();
    return AnimatedBuilder(
      animation: notificacoes,
      builder: (context, _) {
        if (!online || notificacoes.ativo || notificacoes.ativando) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E5),
            border: Border.all(color: const Color(0xFFFFD8A8)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Notificações desativadas: novas solicitações só aparecem '
                  'ao abrir o app.',
                  style: TextStyle(color: Color(0xFF7A4B00), fontSize: 12),
                ),
              ),
              if (notificacoes.disponivel)
                CupertinoButton(
                  padding: const EdgeInsets.only(left: 12),
                  minimumSize: const Size(44, 44),
                  onPressed: notificacoes.ativar,
                  child: const Text('Ativar', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
        );
      },
    );
  }
}
