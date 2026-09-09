import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/api_exception.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
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
  }) {
    return MockClient((request) async {
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
}
