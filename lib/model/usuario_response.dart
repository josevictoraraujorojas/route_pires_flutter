class UsuarioResponse {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final DateTime? dataCadastro;
  final String tipo;
  final String? fotoUrl;
  final List<String> historicoCorridas;

  UsuarioResponse({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    this.dataCadastro,
    required this.tipo,
    this.fotoUrl,
    required this.historicoCorridas,
  });

  factory UsuarioResponse.fromJson(Map<String, dynamic> json) {
    return UsuarioResponse(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      telefone: json['telefone'] ?? '',
      dataCadastro: _parseData(json['dataCadastro']),
      tipo: json['tipo'] ?? '',
      fotoUrl: json['fotoUrl'],
      historicoCorridas: json['historicoCorridas'] != null
          ? List<String>.from(json['historicoCorridas'])
          : [],
    );
  }

  static DateTime? _parseData(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      final normalizado = value
          .replaceFirstMapped(
            RegExp(r'^(\d{2})-(\d{2})-(\d{4})'),
            (match) => '${match[3]}-${match[2]}-${match[1]}',
          )
          .replaceFirst('+0000', 'Z');
      try {
        return DateTime.parse(normalizado);
      } catch (_) {
        return null;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'dataCadastro': dataCadastro?.toIso8601String(),
      'tipo': tipo,
      'fotoUrl': fotoUrl,
      'historicoCorridas': historicoCorridas,
    };
  }
}
