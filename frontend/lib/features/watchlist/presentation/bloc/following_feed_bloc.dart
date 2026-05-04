import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../feed/domain/entities/article.dart';
import '../../../feed/domain/usecases/get_articles.dart';
import '../../domain/entities/watched_entity.dart';

/// Loads articles matching the user's watched entities via the backend
/// `?search=` endpoint — one query per follow, fanned out, results merged
/// and de-duplicated by id. Decoupled from `FeedBloc` so we never miss a
/// match just because the home feed hasn't paginated to the relevant page.
///
/// Trade-off: O(N) HTTP calls for N follows. For a typical 5–15 watched
/// names this is fine; if the count grows, swap for a `?watched=` endpoint.

class FollowingFeedState extends Equatable {
  final List<Article> articles;
  final bool loading;
  final String? errorMessage;

  const FollowingFeedState({
    this.articles = const [],
    this.loading = false,
    this.errorMessage,
  });

  FollowingFeedState copyWith({
    List<Article>? articles,
    bool? loading,
    Object? errorMessage = _sentinel,
  }) =>
      FollowingFeedState(
        articles: articles ?? this.articles,
        loading: loading ?? this.loading,
        errorMessage: identical(errorMessage, _sentinel)
            ? this.errorMessage
            : errorMessage as String?,
      );

  static const _sentinel = Object();

  @override
  List<Object?> get props => [articles, loading, errorMessage];
}

sealed class FollowingFeedEvent extends Equatable {
  const FollowingFeedEvent();
  @override
  List<Object?> get props => const [];
}

class FollowingFeedRequested extends FollowingFeedEvent {
  final List<WatchedEntity> following;
  const FollowingFeedRequested(this.following);
  @override
  List<Object?> get props => [following];
}

class FollowingFeedBloc extends Bloc<FollowingFeedEvent, FollowingFeedState> {
  final GetArticles getArticles;

  FollowingFeedBloc({required this.getArticles})
      : super(const FollowingFeedState()) {
    on<FollowingFeedRequested>(_onRequested);
  }

  Future<void> _onRequested(
    FollowingFeedRequested event,
    Emitter<FollowingFeedState> emit,
  ) async {
    if (event.following.isEmpty) {
      emit(const FollowingFeedState());
      return;
    }

    emit(state.copyWith(loading: true, errorMessage: null));

    // Fan out one query per `name` AND per alias for every watched entity.
    // We learned the hard way that primary-name-only search misses too
    // much: articles writing "Pogacar" (anglicised) are missed by a
    // "Tadej Pogačar" search, and "Giro 2026" misses an entity named
    // "Giro d'Italia". Aliases are short — at avg 4 per entity this is
    // ~5× the calls of the old approach but still well under a second
    // wall-clock with `Future.wait` at the API's sub-100ms p50.
    //
    // To keep load reasonable we cap unique terms per call at 8 — covers
    // every real entity in the seed; user-added entities with lots of
    // custom aliases get the first 8.
    const maxTermsPerEntity = 8;

    final futures = <Future<Either<Failure, ArticlePage>>>[];
    for (final entity in event.following) {
      final terms = <String>{
        entity.name.trim(),
        ...entity.aliases.map((a) => a.trim()),
      }
          .where((t) => t.isNotEmpty)
          .take(maxTermsPerEntity);
      for (final term in terms) {
        futures.add(getArticles(ArticleFilter(
          page: 1,
          limit: 50,
          search: term,
        )));
      }
    }

    final results = await Future.wait(futures);

    // Merge + dedup by id, preserving the most-recent-first order.
    final byId = <int, Article>{};
    String? firstError;
    for (final r in results) {
      r.fold(
        (failure) => firstError ??= failure.message,
        (page) {
          for (final a in page.articles) {
            byId.putIfAbsent(a.id, () => a);
          }
        },
      );
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    emit(FollowingFeedState(
      articles: merged,
      loading: false,
      errorMessage: merged.isEmpty ? firstError : null,
    ));
  }
}
