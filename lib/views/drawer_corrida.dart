import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';

class DrawerCorrida extends StatelessWidget {
  final SolicitacaoCorrida corrida;

  final VoidCallback onIniciar;
  final VoidCallback onVoltar;
  final bool carregando;

  const DrawerCorrida({
    super.key,
    required this.corrida,
    required this.onIniciar,
    required this.onVoltar,
    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {
    final String nome = corrida.passageiroNome;
    final double? avaliacao = corrida.passageiroAvaliacao;
    final emAndamento = corrida.status.toUpperCase() == 'ANDAMENTO';
    final pagamento = switch (corrida.formaPagamento) {
      'DEBITO' => 'Débito',
      'CREDITO' => 'Crédito',
      'DINHEIRO' => 'Dinheiro',
      'PIX' => 'PIX',
      _ => 'Não informado',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Corrida',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.black,
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'PASSAGEIRO',
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

          const SizedBox(height: 18),
          Text(
            'Pagamento: $pagamento',
            style: const TextStyle(color: CupertinoColors.black),
          ),

          const Spacer(),

          _BotaoDrawer(
            texto: emAndamento ? 'Iniciar navegação' : 'Iniciar corrida',
            cor: CupertinoColors.systemBlue,
            onPressed: carregando ? null : onIniciar,
          ),

          const SizedBox(height: 24),

          _BotaoDrawer(
            texto: carregando ? 'Cancelando...' : 'Cancelar Corrida',
            cor: CupertinoColors.systemOrange,
            onPressed: carregando ? null : onVoltar,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _BotaoDrawer extends StatelessWidget {
  final String texto;
  final Color cor;
  final VoidCallback? onPressed;

  const _BotaoDrawer({
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
