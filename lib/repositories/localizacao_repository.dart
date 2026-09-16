import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';

class LocalizacaoRepository {
  LocalizacaoRepository({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: const String.fromEnvironment(
                'GEOCODING_BASE_URL',
                defaultValue: 'https://photon.komoot.io',
              ),
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: const {
                'Accept': 'application/json',
                'User-Agent': 'RoutePiresFlutter/1.0',
              },
            ),
          );

  final Dio _dio;
  final _buscas = <String, List<LocalizacaoPonto>>{};
  final _enderecos = <String, LocalizacaoPonto>{};

  Future<List<LocalizacaoPonto>> buscar(String texto) async {
    final chave = texto.trim().toLowerCase();
    if (_buscas[chave] case final resultado?) return resultado;

    final response = await _dio.get<dynamic>(
      '/api',
      queryParameters: {
        'q': texto.trim(),
        'countrycode': 'BR',
        'limit': 5,
        'lat': -17.29972,
        'lon': -48.27944,
      },
    );
    final data = response.data;
    final features = data is Map ? data['features'] : null;
    final resultado = features is List
        ? features.map(_ponto).whereType<LocalizacaoPonto>().toList()
        : <LocalizacaoPonto>[];
    if (resultado.isNotEmpty) {
      _buscas[chave] = resultado;
    }
    return resultado;
  }

  Future<LocalizacaoPonto> endereco(LatLng ponto) async {
    final chave =
        '${ponto.latitude.toStringAsFixed(5)},'
        '${ponto.longitude.toStringAsFixed(5)}';
    if (_enderecos[chave] case final endereco?) return endereco;

    final response = await _dio.get<dynamic>(
      '/reverse',
      queryParameters: {
        'lat': ponto.latitude,
        'lon': ponto.longitude,
        'limit': 1,
      },
    );
    final data = response.data;
    final features = data is Map ? data['features'] : null;
    final resultado = features is List && features.isNotEmpty
        ? _ponto(features.first)
        : null;
    return _enderecos[chave] = LocalizacaoPonto(
      latitude: ponto.latitude,
      longitude: ponto.longitude,
      rotulo: resultado?.rotulo ?? chave,
    );
  }

  LocalizacaoPonto? _ponto(dynamic data) {
    if (data is! Map) return null;
    final geometry = data['geometry'];
    final coordinates = geometry is Map ? geometry['coordinates'] : null;
    final properties = data['properties'];
    if (coordinates is! List || coordinates.length < 2 || properties is! Map) {
      return null;
    }
    final longitude = double.tryParse('${coordinates[0]}');
    final latitude = double.tryParse('${coordinates[1]}');
    final rotulo =
        [
              'name',
              'housenumber',
              'street',
              'locality',
              'district',
              'city',
              'county',
              'state',
              'postcode',
              'country',
            ]
            .map((campo) => properties[campo]?.toString().trim())
            .whereType<String>()
            .where((parte) => parte.isNotEmpty);
    if (latitude == null || longitude == null || rotulo.isEmpty) return null;
    return LocalizacaoPonto(
      latitude: latitude,
      longitude: longitude,
      rotulo: rotulo.toSet().join(', '),
    );
  }
}
