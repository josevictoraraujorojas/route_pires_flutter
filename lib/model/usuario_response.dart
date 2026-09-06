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
      dataCadastro: json['dataCadastro'] != null
          ? DateTime.parse(json['dataCadastro'])
          : null,
      tipo: json['tipo'] ?? '',
      fotoUrl: json['fotoUrl'],
      historicoCorridas: json['historicoCorridas'] != null
          ? List<String>.from(json['historicoCorridas'])
          : [],
    );
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
