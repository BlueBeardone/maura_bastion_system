import 'package:bloc/bloc.dart';
import 'package:maura_bastion_system/api/dto/login_request.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/features/login/logic/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final IdentityApi _identityApi;

  AuthCubit({required IdentityApi identityApi})
      : _identityApi = identityApi,
        super(const AuthUnauthenticatedState());

  Future<void> login(String email, String password) async {
    emit(const AuthLoadingState());

    try {
      final normalizedEmail = email.trim();
      final normalizedPassword = password.trim();

      if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
        emit(const AuthErrorState(message: 'Email and password are required.'));
        emit(const AuthUnauthenticatedState());
        return;
      }

      final user = await _identityApi.login(
        LoginRequest(email: normalizedEmail, password: normalizedPassword),
      );

      emit(AuthAuthenticatedState(user: user));
    } catch (error) {
      emit(AuthErrorState(message: 'Login failed. Please try again.'));
      emit(const AuthUnauthenticatedState());
    }
  }

  Future<void> logout() async {
    emit(const AuthLoadingState());
    emit(const AuthUnauthenticatedState());
  }
}
