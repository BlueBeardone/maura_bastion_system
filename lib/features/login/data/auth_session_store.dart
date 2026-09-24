import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<void> write(String token);
  Future<String?> read();
  Future<void> delete();
}

class SecureTokenStorage implements TokenStorage {
  static const _key = 'auth_token';
  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

class AuthSessionStore {
  final TokenStorage _storage;

  AuthSessionStore({TokenStorage? storage}) : _storage = storage ?? SecureTokenStorage();

  Future<void> save(String token) => _storage.write(token);

  Future<String?> load() => _storage.read();

  Future<void> clear() => _storage.delete();
}
