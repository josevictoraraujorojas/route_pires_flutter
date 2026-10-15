class Mensagem {
  final String id;
  final String conteudo;
  final DateTime? horarioEnvio;
  final String remetente;
  final String status;

  Mensagem({
    required this.id,
    required this.conteudo,
    required this.remetente,
    this.horarioEnvio,
    this.status = 'PENDENTE',
  });

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    return Mensagem(
      id: json['id']?.toString() ?? '',
      conteudo: json['conteudo']?.toString() ?? '',
      remetente: json['remetente']?.toString() ?? '',
      horarioEnvio: json['horarioEnvio'] != null
          ? DateTime.tryParse(json['horarioEnvio'].toString())
          : null,
      status: json['status']?.toString() ?? 'PENDENTE',
    );
  }
}
