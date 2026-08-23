import 'api_client.dart';

class HealthApi {
  final ApiClient _client;

  HealthApi({required ApiClient client}) : _client = client;

  Future<bool> check() async {
    await _client.get<bool>(
      '/maura/v1/health',
      parser: (data) => true,
    );
    return true;
  }
}