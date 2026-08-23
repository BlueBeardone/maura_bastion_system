import 'api_client.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';

class DefenderApi {
  final ApiClient _client;

  DefenderApi({required ApiClient client}) : _client = client;

  Future<List<Defender>> getAll() async {
    final data = await _client.get<List<dynamic>>(
      '/maura/v1/defenders',
      parser: (json) => json as List<dynamic>,
    );
    return data
        .map((d) => Defender.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<Defender> get(String id) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/maura/v1/defenders/$id',
      parser: (json) => json as Map<String, dynamic>,
    );
    return Defender.fromJson(data);
  }

  Future<Defender> create(Defender defender) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/maura/v1/defenders',
      defender.toJson(),
      parser: (json) => json as Map<String, dynamic>,
    );
    return Defender.fromJson(data);
  }

  Future<Defender> update(String id, Defender defender) async {
    final data = await _client.put<Map<String, dynamic>>(
      '/maura/v1/defenders/$id',
      defender.toJson(),
      parser: (json) => json as Map<String, dynamic>,
    );
    return Defender.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.delete<void>(
      '/maura/v1/defenders/$id',
      parser: (_) {},
    );
  }
}