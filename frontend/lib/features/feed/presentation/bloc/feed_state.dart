part of 'feed_bloc.dart';

enum FeedStatus { initial, loading, loaded, loadingMore, error }

class FeedState extends Equatable {
  final FeedStatus status;
  final List<Article> articles;
  final int total;
  final int page;
  final bool hasMore;
  final ArticleFilter filter;
  final String? errorMessage;

  const FeedState({
    this.status = FeedStatus.initial,
    this.articles = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.filter = const ArticleFilter(),
    this.errorMessage,
  });

  FeedState copyWith({
    FeedStatus? status,
    List<Article>? articles,
    int? total,
    int? page,
    bool? hasMore,
    ArticleFilter? filter,
    Object? errorMessage = _sentinel,
  }) {
    return FeedState(
      status: status ?? this.status,
      articles: articles ?? this.articles,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const _sentinel = Object();

  @override
  List<Object?> get props =>
      [status, articles, total, page, hasMore, filter, errorMessage];
}
