part of 'login_cubit.dart';

abstract class LoginState extends Equatable {
  const LoginState();
}

class LoginInitialState extends LoginState {
  @override
  List<Object?> get props => [];
}

class LoginLoadingState extends LoginState {
  @override
  List<Object?> get props => [];
}

class LoginSuccessState extends LoginState {
  final User user;

  const LoginSuccessState({required this.user});

  @override
  List<Object?> get props => [user];
}

class LogoutInitialState extends LoginState {
  final User user;

  const LogoutInitialState({required this.user});

  @override
  List<Object?> get props => [user];
}

class LogoutLoadingState extends LoginState {
  @override
  List<Object?> get props => [];
}

class LogoutSuccessState extends LoginState {
  @override
  List<Object?> get props => [];
}

class LogoutErrorState extends LoginState {
  final Exception error;
  final StackTrace stackTrace;
  final String message;

  const LogoutErrorState({required this.error, required this.stackTrace, required this.message});

  @override
  List<Object?> get props => [error, stackTrace, message];
}

class LoginErrorState extends LoginState {
  final Exception error;
  final StackTrace stackTrace;
  final String message;

  const LoginErrorState({required this.error, required this.stackTrace, required this.message});

  @override
  List<Object?> get props => [error, stackTrace, message];
}