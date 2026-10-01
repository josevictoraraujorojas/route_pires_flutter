import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';

class LocalizacaoRepository {
  static final compartilhado = LocalizacaoRepository();
  static const _urlConfigurada = String.fromEnvironment('GEOCODING_BASE_URL');
  static const _urlPhoton = 'https://photon.komoot.io';
  static const _urlPhotonMobile = 'https://photon.koalasec.org';

  LocalizacaoRepository({Dio? dio})
    : _dio =
          dio ??
          _criarDio(
            _urlConfigurada.isNotEmpty
                ? _urlConfigurada
                : kIsWeb
                ? _urlPhoton
                : _urlPhotonMobile,
          ),
      _dioReserva = dio == null && !kIsWeb && _urlConfigurada.isEmpty
          ? _criarDio(_urlPhoton)
          : null;

  final Dio _dio;
  final Dio? _dioReserva;
  final _buscas = <String, List<LocalizacaoPonto>>{};
  final _enderecos = <String, (DateTime, LocalizacaoPonto)>{};
  final _enderecosEmBusca = <String, Future<LocalizacaoPonto>>{};

  static Dio _criarDio(String baseUrl) => Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 10),
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'RoutePiresFlutter/1.0',
      },
    ),
  );

  Future<Response<dynamic>> _consultar(
    String caminho,
    Map<String, dynamic> parametros,
  ) async {
    try {
      return await _dio.get<dynamic>(caminho, queryParameters: parametros);
    } on DioException catch (erro) {
      final reserva = _dioReserva;
      final status = erro.response?.statusCode;
      if (reserva == null ||
          (status != null && status != 429 && status < 500)) {
        rethrow;
      }
      return reserva.get<dynamic>(caminho, queryParameters: parametros);
    }
  }

  String _chaveEndereco(LatLng ponto) =>
      '${ponto.latitude.toStringAsFixed(5)},'
      '${ponto.longitude.toStringAsFixed(5)}';

  LocalizacaoPonto? enderecoEmCache(LatLng ponto) {
    final chave = _chaveEndereco(ponto);
    final armazenado = _enderecos[chave];
    if (armazenado == null) return null;
    if (armazenado.$1.isAfter(DateTime.now())) return armazenado.$2;
    _enderecos.remove(chave);
    return null;
  }

  void guardarEndereco(LocalizacaoPonto ponto) {
    if (!LocalizacaoPonto.rotuloLegivel(ponto.rotulo)) return;
    _enderecos[_chaveEndereco(LatLng(ponto.latitude, ponto.longitude))] = (
      DateTime.now().add(const Duration(days: 1)),
      ponto,
    );
  }

  Future<List<LocalizacaoPonto>> buscar(String texto) async {
    final chave = texto.trim().toLowerCase();
    if (_buscas[chave] case final resultado?) return resultado;

    final response = await _consultar('/api', {
      'q': texto.trim(),
      'countrycode': 'BR',
      'limit': 5,
      'lat': -17.29972,
      'lon': -48.27944,
    });
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
    final chave = _chaveEndereco(ponto);
    final armazenado = enderecoEmCache(ponto);
    if (armazenado != null) return armazenado;
    final emBusca = _enderecosEmBusca[chave];
    if (emBusca != null) return emBusca;

    final busca = _buscarEndereco(ponto);
    _enderecosEmBusca[chave] = busca;
    try {
      final encontrado = await busca;
      final prazoCache = encontrado.rotulo == 'Endereço indisponível'
          ? const Duration(minutes: 5)
          : const Duration(days: 1);
      _enderecos[chave] = (DateTime.now().add(prazoCache), encontrado);
      return encontrado;
    } finally {
      _enderecosEmBusca.remove(chave);
    }
  }

  Future<LocalizacaoPonto> _buscarEndereco(LatLng ponto) async {
    final response = await _consultar('/reverse', {
      'lat': ponto.latitude,
      'lon': ponto.longitude,
      'limit': 1,
    });
    final data = response.data;
    final features = data is Map ? data['features'] : null;
    final resultado = features is List && features.isNotEmpty
        ? _ponto(features.first)
        : null;
    final endereco = LocalizacaoPonto(
      latitude: ponto.latitude,
      longitude: ponto.longitude,
      rotulo: resultado?.rotulo ?? 'Endereço indisponível',
    );
    return endereco;
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
