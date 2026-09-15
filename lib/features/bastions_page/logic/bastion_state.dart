part of 'bastion_cubit.dart';

abstract class BastionState extends Equatable {
  const BastionState();
}

class BastionLoadingState extends BastionState {
  @override
  List<Object?> get props => [];
}

class BastionLoadedState extends BastionState {
  final Bastion? userBastion;
  final List<Bastion> browseBastions;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final bool isMutating;

  const BastionLoadedState({
    this.userBastion,
    this.browseBastions = const [],
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.isMutating = false,
  });

  /// All locally-available bastions: the player's own (if any) plus every
  /// loaded browse page. Read-only consumers (bastion_page, app bar menu)
  /// keep using this.
  List<Bastion> get bastions => [
        if (userBastion != null) userBastion!,
        ...browseBastions,
      ];

  BastionLoadedState copyWith({
    Bastion? userBastion,
    bool clearUserBastion = false,
    List<Bastion>? browseBastions,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    bool? isMutating,
  }) {
    return BastionLoadedState(
      userBastion: clearUserBastion ? null : (userBastion ?? this.userBastion),
      browseBastions: browseBastions ?? this.browseBastions,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [
        userBastion,
        browseBastions,
        currentPage,
        hasMore,
        isLoadingMore,
        loadMoreFailed,
        isMutating,
      ];
}

class BastionErrorState extends BastionState {
  final Exception error;
  final StackTrace stackTrace;
  final String message;

  const BastionErrorState({required this.error, required this.stackTrace, required this.message});

  @override
  List<Object?> get props => [error, stackTrace, message];
}
