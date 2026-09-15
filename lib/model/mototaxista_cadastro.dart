import 'package:route_pires_flutter/config/validacao.dart';

class MototaxistaCadastro {
  final String nome;
  final String email;
  final String senha;
  final String telefone;
  final String cnh;
  final String dataValidade;
  final String placa;
  final String renavam;
  final String modelo;
  final String ano;

  const MototaxistaCadastro({
    required this.nome,
    required this.email,
    required this.senha,
    required this.telefone,
    required this.cnh,
    required this.dataValidade,
    required this.placa,
    required this.renavam,
    required this.modelo,
    required this.ano,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'email': emailNormalizado(email),
      'senha': senha,
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
        'ano': int.parse(ano),
      },
      'servicosOferecidos': [],
      'cnh': cnh,
      'dataValidade': dataValidade,
    };
  }
}
