class Chat {
  final String id;
  final String nomeOutroParticipante;

  Chat({required this.id, required this.nomeOutroParticipante});

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id']?.toString() ?? '',
      nomeOutroParticipante:
          json['nomeOutroParticipante']?.toString() ?? 'Usuário',
    );
  }
}
