class Chat {
  final String id;
  final String nomeOutroParticipante;
  final DateTime? dataCriacao;
  final DateTime? dataEncerramento;
  final List<String> participantes;

  Chat({
    required this.id,
    required this.nomeOutroParticipante,
    this.dataCriacao,
    this.dataEncerramento,
    this.participantes = const [],
  });

  bool get encerrado => dataEncerramento != null;

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id']?.toString() ?? '',
      participantes: (json['participantes'] as List? ?? const [])
          .map((id) => id.toString().split('/').last)
          .toList(),
      nomeOutroParticipante:
          json['nomeOutroParticipante']?.toString() ?? 'Usuário',
      dataCriacao: json['dataCriacao'] != null
          ? DateTime.tryParse(json['dataCriacao'].toString())
          : null,
      dataEncerramento: json['dataEncerramento'] != null
          ? DateTime.tryParse(json['dataEncerramento'].toString())
          : null,
    );
  }
}
