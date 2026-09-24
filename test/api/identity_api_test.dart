import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/dto/login_request.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/features/login/data/auth_session_store.dart';

class ThrowingTokenStorage implements TokenStorage {
  @override
  Future<void> write(String token) async {
    throw UnsupportedError(
      'FlutterSecureStorageWeb only works in secure contexts',
    );
  }

  @override
  Future<String?> read() async => null;

  @override
  Future<void> delete() async {}
}

void main() {
  group('IdentityApi.login token persistence', () {
    test('still returns the user when token storage fails', () async {
      final storage = ThrowingTokenStorage();
      final sessionStore = AuthSessionStore(storage: storage);

      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'User logged in',
            'data': {
              'user': {'id': '1', 'displayName': 'Assassin'},
              'token': 'jwt-token-abc',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'http://example.test',
        client: mock,
        sessionStore: sessionStore,
      );
      final identityApi =
          IdentityApi(client: client, sessionStore: sessionStore);

      final user = await identityApi.login(
        LoginRequest(username: 'alice', password: 'pw'),
      );

      expect(user.displayName, 'Assassin');
      expect(client.authToken, 'jwt-token-abc');
    });
  });
}
