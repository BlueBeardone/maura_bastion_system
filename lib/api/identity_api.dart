import 'package:flutter/foundation.dart';

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
      await _persistToken(token);
    }
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Persisting the token is best-effort: the in-memory session is already
  /// authenticated, so a storage failure (e.g. flutter_secure_storage on the
  /// web outside a secure context) must never block a successful login.
  Future<void> _persistToken(String token) async {
    try {
      await _sessionStore.save(token);
    } catch (error) {
      debugPrint('Could not persist auth token: $error');
    }
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

  Future<User> getUser(String id) async {
    final data = await _client.get<Map<String, dynamic>>(
      '/maura/v1/identity/users/$id',
      parser: (json) => json as Map<String, dynamic>,
    );
    return User.fromJson(data);
  }
}