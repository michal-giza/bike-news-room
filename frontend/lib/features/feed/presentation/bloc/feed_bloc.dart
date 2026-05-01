import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/article.dart';
import '../../domain/usecases/get_articles.dart';

part 'feed_event.dart';
part 'feed_state.dart';

/// Single source of truth for the home feed: filters, pagination, refresh.
///
/// Filter changes always reset to page 1; load-more increments while keeping
/// existing articles in the list and emits a transient `loadingMore` status.
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final GetArticles getArticles;

  FeedBloc({required this.getArticles}) : super(const FeedState()) {
    on<FeedRequested>(_onRequested);
    on<FeedLoadMoreRequested>(_onLoadMore);
    on<FeedRefreshRequested>(_onRefresh);
    on<FeedFilterChanged>(_onFilterChanged);
    on<FeedFiltersCleared>(_onFiltersCleared);
  }

  Future<void> _onRequested(FeedRequested event, Emitter<FeedState> emit) =>
      _loadFirstPage(state.filter, emit);

  Future<void> _onRefresh(FeedRefreshRequested event, Emitter<FeedState> emit) =>
      _loadFirstPage(state.filter, emit);

  Future<void> _onLoadMore(
    FeedLoadMoreRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (!state.hasMore || state.status == FeedStatus.loadingMore) return;

    emit(state.copyWith(status: FeedStatus.loadingMore));
    final nextPage = state.page + 1;
    final result = await getArticles(state.filter.copyWith(page: nextPage));

    result.fold(
      (failure) => emit(state.copyWith(
        status: FeedStatus.loaded, // keep showing existing articles
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        status: FeedStatus.loaded,
        articles: [...state.articles, ...page.articles],
        total: page.total,
        page: page.page,
        hasMore: page.hasMore,
        errorMessage: null,
      )),
    );
  }

  Future<void> _onFilterChanged(
    FeedFilterChanged event,
    Emitter<FeedState> emit,
  ) async {
    final newFilter = state.filter.copyWith(
      page: 1,
      region: event.clearRegion ? null : (event.region ?? state.filter.region),
      discipline: event.clearDiscipline
          ? null
          : (event.discipline ?? state.filter.discipline),
      category: event.clearCategory
          ? null
          : (event.category ?? state.filter.category),
      search: event.clearSearch ? null : (event.search ?? state.filter.search),
    );
    await _loadFirstPage(newFilter, emit);
  }

  Future<void> _onFiltersCleared(
    FeedFiltersCleared event,
    Emitter<FeedState> emit,
  ) =>
      _loadFirstPage(const ArticleFilter(), emit);

  Future<void> _loadFirstPage(
    ArticleFilter filter,
    Emitter<FeedState> emit,
  ) async {
    emit(state.copyWith(
      status: FeedStatus.loading,
      filter: filter.copyWith(page: 1),
      errorMessage: null,
    ));

    final result = await getArticles(filter.copyWith(page: 1));
    result.fold(
      (failure) => emit(state.copyWith(
        status: FeedStatus.error,
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        status: FeedStatus.loaded,
        articles: page.articles,
        total: page.total,
        page: page.page,
        hasMore: page.hasMore,
        errorMessage: null,
      )),
    );
  }
}
