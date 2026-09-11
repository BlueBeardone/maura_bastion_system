import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/health_api.dart';

void main() {
  group('HealthApi', () {
    test('check() completes when the backend returns a null-data envelope', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Kafka is running',
            'data': null,
            'errors': null,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = HealthApi(
        client: ApiClient(baseUrl: 'http://example.test', client: mock),
      );

      expect(await api.check(), isTrue);
    });
  });
}