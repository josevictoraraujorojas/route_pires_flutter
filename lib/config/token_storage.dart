import 'token_storage_mobile.dart'
    if (dart.library.js_interop) 'token_storage_web.dart'
    as platform;

abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

TokenStorage createTokenStorage() => platform.createTokenStorage();
