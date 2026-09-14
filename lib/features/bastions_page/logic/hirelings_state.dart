part of 'hirelings_cubit.dart';

class HirelingsState extends Equatable {
  final String bastionId;
  final List<Hireling> hirelings;
  final Exception? error;
  final bool isLoading;
  final bool isMutating;

  const HirelingsState({
    required this.bastionId,
    this.hirelings = const [],
    this.error,
    this.isLoading = false,
    this.isMutating = false,
  });

  static const _unset = Object();

  HirelingsState copyWith({
    String? bastionId,
    List<Hireling>? hirelings,
    bool? isLoading,
    bool? isMutating,
    Object? error = _unset,
  }) {
    return HirelingsState(
      bastionId: bastionId ?? this.bastionId,
      hirelings: hirelings ?? this.hirelings,
      error: identical(error, _unset) ? this.error : error as Exception?,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [bastionId, hirelings, error, isLoading, isMutating];
}
