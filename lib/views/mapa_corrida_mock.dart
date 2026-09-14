import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaCorridaMock extends StatefulWidget {
  const MapaCorridaMock({
    super.key,
    this.exibirRota = false,
    this.onTap,
    this.pontoInicial,
  });

  final bool exibirRota;
  final ValueChanged<LatLng>? onTap;
  final LatLng? pontoInicial;

  @override
  State<MapaCorridaMock> createState() => _MapaCorridaMockState();
}

class _MapaCorridaMockState extends State<MapaCorridaMock> {
  static const centro = LatLng(-17.29972, -48.27944);
  static const inicio = LatLng(-17.3037, -48.2855);
  static const destino = LatLng(-17.2948, -48.2718);
  static const rota = [
    inicio,
    LatLng(-17.3014, -48.2812),
    LatLng(-17.2983, -48.2770),
    LatLng(-17.2962, -48.2746),
    destino,
  ];

  final mapController = MapController();
  late LatLng pontoSelecionado = widget.pontoInicial ?? centro;

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  void selecionar(LatLng ponto) {
    if (widget.onTap == null) return;
    setState(() => pontoSelecionado = ponto);
    widget.onTap!(ponto);
  }

  @override
  Widget build(BuildContext context) {
    final marcadores = widget.exibirRota
        ? const [
            Marker(
              point: inicio,
              child: _Marcador(texto: '1'),
            ),
            Marker(
              point: destino,
              child: _Marcador(texto: '2'),
            ),
          ]
        : [
            Marker(
              point: pontoSelecionado,
              width: 44,
              height: 44,
              alignment: Alignment.topCenter,
              child: const Icon(
                CupertinoIcons.location_solid,
                color: Color(0xFFFF3B4E),
                size: 44,
              ),
            ),
          ];

    return Semantics(
      label: widget.exibirRota
          ? 'Mapa demonstrativo com rota fictícia'
          : 'Mapa demonstrativo para selecionar uma localização',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: widget.pontoInicial ?? centro,
                initialZoom: 14.5,
                onTap: (_, ponto) => selecionar(ponto),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.route_pires_flutter',
                ),
                if (widget.exibirRota)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: rota,
                        color: Color(0xFF006FFD),
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                MarkerLayer(markers: marcadores),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 34,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(24),
                onPressed: () => mapController.move(centro, 14.5),
                child: const Icon(
                  CupertinoIcons.location,
                  color: Color(0xFF006FFD),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Marcador extends StatelessWidget {
  const _Marcador({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFFF3B4E),
        shape: BoxShape.circle,
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
