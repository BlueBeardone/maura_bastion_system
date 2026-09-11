import 'package:maura_bastion_system/data/models/bastion/bastion_turn_result.dart';

import 'api_client.dart';

class DiscordApi {
  final ApiClient _client;

  DiscordApi({required ApiClient client}) : _client = client;

  Future<void> sendMessage(String message) async {
    await _client.post<Map<String, dynamic>>(
      '/maura/v1/discord',
      {'message': message},
      parser: (json) => json as Map<String, dynamic>,
    );
  }

  Future<void> sendIndividualBastionTurn(BastionTurnResult result) async {
    await _client.post<Map<String, dynamic>>(
      '/maura/v1/discord/individual-bastion-turn',
      result.toJson(),
      parser: (json) => json as Map<String, dynamic>,
    );
  }
}
