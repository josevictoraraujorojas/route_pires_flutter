import 'package:flutter/cupertino.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:route_pires_flutter/config/localizacao_atual.dart';

LatLng pontoParaGoogle(latlong.LatLng ponto) {
  return LatLng(latitude: ponto.latitude, longitude: ponto.longitude);
}

latlong.LatLng pontoDeGoogle(LatLng ponto) {
  return latlong.LatLng(ponto.latitude, ponto.longitude);
}

class MapaCorrida extends StatefulWidget {
  const MapaCorrida({
    super.key,
    required this.onTap,
    this.onErro,
    this.pontoInicial,
  });

  final ValueChanged<latlong.LatLng> onTap;
  final ValueChanged<String>? onErro;
  final latlong.LatLng? pontoInicial;

  @override
  State<MapaCorrida> createState() => _MapaCorridaState();
}

class _MapaCorridaState extends State<MapaCorrida> {
  static const centroPadrao = latlong.LatLng(-17.29972, -48.27944);

  static const zoomPadrao = 14.5;
  static const zoomLocal = 16.0;

  GoogleMapViewController? mapController;

  latlong.LatLng? pontoSelecionado;

  bool localizando = false;

  int versaoLocalizacao = 0;

  Marker? marcadorSelecionado;

  @override
  void initState() {
    super.initState();

    pontoSelecionado = widget.pontoInicial;

    if (pontoSelecionado == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        localizar(selecionar: false);
      });
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
        if (mounted) {
          _mover(novo, zoomLocal);
          _atualizarMarcador(novo);
        }
      });
    }
  }

  bool _mesmoPonto(latlong.LatLng a, latlong.LatLng? b) {
    return b != null && a.latitude == b.latitude && a.longitude == b.longitude;
  }

  // ============================================================
  // SELECIONAR PONTO
  // ============================================================

  void selecionar(LatLng ponto) {
    versaoLocalizacao++;

    final pontoFlutter = pontoDeGoogle(ponto);

    _aplicarPonto(pontoFlutter);
  }

  void _aplicarPonto(latlong.LatLng ponto) {
    if (!mounted) return;

    setState(() {
      pontoSelecionado = ponto;
    });

    widget.onTap(ponto);

    _atualizarMarcador(ponto);
  }

  // ============================================================
  // MARCADOR
  // ============================================================

  Future<void> _atualizarMarcador(latlong.LatLng ponto) async {
    final controller = mapController;

    if (controller == null) return;

    try {
      // Remove o marcador anterior.
      if (marcadorSelecionado != null) {
        await controller.removeMarkers([marcadorSelecionado!]);
      }

      // Cria o novo marcador.
      final marcadores = await controller.addMarkers([
        MarkerOptions(
          position: LatLng(
            latitude: ponto.latitude,
            longitude: ponto.longitude,
          ),
          consumeTapEvents: false,
        ),
      ]);

      if (marcadores.isNotEmpty && marcadores.first != null) {
        marcadorSelecionado = marcadores.first;
      }
    } catch (_) {}
  }

  // ============================================================
  // ERRO
  // ============================================================

  void _mostrarErro(String mensagem) {
    if (mounted) {
      widget.onErro?.call(mensagem);
    }
  }

  // ============================================================
  // MOVER CÂMERA
  // ============================================================

  Future<void> _mover(latlong.LatLng ponto, double zoom) async {
    final controller = mapController;

    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(latitude: ponto.latitude, longitude: ponto.longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  // ============================================================
  // MAPA CRIADO
  // ============================================================

  Future<void> _onMapCreated(GoogleMapViewController controller) async {
    mapController = controller;

    try {
      await controller.setMyLocationEnabled(true);

      // Remove a bússola/controles nativos.
      await controller.setRecenterButtonEnabled(false);
    } catch (_) {}

    final ponto = pontoSelecionado;

    if (ponto != null) {
      await _mover(ponto, zoomLocal);

      await _atualizarMarcador(ponto);
    }
  }

  // ============================================================
  // LOCALIZAÇÃO ATUAL
  // ============================================================

  Future<void> localizar({bool selecionar = true}) async {
    if (!mounted || localizando) return;

    final versao = ++versaoLocalizacao;

    setState(() {
      localizando = true;
    });

    try {
      final ponto = await posicaoAtual();

      if (!mounted || versao != versaoLocalizacao) {
        return;
      }

      if (selecionar) {
        _aplicarPonto(ponto);
      }

      await _mover(ponto, zoomLocal);

      await _atualizarMarcador(ponto);
    } on FalhaLocalizacao catch (erro) {
      if (versao == versaoLocalizacao) {
        _mostrarErro(erro.mensagem);
      }
    } catch (_) {
      if (versao == versaoLocalizacao) {
        _mostrarErro('Não foi possível obter sua localização.');
      }
    } finally {
      if (mounted) {
        setState(() {
          localizando = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final centro = pontoSelecionado ?? centroPadrao;

    return Semantics(
      label: 'Mapa para selecionar uma localização',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMapsMapView(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  latitude: centro.latitude,
                  longitude: centro.longitude,
                ),
                zoom: pontoSelecionado == null ? zoomPadrao : zoomLocal,
              ),

              initialCompassEnabled: false,

              initialZoomControlsEnabled: false,

              initialMapToolbarEnabled: false,

              onViewCreated: _onMapCreated,

              onMapClicked: (LatLng ponto) {
                selecionar(ponto);
              },
            ),

            // ==================================================
            // BOTÃO DE LOCALIZAÇÃO
            // ==================================================
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
