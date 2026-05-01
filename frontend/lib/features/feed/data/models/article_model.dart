import '../../../../core/text/strip_html.dart';
import '../../domain/entities/article.dart';

/// Data-layer model that knows how to round-trip JSON.
/// Inherits from [Article] so it's interchangeable at the domain boundary.
class ArticleModel extends Article {
  const ArticleModel({
    required super.id,
    required super.feedId,
    required super.title,
    required super.url,
    required super.publishedAt,
    super.description,
    super.imageUrl,
    super.fetchedAt,
    super.category,
    super.region,
    super.discipline,
    super.language,
    super.clusterCount = 0,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final rawDescription = json['description'] as String?;
    final cleanDescription =
        rawDescription == null ? null : stripHtml(rawDescription);
    return ArticleModel(
      id: json['id'] as int,
      feedId: json['feed_id'] as int,
      title: stripHtml(json['title'] as String? ?? ''),
      description: cleanDescription?.isEmpty ?? true ? null : cleanDescription,
      url: json['url'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      publishedAt: _parseDate(json['published_at']) ?? DateTime.now(),
      fetchedAt: _parseDate(json['fetched_at']),
      category: json['category'] as String?,
      region: json['region'] as String?,
      discipline: json['discipline'] as String?,
      language: json['language'] as String?,
      clusterCount: (json['cluster_count'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    // Backend emits both RFC3339 (`...+00:00`) and SQLite default
    // (`YYYY-MM-DD HH:MM:SS`) — try both.
    return DateTime.tryParse(value) ?? DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }
}

class ArticlePageModel extends ArticlePage {
  const ArticlePageModel({
    required super.articles,
    required super.total,
    required super.page,
    required super.hasMore,
  });

  factory ArticlePageModel.fromJson(Map<String, dynamic> json) {
    final list = (json['articles'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ArticleModel.fromJson)
        .toList(growable: false);
    return ArticlePageModel(
      articles: list,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
