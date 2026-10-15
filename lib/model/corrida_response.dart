class CorridaResponse {
  const CorridaResponse({
    required this.id,
    this.mototaxistaId,
    this.passageiroId,
    this.status,
    this.tempoRestanteSegundos,
    this.distanciaRestanteMetros,
    this.pontoAtual,
    this.estimativaAtualizadaEm,
  });

  final String id;
  final String? mototaxistaId;
  final String? passageiroId;
  final String? status;
  final int? tempoRestanteSegundos;
  final double? distanciaRestanteMetros;
  final int? pontoAtual;
  final DateTime? estimativaAtualizadaEm;

  factory CorridaResponse.fromJson(Map<String, dynamic> json) {
    return CorridaResponse(
      id: json['id']?.toString() ?? '',
      mototaxistaId: json['mototaxistaId']?.toString(),
      passageiroId:
          (json['passageiro'] ?? json['passageiroId'] ?? json['solicitanteId'])
              ?.toString(),
      status: json['status']?.toString(),
      tempoRestanteSegundos: (json['tempoRestanteSegundos'] as num?)?.toInt(),
      distanciaRestanteMetros: (json['distanciaRestanteMetros'] as num?)
          ?.toDouble(),
      pontoAtual: (json['pontoAtual'] as num?)?.toInt(),
      estimativaAtualizadaEm: DateTime.tryParse(
        json['estimativaAtualizadaEm']?.toString() ?? '',
      )?.toUtc(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CorridaResponse &&
        other.id == id &&
        other.mototaxistaId == mototaxistaId &&
        other.passageiroId == passageiroId &&
        other.status == status &&
        other.tempoRestanteSegundos == tempoRestanteSegundos &&
        other.distanciaRestanteMetros == distanciaRestanteMetros &&
        other.pontoAtual == pontoAtual &&
        other.estimativaAtualizadaEm == estimativaAtualizadaEm;
  }

  @override
  int get hashCode => Object.hash(
    id,
    mototaxistaId,
    passageiroId,
    status,
    tempoRestanteSegundos,
    distanciaRestanteMetros,
    pontoAtual,
    estimativaAtualizadaEm,
  );
}
