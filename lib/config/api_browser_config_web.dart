import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

void configureBrowserCookies(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
}
