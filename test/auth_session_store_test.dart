import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/features/login/data/auth_session_store.dart';

class InMemoryTokenStorage implements TokenStorage {
  String? _value;

  @override
  Future<void> write(String token) async => _value = token;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> delete() async => _value = null;
}

void main() {
  late AuthSessionStore store;

  setUp(() {
    store = AuthSessionStore(storage: InMemoryTokenStorage());
  });

  test('load returns null when nothing saved', () async {
    expect(await store.load(), isNull);
  });

  test('save then load returns the token', () async {
    await store.save('token-abc');
    expect(await store.load(), 'token-abc');
  });

  test('clear removes the token', () async {
    await store.save('token-abc');
    await store.clear();
    expect(await store.load(), isNull);
  });

  group('SecureTokenStorage (real FlutterSecureStorage delegation)', () {
    test('read returns the value stored under the auth_token key', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'seeded'});
      final storage = SecureTokenStorage();

      expect(await storage.read(), 'seeded');
    });

    test('write stores the token under the auth_token key', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = SecureTokenStorage();

      await storage.write('token-xyz');

      expect(
        await const FlutterSecureStorage().read(key: 'auth_token'),
        'token-xyz',
      );
    });

    test('delete removes the auth_token key', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'seeded'});
      final storage = SecureTokenStorage();

      await storage.delete();

      expect(await storage.read(), isNull);
    });

    test('round-trips through AuthSessionStore end to end', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final store = AuthSessionStore(storage: SecureTokenStorage());

      await store.save('token-123');
      expect(await store.load(), 'token-123');
      await store.clear();
      expect(await store.load(), isNull);
    });
  });
}
