import 'api_client.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';

class HirelingApi {
  final ApiClient _client;

  HirelingApi({required ApiClient client}) : _client = client;

  Future<List<Hireling>> getAll() async {
    final data = await _client.get<List<dynamic>>(
      '/maura/v1/hirelings',
      parser: (json) => json as List<dynamic>,
    );
    return data
        .map((h) => Hireling.fromJson(h as Map<String, dynamic>))
        .toList();
  }

  Future<Hireling> get(String id) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/maura/v1/hirelings/$id',
      parser: (json) => json as Map<String, dynamic>,
    );
    return Hireling.fromJson(data);
  }

  Future<Hireling> create(Hireling hireling) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/maura/v1/hirelings',
      hireling.toJson(),
      parser: (json) => json as Map<String, dynamic>,
    );
    return Hireling.fromJson(data);
  }

  Future<Hireling> update(String id, Hireling hireling) async {
    final data = await _client.put<Map<String, dynamic>>(
      '/maura/v1/hirelings/$id',
      hireling.toJson(),
      parser: (json) => json as Map<String, dynamic>,
    );
    return Hireling.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.delete<void>(
      '/maura/v1/hirelings/$id',
      parser: (_) {},
    );
  }
}