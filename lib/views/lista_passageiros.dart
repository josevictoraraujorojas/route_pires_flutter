import 'package:flutter/cupertino.dart';

class ListaPassageiros extends StatelessWidget {
  const ListaPassageiros({super.key});

  final List<Map<String, dynamic>> passageiros = const [
    {'nome': 'Haley James', 'avaliacao': 5},
    {'nome': 'Nathan Scott', 'avaliacao': 5},
    {'nome': 'Brooke Davis', 'avaliacao': 5},
    {'nome': 'Jamie Scott', 'avaliacao': 5},
    {'nome': 'Marvin McFadden', 'avaliacao': 5},
    {'nome': 'Antwon Taylor', 'avaliacao': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 0, bottom: 20),

      itemCount: passageiros.length,

      itemBuilder: (context, index) {
        final passageiro = passageiros[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),

          child: Row(
            children: [
              // ==========================================
              // FOTO
              // ==========================================

              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: const Icon(
                  CupertinoIcons.person_fill,
                  size: 30,
                  color: Color(0xFF9ED0FF),
                ),
              ),

              const SizedBox(width: 24),

              // ==========================================
              // NOME
              // ==========================================
              Expanded(
                child: Text(
                  passageiro['nome'],

                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.black,
                  ),
                ),
              ),

              // ==========================================
              // ESTRELAS
              // ==========================================
              Row(
                mainAxisSize: MainAxisSize.min,

                children: List.generate(passageiro['avaliacao'], (index) {
                  return const Icon(
                    CupertinoIcons.star_fill,
                    size: 11,
                    color: CupertinoColors.systemBlue,
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
