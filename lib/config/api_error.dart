import 'package:dio/dio.dart';

String mensagemErroDio(
  DioException e, {
  required String fallback,
  Map<int, String> porStatus = const {},
}) {
  final response = e.response;
  if (response == null) {
    return 'Não foi possível conectar ao servidor';
  }

  final data = response.data;
  if (data is Map && data['message'] is String) {
    final mensagem = (data['message'] as String).trim();
    if (mensagem.isNotEmpty) {
      return mensagem;
    }
  }

  return porStatus[response.statusCode] ?? fallback;
}
