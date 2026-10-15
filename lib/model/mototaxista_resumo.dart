class MototaxistaResumo {
  const MototaxistaResumo({
    required this.id,
    required this.nome,
    this.avaliacaoMedia = 0,
    this.fotoUrl,
    this.disponivel = true,
    this.precoZonaUrbana,
    this.precoBairrosAfastados,
    this.precoBandeira2,
  });

  final String id;
  final String nome;
  final double avaliacaoMedia;
  final String? fotoUrl;
  final bool disponivel;

  final double? precoZonaUrbana;
  final double? precoBairrosAfastados;
  final double? precoBandeira2;

  int get estrelas => avaliacaoMedia.round().clamp(0, 5);

  static double? _lerPreco(dynamic valor) {
    if (valor is num) return valor.toDouble();

    if (valor is String) {
      return double.tryParse(valor.trim().replaceAll(',', '.'));
    }

    return null;
  }

  factory MototaxistaResumo.fromJson(Map<String, dynamic> json) {
    return MototaxistaResumo(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      avaliacaoMedia: (json['avaliacaoMedia'] as num?)?.toDouble() ?? 0,
      fotoUrl: json['fotoUrl'] as String?,
      disponivel: json['disponivel'] as bool? ?? true,
      precoZonaUrbana: _lerPreco(json['precoZonaUrbana']),
      precoBairrosAfastados: _lerPreco(json['precoBairrosAfastados']),
      precoBandeira2: _lerPreco(json['precoBandeira2']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MototaxistaResumo &&
        other.id == id &&
        other.nome == nome &&
        other.avaliacaoMedia == avaliacaoMedia &&
        other.fotoUrl == fotoUrl &&
        other.disponivel == disponivel &&
        other.precoZonaUrbana == precoZonaUrbana &&
        other.precoBairrosAfastados == precoBairrosAfastados &&
        other.precoBandeira2 == precoBandeira2;
  }

  @override
  int get hashCode => Object.hash(
    id,
    nome,
    avaliacaoMedia,
    fotoUrl,
    disponivel,
    precoZonaUrbana,
    precoBairrosAfastados,
    precoBandeira2,
  );
}
