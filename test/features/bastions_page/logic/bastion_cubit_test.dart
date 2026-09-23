import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/discord_api.dart';
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_result.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/bastion/facility_catalog.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';

/// Wraps a handler so `GET /maura/v1/bastions/browse` returns an empty page
/// with hasMore: false. The cubit's loadBastions now fetches getMine() +
/// browse(page: 1); getMine() hits the same `/maura/v1/bastions` endpoint the
/// handlers below already serve, so the loaded state's `bastions` getter still
/// yields exactly the bastions these mocks return.
MockClient _withEmptyBrowsePage(
  Future<http.Response> Function(http.Request request) handler,
) {
  return MockClient((request) async {
    if (request.method == 'GET' &&
        request.url.path == '/maura/v1/bastions/browse') {
      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'ok',
          'data': {
            'bastions': [],
            'page': 1,
            'limit': 20,
            'total': 0,
            'hasMore': false,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return handler(request);
  });
}

void main() {
  group('BastionCubit.addFacility', () {
    test('POSTs the facility to /maura/v1/facilities from any state',
        () async {
      late http.Request captured;
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                {
                  'id': 'bastion-1',
                  'userId': 'user_1',
                  'name': 'Test Bastion',
                  'description': 'desc',
                  'facilities': [],
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
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

      await cubit.loadBastions();
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

  group('BastionCubit facility cap', () {
    Map<String, dynamic> facilityJson({
      required String id,
      required String name,
      String rank = 'd',
    }) =>
        {
          'id': id,
          'name': name,
          'rank': rank,
          'description': 'desc',
          'constructionTurns': 2,
          'constructedTurns': 2,
          'minimumRequiredHirelings': 0,
          'cost': 600,
        };

    Map<String, dynamic> bastionJson(List<Map<String, dynamic>> facilities) =>
        {
          'id': 'bastion-1',
          'userId': 'user_1',
          'name': 'Test Bastion',
          'description': 'desc',
          'facilities': facilities,
        };

    test('addFacility rejects a 17th facility without any API call', () async {
      final posts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson(List.generate(
                  maxFacilitiesPerBastion,
                  (i) => facilityJson(id: 'f$i', name: 'F$i'),
                )),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'POST') {
          posts.add(request);
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
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

      final facility = Facility(
        id: 'barracks',
        name: 'Barracks',
        rank: Rank.D,
        description: 'Houses the guard.',
        constructionTurns: 2,
        cost: 100,
      );

      final ok = await cubit.addFacility('bastion-1', facility);

      expect(ok, isFalse);
      expect(posts, isEmpty);

      await cubit.close();
    });

    test('addFacility allows a 16th facility', () async {
      final posts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson(List.generate(
                  maxFacilitiesPerBastion - 1,
                  (i) => facilityJson(id: 'f$i', name: 'F$i'),
                )),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'POST' &&
            request.url.path == '/maura/v1/facilities') {
          posts.add(request);
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

      final facility = Facility(
        id: 'barracks',
        name: 'Barracks',
        rank: Rank.D,
        description: 'Houses the guard.',
        constructionTurns: 2,
        cost: 100,
      );

      final ok = await cubit.addFacility('bastion-1', facility);

      expect(ok, isTrue);
      expect(posts, hasLength(1));

      await cubit.close();
    });

    test('createBastion rejects more than 16 selected facilities', () async {
      final posts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/maura/v1/bastions') {
          posts.add(request);
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
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

      final facilities = List.generate(maxFacilitiesPerBastion + 1, (i) =>
          Facility(
            id: 'f$i',
            name: 'F$i',
            rank: Rank.D,
            description: 'desc',
            constructionTurns: 2,
            cost: 600,
          ));

      final result = await cubit.createBastion('Name', 'desc', null, facilities);

      expect(result, isNull);
      expect(posts, isEmpty);

      await cubit.close();
    });
  });

  group('BastionCubit S-Rank base facility restriction', () {
    Map<String, dynamic> facilityJson({
      required String id,
      required String name,
      String rank = 'd',
    }) =>
        {
          'id': id,
          'name': name,
          'rank': rank,
          'description': 'desc',
          'constructionTurns': 2,
          'constructedTurns': 2,
          'minimumRequiredHirelings': 0,
          'cost': 600,
        };

    Map<String, dynamic> bastionJson(List<Map<String, dynamic>> facilities) =>
        {
          'id': 'bastion-1',
          'userId': 'user_1',
          'name': 'Test Bastion',
          'description': 'desc',
          'facilities': facilities,
        };

    test('addFacility rejects a second S-Rank base facility without any API call',
        () async {
      final posts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(id: 'cat_colosseum', name: 'Colosseum', rank: 's'),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'POST') {
          posts.add(request);
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
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

      final ok = await cubit.addFacility(
        'bastion-1',
        Facility(
          id: 'cat_ivory_tower',
          name: 'Ivory Tower',
          rank: Rank.S,
          description: 'desc',
        ),
      );

      expect(ok, isFalse);
      expect(posts, isEmpty);

      await cubit.close();
    });

    test('addFacility allows an S-Rank base facility when only an upgraded S-Rank Bedroom exists',
        () async {
      final posts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(id: 'cat_bedroom', name: 'Bedroom', rank: 's'),
                ]),
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'POST' &&
            request.url.path == '/maura/v1/facilities') {
          posts.add(request);
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

      final ok = await cubit.addFacility(
        'bastion-1',
        Facility(
          id: 'cat_colosseum',
          name: 'Colosseum',
          rank: Rank.S,
          description: 'desc',
        ),
      );

      expect(ok, isTrue);
      expect(posts, hasLength(1));

      await cubit.close();
    });

    test('createBastion rejects two S-Rank base facilities', () async {
      final posts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/maura/v1/bastions') {
          posts.add(request);
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
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

      final facilities = [
        Facility(
          id: 'cat_colosseum',
          name: 'Colosseum',
          rank: Rank.S,
          description: 'desc',
        ),
        Facility(
          id: 'cat_ivory_tower',
          name: 'Ivory Tower',
          rank: Rank.S,
          description: 'desc',
        ),
      ];

      final result = await cubit.createBastion('Name', 'desc', null, facilities);

      expect(result, isNull);
      expect(posts, isEmpty);

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
      final mock = _withEmptyBrowsePage((request) async {
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
      final mock = _withEmptyBrowsePage((request) async {
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
      final mock = _withEmptyBrowsePage((request) async {
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
      final mock = _withEmptyBrowsePage((request) async {
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
      final mock = _withEmptyBrowsePage((request) async {
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
                    id: 'cat_pub', name: 'Pub of Legend', rank: 'a',
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
      expect(pubBody['name'], 'Pub');
      final basePub =
          getFacilityCatalog().firstWhere((f) => f.id == 'cat_pub');
      expect(pubBody['description'], basePub.description);
      await cubit.close();
    });

    test('gate runs before the facility PUT and the turn is persisted',
        () async {
      final requests = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
        requests.add(request);
        if (request.method == 'POST' &&
            request.url.path == '/maura/v1/discord/individual-bastion-turn') {
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
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
      GetIt.I.registerSingleton<DiscordApi>(
        DiscordApi(
            client: ApiClient(baseUrl: 'http://example.test', client: mock)),
      );
      addTearDown(GetIt.I.reset);
      final cubit = BastionCubit(
        bastionApi: BastionApi(client: apiClient),
        facilityApi: FacilityApi(client: apiClient),
      );
      await cubit.loadBastions();
      requests.clear();

      final gateCalls = <String>[];
      final advanced = await cubit.advanceBastionTurn(
        'bastion-1',
        gate: (advanced) async {
          gateCalls.add('gate:${advanced?.name}');
          await GetIt.I<DiscordApi>()
              .sendIndividualBastionTurn(BastionTurnResult(
            bastionId: 'bastion-1',
            bastionName: 'Test Bastion',
            quest: 'Patrol',
          ));
        },
      );

      expect(advanced, isNotNull);
      expect(gateCalls, ['gate:Barracks']);
      expect(requests[0].url.path,
          '/maura/v1/discord/individual-bastion-turn');
      expect(requests[1].url.path, '/maura/v1/facilities/barracks');

      await cubit.close();
    });

    test('gate runs with null when no facility is under construction',
        () async {
      final requests = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
        requests.add(request);
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(id: 'keep', name: 'Keep', constructed: 2,
                      total: 2),
                ]),
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

      final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
      final cubit = BastionCubit(
        bastionApi: BastionApi(client: apiClient),
        facilityApi: FacilityApi(client: apiClient),
      );
      await cubit.loadBastions();
      requests.clear();

      final gateArgs = <Facility?>[];
      final advanced = await cubit.advanceBastionTurn(
        'bastion-1',
        gate: (advanced) async {
          gateArgs.add(advanced);
        },
      );

      expect(advanced, isNull);
      expect(gateArgs, [null]);
      expect(requests.where((r) => r.method == 'PUT'), isEmpty);
      expect(cubit.state, isA<BastionLoadedState>());

      await cubit.close();
    });

    test('a failing gate blocks the turn and returns null', () async {
      final puts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/maura/v1/discord/individual-bastion-turn') {
          return http.Response(
            jsonEncode({'success': false, 'message': 'webhook unreachable'}),
            500,
            headers: {'content-type': 'application/json'},
          );
        }
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
      GetIt.I.registerSingleton<DiscordApi>(
        DiscordApi(
            client: ApiClient(baseUrl: 'http://example.test', client: mock)),
      );
      addTearDown(GetIt.I.reset);
      final cubit = BastionCubit(
        bastionApi: BastionApi(client: apiClient),
        facilityApi: FacilityApi(client: apiClient),
      );
      await cubit.loadBastions();

      var gateRan = false;
      final advanced = await cubit.advanceBastionTurn(
        'bastion-1',
        gate: (advanced) async {
          gateRan = true;
          await GetIt.I<DiscordApi>()
              .sendIndividualBastionTurn(BastionTurnResult(
            bastionId: 'bastion-1',
            bastionName: 'Test Bastion',
            quest: 'Patrol',
          ));
        },
      );

      expect(gateRan, isTrue);
      expect(advanced, isNull);
      expect(puts, isEmpty);
      expect(cubit.state, isA<BastionLoadedState>());

      await cubit.close();
    });

    test('closeFacilityId marks an operational facility one turn short',
        () async {
      final puts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
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
                  facilityJson(
                      id: 'cat_kitchen', name: 'Kitchen', constructed: 2, total: 2),
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

      final advanced = await cubit.advanceBastionTurn(
        'bastion-1',
        closeFacilityId: 'cat_kitchen',
      );

      expect(advanced, isNotNull);
      expect(advanced!.name, 'Barracks');
      expect(puts, hasLength(2));
      final kitchenPut = puts
          .firstWhere((r) => r.url.path == '/maura/v1/facilities/cat_kitchen');
      final body = jsonDecode(kitchenPut.body) as Map<String, dynamic>;
      expect(body['constructedTurns'], 1);
      expect(body['constructionTurns'], 2);

      await cubit.close();
    });

    test('closeFacilityId persists when nothing else is under construction',
        () async {
      final puts = <http.Request>[];
      final gateArgs = <Facility?>[];
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson([
                  facilityJson(
                      id: 'cat_kitchen', name: 'Kitchen', constructed: 2, total: 2),
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

      final advanced = await cubit.advanceBastionTurn(
        'bastion-1',
        closeFacilityId: 'cat_kitchen',
        gate: (f) async => gateArgs.add(f),
      );

      expect(advanced, isNull);
      expect(gateArgs, [null]);
      expect(puts, hasLength(1));
      expect(jsonDecode(puts.single.body)['constructedTurns'], 1);
      expect(puts.single.url.path, '/maura/v1/facilities/cat_kitchen');

      await cubit.close();
    });

    test('closeFacilityId is a no-op for an absent facility', () async {
      final puts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
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

      await cubit.advanceBastionTurn(
        'bastion-1',
        closeFacilityId: 'cat_kitchen',
      );

      expect(
        puts.where((r) => r.url.path == '/maura/v1/facilities/cat_kitchen'),
        isEmpty,
      );

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
      final mock = _withEmptyBrowsePage((request) async {
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
      final mock = _withEmptyBrowsePage((request) async {
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
      final mock = _withEmptyBrowsePage((request) async {
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

    test('upgrades a facility id that is not in the catalog allowlist',
        () async {
      final puts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
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

      expect(result, isNotNull);
      expect(result!.rank, Rank.C);
      expect(puts, hasLength(1));
      expect(puts.single.url.path, contains('keep'));

      await cubit.close();
    });
  });

  group('BastionCubit.purchaseBranchUpgrade', () {
    Map<String, dynamic> facilityJson({
      required String id,
      required String name,
      required String rank,
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
      final mock = _withEmptyBrowsePage((request) async {
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
      expect(result!.name, 'Industrial Kitchen');
      final upgrade = branchUpgradeFor('cat_kitchen')!;
      expect(result.description, upgrade.upgradedDescription);
      expect(puts, hasLength(1));
      final body = jsonDecode(puts.first.body) as Map<String, dynamic>;
      expect(body['name'], 'Industrial Kitchen');
      expect(body['description'], upgrade.upgradedDescription);
      await cubit.close();
    });

    test('rejects purchase when a branch upgrade is already active',
        () async {
      final (mock, puts) = purchaseMock([
        facilityJson(id: 'cat_kitchen', name: 'Industrial Kitchen', rank: 'd'),
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

    test('purchases a perTurn upgrade again after it lapses', () async {
      final (mock, puts) = purchaseMock([
        facilityJson(id: 'cat_pub', name: 'Pub', rank: 'a'),
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
      expect(result!.name, 'Pub of Legend');
      expect(puts, hasLength(1));
      final body = jsonDecode(puts.first.body) as Map<String, dynamic>;
      expect(body['name'], 'Pub of Legend');
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
    var discordSucceeds = true;
    final bastionPosts = <http.Request>[];
    final facilityCreations = <http.Request>[];
    final facilityUpdates = <http.Request>[];
    final allRequests = <http.Request>[];
    late MockClient mock;

    setUp(() {
      discordPosts.clear();
      discordSucceeds = true;
      bastionPosts.clear();
      facilityCreations.clear();
      facilityUpdates.clear();
      allRequests.clear();
      mock = _withEmptyBrowsePage((request) async {
        allRequests.add(request);
const discordPaths = <String>{
        '/maura/v1/discord/bastion-creation',
        '/maura/v1/discord/facility-built',
        '/maura/v1/discord/facility-rank-up',
        '/maura/v1/discord/branch-upgrade',
      };
      if (request.method == 'POST' && discordPaths.contains(request.url.path)) {
        discordPosts.add(request);
        if (!discordSucceeds) {
          return http.Response(
            jsonEncode({'success': false, 'message': 'webhook unreachable'}),
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
        if (request.method == 'POST' && request.url.path == '/maura/v1/bastions') {
          bastionPosts.add(request);
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
          facilityCreations.add(request);
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
          facilityUpdates.add(request);
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

    test('upgradeFacility is blocked when the announcer throws', () async {
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

      expect(upgraded, isNull);
      expect(c.state, isA<BastionLoadedState>());

      await c.close();
    });

    test('addFacility is blocked when the Discord log fails', () async {
      discordSucceeds = false;
      final c = cubit();
      await c.loadBastions();

      const facility = Facility(
        id: 'cat_garden',
        name: 'Garden',
        rank: Rank.D,
        description: 'Grows food.',
        constructionTurns: 2,
        cost: 600,
      );
      await c.addFacility('bastion-1', facility);

      expect(facilityCreations, isEmpty);
      expect(c.state, isA<BastionLoadedState>());

      await c.close();
    });

    test('purchaseBranchUpgrade is blocked when the Discord log fails',
        () async {
      discordSucceeds = false;
      final c = cubit();
      await c.loadBastions();
      final bastion =
          (c.state as BastionLoadedState).bastions.first;
      final kitchen = bastion.facilities
          .firstWhere((f) => f.id == 'cat_kitchen');

      final result = await c.purchaseBranchUpgrade('bastion-1', kitchen);

      expect(result, isNull);
      expect(facilityUpdates, isEmpty);
      expect(c.state, isA<BastionLoadedState>());

      await c.close();
    });

    test('announcements are sent before the mutating call', () async {
      final c = cubit();
      await c.loadBastions();
      allRequests.clear();

      final bastion =
          (c.state as BastionLoadedState).bastions.first;
      final barracks = bastion.facilities
          .firstWhere((f) => f.id == 'cat_barracks');

      await c.upgradeFacility('bastion-1', barracks);

      expect(allRequests.length, greaterThanOrEqualTo(2));
      expect(allRequests[0].method, 'POST');
      expect(allRequests[0].url.path, '/maura/v1/discord/facility-rank-up');
      expect(allRequests[1].method, 'PUT');
      expect(
        allRequests[1].url.path,
        startsWith('/maura/v1/facilities/'),
      );

      await c.close();
    });
  });
  group('BastionCubit.removeFacility', () {
    Map<String, dynamic> facilityJson({
      required String id,
      required String name,
      String rank = 'd',
      int constructed = 2,
      int total = 2,
    }) =>
        {
          'id': id,
          'name': name,
          'rank': rank,
          'description': 'desc',
          'constructionTurns': total,
          'constructedTurns': constructed,
          'minimumRequiredHirelings': 0,
          'cost': 600,
        };

    Map<String, dynamic> hirelingJson({
      required String id,
      required String name,
      String? facilityId,
    }) =>
        {
          'id': id,
          'name': name,
          'bastionId': 'bastion-1',
          'facilityId': facilityId,
        };

    Map<String, dynamic> bastionJson(
      List<Map<String, dynamic>> facilities,
      List<Map<String, dynamic>> hirelings,
    ) =>
        {
          'id': 'bastion-1',
          'userId': 'user_1',
          'name': 'Ravencrest',
          'description': 'desc',
          'facilities': facilities,
          'hirelings': hirelings,
        };

    late List<http.Request> discordPosts;
    late List<http.Request> hirelingPuts;
    late List<http.Request> facilityDeletes;
    late bool discordSucceeds;
    final deletedFacilityIds = <String>{};
    late MockClient mock;

    setUp(() {
      discordPosts = [];
      hirelingPuts = [];
      facilityDeletes = [];
      discordSucceeds = true;
      deletedFacilityIds.clear();
      mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/maura/v1/discord/facility-removed') {
          discordPosts.add(request);
          if (!discordSucceeds) {
            return http.Response(
              jsonEncode({'success': false, 'message': 'webhook unreachable'}),
              500,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path.startsWith('/maura/v1/hirelings/')) {
          hirelingPuts.add(request);
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
        if (request.method == 'DELETE' &&
            request.url.path.startsWith('/maura/v1/facilities/')) {
          facilityDeletes.add(request);
          deletedFacilityIds.add(
              request.url.pathSegments.last);
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                {
                  ...bastionJson(
                    [
                      facilityJson(id: 'cat_barracks', name: 'Barracks'),
                      facilityJson(id: 'cat_kitchen', name: 'Kitchen'),
                    ],
                    [
                      hirelingJson(
                          id: 'h1', name: 'Tom', facilityId: 'cat_barracks'),
                      hirelingJson(
                          id: 'h2', name: 'Anna', facilityId: 'cat_kitchen'),
                      hirelingJson(id: 'h3', name: 'Ben'),
                    ],
                  ),
                  'facilities': [
                    facilityJson(id: 'cat_barracks', name: 'Barracks'),
                    facilityJson(id: 'cat_kitchen', name: 'Kitchen'),
                  ]
                      .where((f) => !deletedFacilityIds.contains(f['id']))
                      .toList(),
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
          hirelingApi: HirelingApi(
              client: ApiClient(baseUrl: 'http://example.test', client: mock)),
          discordAnnouncer: DiscordAnnouncer(
              discordApi: DiscordApi(
                  client:
                      ApiClient(baseUrl: 'http://example.test', client: mock))),
        );

    test('announces, unassigns the facility hirelings, deletes, and reloads',
        () async {
      final c = cubit();
      await c.loadBastions();
      final bastion = (c.state as BastionLoadedState).bastions.first;
      final barracks =
          bastion.facilities.firstWhere((f) => f.id == 'cat_barracks');

      await c.removeFacility('bastion-1', barracks);

      expect(discordPosts, hasLength(1));
      expect(hirelingPuts, hasLength(1));
      expect(hirelingPuts.first.url.path, '/maura/v1/hirelings/h1');
      expect(
        (jsonDecode(hirelingPuts.first.body)
            as Map<String, dynamic>)['facilityId'],
        isNull,
      );
      expect(facilityDeletes, hasLength(1));
      expect(
          facilityDeletes.first.url.path, '/maura/v1/facilities/cat_barracks');
      final reloaded = (c.state as BastionLoadedState).bastions.first;
      expect(reloaded.facilities.any((f) => f.id == 'cat_barracks'), isFalse);
      expect(reloaded.facilities.any((f) => f.id == 'cat_kitchen'), isTrue);

      await c.close();
    });

    test('is blocked when the Discord log fails', () async {
      discordSucceeds = false;
      final c = cubit();
      await c.loadBastions();
      final bastion = (c.state as BastionLoadedState).bastions.first;
      final barracks =
          bastion.facilities.firstWhere((f) => f.id == 'cat_barracks');

      await c.removeFacility('bastion-1', barracks);

      expect(hirelingPuts, isEmpty);
      expect(facilityDeletes, isEmpty);
      expect(c.state, isA<BastionLoadedState>());

      await c.close();
    });

    test('returns false when the delete fails', () async {
      final failingMock = _withEmptyBrowsePage((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/maura/v1/discord/facility-removed') {
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'DELETE') {
          return http.Response(
            jsonEncode({'success': false, 'message': 'db error'}),
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                bastionJson(
                  [facilityJson(id: 'cat_barracks', name: 'Barracks')],
                  [],
                ),
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
      final failingCubit = BastionCubit(
        bastionApi: BastionApi(
            client:
                ApiClient(baseUrl: 'http://example.test', client: failingMock)),
        facilityApi: FacilityApi(
            client:
                ApiClient(baseUrl: 'http://example.test', client: failingMock)),
        hirelingApi: HirelingApi(
            client:
                ApiClient(baseUrl: 'http://example.test', client: failingMock)),
      );
      await failingCubit.loadBastions();
      final fb = (failingCubit.state as BastionLoadedState).bastions.first;
      final f = fb.facilities.first;

      await failingCubit.removeFacility('bastion-1', f);

      expect(failingCubit.state, isA<BastionLoadedState>());
      expect(hirelingPuts, isEmpty);

      await failingCubit.close();
    });
  });

  group('BastionCubit.updateBastion', () {
    Map<String, dynamic> facilityJson({
      required String id,
      required String name,
      String rank = 'd',
    }) =>
        {
          'id': id,
          'name': name,
          'rank': rank,
          'description': 'desc',
          'constructionTurns': 0,
          'constructedTurns': 0,
          'minimumRequiredHirelings': 0,
          'cost': 0,
        };

    test(
        'PUTs updated details to /maura/v1/bastions/{id} and refreshes the user bastion',
        () async {
      Map<String, dynamic> bastion = {
        'id': 'bastion-1',
        'userId': 'user_1',
        'name': 'Old Name',
        'description': 'Old description',
        'imgUrl': 'https://old.example/keep.png',
        'facilities': [facilityJson(id: 'keep', name: 'Keep')],
      };
      final puts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': [bastion]}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path == '/maura/v1/bastions/bastion-1') {
          puts.add(request);
          bastion = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': bastion}),
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

      final toUpdate = (cubit.state as BastionLoadedState).userBastion!;
      final error = await cubit.updateBastion(toUpdate.copyWith(
        name: 'New Name',
        description: 'New description',
        imgUrl: null,
      ));

      expect(error, isNull);
      expect(puts, hasLength(1));
      expect(puts.first.url.path, '/maura/v1/bastions/bastion-1');
      final body = jsonDecode(puts.first.body) as Map<String, dynamic>;
      expect(body['name'], 'New Name');
      expect(body['description'], 'New description');
      expect(body['imgUrl'], isNull);
      expect((body['facilities'] as List).first['bastionId'], 'bastion-1');

      final refreshed = (cubit.state as BastionLoadedState).userBastion!;
      expect(refreshed.name, 'New Name');
      expect(refreshed.imgUrl, isNull);
      expect(refreshed.facilities.first.id, 'keep');
      expect((cubit.state as BastionLoadedState).isMutating, isFalse);

      await cubit.close();
    });

    test('returns the server message and keeps loaded state on failure',
        () async {
      final puts = <http.Request>[];
      final mock = _withEmptyBrowsePage((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                {
                  'id': 'bastion-1',
                  'userId': 'user_1',
                  'name': 'Old Name',
                  'description': 'Old description',
                  'imgUrl': 'https://old.example/keep.png',
                  'facilities': [facilityJson(id: 'keep', name: 'Keep')],
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path == '/maura/v1/bastions/bastion-1') {
          puts.add(request);
          return http.Response(
            jsonEncode({'success': false, 'message': 'Not your bastion'}),
            403,
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

      final toUpdate = (cubit.state as BastionLoadedState).userBastion!;
      final error = await cubit.updateBastion(
        toUpdate.copyWith(name: 'New Name'),
      );

      expect(error, 'Not your bastion');
      expect(puts, hasLength(1));
      expect((cubit.state as BastionLoadedState).userBastion!.name, 'Old Name');
      expect((cubit.state as BastionLoadedState).isMutating, isFalse);

      await cubit.close();
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
