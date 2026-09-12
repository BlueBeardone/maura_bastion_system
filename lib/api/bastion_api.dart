import 'api_client.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';

class BastionApi {
  final ApiClient _client;

  BastionApi({required ApiClient client}) : _client = client;

  Future<List<Bastion>> getAll() async {
    final data = await _client.get<List<dynamic>>(
      '/maura/v1/bastions?all=true',
      parser: (json) => json as List<dynamic>,
    );
    return data
        .map((b) => Bastion.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  Future<Bastion> get(String id) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/maura/v1/bastions/$id',
      parser: (json) => json as Map<String, dynamic>,
    );
    return Bastion.fromJson(data);
  }

  Future<Bastion> create(Bastion bastion) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/maura/v1/bastions',
      bastion.toJson(),
      parser: (json) => json as Map<String, dynamic>,
    );
    return Bastion.fromJson(data);
  }

  Future<Bastion> update(String id, Bastion bastion) async {
    final json = bastion.toJson();
    final facilities = (json['facilities'] as List<dynamic>?)?.map((f) {
      final fMap = Map<String, dynamic>.from(f as Map);
      fMap['bastionId'] = id;
      return fMap;
    }).toList();
    json['facilities'] = facilities ?? [];

    final data = await _client.put<Map<String, dynamic>>(
      '/maura/v1/bastions/$id',
      json,
      parser: (json) => json as Map<String, dynamic>,
    );
    return Bastion.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.delete<void>(
      '/maura/v1/bastions/$id',
      parser: (_) {},
    );
  }
}