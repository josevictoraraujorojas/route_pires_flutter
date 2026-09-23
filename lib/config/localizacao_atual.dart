import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class FalhaLocalizacao implements Exception {
  FalhaLocalizacao(this.mensagem);

  final String mensagem;
}

Future<LatLng>? _emVoo;
LatLng? _cache;
DateTime? _cacheEm;

Future<LatLng> posicaoAtual() {
  final cache = _cache;
  final cacheEm = _cacheEm;
  if (cache != null &&
      cacheEm != null &&
      DateTime.now().difference(cacheEm) < const Duration(seconds: 8)) {
    return Future.value(cache);
  }
  return _emVoo ??= _lerPosicao().whenComplete(() {
    _emVoo = null;
  });
}

Future<LatLng> _lerPosicao() async {
  await verificarPermissaoLocalizacao();

  try {
    final posicao = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    final ponto = LatLng(posicao.latitude, posicao.longitude);
    _cache = ponto;
    _cacheEm = DateTime.now();
    return ponto;
  } catch (erro) {
    if (erro is FalhaLocalizacao) rethrow;
    throw FalhaLocalizacao('Não foi possível obter sua localização.');
  }
}

Future<void> verificarPermissaoLocalizacao() async {
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
}
