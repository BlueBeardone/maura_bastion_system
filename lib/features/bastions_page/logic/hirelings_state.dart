part of 'hirelings_cubit.dart';

class HirelingsState extends Equatable {
  final String bastionId;
  final List<Hireling> hirelings;
  final Exception? error;

  const HirelingsState({
    required this.bastionId,
    this.hirelings = const [],
    this.error,
  });

  HirelingsState copyWith({
    String? bastionId,
    List<Hireling>? hirelings,
  }) {
    return HirelingsState(
      bastionId: bastionId ?? this.bastionId,
      hirelings: hirelings ?? this.hirelings,
      error: error,
    );
  }

  @override
  List<Object?> get props => [bastionId, hirelings, error];
}
