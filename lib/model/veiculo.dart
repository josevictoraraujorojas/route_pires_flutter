class Veiculo {
  const Veiculo({
    required this.placa,
    required this.renavam,
    required this.modelo,
    required this.ano,
  });

  final String placa;
  final String renavam;
  final String modelo;
  final String ano;

  factory Veiculo.fromJson(Map<String, dynamic> json) {
    return Veiculo(
      placa: json['placa']?.toString() ?? '',
      renavam: json['renavam']?.toString() ?? '',
      modelo: json['modelo']?.toString() ?? '',
      ano: json['ano']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placa': placa,
      'renavam': renavam,
      'modelo': modelo,
      'ano': int.parse(ano),
    };
  }
}
