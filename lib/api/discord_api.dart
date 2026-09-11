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

  Future<void> sendFacilityBuilt(String message) =>
      _post('/maura/v1/discord/facility-built', message);

  Future<void> sendFacilityRankUp(String message) =>
      _post('/maura/v1/discord/facility-rank-up', message);

  Future<void> sendBranchUpgradePurchased(String message) =>
      _post('/maura/v1/discord/branch-upgrade', message);

  Future<void> sendHirelingHired(String message) =>
      _post('/maura/v1/discord/hireling-hired', message);

  Future<void> sendDefenderAcquired(String message) =>
      _post('/maura/v1/discord/defender-acquired', message);

  Future<void> _post(String path, String message) async {
    await _client.post<Map<String, dynamic>?>(
      path,
      {'message': message},
      parser: (json) => json as Map<String, dynamic>,
    );
  }
}
