import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/model/corrida_response.dart';

class PrevisaoChegada extends StatelessWidget {
  const PrevisaoChegada({super.key, required this.corrida});

  final CorridaResponse? corrida;

  @override
  Widget build(BuildContext context) {
    final atual = corrida;
    if (atual?.status?.toUpperCase() != 'ANDAMENTO') {
      return const SizedBox.shrink();
    }
    if (atual?.pontoAtual == 1) {
      return const Text('Em viagem para o destino');
    }
    final segundos = atual?.tempoRestanteSegundos;
    final metros = atual?.distanciaRestanteMetros;
    final atualizadoEm = atual?.estimativaAtualizadaEm;
    final idade = atualizadoEm == null
        ? null
        : DateTime.now().toUtc().difference(atualizadoEm);
    final recente =
        idade != null &&
        idade >= Duration.zero &&
        idade <= const Duration(seconds: 120);
    final disponivel =
        recente &&
        atual?.pontoAtual == 0 &&
        segundos != null &&
        segundos >= 0 &&
        metros != null &&
        metros.isFinite &&
        metros >= 0;
    if (!disponivel) return const Text('Aguardando previsão');

    final distancia = metros < 1000
        ? '${metros.round()} m'
        : '${(metros / 1000).toStringAsFixed(1)} km';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chegada ao embarque'),
        const SizedBox(height: 4),
        Text(
          '${(segundos / 60).ceil()} min • $distancia',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(
          'Google Maps',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF5E5E5E),
          ),
        ),
      ],
    );
  }
}
