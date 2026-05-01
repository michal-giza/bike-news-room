import '../../domain/entities/feed_source.dart';

class FeedSourceModel extends FeedSource {
  const FeedSourceModel({
    required super.id,
    required super.url,
    required super.title,
    required super.region,
    required super.errorCount,
    super.discipline,
    super.language,
    super.lastFetchedAt,
  });

  factory FeedSourceModel.fromJson(Map<String, dynamic> json) {
    return FeedSourceModel(
      id: json['id'] as int,
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      region: json['region'] as String? ?? 'world',
      discipline: json['discipline'] as String?,
      language: json['language'] as String?,
      errorCount: (json['error_count'] as num?)?.toInt() ?? 0,
      lastFetchedAt: _parseDate(json['last_fetched_at']),
    );
  }

  static DateTime? _parseDate(Object? v) {
    if (v is! String || v.isEmpty) return null;
    return DateTime.tryParse(v) ?? DateTime.tryParse(v.replaceFirst(' ', 'T'));
  }
}
