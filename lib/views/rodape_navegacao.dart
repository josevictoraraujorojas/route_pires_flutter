import 'package:flutter/cupertino.dart';

class RodapeNavegacao extends StatelessWidget {
  const RodapeNavegacao({super.key, this.selecionado = 0});

  final int selecionado;

  @override
  Widget build(BuildContext context) {
    const itens = [
      (CupertinoIcons.compass, 'Corrida'),
      (CupertinoIcons.person_2, 'Avaliações'),
      (CupertinoIcons.chat_bubble_2, 'Negociação'),
      (CupertinoIcons.person, 'Perfil'),
    ];

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8E9F0))),
      ),
      child: Row(
        children: itens.indexed.map((item) {
          final (index, dados) = item;
          final (icone, texto) = dados;
          final ativo = index == selecionado;
          final cor = ativo ? const Color(0xFF006FFD) : const Color(0xFFC5C6CC);

          return Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.only(top: 7),
              onPressed: () {},
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icone, size: 18, color: cor),
                  const SizedBox(height: 3),
                  Text(
                    texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cor, fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
