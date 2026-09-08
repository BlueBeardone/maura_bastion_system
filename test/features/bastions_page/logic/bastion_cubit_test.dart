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

  group('BastionCubit.advanceBastionTurn', () {
    Map<String, dynamic> facilityJson({
      required String id,
      required String name,
      int constructed = 0,
      int total = 0,
      int requiredHirelings = 0,
    }) =>
        {
          'id': id,
          'name': name,
          'rank': 'd',
          'description': 'desc',
          'constructionTurns': total,
          'constructedTurns': constructed,
          'minimumRequiredHirelings': requiredHirelings,
          'cost': 0,
        };

    Map<String, dynamic> bastionJson(List<Map<String, dynamic>> facilities) =>
        {
          'id': 'bastion-1',
          'userId': 'user_1',
          'name': 'Test Bastion',
          'description': 'desc',
          'facilities': facilities,
        };

    test('increments the FIRST under-construction facility and persists it',
        () async {
      final puts = <http.Request>[];
      var bastionGets = 0;
      final mock = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          bastionGets++;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(id: 'keep', name: 'Keep'),
                  facilityJson(
                      id: 'barracks', name: 'Barracks', constructed: 0, total: 2),
                  facilityJson(
                      id: 'garden', name: 'Garden', constructed: 1, total: 3),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path == '/maura/v1/facilities/barracks') {
          puts.add(request);
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
      await cubit.loadBastions();

      final advanced = await cubit.advanceBastionTurn('bastion-1');

      expect(advanced, isNotNull);
      expect(advanced!.name, 'Barracks');
      expect(advanced.constructedTurns, 1);
      expect(puts.length, 1);
      expect(
        jsonDecode(puts.first.body)['constructedTurns'],
        1,
      );
      expect(bastionGets, greaterThanOrEqualTo(2)); // refetched after update

      await cubit.close();
    });

    test('returns null and calls no API when all facilities are complete',
        () async {
      final puts = <http.Request>[];
      final mock = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(id: 'keep', name: 'Keep'),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT') {
          puts.add(request);
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
      await cubit.loadBastions();

      final advanced = await cubit.advanceBastionTurn('bastion-1');

      expect(advanced, isNull);
      expect(puts, isEmpty);

      await cubit.close();
    });
  });
}