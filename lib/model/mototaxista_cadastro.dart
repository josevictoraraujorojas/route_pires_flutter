class MototaxistaCadastro {
  final String nome;
  final String telefone;
  final String cnh;
  final String placa;
  final String renavam;
  final String modelo;
  final String ano;

  const MototaxistaCadastro({
    required this.nome,
    required this.telefone,
    required this.cnh,
    required this.placa,
    required this.renavam,
    required this.modelo,
    required this.ano,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'telefone': telefone.replaceAll(RegExp(r'\D'), ''),
      'dataCadastro': DateTime.now().toUtc().toIso8601String(),
      'tipo': 'MOTOTAXISTA',
      'fotoUrl': null,
      'historicoCorridas': [],
      'disponivel': false,
      'localizacaoAtual': null,
      'veiculo': {
        'placa': placa,
        'renavam': renavam,
        'modelo': modelo,
        'ano': ano,
      },
      'servicosOferecidos': [],
      'cnh': cnh,
    };
  }
}