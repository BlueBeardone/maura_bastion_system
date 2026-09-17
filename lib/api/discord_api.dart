import 'package:maura_bastion_system/data/models/bastion/bastion_turn_result.dart';

import 'api_client.dart';

class DiscordApi {
  final ApiClient _client;

  DiscordApi({required ApiClient client}) : _client = client;

  Future<void> sendMessage(String message) async {
    await _client.post<Map<String, dynamic>?>(
      '/maura/v1/discord',
      {'message': message},
      parser: (json) => json as Map<String, dynamic>,
    );
  }

  Future<void> sendIndividualBastionTurn(BastionTurnResult result) async {
    await _client.post<Map<String, dynamic>?>(
      '/maura/v1/discord/individual-bastion-turn',
      result.toJson(),
      parser: (json) => json as Map<String, dynamic>,
    );
  }

  Future<void> sendBastionCreated(String message) =>
      _post('/maura/v1/discord/bastion-creation', message);

  Future<void> sendFacilityBuilt(String message, {String? bastionId}) =>
      _post('/maura/v1/discord/facility-built', message, bastionId: bastionId);

  Future<void> sendFacilityRankUp(String message, {String? bastionId}) =>
      _post('/maura/v1/discord/facility-rank-up', message, bastionId: bastionId);

  Future<void> sendBranchUpgradePurchased(String message, {String? bastionId}) =>
      _post('/maura/v1/discord/branch-upgrade', message, bastionId: bastionId);

  Future<void> sendFacilityRemoved(String message, {String? bastionId}) =>
      _post('/maura/v1/discord/facility-removed', message, bastionId: bastionId);

  Future<void> sendHirelingHired(String message, {String? bastionId}) =>
      _post('/maura/v1/discord/hireling-hired', message, bastionId: bastionId);

  Future<void> sendDefenderAcquired(String message, {String? bastionId}) =>
      _post('/maura/v1/discord/defender-acquired', message, bastionId: bastionId);

  Future<void> _post(String path, String message, {String? bastionId}) async {
    await _client.post<Map<String, dynamic>?>(
      path,
      {
        'message': message,
        if (bastionId != null && bastionId.isNotEmpty) 'bastionId': bastionId,
      },
      parser: (json) => json as Map<String, dynamic>,
    );
  }
}
