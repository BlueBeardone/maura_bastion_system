part of 'defenders_cubit.dart';

class DefendersState extends Equatable {
  final String bastionId;
  final List<Defender> defenders;
  final Exception? error;
  final bool isLoading;
  final bool isMutating;

  const DefendersState({
    required this.bastionId,
    this.defenders = const [],
    this.error,
    this.isLoading = false,
    this.isMutating = false,
  });

  static const _unset = Object();

  DefendersState copyWith({
    String? bastionId,
    List<Defender>? defenders,
    bool? isLoading,
    bool? isMutating,
    Object? error = _unset,
  }) {
    return DefendersState(
      bastionId: bastionId ?? this.bastionId,
      defenders: defenders ?? this.defenders,
      error: identical(error, _unset) ? this.error : error as Exception?,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [bastionId, defenders, error, isLoading, isMutating];
}
