import 'package:bloc/bloc.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/api_exception.dart';
import 'package:maura_bastion_system/api/dto/login_request.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/features/login/data/auth_session_store.dart';
import 'package:maura_bastion_system/features/login/logic/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final IdentityApi _identityApi;
  final ApiClient _apiClient;
  final AuthSessionStore _sessionStore;

  AuthCubit({
    required IdentityApi identityApi,
    required ApiClient apiClient,
    required AuthSessionStore sessionStore,
  })  : _identityApi = identityApi,
        _apiClient = apiClient,
        _sessionStore = sessionStore,
        super(const AuthLoadingState());

  Future<void> restoreSession() async {
    String? token;
    try {
      token = await _sessionStore.load();
    } catch (error) {
      emit(const AuthUnauthenticatedState());
      return;
    }
    if (token == null) {
      emit(const AuthUnauthenticatedState());
      return;
    }

    _apiClient.setAuthToken(token);
    try {
      final user = await _identityApi.getMe();
      emit(AuthAuthenticatedState(user: user));
    } on ApiException catch (error) {
      final rejected = error.statusCode == 401 || error.statusCode == 403;
      if (rejected) {
        await _sessionStore.clear();
        _apiClient.setAuthToken(null);
      }
      emit(const AuthUnauthenticatedState());
    } catch (error) {
      emit(const AuthUnauthenticatedState());
    }
  }

  Future<void> login(String username, String password) async {
    emit(const AuthLoadingState());

    try {
      final normalizedUsername = username.trim();
      final normalizedPassword = password.trim();

      if (normalizedUsername.isEmpty || normalizedPassword.isEmpty) {
        emit(const AuthErrorState(message: 'Username and password are required.'));
        emit(const AuthUnauthenticatedState());
        return;
      }

      final user = await _identityApi.login(
        LoginRequest(username: normalizedUsername, password: normalizedPassword),
      );

      emit(AuthAuthenticatedState(user: user));
    } catch (error) {
      emit(AuthErrorState(message: 'Login failed. Please try again.'));
      emit(const AuthUnauthenticatedState());
    }
  }

  Future<void> logout() async {
    emit(const AuthLoadingState());
    await _sessionStore.clear();
    _apiClient.setAuthToken(null);
    emit(const AuthUnauthenticatedState());
  }
}