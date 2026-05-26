import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maura_bastion_system/data/models/user/user.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitialState());

  Future<void> login(String username, String password) async {
    emit(LoginLoadingState());
    try {
      await Future.delayed(Duration(seconds: 2));
      final User user = User(id: '1', displayName: username,);
      emit(LoginSuccessState(user: user));
    } catch (e, stackTrace) {
      emit(LoginErrorState(error: e as Exception, stackTrace: stackTrace, message: 'Login failed'));
    }
  }

  Future<void> logout(User user) async {
    emit(LogoutLoadingState());
    try {
      await Future.delayed(Duration(seconds: 1));
      emit(LogoutSuccessState());
    } catch (e, stackTrace) {
      emit(LogoutErrorState(error: e as Exception, stackTrace: stackTrace, message: 'Logout failed'));
    }
  }
}