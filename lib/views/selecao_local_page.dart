import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_pires_flutter/views/botao_primario.dart';
import 'package:route_pires_flutter/views/mapa_corrida_mock.dart';
import 'package:route_pires_flutter/views/rodape_navegacao.dart';
import 'package:route_pires_flutter/views/solicitar_corrida_page.dart';

class SelecaoLocalPage extends StatefulWidget {
  const SelecaoLocalPage({super.key});

  @override
  State<SelecaoLocalPage> createState() => _SelecaoLocalPageState();
}

class _SelecaoLocalPageState extends State<SelecaoLocalPage> {
  final controller = TextEditingController();
  LatLng localSelecionado = const LatLng(-17.29972, -48.27944);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(
                  height: 44,
                  child: Center(
                    child: Text(
                      'Pesquisar Localização',
                      style: TextStyle(
                        color: Color(0xFF1F2024),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const _Divisor(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: CupertinoSearchTextField(
                    controller: controller,
                    placeholder: 'Rua Exemplo',
                  ),
                ),
                const _Divisor(),
                const SizedBox(
                  height: 70,
                  child: Center(
                    child: Text(
                      'Selecionar Localização',
                      style: TextStyle(
                        color: Color(0xFF1F2024),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const _Divisor(),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MapaCorridaMock(
                  pontoInicial: localSelecionado,
                  onTap: (local) => setState(() => localSelecionado = local),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 20,
                  child: BotaoPrimario(
                    texto: 'SELECIONAR',
                    onPressed: () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => const SolicitarCorridaPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SafeArea(top: false, child: RodapeNavegacao()),
        ],
      ),
    );
  }
}

class _Divisor extends StatelessWidget {
  const _Divisor();

  @override
  Widget build(BuildContext context) {
    return Container(height: .5, color: const Color(0xFFE8E9F0));
  }
}
