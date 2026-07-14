part of 'hirelings_cubit.dart';

class HirelingsState extends Equatable {
  final String bastionId;
  final List<Hireling> hirelings;

  const HirelingsState({
    required this.bastionId,
    this.hirelings = const [],
  });

  HirelingsState copyWith({
    String? bastionId,
    List<Hireling>? hirelings,
  }) {
    return HirelingsState(
      bastionId: bastionId ?? this.bastionId,
      hirelings: hirelings ?? this.hirelings,
    );
  }

  @override
  List<Object?> get props => [bastionId, hirelings];
}
