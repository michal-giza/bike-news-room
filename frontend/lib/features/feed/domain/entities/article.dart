import 'package:equatable/equatable.dart';

/// Domain entity for a news article. Mirrors the backend's article shape but
/// is decoupled from JSON: data-layer models do the conversion.
class Article extends Equatable {
  final int id;
  final int feedId;
  final String title;
  final String? description;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final DateTime? fetchedAt;
  final String? category;
  final String? region;
  final String? discipline;
  final String? language;
  /// Number of duplicate articles that point to this one as canonical.
  /// 0 means the article stands alone.
  final int clusterCount;

  const Article({
    required this.id,
    required this.feedId,
    required this.title,
    required this.url,
    required this.publishedAt,
    this.description,
    this.imageUrl,
    this.fetchedAt,
    this.category,
    this.region,
    this.discipline,
    this.language,
    this.clusterCount = 0,
  });

  /// True if the article was published less than an hour ago — drives the
  /// "LIVE" indicator on the card.
  bool get isLive => DateTime.now().difference(publishedAt).inMinutes < 60;

  @override
  List<Object?> get props => [
        id,
        feedId,
        title,
        description,
        url,
        imageUrl,
        publishedAt,
        fetchedAt,
        category,
        region,
        discipline,
        language,
        clusterCount,
      ];
}

class ArticlePage extends Equatable {
  final List<Article> articles;
  final int total;
  final int page;
  final bool hasMore;

  const ArticlePage({
    required this.articles,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [articles, total, page, hasMore];
}

/// Filters applied to a feed query — every field optional.
class ArticleFilter extends Equatable {
  final int page;
  final int limit;
  final String? region;
  final String? discipline;
  final String? category;
  final String? search;
  final DateTime? since;
  /// Symmetric to `since`. Only articles older than this timestamp.
  /// Drives the per-race archive page through past editions.
  final DateTime? before;
  /// Race slug from the matcher catalogue. When set, the backend joins
  /// `race_articles` so only articles linked to that race come back.
  final String? raceSlug;

  const ArticleFilter({
    this.page = 1,
    this.limit = 20,
    this.region,
    this.discipline,
    this.category,
    this.search,
    this.since,
    this.before,
    this.raceSlug,
  });

  ArticleFilter copyWith({
    int? page,
    int? limit,
    Object? region = _sentinel,
    Object? discipline = _sentinel,
    Object? category = _sentinel,
    Object? search = _sentinel,
    Object? since = _sentinel,
    Object? before = _sentinel,
    Object? raceSlug = _sentinel,
  }) {
    return ArticleFilter(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      region: identical(region, _sentinel) ? this.region : region as String?,
      discipline:
          identical(discipline, _sentinel) ? this.discipline : discipline as String?,
      category: identical(category, _sentinel) ? this.category : category as String?,
      search: identical(search, _sentinel) ? this.search : search as String?,
      since: identical(since, _sentinel) ? this.since : since as DateTime?,
      before:
          identical(before, _sentinel) ? this.before : before as DateTime?,
      raceSlug:
          identical(raceSlug, _sentinel) ? this.raceSlug : raceSlug as String?,
    );
  }

  static const _sentinel = Object();

  @override
  List<Object?> get props =>
      [page, limit, region, discipline, category, search, since, before, raceSlug];
}
