class CorridaResponse {
  const CorridaResponse({
    required this.id,
    this.mototaxistaId,
    this.passageiroId,
    this.status,
  });

  final String id;
  final String? mototaxistaId;
  final String? passageiroId;
  final String? status;

  factory CorridaResponse.fromJson(Map<String, dynamic> json) {
    return CorridaResponse(
      id: json['id']?.toString() ?? '',
      mototaxistaId: json['mototaxistaId']?.toString(),
      passageiroId:
          (json['passageiro'] ?? json['passageiroId'] ?? json['solicitanteId'])
              ?.toString(),
      status: json['status']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CorridaResponse &&
        other.id == id &&
        other.mototaxistaId == mototaxistaId &&
        other.passageiroId == passageiroId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, mototaxistaId, passageiroId, status);
}
