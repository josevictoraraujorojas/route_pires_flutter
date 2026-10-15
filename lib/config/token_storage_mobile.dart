import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_storage.dart';

class MobileTokenStorage implements TokenStorage {
  MobileTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

TokenStorage createTokenStorage() => MobileTokenStorage();
