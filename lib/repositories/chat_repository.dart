import 'package:dio/dio.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/api_config.dart';
import 'package:route_pires_flutter/model/chat.dart';
import 'package:route_pires_flutter/model/mensagem.dart';

class ChatRepository {
  final Dio _dio;

  ChatRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<List<Chat>> listar({CancelToken? cancelToken}) async {
    final response = await _dio.get(ApiConfig.chats, cancelToken: cancelToken);

    final data = response.data;

    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map((item) => Chat.fromJson(Map<String, dynamic>.from(item)))
        .where((chat) => chat.id.isNotEmpty)
        .toList();
  }

  Future<List<Mensagem>> listarMensagens(
    String chatId, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '${ApiConfig.chats}/$chatId/mensagens',
      cancelToken: cancelToken,
    );

    final data = response.data;

    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map((item) => Mensagem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
