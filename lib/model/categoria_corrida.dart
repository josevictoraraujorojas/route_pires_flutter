enum CategoriaCorrida {
  corrida,
  freteSimples,
  frete;

  String get label => switch (this) {
    CategoriaCorrida.corrida => 'CORRIDA',
    CategoriaCorrida.freteSimples => 'FRETE SIMPLES',
    CategoriaCorrida.frete => 'FRETE',
  };
}
