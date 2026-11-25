import 'package:flutter/cupertino.dart';

/// Valores compatíveis com o enum Servico utilizado pela API.
class ServicosMototaxista {
  static const transportePassageiro = 'TRANSPORTE_PASSAGEIRO';
  static const frete = 'FRETE';

  static const opcoes = <(String, String)>[
    (transportePassageiro, 'Transporte de passageiros'),
    (frete, 'Frete (inclui frete simples)'),
  ];
}

class SeletorServicos extends StatelessWidget {
  const SeletorServicos({
    super.key,
    required this.selecionados,
    required this.onChanged,
    this.habilitado = true,
  });

  final Set<String> selecionados;
  final ValueChanged<Set<String>> onChanged;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Serviços oferecidos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Selecione as modalidades que deseja atender. '
          'É necessário escolher pelo menos uma.',
          style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 12),
        for (final opcao in ServicosMototaxista.opcoes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(opcao.$2)),
                CupertinoSwitch(
                  value: selecionados.contains(opcao.$1),
                  onChanged: !habilitado
                      ? null
                      : (valor) {
                          final novos = <String>{...selecionados};
                          if (valor) {
                            novos.add(opcao.$1);
                          } else {
                            novos.remove(opcao.$1);
                          }
                          onChanged(novos);
                        },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
