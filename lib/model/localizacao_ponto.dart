class LocalizacaoPonto {
  const LocalizacaoPonto({
    required this.latitude,
    required this.longitude,
    required this.rotulo,
  });

  final double latitude;
  final double longitude;
  final String rotulo;

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
