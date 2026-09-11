import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/api_exception.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/api/discord_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defenders_cubit.dart';

void main() {
  Map<String, dynamic> defenderJson({
    required String id,
    String type = 'knight',
  }) =>
      {
        'id': id,
        'name': 'Defender $id',
        'type': type,
        'description': 'desc',
        'bastionId': 'bastion-1',
        'acquisitionStory': 'story',
      };

  MockClient defendersMockClient({
    void Function(http.Request)? onDelete,
    bool deleteSucceeds = true,
    List<http.Request>? discordPosts,
  }) {
    return MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.path == '/maura/v1/discord/defender-acquired') {
        discordPosts?.add(request);
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'POST' &&
          request.url.path == '/maura/v1/defenders') {
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
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/defenders') {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': [
              defenderJson(id: 'd1'),
              defenderJson(id: 'd2', type: 'beast'),
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'DELETE' &&
          request.url.path == '/maura/v1/defenders/d1') {
        onDelete?.call(request);
        if (!deleteSucceeds) {
          return http.Response(
            jsonEncode({'success': false, 'message': 'boom'}),
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': null}),
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

  group('DefendersCubit.removeDefender', () {
    test('DELETEs the defender and removes it from state', () async {
      http.Request? captured;
      final mock = defendersMockClient(onDelete: (request) => captured = request);

      final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
      final cubit = DefendersCubit(
        bastionId: 'bastion-1',
        defenderApi: DefenderApi(client: apiClient),
      );
      await cubit.loadDefenders();
      expect(cubit.state.defenders.length, 2);

      await cubit.removeDefender('d1');

      expect(captured, isNotNull);
      expect(captured!.method, 'DELETE');
      expect(captured!.url.path, '/maura/v1/defenders/d1');
      expect(cubit.state.defenders.length, 1);
      expect(cubit.state.defenders.first.id, 'd2');

      await cubit.close();
    });

    test('rethrows on API failure and leaves state unchanged', () async {
      final mock = defendersMockClient(deleteSucceeds: false);

      final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
      final cubit = DefendersCubit(
        bastionId: 'bastion-1',
        defenderApi: DefenderApi(client: apiClient),
      );
      await cubit.loadDefenders();

      await expectLater(
        cubit.removeDefender('d1'),
        throwsA(isA<ApiException>()),
      );
      expect(cubit.state.defenders.length, 2);

      await cubit.close();
    });
  });

  group('DefendersCubit.addDefender announcements', () {
    test('announces the new defender to Discord', () async {
      final discordPosts = <http.Request>[];
      final mock = defendersMockClient(discordPosts: discordPosts);

      final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
      final cubit = DefendersCubit(
        bastionId: 'bastion-1',
        defenderApi: DefenderApi(client: apiClient),
        discordAnnouncer: DiscordAnnouncer(
            discordApi: DiscordApi(client: apiClient)),
        bastionName: 'Ravencrest',
      );
      await cubit.loadDefenders();
      discordPosts.clear();

      await cubit.addDefender(
        name: 'Sergeant Aldric',
        type: DefenderType.knight,
        description: 'A stern veteran.',
        acquisitionStory: 'Won in a duel.',
      );

      expect(discordPosts, hasLength(1));
      final body = jsonDecode(discordPosts.first.body) as Map<String, dynamic>;
      expect(
        body['message'],
        '🛡️ **Ravencrest** gains a new defender: **Sergeant Aldric** (Knight)!\n\n'
            'A stern veteran.\n\n'
            'How they were gained: Won in a duel.',
      );

      await cubit.close();
    });

    test('addDefender still succeeds when the announcer throws', () async {
      final mock = defendersMockClient();

      final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
      final cubit = DefendersCubit(
        bastionId: 'bastion-1',
        defenderApi: DefenderApi(client: apiClient),
        discordAnnouncer: _ThrowingDefenderAnnouncer(
            discordApi: DiscordApi(client: apiClient)),
        bastionName: 'Ravencrest',
      );
      await cubit.loadDefenders();

      await cubit.addDefender(
        name: 'Sergeant Aldric',
        type: DefenderType.knight,
        description: 'A stern veteran.',
        acquisitionStory: 'Won in a duel.',
      );

      expect(cubit.state.defenders.length, 3);

      await cubit.close();
    });
  });
}

class _ThrowingDefenderAnnouncer extends DiscordAnnouncer {
  _ThrowingDefenderAnnouncer({required super.discordApi});

  @override
  Future<void> announceDefenderAcquired(Defender defender, {String? bastionName}) =>
      throw Exception('Discord is down');
}
