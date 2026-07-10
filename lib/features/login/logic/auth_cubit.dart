import 'package:bloc/bloc.dart';
import 'package:maura_bastion_system/data/models/user/user.dart';
import 'package:maura_bastion_system/data/test_data/user/fake_user_data.dart';
import 'package:maura_bastion_system/features/login/logic/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthUnauthenticatedState());

  Future<void> login(String username, String password) async {
    emit(const AuthLoadingState());

    try {
      await Future.delayed(const Duration(seconds: 2));

      final String normalizedUsername = username.trim();
      final String normalizedPassword = password.trim();

      if (normalizedUsername.isEmpty || normalizedPassword.isEmpty) {
        emit(const AuthErrorState(message: 'Username and password are required.'));
        emit(const AuthUnauthenticatedState());
        return;
      }

      final User? user = findUserByCredentials(normalizedUsername, normalizedPassword);
      if (user == null) {
        emit(const AuthErrorState(message: 'Invalid username or password.'));
        emit(const AuthUnauthenticatedState());
        return;
      }

      emit(AuthAuthenticatedState(user: user));
    } catch (error) {
      emit(AuthErrorState(message: 'Login failed. Please try again.'));
      emit(const AuthUnauthenticatedState());
    }
  }

  Future<void> logout() async {
    emit(const AuthLoadingState());
    await Future.delayed(const Duration(milliseconds: 500));
    emit(const AuthUnauthenticatedState());
  }
}
