import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/features/login/data/auth_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load returns null when nothing saved', () async {
    final store = AuthSessionStore();
    expect(await store.load(), isNull);
  });

  test('save then load returns the token', () async {
    final store = AuthSessionStore();
    await store.save('token-abc');
    expect(await store.load(), 'token-abc');
  });

  test('clear removes the token', () async {
    final store = AuthSessionStore();
    await store.save('token-abc');
    await store.clear();
    expect(await store.load(), isNull);
  });
}
