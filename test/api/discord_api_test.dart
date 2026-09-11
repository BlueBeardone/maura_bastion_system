import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/api_exception.dart';
import 'package:maura_bastion_system/api/discord_api.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion_turn_result.dart';

void main() {
  group('DiscordApi', () {
    test('sends an enveloped POST with the message body', () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = DiscordApi(
        client: ApiClient(baseUrl: 'http://example.test', client: mock),
      );

      await api.sendMessage('Hello from the bastion');

      expect(captured.method, 'POST');
      expect(captured.url.toString(), 'http://example.test/maura/v1/discord');
      expect(
        captured.body,
        jsonEncode({'message': 'Hello from the bastion'}),
      );
    });

    test('throws ApiException when the backend reports failure', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'webhook unreachable'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = DiscordApi(
        client: ApiClient(baseUrl: 'http://example.test', client: mock),
      );

      expect(
        () => api.sendMessage('Hello from the bastion'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', 'webhook unreachable'),
        ),
      );
    });

    test('sends the individual bastion turn result to the endpoint', () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = DiscordApi(
        client: ApiClient(baseUrl: 'http://example.test', client: mock),
      );

      const result = BastionTurnResult(
        bastionId: 'bastion-1',
        bastionName: 'Ravencrest',
        quest: 'Clear the goblin warren',
        advancedFacility: BastionTurnAdvancedFacility(
          name: 'Kitchen',
          rankTitle: 'C',
          constructedTurns: 1,
          constructionTurns: 2,
        ),
        event: BastionTurnEventResult(
          name: 'Guest',
          description: 'A guest arrives',
          rolledRow: '2 | Seeking Sanctuary',
        ),
      );

      await api.sendIndividualBastionTurn(result);

      expect(captured.method, 'POST');
      expect(
        captured.url.toString(),
        'http://example.test/maura/v1/discord/individual-bastion-turn',
      );
      expect(captured.body, jsonEncode(result.toJson()));
    });

    test(
      'throws ApiException when the backend reports failure for the bastion turn result',
      () async {
        final mock = MockClient((request) async {
          return http.Response(
            jsonEncode({'success': false, 'message': 'webhook unreachable'}),
            500,
            headers: {'content-type': 'application/json'},
          );
        });

        final api = DiscordApi(
          client: ApiClient(baseUrl: 'http://example.test', client: mock),
        );

        const result = BastionTurnResult(
          bastionId: 'bastion-1',
          bastionName: 'Ravencrest',
          quest: 'Clear the goblin warren',
          advancedFacility: BastionTurnAdvancedFacility(
            name: 'Kitchen',
            rankTitle: 'C',
            constructedTurns: 1,
            constructionTurns: 2,
          ),
          event: BastionTurnEventResult(
            name: 'Guest',
            description: 'A guest arrives',
            rolledRow: '2 | Seeking Sanctuary',
          ),
        );

        expect(
          () => api.sendIndividualBastionTurn(result),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 500)
                .having((e) => e.message, 'message', 'webhook unreachable'),
          ),
        );
      },
    );
  });
}
