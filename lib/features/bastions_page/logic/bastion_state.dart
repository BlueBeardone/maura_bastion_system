part of 'bastion_cubit.dart';

abstract class BastionState extends Equatable {
  const BastionState();
}

class BastionLoadingState extends BastionState {
  @override
  List<Object?> get props => [];
}

class BastionLoadedState extends BastionState {
  final List<Bastion> bastions;

  const BastionLoadedState({required this.bastions});

  @override
  List<Object?> get props => [bastions];
}

class BastionErrorState extends BastionState {
  final Exception error;
  final StackTrace stackTrace;
  final String message;

  const BastionErrorState({required this.error, required this.stackTrace, required this.message});

  @override
  List<Object?> get props => throw UnimplementedError();
}