class MototaxistaResumo {
  const MototaxistaResumo({
    required this.id,
    required this.nome,
    this.avaliacaoMedia = 0,
    this.fotoUrl,
    this.disponivel = true,
  });

  final String id;
  final String nome;
  final double avaliacaoMedia;
  final String? fotoUrl;
  final bool disponivel;

  int get estrelas {
    final valor = avaliacaoMedia.round();
    if (valor < 0) return 0;
    if (valor > 5) return 5;
    return valor;
  }

  factory MototaxistaResumo.fromJson(Map<String, dynamic> json) {
    return MototaxistaResumo(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      avaliacaoMedia: (json['avaliacaoMedia'] as num?)?.toDouble() ?? 0,
      fotoUrl: json['fotoUrl'] as String?,
      disponivel: json['disponivel'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MototaxistaResumo &&
        other.id == id &&
        other.nome == nome &&
        other.avaliacaoMedia == avaliacaoMedia &&
        other.fotoUrl == fotoUrl &&
        other.disponivel == disponivel;
  }

  @override
  int get hashCode =>
      Object.hash(id, nome, avaliacaoMedia, fotoUrl, disponivel);
}
