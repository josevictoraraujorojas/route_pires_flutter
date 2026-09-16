import 'package:flutter/cupertino.dart';

class DrawerEntrega extends StatelessWidget {
  final Map<String, dynamic> entrega;

  final VoidCallback onIniciar;
  final VoidCallback onVoltar;

  const DrawerEntrega({
    super.key,
    required this.entrega,
    required this.onIniciar,
    required this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    final String descricao =
        entrega['descricao'] ?? 'Perfeito, fácil de encontrar e perto de tudo.';

    final String peso = entrega['peso']?.toString() ?? '10KG';

    final String nome = entrega['nome'] ?? 'Passageiro';

    final String avaliacao = entrega['avaliacao']?.toString() ?? '4.8';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Entrega',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.black,
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'SOBRE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            descricao,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _TipoEntrega(
                selecionado: entrega['fragil'] == true,
                texto: 'Frágil',
              ),

              const SizedBox(width: 28),

              _TipoEntrega(
                selecionado: entrega['fragil'] != true,
                texto: 'Comum',
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Text(
            'PESO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            peso,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.black,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'SOLICITANTE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Container(
                width: 42,
                height: 42,

                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: const Icon(
                  CupertinoIcons.person_fill,
                  size: 25,
                  color: Color(0xFF9ED0FF),
                ),
              ),

              const SizedBox(width: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.black,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.star_fill,
                        size: 13,
                        color: CupertinoColors.systemBlue,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        avaliacao,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          _BotaoEntrega(
            texto: 'Aceitar Entrega',
            cor: CupertinoColors.systemBlue,
            onPressed: onIniciar,
          ),

          const SizedBox(height: 24),

          _BotaoEntrega(
            texto: 'Cancelar Entrega',
            cor: CupertinoColors.systemOrange,
            onPressed: onVoltar,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TipoEntrega extends StatelessWidget {
  final bool selecionado;
  final String texto;

  const _TipoEntrega({required this.selecionado, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,

          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selecionado
                ? CupertinoColors.systemBlue
                : CupertinoColors.systemGrey4,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          texto,
          style: const TextStyle(
            fontSize: 11,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }
}

class _BotaoEntrega extends StatelessWidget {
  final String texto;
  final Color cor;
  final VoidCallback onPressed;

  const _BotaoEntrega({
    required this.texto,
    required this.cor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,

      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,

        child: Container(
          width: double.infinity,
          height: 44,

          decoration: BoxDecoration(
            color: CupertinoColors.white,
            border: Border.all(color: cor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),

          alignment: Alignment.center,

          child: Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ),
      ),
    );
  }
}
