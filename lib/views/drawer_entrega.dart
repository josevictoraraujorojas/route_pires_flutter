import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';

class DrawerEntrega extends StatelessWidget {
  final SolicitacaoCorrida entrega;

  final VoidCallback onIniciar;
  final VoidCallback onVoltar;
  final bool carregando;

  const DrawerEntrega({
    super.key,
    required this.entrega,
    required this.onIniciar,
    required this.onVoltar,
    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {
    final String? descricao = entrega.descricaoCarga?.trim();

    final double? peso = entrega.pesoCarga;

    final bool fragil = entrega.cargaFragil ?? false;

    final String nome = entrega.passageiroNome;

    final double? avaliacao = entrega.passageiroAvaliacao;

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

          if (descricao != null && descricao.isNotEmpty) ...[
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
          ],

          Row(
            children: [
              _TipoEntrega(selecionado: fragil, texto: 'Frágil'),

              const SizedBox(width: 28),

              _TipoEntrega(selecionado: !fragil, texto: 'Comum'),
            ],
          ),

          const SizedBox(height: 18),

          if (peso != null) ...[
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
              '${peso.toStringAsFixed(peso == peso.roundToDouble() ? 0 : 1)}KG',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.black,
              ),
            ),

            const SizedBox(height: 18),
          ],

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

                  if (avaliacao != null)
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.star_fill,
                          size: 13,
                          color: CupertinoColors.systemBlue,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          avaliacao.toStringAsFixed(1),
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
            onPressed: carregando ? null : onIniciar,
          ),

          const SizedBox(height: 24),

          _BotaoEntrega(
            texto: carregando ? 'Cancelando...' : 'Cancelar Entrega',
            cor: CupertinoColors.systemOrange,
            onPressed: carregando ? null : onVoltar,
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
  final VoidCallback? onPressed;

  const _BotaoEntrega({
    required this.texto,
    required this.cor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final corEfetiva = onPressed == null ? CupertinoColors.systemGrey3 : cor;

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
            border: Border.all(color: corEfetiva, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),

          alignment: Alignment.center,

          child: Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: corEfetiva,
            ),
          ),
        ),
      ),
    );
  }
}
