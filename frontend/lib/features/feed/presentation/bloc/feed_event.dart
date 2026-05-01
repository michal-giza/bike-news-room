part of 'feed_bloc.dart';

sealed class FeedEvent extends Equatable {
  const FeedEvent();
  @override
  List<Object?> get props => const [];
}

/// Initial load (or full reset).
class FeedRequested extends FeedEvent {
  const FeedRequested();
}

/// Load the next page (infinite scroll).
class FeedLoadMoreRequested extends FeedEvent {
  const FeedLoadMoreRequested();
}

/// Pull-to-refresh / "X new articles" pill.
class FeedRefreshRequested extends FeedEvent {
  const FeedRefreshRequested();
}

class FeedFilterChanged extends FeedEvent {
  final String? region;
  final String? discipline;
  final String? category;
  final String? search;
  /// `true` to clear the field even though the value is null.
  final bool clearRegion;
  final bool clearDiscipline;
  final bool clearCategory;
  final bool clearSearch;

  const FeedFilterChanged({
    this.region,
    this.discipline,
    this.category,
    this.search,
    this.clearRegion = false,
    this.clearDiscipline = false,
    this.clearCategory = false,
    this.clearSearch = false,
  });

  @override
  List<Object?> get props => [
        region,
        discipline,
        category,
        search,
        clearRegion,
        clearDiscipline,
        clearCategory,
        clearSearch,
      ];
}

class FeedFiltersCleared extends FeedEvent {
  const FeedFiltersCleared();
}
