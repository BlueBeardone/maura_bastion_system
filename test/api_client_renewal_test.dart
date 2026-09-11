import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/api_exception.dart';
import 'package:maura_bastion_system/features/login/data/auth_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AuthSessionStore freshStore() => AuthSessionStore();

  test('successful response with renewedToken updates token and persists it', () async {
    final store = freshStore();
    final client = ApiClient(
      sessionStore: store,
      client: MockClient((request) async => http.Response(
            jsonEncode({'success': true, 'data': {'k': 'v'}, 'renewedToken': 'new-token'}),
            200,
            headers: {'content-type': 'application/json'},
          )),
    );
    client.setAuthToken('old-token');

    await client.get<Map<String, dynamic>>('/x', parser: (json) => json as Map<String, dynamic>);

    expect(client.authToken, 'new-token');
    expect(await store.load(), 'new-token');
  });

  test('successful response without renewedToken leaves token unchanged', () async {
    final store = freshStore();
    final client = ApiClient(
      sessionStore: store,
      client: MockClient((request) async => http.Response(
            jsonEncode({'success': true, 'data': {'k': 'v'}}),
            200,
            headers: {'content-type': 'application/json'},
          )),
    );
    client.setAuthToken('old-token');

    await client.get<Map<String, dynamic>>('/x', parser: (json) => json as Map<String, dynamic>);

    expect(client.authToken, 'old-token');
    expect(await store.load(), isNull);
  });

  test('error response does not renew', () async {
    final store = freshStore();
    final client = ApiClient(
      sessionStore: store,
      client: MockClient((request) async => http.Response(
            jsonEncode({'success': false, 'message': 'Invalid token', 'renewedToken': 'evil'}),
            401,
            headers: {'content-type': 'application/json'},
          )),
    );
    client.setAuthToken('old-token');

    await expectLater(
      client.get<Map<String, dynamic>>('/x', parser: (json) => json as Map<String, dynamic>),
      throwsA(isA<ApiException>()),
    );
    expect(client.authToken, 'old-token');
    expect(await store.load(), isNull);
  });

  test('subsequent request uses the renewed token in the Authorization header', () async {
    SharedPreferences.setMockInitialValues({});
    final store = freshStore();
    String? seenAuthHeader;
    final client = ApiClient(
      sessionStore: store,
      client: MockClient((request) async {
        seenAuthHeader = request.headers['Authorization'];
        return http.Response(
          jsonEncode({'success': true, 'data': {}, 'renewedToken': 'new-token'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    client.setAuthToken('old-token');
    await client.get<Map<String, dynamic>>('/first', parser: (json) => json as Map<String, dynamic>);
    await client.get<Map<String, dynamic>>('/second', parser: (json) => json as Map<String, dynamic>);

    expect(seenAuthHeader, 'Bearer new-token');
  });
}
