import 'package:flutter/cupertino.dart';

class ListaPassageiros extends StatelessWidget {
  final Function(Map<String, dynamic>) onPassageiroSelecionado;

  const ListaPassageiros({super.key, required this.onPassageiroSelecionado});

  // ============================================================
  // LISTA DE SOLICITAÇÕES
  // ============================================================

  final List<Map<String, dynamic>> passageiros = const [
    {
      'nome': 'Haley James',
      'avaliacao': 5,
      'tipo': 'corrida',

      // ----------------------------------------------------------
      // LOCAL DO CLIENTE
      // Centro
      // ----------------------------------------------------------
      'latitude_cliente': -17.3015,
      'longitude_cliente': -48.2765,

      // ----------------------------------------------------------
      // DESTINO FINAL
      // Jardim Guanabara
      // ----------------------------------------------------------
      'latitude_destino': -17.3075,
      'longitude_destino': -48.2705,
    },

    {
      'nome': 'Nathan Scott',
      'avaliacao': 5,
      'tipo': 'entrega',

      // ----------------------------------------------------------
      // LOCAL DO CLIENTE
      // Alto da Baronesa
      // ----------------------------------------------------------
      'latitude_cliente': -17.2958,
      'longitude_cliente': -48.2740,

      // ----------------------------------------------------------
      // DESTINO FINAL
      // Parque Santana
      // ----------------------------------------------------------
      'latitude_destino': -17.3105,
      'longitude_destino': -48.2835,
    },

    {
      'nome': 'Brooke Davis',
      'avaliacao': 3,
      'tipo': 'corrida',

      // ----------------------------------------------------------
      // LOCAL DO CLIENTE
      // Jardim Guanabara
      // ----------------------------------------------------------
      'latitude_cliente': -17.3075,
      'longitude_cliente': -48.2705,

      // ----------------------------------------------------------
      // DESTINO FINAL
      // Jardim JK
      // ----------------------------------------------------------
      'latitude_destino': -17.2965,
      'longitude_destino': -48.2860,
    },

    {
      'nome': 'Jamie Scott',
      'avaliacao': 5,
      'tipo': 'entrega',

      // ----------------------------------------------------------
      // LOCAL DO CLIENTE
      // Parque Santana
      // ----------------------------------------------------------
      'latitude_cliente': -17.3105,
      'longitude_cliente': -48.2835,

      // ----------------------------------------------------------
      // DESTINO FINAL
      // Setor Industrial
      // ----------------------------------------------------------
      'latitude_destino': -17.3135,
      'longitude_destino': -48.2725,
    },

    {
      'nome': 'Marvin McFadden',
      'avaliacao': 5,
      'tipo': 'corrida',

      // ----------------------------------------------------------
      // LOCAL DO CLIENTE
      // Jardim JK
      // ----------------------------------------------------------
      'latitude_cliente': -17.2965,
      'longitude_cliente': -48.2860,

      // ----------------------------------------------------------
      // DESTINO FINAL
      // Centro
      // ----------------------------------------------------------
      'latitude_destino': -17.3015,
      'longitude_destino': -48.2765,
    },

    {
      'nome': 'Antwon Taylor',
      'avaliacao': 5,
      'tipo': 'entrega',

      // ----------------------------------------------------------
      // LOCAL DO CLIENTE
      // Setor Industrial
      // ----------------------------------------------------------
      'latitude_cliente': -17.3135,
      'longitude_cliente': -48.2725,

      // ----------------------------------------------------------
      // DESTINO FINAL
      // Alto da Baronesa
      // ----------------------------------------------------------
      'latitude_destino': -17.2958,
      'longitude_destino': -48.2740,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 0, bottom: 20),

      itemCount: passageiros.length,

      itemBuilder: (context, index) {
        final passageiro = passageiros[index];

        final String nome = passageiro['nome'];
        final int avaliacao = passageiro['avaliacao'];
        final String tipo = passageiro['tipo'];

        return GestureDetector(
          onTap: () {
            // Envia TODOS os dados da solicitação
            // para a página principal.
            onPassageiroSelecionado(passageiro);
          },

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),

            child: Row(
              children: [
                // ==================================================
                // ÍCONE
                // ==================================================

                Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: Icon(
                    tipo == 'corrida'
                        ? CupertinoIcons.person_fill
                        : CupertinoIcons.cube_box_fill,

                    size: 30,

                    color: const Color(0xFF9ED0FF),
                  ),
                ),

                const SizedBox(width: 24),

                // ==================================================
                // INFORMAÇÕES
                // ==================================================
                Expanded(
                  child: Column(
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

                      const SizedBox(height: 4),

                      Text(
                        tipo == 'corrida' ? 'Corrida' : 'Entrega',

                        style: const TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // AVALIAÇÃO
                // ==================================================
                Row(
                  mainAxisSize: MainAxisSize.min,

                  children: List.generate(avaliacao, (index) {
                    return const Icon(
                      CupertinoIcons.star_fill,
                      size: 11,
                      color: CupertinoColors.systemBlue,
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
