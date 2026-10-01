class LocalizacaoPonto {
  const LocalizacaoPonto({
    required this.latitude,
    required this.longitude,
    required this.rotulo,
  });

  final double latitude;
  final double longitude;
  final String rotulo;

  static bool rotuloLegivel(String rotulo) {
    final valor = rotulo.trim();
    if (valor.isEmpty ||
        valor == 'Origem' ||
        valor == 'Destino' ||
        valor == 'Endereço indisponível' ||
        valor == 'Buscando endereço...') {
      return false;
    }
    return !RegExp(r'^-?\d+(?:[.,]\d+)?\s*,\s*-?\d+(?:[.,]\d+)?$')
        .hasMatch(valor);
  }

  @override
  bool operator ==(Object other) {
    return other is LocalizacaoPonto &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.rotulo == rotulo;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, rotulo);
}
