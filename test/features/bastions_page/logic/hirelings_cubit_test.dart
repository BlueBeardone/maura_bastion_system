import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/api_exception.dart';
import 'package:maura_bastion_system/api/discord_api.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/hirelings_cubit.dart';

void main() {
  MockClient hirelingsMockClient({
    List<http.Request>? discordPosts,
    bool discordSucceeds = true,
    List<http.Request>? hirelingPosts,
  }) {
    return MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.path == '/maura/v1/discord/hireling-hired') {
        discordPosts?.add(request);
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
      if (request.method == 'POST' &&
          request.url.path == '/maura/v1/hirelings') {
        hirelingPosts?.add(request);
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': {
              ...jsonDecode(request.body) as Map<String, dynamic>,
              'id': 'h-new',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/hirelings') {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': [
              {
                'id': 'h1',
                'name': 'Marta',
                'bastionId': 'bastion-1',
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
  }

  HirelingsCubit cubitWith(MockClient mock) => HirelingsCubit(
        bastionId: 'bastion-1',
        hirelingApi: HirelingApi(
            client: ApiClient(baseUrl: 'http://example.test', client: mock)),
        discordAnnouncer: DiscordAnnouncer(
            discordApi: DiscordApi(
                client:
                    ApiClient(baseUrl: 'http://example.test', client: mock))),
        bastionName: 'Ravencrest',
      );

  group('HirelingsCubit.addHireling gate', () {
    test('logs to Discord before creating the hireling', () async {
      final requests = <http.Request>[];
      final mock = MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST' &&
            request.url.path == '/maura/v1/discord/hireling-hired') {
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'POST' &&
            request.url.path == '/maura/v1/hirelings') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': {
                ...jsonDecode(request.body) as Map<String, dynamic>,
                'id': 'h-new',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/hirelings') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                {'id': 'h1', 'name': 'Marta', 'bastionId': 'bastion-1'},
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

      final cubit = HirelingsCubit(
        bastionId: 'bastion-1',
        hirelingApi: HirelingApi(
            client: ApiClient(baseUrl: 'http://example.test', client: mock)),
        discordAnnouncer: DiscordAnnouncer(
            discordApi: DiscordApi(
                client:
                    ApiClient(baseUrl: 'http://example.test', client: mock))),
        bastionName: 'Ravencrest',
      );
      await cubit.loadHirelings();
      requests.clear();

      await cubit.addHireling(name: 'Marta');

      expect(requests.length, 2);
      expect(requests[0].url.path, '/maura/v1/discord/hireling-hired');
      expect(requests[1].url.path, '/maura/v1/hirelings');
      expect(cubit.state.hirelings.length, 2);
      expect(cubit.state.error, isNull);

      await cubit.close();
    });

    test('does not create the hireling when the Discord log fails', () async {
      final hirelingPosts = <http.Request>[];
      final mock = hirelingsMockClient(
        discordSucceeds: false,
        hirelingPosts: hirelingPosts,
      );

      final cubit = cubitWith(mock);
      await cubit.loadHirelings();

      await cubit.addHireling(name: 'Marta');

      expect(hirelingPosts, isEmpty);
      expect(cubit.state.hirelings.length, 1);
      expect(cubit.state.error, isA<ApiException>());

      await cubit.close();
    });
  });
}