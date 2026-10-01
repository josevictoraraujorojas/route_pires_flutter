import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/repositories/localizacao_repository.dart';

/// Mostra um endereço legível mesmo quando a API da corrida devolve só o ponto.
class EnderecoCorrida extends StatefulWidget {
  const EnderecoCorrida({
    super.key,
    required this.ponto,
    this.prefixo = '',
    this.style,
  });

  final LocalizacaoPonto ponto;
  final String prefixo;
  final TextStyle? style;

  @override
  State<EnderecoCorrida> createState() => _EnderecoCorridaState();
}

class _EnderecoCorridaState extends State<EnderecoCorrida> {
  static final _localizacao = LocalizacaoRepository.compartilhado;
  late String _endereco;

  @override
  void initState() {
    super.initState();
    _definirEndereco(widget.ponto);
  }

  @override
  void didUpdateWidget(covariant EnderecoCorrida oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ponto.latitude != widget.ponto.latitude ||
        oldWidget.ponto.longitude != widget.ponto.longitude) {
      _definirEndereco(widget.ponto);
    }
  }

  void _definirEndereco(LocalizacaoPonto ponto) {
    final rotulo = ponto.rotulo.trim();
    if (LocalizacaoPonto.rotuloLegivel(rotulo)) {
      _endereco = rotulo;
      _localizacao.guardarEndereco(ponto);
      return;
    }
    if (ponto.latitude == 0 && ponto.longitude == 0) {
      _endereco = 'Endereço indisponível';
      return;
    }

    final conhecido = _localizacao.enderecoEmCache(
      LatLng(ponto.latitude, ponto.longitude),
    );
    if (conhecido != null) {
      final nome = conhecido.rotulo.trim();
      _endereco = LocalizacaoPonto.rotuloLegivel(nome)
          ? nome
          : 'Endereço indisponível • ${_coordenadas(ponto)}';
      return;
    }

    // A API ainda devolve apenas coordenadas. Mostra um valor útil enquanto
    // consulta o nome da rua uma vez por ponto.
    _endereco = _coordenadas(ponto);
    unawaited(_buscarEndereco(ponto));
  }

  Future<void> _buscarEndereco(LocalizacaoPonto ponto) async {
    final latitude = ponto.latitude;
    final longitude = ponto.longitude;
    try {
      final encontrado = await _localizacao.endereco(
        LatLng(latitude, longitude),
      );
      final nome = encontrado.rotulo.trim();
      if (!mounted ||
          widget.ponto.latitude != latitude ||
          widget.ponto.longitude != longitude) {
        return;
      }
      setState(() {
        _endereco = LocalizacaoPonto.rotuloLegivel(nome)
            ? nome
            : 'Endereço indisponível • ${_coordenadas(ponto)}';
      });
    } catch (_) {
      if (!mounted ||
          widget.ponto.latitude != latitude ||
          widget.ponto.longitude != longitude) {
        return;
      }
      setState(() {
        _endereco = 'Endereço indisponível • ${_coordenadas(ponto)}';
      });
    }
  }

  String _coordenadas(LocalizacaoPonto ponto) =>
      '${ponto.latitude.toStringAsFixed(5)}, ${ponto.longitude.toStringAsFixed(5)}';

  @override
  Widget build(BuildContext context) =>
      Text('${widget.prefixo}$_endereco', style: widget.style);
}
