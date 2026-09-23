import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';

class SolicitacaoCorrida {
  const SolicitacaoCorrida({
    required this.id,
    required this.categoria,
    required this.status,
    required this.mototaxistaId,
    required this.passageiroId,
    this.passageiroNome = 'Passageiro',
    this.passageiroAvaliacao,
    required this.origem,
    required this.destino,
    this.descricaoCarga,
    this.pesoCarga,
    this.cargaFragil,
    this.formaPagamento,
    this.dataHoraSolicitacao,
  });

  final String id;
  final CategoriaCorrida categoria;
  final String status;
  final String mototaxistaId;
  final String passageiroId;
  final String passageiroNome;
  final double? passageiroAvaliacao;
  final LocalizacaoPonto origem;
  final LocalizacaoPonto destino;
  final String? descricaoCarga;
  final double? pesoCarga;
  final bool? cargaFragil;
  final String? formaPagamento;
  final DateTime? dataHoraSolicitacao;

  bool get ehEntrega => categoria != CategoriaCorrida.corrida;

  factory SolicitacaoCorrida.fromJson(
    Map<String, dynamic> json, {
    required CategoriaCorrida categoria,
  }) {
    final descricaoCarga = json['descricaoCarga']?.toString();
    final cargaLegadaSemDados =
        json['modalidadeFrete'] == null &&
        (descricaoCarga?.toLowerCase() == 'frete' ||
            descricaoCarga?.toLowerCase() == 'frete simples');
    final categoriaEfetiva = categoria == CategoriaCorrida.corrida
        ? categoria
        : switch (json['modalidadeFrete']?.toString()) {
            'FRETE_SIMPLES' => CategoriaCorrida.freteSimples,
            'FRETE' => CategoriaCorrida.frete,
            _ when descricaoCarga?.toLowerCase() == 'frete simples' =>
              CategoriaCorrida.freteSimples,
            _ => CategoriaCorrida.frete,
          };
    final passageiroId = categoria == CategoriaCorrida.corrida
        ? (json['passageiro'] ?? json['passageiroId'])?.toString() ?? ''
        : (json['solicitanteId'] ?? json['passageiroId'])?.toString() ?? '';

    return SolicitacaoCorrida(
      id: json['id']?.toString() ?? '',
      categoria: categoriaEfetiva,
      status: json['status']?.toString() ?? '',
      mototaxistaId: json['mototaxistaId']?.toString() ?? '',
      passageiroId: passageiroId,
      origem: _ponto(json['origem'], rotuloPadrao: 'Origem'),
      destino: _ponto(json['destino'], rotuloPadrao: 'Destino'),
      descricaoCarga: cargaLegadaSemDados ? null : descricaoCarga,
      pesoCarga: cargaLegadaSemDados ? null : _numero(json['pesoCarga']),
      cargaFragil: json['cargaFragil'] as bool?,
      formaPagamento: json['formaPagamento']?.toString(),
      dataHoraSolicitacao: DateTime.tryParse(
        json['dataHoraSolicitacao']?.toString() ?? '',
      ),
    );
  }

  SolicitacaoCorrida copyWith({
    String? passageiroNome,
    double? passageiroAvaliacao,
  }) {
    return SolicitacaoCorrida(
      id: id,
      categoria: categoria,
      status: status,
      mototaxistaId: mototaxistaId,
      passageiroId: passageiroId,
      passageiroNome: passageiroNome ?? this.passageiroNome,
      passageiroAvaliacao: passageiroAvaliacao ?? this.passageiroAvaliacao,
      origem: origem,
      destino: destino,
      descricaoCarga: descricaoCarga,
      pesoCarga: pesoCarga,
      cargaFragil: cargaFragil,
      formaPagamento: formaPagamento,
      dataHoraSolicitacao: dataHoraSolicitacao,
    );
  }

  static Map<String, dynamic>? _mapa(dynamic valor) {
    return valor is Map ? Map<String, dynamic>.from(valor) : null;
  }

  static double? _numero(dynamic valor) {
    if (valor is num) return valor.toDouble();
    if (valor is String) return double.tryParse(valor);
    return null;
  }

  static LocalizacaoPonto _ponto(
    dynamic valor, {
    required String rotuloPadrao,
  }) {
    final mapa = _mapa(valor);
    final localizacao = _mapa(mapa?['localizacao']) ?? mapa;

    return LocalizacaoPonto(
      latitude: _numero(localizacao?['latitude']) ?? 0,
      longitude: _numero(localizacao?['longitude']) ?? 0,
      rotulo: mapa?['rotulo']?.toString() ?? rotuloPadrao,
    );
  }
}
