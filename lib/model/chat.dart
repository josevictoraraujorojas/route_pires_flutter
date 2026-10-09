class Chat {
  final String id;
  final String nomeOutroParticipante;
  final DateTime? dataCriacao;
  final DateTime? dataEncerramento;

  Chat({
    required this.id,
    required this.nomeOutroParticipante,
    this.dataCriacao,
    this.dataEncerramento,
  });

  bool get encerrado => dataEncerramento != null;

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id']?.toString() ?? '',
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
