import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/api_exception.dart';

void main() {
  group('ApiClient', () {
    test('sends an enveloped GET and parses the data payload', () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': {'name': 'A'}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'http://example.test',
        client: mock,
      );

      final result = await client.get<Map<String, dynamic>>(
        '/maura/v1/bastions',
        parser: (json) => json as Map<String, dynamic>,
      );

      expect(captured.method, 'GET');
      expect(captured.url.toString(), 'http://example.test/maura/v1/bastions');
      expect(result['name'], 'A');
    });

    test('throws ApiException with the server message on non-success status',
        () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'bad credentials'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(baseUrl: 'http://example.test', client: mock);

      expect(
        () => client.get<Map<String, dynamic>>(
          '/maura/v1/bastions',
          parser: (json) => json as Map<String, dynamic>,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'bad credentials'),
        ),
      );
    });

    test('sends the auth token as a Bearer header', () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'http://example.test',
        client: mock,
      )..setAuthToken('abc123');

      await client.get<Map<String, dynamic>>(
        '/maura/v1/bastions',
        parser: (json) => json as Map<String, dynamic>,
      );

      expect(captured.headers['authorization'], 'Bearer abc123');
    });
  });
}