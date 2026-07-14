part of 'defenders_cubit.dart';

class DefendersState extends Equatable {
  final String bastionId;
  final List<Defender> defenders;

  const DefendersState({
    required this.bastionId,
    this.defenders = const [],
  });

  DefendersState copyWith({
    String? bastionId,
    List<Defender>? defenders,
  }) {
    return DefendersState(
      bastionId: bastionId ?? this.bastionId,
      defenders: defenders ?? this.defenders,
    );
  }

  @override
  List<Object?> get props => [bastionId, defenders];
}