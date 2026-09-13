import 'dart:async';

import 'package:flutter/foundation.dart';

enum EtapaCorrida { buscando, motoristas, negociacao }

class CorridaViewModel extends ChangeNotifier {
  static const motoristas = [
    'Haley James',
    'Nathan Scott',
    'Brooke Davis',
    'Jamie Scott',
    'Marvin McFadden',
    'Antwon Taylor',
  ];

  EtapaCorrida _etapa = EtapaCorrida.buscando;
  String _motorista = '';
  Timer? _timer;

  CorridaViewModel() {
    _timer = Timer(const Duration(seconds: 2), _mostrarMotoristas);
  }

  EtapaCorrida get etapa => _etapa;
  String get motorista => _motorista;

  String get titulo => 'Buscando Corrida';

  void selecionarMotorista(String nome) {
    _motorista = nome;
    _etapa = EtapaCorrida.negociacao;
    notifyListeners();
  }

  void recusarNegociacao() {
    _etapa = EtapaCorrida.motoristas;
    notifyListeners();
  }

  void _mostrarMotoristas() {
    _timer = null;
    _etapa = EtapaCorrida.motoristas;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
