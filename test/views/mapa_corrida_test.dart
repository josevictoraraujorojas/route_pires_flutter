import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_pires_flutter/views/mapa_corrida.dart';

void main() {
  test('Converte o ponto de latlong2 para Google Maps e de volta', () {
    const origem = LatLng(-17.29972, -48.27944);

    final google = pontoParaGoogle(origem);
    expect(google.latitude, origem.latitude);
    expect(google.longitude, origem.longitude);

    final volta = pontoDeGoogle(google);
    expect(volta.latitude, origem.latitude);
    expect(volta.longitude, origem.longitude);
  });
}
