import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/discord_api.dart';
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/facility_catalog.dart';
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
      String rank = 'd',
      int constructed = 0,
      int total = 0,
      int requiredHirelings = 0,
      String? branchUpgradeId,
      bool branchUpgradeActive = false,
    }) =>
        {
          'id': id,
          'name': name,
          'rank': rank.toLowerCase(),
          'description': 'desc',
          'constructionTurns': total,
          'constructedTurns': constructed,
          'minimumRequiredHirelings': requiredHirelings,
          'cost': 0,
          'branchUpgradeId': ?branchUpgradeId,
          'branchUpgradeActive': branchUpgradeActive,
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
      expect(jsonDecode(puts.first.body)['bastionId'], 'bastion-1');
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

    test('ignores re-entrant calls while an advance is in flight', () async {
      final puts = <http.Request>[];
      final putReceived = Completer<void>();
      final releasePut = Completer<void>();
      final mock = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(
                      id: 'barracks', name: 'Barracks', constructed: 0, total: 2),
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
          putReceived.complete();
          await releasePut.future;
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

      final first = cubit.advanceBastionTurn('bastion-1');
      await putReceived.future;

      final second = await cubit.advanceBastionTurn('bastion-1');
      expect(second, isNull);
      expect(puts.length, 1);

      releasePut.complete();
      final advanced = await first;
      expect(advanced, isNotNull);
      expect(advanced!.constructedTurns, 1);
      expect(puts.length, 1);

      await cubit.close();
    });

    test('stops advancing when facility reaches its construction cap',
        () async {
      final puts = <http.Request>[];
      var constructed = 1;
      final mock = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(
                      id: 'barracks',
                      name: 'Barracks',
                      constructed: constructed,
                      total: 2),
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
          constructed =
              (jsonDecode(request.body) as Map<String, dynamic>)['constructedTurns']
                  as int;
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

      final first = await cubit.advanceBastionTurn('bastion-1');
      expect(first, isNotNull);
      expect(first!.constructedTurns, 2);
      expect(puts.length, 1);
      expect(jsonDecode(puts.first.body)['constructedTurns'], 2);
      expect(jsonDecode(puts.first.body)['bastionId'], 'bastion-1');

      final second = await cubit.advanceBastionTurn('bastion-1');
      expect(second, isNull);
      expect(puts.length, 1);

      await cubit.close();
    });

    test('lapses an active perTurn branch upgrade on turn advance', () async {
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
                  facilityJson(
                    id: 'cat_kitchen', name: 'Kitchen', rank: 'd',
                    constructed: 0, total: 2,
                  ),
                  facilityJson(
                    id: 'cat_pub', name: 'Pub', rank: 'a',
                    branchUpgradeId: 'bru_pub_of_legend',
                    branchUpgradeActive: true,
                  ),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path.startsWith('/maura/v1/facilities/')) {
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

      await cubit.advanceBastionTurn('bastion-1');

      expect(puts, hasLength(2));
      final kitchenPut = puts.firstWhere(
        (r) => r.url.path == '/maura/v1/facilities/cat_kitchen',
      );
      final pubPut = puts.firstWhere(
        (r) => r.url.path == '/maura/v1/facilities/cat_pub',
      );
      final kitchenBody = jsonDecode(kitchenPut.body) as Map<String, dynamic>;
      final pubBody = jsonDecode(pubPut.body) as Map<String, dynamic>;
      expect(kitchenBody['constructedTurns'], 1);
      expect(pubBody['branchUpgradeActive'], isFalse);
      await cubit.close();
    });
  });

  group('BastionCubit.upgradeFacility', () {
    Map<String, dynamic> facilityJson({
      required String id,
      required String name,
      String rank = 'd',
      int constructed = 0,
      int total = 0,
      int requiredHirelings = 0,
      Map<String, dynamic>? table,
    }) =>
        {
          'id': id,
          'name': name,
          'rank': rank,
          'description': 'desc',
          'constructionTurns': total,
          'constructedTurns': constructed,
          'minimumRequiredHirelings': requiredHirelings,
          'cost': 0,
          'table': table,
        };

    Map<String, dynamic> bastionJson(List<Map<String, dynamic>> facilities) =>
        {
          'id': 'bastion-1',
          'userId': 'user_1',
          'name': 'Test Bastion',
          'description': 'desc',
          'facilities': facilities,
        };

    test('upgrades a built D facility to C, persisting rank, cost, and turns',
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
                  facilityJson(
                    id: 'cat_barracks',
                    name: 'Barracks',
                    constructed: 2,
                    total: 2,
                    table: {
                      'table': [
                        ['Rank', 'Capacity'],
                        ['D', '4'],
                      ],
                    },
                  ),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path == '/maura/v1/facilities/cat_barracks') {
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

      final barracks =
          (cubit.state as BastionLoadedState).bastions.first.facilities.first;
      final upgraded = await cubit.upgradeFacility('bastion-1', barracks);

      expect(upgraded, isNotNull);
      expect(upgraded!.rank, Rank.C);
      expect(upgraded.cost, 1500);
      expect(upgraded.constructionTurns, 2);
      expect(upgraded.constructedTurns, 0);
      expect(upgraded.id, 'cat_barracks');
      expect(upgraded.table, isNotNull);
      expect(puts.length, 1);
      final body = jsonDecode(puts.first.body) as Map<String, dynamic>;
      expect(body['rank'], 'c');
      expect(body['cost'], 1500);
      expect(body['constructionTurns'], 2);
      expect(body['constructedTurns'], 0);

      await cubit.close();
    });

    test('returns null without PUT when another facility is under construction',
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
                  facilityJson(
                      id: 'cat_barracks',
                      name: 'Barracks',
                      constructed: 2,
                      total: 2),
                  facilityJson(
                      id: 'cat_kitchen',
                      name: 'Kitchen',
                      constructed: 0,
                      total: 2),
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

      final barracks = (cubit.state as BastionLoadedState)
          .bastions
          .first
          .facilities
          .firstWhere((f) => f.id == 'cat_barracks');
      final result = await cubit.upgradeFacility('bastion-1', barracks);

      expect(result, isNull);
      expect(puts, isEmpty);

      await cubit.close();
    });

    test('returns null without PUT when the facility is already Rank S',
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
                  facilityJson(
                      id: 'cat_barracks',
                      name: 'Barracks',
                      rank: 's',
                      constructed: 2,
                      total: 2),
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

      final barracks = (cubit.state as BastionLoadedState)
          .bastions
          .first
          .facilities
          .firstWhere((f) => f.id == 'cat_barracks');
      final result = await cubit.upgradeFacility('bastion-1', barracks);

      expect(result, isNull);
      expect(puts, isEmpty);

      await cubit.close();
    });

    test('returns null without PUT for a non-upgradeable facility id',
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
                  facilityJson(
                      id: 'keep', name: 'Keep', constructed: 2, total: 2),
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

      final keep = (cubit.state as BastionLoadedState)
          .bastions
          .first
          .facilities
          .firstWhere((f) => f.id == 'keep');
      final result = await cubit.upgradeFacility('bastion-1', keep);

      expect(result, isNull);
      expect(puts, isEmpty);

      await cubit.close();
    });
  });

  group('BastionCubit.purchaseBranchUpgrade', () {
    Map<String, dynamic> facilityJson({
      required String id,
      required String name,
      required String rank,
      String? branchUpgradeId,
      bool branchUpgradeActive = false,
      int constructed = 2,
      int total = 2,
    }) =>
        {
          'id': id,
          'name': name,
          'rank': rank.toLowerCase(),
          'description': 'desc',
          'constructionTurns': total,
          'constructedTurns': constructed,
          'minimumRequiredHirelings': 1,
          'cost': 600,
          'branchUpgradeId': ?branchUpgradeId,
          'branchUpgradeActive': branchUpgradeActive,
        };

    Map<String, dynamic> bastionJson(List<Map<String, dynamic>> facilities) =>
        {
          'id': 'bastion-1',
          'userId': 'user_1',
          'name': 'Test Bastion',
          'description': 'desc',
          'facilities': facilities,
        };

    /// Returns (mockClient, capturedPuts). The mock answers GET
    /// /maura/v1/bastions with the given facilities and PUTs facilities back.
    (MockClient, List<http.Request>) purchaseMock(
      List<Map<String, dynamic>> facilities,
    ) {
      final puts = <http.Request>[];
      final mock = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [bastionJson(facilities)],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path.startsWith('/maura/v1/facilities/')) {
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
      return (mock, puts);
    }

    BastionCubit cubitWith(MockClient mock) {
      final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
      return BastionCubit(
        bastionApi: BastionApi(client: apiClient),
        facilityApi: FacilityApi(client: apiClient),
      );
    }

    test('purchases a oneTime upgrade and persists ownership', () async {
      final (mock, puts) = purchaseMock([
        facilityJson(id: 'cat_kitchen', name: 'Kitchen', rank: 'd'),
      ]);
      final cubit = cubitWith(mock);
      await cubit.loadBastions();
      final kitchen = (cubit.state as BastionLoadedState)
          .bastions
          .first
          .facilities
          .first;

      final result = await cubit.purchaseBranchUpgrade('bastion-1', kitchen);

      expect(result, isNotNull);
      expect(result!.branchUpgradeId, 'bru_industrial_kitchen');
      expect(result.branchUpgradeActive, isTrue);
      expect(puts, hasLength(1));
      final body = jsonDecode(puts.first.body) as Map<String, dynamic>;
      expect(body['branchUpgradeId'], 'bru_industrial_kitchen');
      expect(body['branchUpgradeActive'], isTrue);
      await cubit.close();
    });

    test('rejects purchase when a branch upgrade is already active',
        () async {
      final (mock, puts) = purchaseMock([
        facilityJson(
          id: 'cat_kitchen',
          name: 'Kitchen',
          rank: 'd',
          branchUpgradeId: 'bru_industrial_kitchen',
        ),
      ]);
      final cubit = cubitWith(mock);
      await cubit.loadBastions();
      final kitchen = (cubit.state as BastionLoadedState)
          .bastions
          .first
          .facilities
          .first;

      final result = await cubit.purchaseBranchUpgrade('bastion-1', kitchen);

      expect(result, isNull);
      expect(puts, isEmpty);
      await cubit.close();
    });

    test('rejects facilities without a branch upgrade', () async {
      final (mock, puts) = purchaseMock([
        facilityJson(id: 'cat_barracks', name: 'Barracks', rank: 'd'),
      ]);
      final cubit = cubitWith(mock);
      await cubit.loadBastions();
      final barracks = (cubit.state as BastionLoadedState)
          .bastions
          .first
          .facilities
          .first;

      final result = await cubit.purchaseBranchUpgrade('bastion-1', barracks);

      expect(result, isNull);
      expect(puts, isEmpty);
      await cubit.close();
    });

    test('rejects facility still under construction', () async {
      final (mock, puts) = purchaseMock([
        facilityJson(
            id: 'cat_kitchen', name: 'Kitchen', rank: 'd',
            constructed: 0, total: 2),
      ]);
      final cubit = cubitWith(mock);
      await cubit.loadBastions();
      final kitchen = (cubit.state as BastionLoadedState)
          .bastions
          .first
          .facilities
          .first;

      final result = await cubit.purchaseBranchUpgrade('bastion-1', kitchen);

      expect(result, isNull);
      expect(puts, isEmpty);
      await cubit.close();
    });

    test('renews a lapsed perTurn upgrade', () async {
      final (mock, puts) = purchaseMock([
        facilityJson(
          id: 'cat_pub',
          name: 'Pub',
          rank: 'a',
          branchUpgradeId: 'bru_pub_of_legend',
          branchUpgradeActive: false,
        ),
      ]);
      final cubit = cubitWith(mock);
      await cubit.loadBastions();
      final pub = (cubit.state as BastionLoadedState)
          .bastions
          .first
          .facilities
          .first;

      final result = await cubit.purchaseBranchUpgrade('bastion-1', pub);

      expect(result, isNotNull);
      expect(result!.branchUpgradeActive, isTrue);
      expect(puts, hasLength(1));
      await cubit.close();
    });

    test('rejects perUse upgrades without persisting anything', () async {
      final (mock, puts) = purchaseMock([
        facilityJson(id: 'cat_theatre', name: 'Theatre', rank: 'b'),
      ]);
      final cubit = cubitWith(mock);
      await cubit.loadBastions();
      final theatre = (cubit.state as BastionLoadedState)
          .bastions
          .first
          .facilities
          .first;

      final result = await cubit.purchaseBranchUpgrade('bastion-1', theatre);

      expect(result, isNull);
      expect(puts, isEmpty);
      await cubit.close();
    });
  });

  group('BastionCubit announcements', () {
    final discordPosts = <http.Request>[];
    late MockClient mock;

    setUp(() {
      discordPosts.clear();
      mock = MockClient((request) async {
const discordPaths = <String>{
        '/maura/v1/discord/bastion-creation',
        '/maura/v1/discord/facility-built',
        '/maura/v1/discord/facility-rank-up',
        '/maura/v1/discord/branch-upgrade',
      };
      if (request.method == 'POST' && discordPaths.contains(request.url.path)) {
        discordPosts.add(request);
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'POST' && request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': {
                ...jsonDecode(request.body) as Map<String, dynamic>,
                'id': 'bastion-1',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'POST' && request.url.path == '/maura/v1/facilities') {
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
        if (request.method == 'PUT' &&
            request.url.path.startsWith('/maura/v1/facilities/')) {
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
        if (request.method == 'GET' && request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                {
                  'id': 'bastion-1',
                  'userId': 'user_1',
                  'name': 'Ravencrest',
                  'description': 'A keep on the hill.',
                  'facilities': [
                    {
                      'id': 'cat_barracks',
                      'name': 'Barracks',
                      'rank': 'd',
                      'description': 'Houses the guard.',
                      'constructionTurns': 2,
                      'constructedTurns': 2,
                      'minimumRequiredHirelings': 0,
                      'cost': 600,
                    },
                    {
                      'id': 'cat_kitchen',
                      'name': 'Kitchen',
                      'rank': 'd',
                      'description': 'Cooks food.',
                      'constructionTurns': 2,
                      'constructedTurns': 2,
                      'minimumRequiredHirelings': 1,
                      'cost': 600,
                    },
                  ],
                },
              ],
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
    });

    BastionCubit cubit() => BastionCubit(
          bastionApi: BastionApi(
              client: ApiClient(baseUrl: 'http://example.test', client: mock)),
          facilityApi: FacilityApi(
              client: ApiClient(baseUrl: 'http://example.test', client: mock)),
          discordAnnouncer: DiscordAnnouncer(
              discordApi: DiscordApi(
                  client:
                      ApiClient(baseUrl: 'http://example.test', client: mock))),
        );

    test('createBastion announces the founding', () async {
      final c = cubit();
      await c.createBastion('Ravencrest', 'A keep on the hill.', null, []);

      expect(discordPosts, hasLength(1));
      final body = jsonDecode(discordPosts.first.body) as Map<String, dynamic>;
      expect(body['message'],
          '🏰 **Ravencrest** has been founded!\n\nA keep on the hill.');

      await c.close();
    });

    test('addFacility announces construction start with the bastion name', () async {
      final c = cubit();
      await c.loadBastions();
      discordPosts.clear();

      const facility = Facility(
        id: 'cat_garden',
        name: 'Garden',
        rank: Rank.D,
        description: 'Grows food.',
        constructionTurns: 2,
        cost: 600,
      );
      await c.addFacility('bastion-1', facility);

      expect(discordPosts, hasLength(1));
      final body = jsonDecode(discordPosts.first.body) as Map<String, dynamic>;
      expect(
        body['message'],
        '🏗️ **Ravencrest** has started construction on **Garden** (Rank D)!\n\n'
            'Grows food.\n\n'
            'Cost: 600gp • Build time: 2 turns • Required hirelings: 0',
      );

      await c.close();
    });

    test('upgradeFacility announces the rank advance', () async {
      final c = cubit();
      await c.loadBastions();
      final bastion =
          (c.state as BastionLoadedState).bastions.first;
      final barracks = bastion.facilities
          .firstWhere((f) => f.id == 'cat_barracks');
      discordPosts.clear();

      await c.upgradeFacility('bastion-1', barracks);

      expect(discordPosts, hasLength(1));
      final body = jsonDecode(discordPosts.first.body) as Map<String, dynamic>;
      expect(
        body['message'],
        '⬆️ **Ravencrest**\'s **Barracks** is advancing from Rank D to Rank C!\n\n'
            'Houses the guard.\n\n'
            'Upgrade cost: 900gp • Construction: 2 turns',
      );

      await c.close();
    });

    test('purchaseBranchUpgrade announces the activation', () async {
      final c = cubit();
      await c.loadBastions();
      final bastion =
          (c.state as BastionLoadedState).bastions.first;
      final kitchen = bastion.facilities
          .firstWhere((f) => f.id == 'cat_kitchen');
      discordPosts.clear();

      final upgrade = branchUpgradeFor('cat_kitchen');
      expect(upgrade, isNotNull);

      await c.purchaseBranchUpgrade('bastion-1', kitchen);

      expect(discordPosts, hasLength(1));
      final body = jsonDecode(discordPosts.first.body) as Map<String, dynamic>;
      expect(
        body['message'],
        startsWith(
            '🌟 **Ravencrest**\'s **Kitchen** activates **Industrial Kitchen**!'),
      );
      expect(
        body['message'],
        contains('One-time purchase • Cost: 500gp • Hireling capacity: 3'),
      );

      await c.close();
    });

    test('cubit methods still succeed when the announcer throws', () async {
      final throwingAnnouncer = _ThrowingAnnouncer(
          discordApi: DiscordApi(
              client: ApiClient(baseUrl: 'http://example.test')));
      final c = BastionCubit(
        bastionApi: BastionApi(
            client: ApiClient(baseUrl: 'http://example.test', client: mock)),
        facilityApi: FacilityApi(
            client: ApiClient(baseUrl: 'http://example.test', client: mock)),
        discordAnnouncer: throwingAnnouncer,
      );
      await c.loadBastions();
      final bastion =
          (c.state as BastionLoadedState).bastions.first;
      final barracks = bastion.facilities
          .firstWhere((f) => f.id == 'cat_barracks');

      final upgraded = await c.upgradeFacility('bastion-1', barracks);

      expect(upgraded, isNotNull);

      await c.close();
    });
  });
}

class _ThrowingAnnouncer extends DiscordAnnouncer {
  _ThrowingAnnouncer({required super.discordApi});

  @override
  Future<void> announceFacilityRankUp(
    Bastion bastion,
    Facility oldFacility,
    Facility upgraded,
  ) =>
      throw Exception('Discord is down');
}
