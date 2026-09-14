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
  final bool isMutating;

  const BastionLoadedState({required this.bastions, this.isMutating = false});

  BastionLoadedState copyWith({List<Bastion>? bastions, bool? isMutating}) {
    return BastionLoadedState(
      bastions: bastions ?? this.bastions,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [bastions, isMutating];
}

class BastionErrorState extends BastionState {
  final Exception error;
  final StackTrace stackTrace;
  final String message;

  const BastionErrorState({required this.error, required this.stackTrace, required this.message});

  @override
  List<Object?> get props => [error, stackTrace, message];
}