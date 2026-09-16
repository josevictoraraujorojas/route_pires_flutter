import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';

class ListaPassageiros extends StatelessWidget {
  final List<SolicitacaoCorrida> solicitacoes;
  final ValueChanged<SolicitacaoCorrida> onPassageiroSelecionado;
  final bool carregando;
  final String? erro;

  const ListaPassageiros({
    super.key,
    required this.solicitacoes,
    required this.onPassageiroSelecionado,
    this.carregando = false,
    this.erro,
  });

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            erro!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: CupertinoColors.systemRed),
          ),
        ),
      );
    }

    if (solicitacoes.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma solicitação no momento',
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 0, bottom: 20),

      itemCount: solicitacoes.length,

      itemBuilder: (context, index) {
        final solicitacao = solicitacoes[index];

        return GestureDetector(
          onTap: () {
            onPassageiroSelecionado(solicitacao);
          },

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),

            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: Icon(
                    solicitacao.ehEntrega
                        ? CupertinoIcons.cube_box_fill
                        : CupertinoIcons.person_fill,

                    size: 30,

                    color: const Color(0xFF9ED0FF),
                  ),
                ),

                const SizedBox(width: 24),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        solicitacao.passageiroNome,

                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        solicitacao.ehEntrega ? 'Entrega' : 'Corrida',

                        style: const TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),

                if (solicitacao.passageiroAvaliacao != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,

                    children: List.generate(
                      solicitacao.passageiroAvaliacao!.round().clamp(0, 5),
                      (index) => const Icon(
                        CupertinoIcons.star_fill,
                        size: 11,
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
