part of 'defenders_cubit.dart';

class DefendersState extends Equatable {
  final String bastionId;
  final List<Defender> defenders;
  final Exception? error;

  const DefendersState({
    required this.bastionId,
    this.defenders = const [],
    this.error,
  });

  DefendersState copyWith({
    String? bastionId,
    List<Defender>? defenders,
  }) {
    return DefendersState(
      bastionId: bastionId ?? this.bastionId,
      defenders: defenders ?? this.defenders,
      error: error,
    );
  }

  @override
  List<Object?> get props => [bastionId, defenders, error];
}