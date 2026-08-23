import 'api_client.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';

class FacilityApi {
  final ApiClient _client;

  FacilityApi({required ApiClient client}) : _client = client;

  Future<List<Facility>> getAll() async {
    final data = await _client.get<List<dynamic>>(
      '/maura/v1/facilities',
      parser: (json) => json as List<dynamic>,
    );
    return data
        .map((f) => Facility.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  Future<Facility> get(String id) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/maura/v1/facilities/$id',
      parser: (json) => json as Map<String, dynamic>,
    );
    return Facility.fromJson(data);
  }

  Future<Facility> create(Facility facility, String bastionId) async {
    final json = facility.toJson();
    json['bastionId'] = bastionId;

    final data = await _client.post<Map<String, dynamic>>(
      '/maura/v1/facilities',
      json,
      parser: (json) => json as Map<String, dynamic>,
    );
    return Facility.fromJson(data);
  }

  Future<Facility> update(String id, Facility facility) async {
    final json = facility.toJson();
    if (json['bastionId'] == null) {
      json['bastionId'] = '';
    }

    final data = await _client.put<Map<String, dynamic>>(
      '/maura/v1/facilities/$id',
      json,
      parser: (json) => json as Map<String, dynamic>,
    );
    return Facility.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.delete<void>(
      '/maura/v1/facilities/$id',
      parser: (_) {},
    );
  }
}