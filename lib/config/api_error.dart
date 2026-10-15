import 'package:dio/dio.dart';

String mensagemErroDio(
  DioException e, {
  required String fallback,
  Map<int, String> porStatus = const {},
}) {
  final response = e.response;
  if (response == null) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'O servidor demorou para responder. Tente novamente';
    }
    return 'Não foi possível conectar ao servidor';
  }

  if (response.statusCode == 502 ||
      response.statusCode == 503 ||
      response.statusCode == 504) {
    return 'Servidor indisponível no momento. Tente novamente em instantes';
  }

  final data = response.data;
  if (data is Map && data['message'] is String) {
    final mensagem = (data['message'] as String).trim();
    if (mensagem.isNotEmpty) {
      return mensagem;
    }
  }

  if (response.statusCode == 403) {
    return 'Você não tem permissão para esta ação';
  }
  return porStatus[response.statusCode] ?? fallback;
}
