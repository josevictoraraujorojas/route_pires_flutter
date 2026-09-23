import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_pires_flutter/config/localizacao_atual.dart';

/// Alternativa Web para escolher um ponto sem a SDK de navegação mobile.
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
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  bool _localizando = false;

  @override
  void initState() {
    super.initState();
    _latitude = TextEditingController();
    _longitude = TextEditingController();
    _preencher(widget.pontoInicial);
  }

  @override
  void didUpdateWidget(covariant MapaCorrida oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pontoInicial != oldWidget.pontoInicial) {
      _preencher(widget.pontoInicial);
    }
  }

  void _preencher(LatLng? ponto) {
    _latitude.text = ponto?.latitude.toStringAsFixed(6) ?? '';
    _longitude.text = ponto?.longitude.toStringAsFixed(6) ?? '';
  }

  void _selecionar() {
    final latitude = double.tryParse(
      _latitude.text.trim().replaceAll(',', '.'),
    );
    final longitude = double.tryParse(
      _longitude.text.trim().replaceAll(',', '.'),
    );
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      widget.onErro?.call('Informe latitude e longitude válidas.');
      return;
    }
    widget.onTap(LatLng(latitude, longitude));
  }

  Future<void> _usarLocalizacao() async {
    setState(() => _localizando = true);
    try {
      final ponto = await posicaoAtual();
      if (!mounted) return;
      _preencher(ponto);
      widget.onTap(ponto);
    } on FalhaLocalizacao catch (e) {
      widget.onErro?.call(e.mensagem);
    } catch (_) {
      widget.onErro?.call('Não foi possível obter sua localização.');
    } finally {
      if (mounted) setState(() => _localizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Selecionar localização por coordenadas',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecione um endereço na busca ou informe coordenadas.',
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _latitude,
              placeholder: 'Latitude',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _longitude,
              placeholder: 'Longitude',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 8),
            CupertinoButton.filled(
              onPressed: _selecionar,
              child: const Text('Usar coordenadas'),
            ),
            CupertinoButton(
              onPressed: _localizando ? null : _usarLocalizacao,
              child: _localizando
                  ? const CupertinoActivityIndicator()
                  : const Text('Usar minha localização'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }
}
