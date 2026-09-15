import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class FalhaLocalizacao implements Exception {
  FalhaLocalizacao(this.mensagem);

  final String mensagem;
}

Future<LatLng> posicaoAtual() async {
  final servicoAtivo = await Geolocator.isLocationServiceEnabled();
  if (!servicoAtivo) {
    throw FalhaLocalizacao('Ative a localização do aparelho.');
  }

  var permissao = await Geolocator.checkPermission();
  if (permissao == LocationPermission.denied) {
    permissao = await Geolocator.requestPermission();
  }
  if (permissao == LocationPermission.denied) {
    throw FalhaLocalizacao('Permissão de localização negada.');
  }
  if (permissao == LocationPermission.deniedForever) {
    throw FalhaLocalizacao(
      'Libere a localização nas configurações do aplicativo.',
    );
  }

  try {
    final posicao = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(posicao.latitude, posicao.longitude);
  } catch (_) {
    throw FalhaLocalizacao('Não foi possível obter sua localização.');
  }
}
