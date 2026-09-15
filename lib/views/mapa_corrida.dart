import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

gmaps.LatLng pontoParaGoogle(LatLng ponto) {
  return gmaps.LatLng(ponto.latitude, ponto.longitude);
}

LatLng pontoDeGoogle(gmaps.LatLng ponto) {
  return LatLng(ponto.latitude, ponto.longitude);
}

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
  static const zoomPadrao = 14.5;
  static const zoomLocal = 16.0;

  gmaps.GoogleMapController? mapController;
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
        if (mounted) _mover(novo, zoomLocal);
      });
    }
  }

  @override
  void dispose() {
    mapController?.dispose();
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

  Future<void> _mover(LatLng ponto, double zoom) async {
    final controller = mapController;
    if (controller == null) return;
    await controller.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(pontoParaGoogle(ponto), zoom),
    );
  }

  void _onMapCreated(gmaps.GoogleMapController controller) {
    mapController = controller;
    final ponto = pontoSelecionado;
    if (ponto != null) {
      _mover(ponto, zoomLocal);
    }
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
      await _mover(ponto, zoomLocal);
    } catch (_) {
      if (versao == versaoLocalizacao) {
        _mostrarErro('Não foi possível obter sua localização.');
      }
    } finally {
      if (mounted) setState(() => localizando = false);
    }
  }

  Set<gmaps.Marker> get _marcadores {
    final ponto = pontoSelecionado;
    if (ponto == null) return {};
    return {
      gmaps.Marker(
        markerId: const gmaps.MarkerId('selecionado'),
        position: pontoParaGoogle(ponto),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueRed,
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final centro = pontoSelecionado ?? centroPadrao;
    return Semantics(
      label: 'Mapa para selecionar uma localização',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: pontoParaGoogle(centro),
                zoom: pontoSelecionado == null ? zoomPadrao : zoomLocal,
              ),
              onMapCreated: _onMapCreated,
              onTap: (ponto) => selecionar(pontoDeGoogle(ponto)),
              markers: _marcadores,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
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
