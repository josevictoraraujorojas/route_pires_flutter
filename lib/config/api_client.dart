import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_browser_config_stub.dart'
    if (dart.library.js_interop) 'api_browser_config_web.dart'
    as browser_config;
import 'api_config.dart';

/// Cliente único da API. O token fica em memória após a leitura do storage
/// seguro no mobile; no navegador a sessão usa cookie HttpOnly.
class ApiClient {
  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    browser_config.configureBrowserCookies(dio);
    dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio dio;
  String? _accessToken;
  String? _csrfToken;
  String _csrfHeader = 'X-CSRF-TOKEN';

  Future<void> Function()? onUnauthorized;

  void setAccessToken(String? token) => _accessToken = token;

  void setCsrf(String? token, {String headerName = 'X-CSRF-TOKEN'}) {
    _csrfToken = token;
    _csrfHeader = headerName;
  }

  void clearSession() {
    _accessToken = null;
    _csrfToken = null;
  }

  static bool _isPublic(RequestOptions options) {
    if (options.method.toUpperCase() != 'POST') return false;
    return switch (options.path) {
      '/login' ||
      '/auth/web/login' ||
      '/passageiros' ||
      '/mototaxistas' => true,
      _ => false,
    };
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isPublic(options)) {
      if (kIsWeb) {
        final method = options.method.toUpperCase();
        if (method != 'GET' && method != 'HEAD' && _csrfToken != null) {
          options.headers[_csrfHeader] = _csrfToken;
        }
      } else if (_accessToken != null) {
        options.headers['Authorization'] = 'Bearer $_accessToken';
      }
    }
    handler.next(options);
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) {
    if (error.response?.statusCode == 401 && !_isPublic(error.requestOptions)) {
      final callback = onUnauthorized;
      if (callback != null) {
        unawaited(callback());
      }
    }
    handler.next(error);
  }
}
