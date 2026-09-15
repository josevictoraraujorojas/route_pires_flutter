import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapaCorrida extends StatefulWidget {
  const MapaCorrida({
    super.key,
    required this.onTap,
    this.onErro,
    this.pontoInicial,
  });

  final ValueChanged<LatLng> onTap;
  final ValueChanged<String>? onErro;
  final LatLng? pontoInicial;

  @override
  State<MapaCorrida> createState() => _MapaCorridaState();
}

class _MapaCorridaState extends State<MapaCorrida> {
  static const centroPadrao = LatLng(-17.29972, -48.27944);

  final mapController = MapController();
  late LatLng? pontoSelecionado = widget.pontoInicial;
  bool localizando = false;
  int versaoLocalizacao = 0;

  @override
  void initState() {
    super.initState();
    if (pontoSelecionado == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => localizar());
    }
  }

  @override
  void didUpdateWidget(MapaCorrida oldWidget) {
    super.didUpdateWidget(oldWidget);
    final novo = widget.pontoInicial;
    if (novo != null && !_mesmoPonto(novo, pontoSelecionado)) {
      versaoLocalizacao++;
      pontoSelecionado = novo;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) mapController.move(novo, 16);
      });
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  bool _mesmoPonto(LatLng a, LatLng? b) {
    return b != null && a.latitude == b.latitude && a.longitude == b.longitude;
  }

  void selecionar(LatLng ponto) {
    versaoLocalizacao++;
    _aplicarPonto(ponto);
  }

  void _aplicarPonto(LatLng ponto) {
    setState(() => pontoSelecionado = ponto);
    widget.onTap(ponto);
  }

  void _mostrarErro(String mensagem) {
    if (mounted) widget.onErro?.call(mensagem);
  }

  Future<void> localizar() async {
    if (localizando) return;
    final versao = ++versaoLocalizacao;
    setState(() => localizando = true);

    try {
      final servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!mounted || versao != versaoLocalizacao) return;
      if (!servicoAtivo) {
        _mostrarErro('Ative a localização do aparelho.');
        return;
      }

      var permissao = await Geolocator.checkPermission();
      if (!mounted || versao != versaoLocalizacao) return;
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
        if (!mounted || versao != versaoLocalizacao) return;
      }
      if (permissao == LocationPermission.denied) {
        _mostrarErro('Permissão de localização negada.');
        return;
      }
      if (permissao == LocationPermission.deniedForever) {
        _mostrarErro('Libere a localização nas configurações do aplicativo.');
        return;
      }

      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted || versao != versaoLocalizacao) return;
      final ponto = LatLng(posicao.latitude, posicao.longitude);
      _aplicarPonto(ponto);
      mapController.move(ponto, 16);
    } catch (_) {
      if (versao == versaoLocalizacao) {
        _mostrarErro('Não foi possível obter sua localização.');
      }
    } finally {
      if (mounted) setState(() => localizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mapa para selecionar uma localização',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: pontoSelecionado ?? centroPadrao,
                initialZoom: 14.5,
                onTap: (_, ponto) => selecionar(ponto),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.route_pires_flutter',
                ),
                if (pontoSelecionado case final ponto?)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: ponto,
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          CupertinoIcons.location_solid,
                          color: Color(0xFFFF3B4E),
                          size: 44,
                        ),
                      ),
                    ],
                  ),
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
                onPressed: localizando ? null : localizar,
                child: localizando
                    ? const CupertinoActivityIndicator()
                    : const Icon(
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
