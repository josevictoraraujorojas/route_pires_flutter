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

  // Preços das corridas, em reais.
  final double precoZonaUrbana;
  final double precoBairrosAfastados;
  final double precoBandeira2;

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
    required this.precoZonaUrbana,
    required this.precoBairrosAfastados,
    required this.precoBandeira2,
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

      // Preços enviados para a API.
      'precoZonaUrbana': precoZonaUrbana,
      'precoBairrosAfastados': precoBairrosAfastados,
      'precoBandeira2': precoBandeira2,
    };
  }
}

class MototaxistaRascunho {
  String nome = '';
  String email = '';
  String senha = '';
  String telefone = '';
  String cnh = '';
  String dataValidade = '';
  String placa = '';
  String renavam = '';
  String modelo = '';
  String ano = '';

  // Guardamos os preços como texto enquanto o usuário preenche o formulário.
  String precoZonaUrbana = '';
  String precoBairrosAfastados = '';
  String precoBandeira2 = '';

  bool aceitouTermos = false;

  double _converterPreco(String valor) {
    final normalizado = valor.trim().replaceAll(',', '.');
    final preco = double.tryParse(normalizado);

    if (preco == null || !preco.isFinite || preco <= 0) {
      throw const FormatException('Informe um preço válido maior que zero.');
    }

    return preco;
  }

  MototaxistaCadastro paraCadastro() {
    return MototaxistaCadastro(
      nome: nome,
      email: email,
      senha: senha,
      telefone: telefone,
      cnh: cnh,
      dataValidade: dataValidade,
      placa: placa,
      renavam: renavam,
      modelo: modelo,
      ano: ano,
      precoZonaUrbana: _converterPreco(precoZonaUrbana),
      precoBairrosAfastados: _converterPreco(precoBairrosAfastados),
      precoBandeira2: _converterPreco(precoBandeira2),
    );
  }
}
