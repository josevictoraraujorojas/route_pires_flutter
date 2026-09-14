import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/views/botao_primario.dart';
import 'package:route_pires_flutter/views/mapa_corrida_mock.dart';
import 'package:route_pires_flutter/views/rodape_navegacao.dart';

class PesquisarLocalizacaoPage extends StatefulWidget {
  const PesquisarLocalizacaoPage({super.key, this.pontoInicial});

  final LocalizacaoPonto? pontoInicial;

  @override
  State<PesquisarLocalizacaoPage> createState() =>
      _PesquisarLocalizacaoPageState();
}

class _PesquisarLocalizacaoPageState extends State<PesquisarLocalizacaoPage> {
  static const enderecos = [
    LocalizacaoPonto(
      latitude: -17.29972,
      longitude: -48.27944,
      rotulo: 'Rua Exemplo - Setor Exemplo',
    ),
    LocalizacaoPonto(
      latitude: -17.3014,
      longitude: -48.2812,
      rotulo: 'Rua Exemplo Filho Neto',
    ),
    LocalizacaoPonto(
      latitude: -17.2983,
      longitude: -48.2770,
      rotulo: 'Rua Exp - Centro',
    ),
    LocalizacaoPonto(
      latitude: -17.3037,
      longitude: -48.2855,
      rotulo: 'Rua Inicial - Setor Universitário',
    ),
    LocalizacaoPonto(
      latitude: -17.2948,
      longitude: -48.2718,
      rotulo: 'Rua Final - Centro',
    ),
  ];

  static const _centro = LocalizacaoPonto(
    latitude: -17.29972,
    longitude: -48.27944,
    rotulo: 'Local selecionado no mapa',
  );

  late final TextEditingController controller;
  late LocalizacaoPonto pontoMapa;

  @override
  void initState() {
    super.initState();
    pontoMapa = widget.pontoInicial ?? _centro;
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void selecionar(LocalizacaoPonto ponto) => Navigator.pop(context, ponto);

  void limparBusca() {
    controller.clear();
    setState(() {});
  }

  LocalizacaoPonto pontoDoMapa(LatLng latLng) {
    return LocalizacaoPonto(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      rotulo:
          '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final termo = controller.text.trim().toLowerCase();
    final sugestoes = termo.isEmpty
        ? <LocalizacaoPonto>[]
        : enderecos
              .where(
                (endereco) => endereco.rotulo.toLowerCase().contains(termo),
              )
              .toList();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text(
          'Pesquisar Localização',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: CupertinoSearchTextField(
                controller: controller,
                autofocus: true,
                placeholder: 'Rua Exemplo',
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          'Selecionar Localização',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: MapaCorridaMock(
                            pontoInicial: LatLng(
                              pontoMapa.latitude,
                              pontoMapa.longitude,
                            ),
                            onTap: (latLng) {
                              setState(() => pontoMapa = pontoDoMapa(latLng));
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                        child: BotaoPrimario(
                          texto: 'SELECIONAR',
                          onPressed: () => selecionar(pontoMapa),
                        ),
                      ),
                      const RodapeNavegacao(),
                    ],
                  ),
                  if (sugestoes.isNotEmpty)
                    ColoredBox(
                      color: CupertinoColors.white,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: sugestoes.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 8, top: 4),
                              child: Text(
                                'PESQUISA SUGERIDA',
                                style: TextStyle(
                                  color: Color(0xFF8F9098),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            );
                          }
                          final endereco = sugestoes[index - 1];
                          return Row(
                            children: [
                              Expanded(
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  onPressed: () => selecionar(endereco),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.location_solid,
                                        color: Color(0xFFFF3B4E),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          endereco.rotulo,
                                          style: const TextStyle(
                                            color: Color(0xFF1F2024),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.all(8),
                                minimumSize: const Size(44, 44),
                                onPressed: limparBusca,
                                child: const Icon(
                                  CupertinoIcons.xmark,
                                  size: 16,
                                  color: Color(0xFFC5C6CC),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
