import 'api_client.dart';
import 'dto/login_request.dart';
import 'dto/register_request.dart';
import 'package:maura_bastion_system/data/models/user/user.dart';
import 'package:maura_bastion_system/features/login/data/auth_session_store.dart';

class IdentityApi {
  final ApiClient _client;
  final AuthSessionStore _sessionStore;

  IdentityApi({required ApiClient client, required AuthSessionStore sessionStore})
      : _client = client,
        _sessionStore = sessionStore;

  Future<User> login(LoginRequest request) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/maura/v1/identity/auth/login',
      request.toJson(),
      parser: (json) => json as Map<String, dynamic>,
    );
    if (data['token'] != null) {
      final token = data['token'] as String;
      _client.setAuthToken(token);
      await _sessionStore.save(token);
    }
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> register(RegisterRequest request) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/maura/v1/identity/auth/register',
      request.toJson(),
      parser: (json) => json as Map<String, dynamic>,
    );
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> getMe() async {
    final data = await _client.get<Map<String, dynamic>>(
      '/maura/v1/identity/auth/me',
      parser: (json) => json as Map<String, dynamic>,
    );
    return User.fromJson(data);
  }

  Future<List<User>> getAllUsers() async {
    final data = await _client.get<List<dynamic>>(
      '/maura/v1/identity/users',
      parser: (json) => json as List<dynamic>,
    );
    return data.map((u) => User.fromJson(u as Map<String, dynamic>)).toList();
  }

  Future<User> getUser(String id) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/maura/v1/identity/users/$id',
      parser: (json) => json as Map<String, dynamic>,
    );
    return User.fromJson(data);
  }

  Future<User> updateUser(String id, User user) async {
    final data = await _client.put<Map<String, dynamic>>(
      '/maura/v1/identity/users/$id',
      user.toJson(),
      parser: (json) => json as Map<String, dynamic>,
    );
    return User.fromJson(data);
  }

  Future<void> deleteUser(String id) async {
    await _client.delete<void>(
      '/maura/v1/identity/users/$id',
      parser: (_) {},
    );
  }
}