import 'package:bloc/bloc.dart';
import 'package:maura_bastion_system/data/models/user/user.dart';
import 'package:maura_bastion_system/features/login/logic/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthUnauthenticatedState());

  Future<void> login(String username, String password) async {
    emit(const AuthLoadingState());

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (username.isEmpty || password.isEmpty) {
        emit(const AuthErrorState(message: 'Username and password are required.'));
        emit(const AuthUnauthenticatedState());
        return;
      }

      final User user = User(id: '1', displayName: username);
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
