import 'token_storage.dart';

/// O navegador autentica com cookie HttpOnly; token não vai para JS storage.
class WebTokenStorage implements TokenStorage {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> delete() async {}
}

TokenStorage createTokenStorage() => WebTokenStorage();
