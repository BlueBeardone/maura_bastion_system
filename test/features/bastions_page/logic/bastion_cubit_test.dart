import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';

void main() {
  group('BastionCubit.addFacility', () {
    test('POSTs the facility to /maura/v1/facilities from any state',
        () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        if (request.url.path == '/maura/v1/facilities') {
          captured = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': jsonDecode(request.body),
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': false, 'message': 'unexpected'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
      final cubit = BastionCubit(
        bastionApi: BastionApi(client: apiClient),
        facilityApi: FacilityApi(client: apiClient),
      );

      final facility = Facility(
        id: 'barracks',
        name: 'Barracks',
        rank: Rank.D,
        description: 'Houses the guard.',
        constructionTurns: 2,
        cost: 100,
      );

      await cubit.addFacility('bastion-1', facility);

      expect(captured, isNotNull);
      expect(captured.method, 'POST');
      expect(captured.url.path, '/maura/v1/facilities');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['bastionId'], 'bastion-1');
      expect(body['id'], 'barracks');

      await cubit.close();
    });
  });
}