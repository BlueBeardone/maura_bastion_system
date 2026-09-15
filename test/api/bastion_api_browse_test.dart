import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';

Map<String, dynamic> _bastionJson(String id) => {
      'id': id,
      'name': 'B$id',
      'description': 'D',
      'facilities': [],
      'defenders': [],
      'hirelings': [],
    };

void main() {
  test('browse requests page params and parses BastionPage', () async {
    String? requestedPath;
    final api = BastionApi(
      client: ApiClient(
        baseUrl: 'http://test',
        client: MockClient((request) async {
          requestedPath = request.url.toString();
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Bastions found',
              'data': {
                'bastions': [_bastionJson('b-1')],
                'page': 2,
                'limit': 20,
                'total': 57,
                'hasMore': true,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    final page = await api.browse(page: 2);

    expect(requestedPath, 'http://test/maura/v1/bastions/browse?page=2&limit=20');
    expect(page.bastions, hasLength(1));
    expect(page.bastions.first.id, 'b-1');
    expect(page.page, 2);
    expect(page.limit, 20);
    expect(page.total, 57);
    expect(page.hasMore, isTrue);
  });

  test('browse uses default page 1 and limit 20', () async {
    String? requestedPath;
    final api = BastionApi(
      client: ApiClient(
        baseUrl: 'http://test',
        client: MockClient((request) async {
          requestedPath = request.url.toString();
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'bastions': [], 'page': 1, 'limit': 20, 'total': 0, 'hasMore': false},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    await api.browse();

    expect(requestedPath, 'http://test/maura/v1/bastions/browse?page=1&limit=20');
  });

  test('getMine requests /maura/v1/bastions without the all param', () async {
    String? requestedPath;
    final api = BastionApi(
      client: ApiClient(
        baseUrl: 'http://test',
        client: MockClient((request) async {
          requestedPath = request.url.toString();
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [_bastionJson('mine-1')],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    final bastions = await api.getMine();

    expect(requestedPath, 'http://test/maura/v1/bastions');
    expect(bastions, hasLength(1));
    expect(bastions.first.id, 'mine-1');
  });
}
