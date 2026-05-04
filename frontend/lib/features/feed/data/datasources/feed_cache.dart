import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/article_model.dart';

/// Lightweight on-device cache for the home-feed first page.
///
/// Why it exists: opening the app on the train, in a tunnel, or with the
/// backend down should still show *something* useful. We persist the most
/// recent first-page response as JSON in SharedPreferences (sub-50 KB
/// typical) and serve it as a fallback when the network call fails. This
/// is one of the concrete features Apple's reviewers look for under
/// guideline 4.2.2 — "solid offline handling" separates a real native app
/// from a webview wrapper.
///
/// Scope is intentionally tiny:
/// - Only the home feed (no filters) gets cached. Filtered/searched views
///   skip the cache; the user explicitly asked for a fresh slice.
/// - 24-hour staleness cap. After that, we'd rather show "couldn't reach
///   the news room" than week-old headlines.
/// - First page only. Pagination is online-only.
class FeedCache {
  final SharedPreferences prefs;
  FeedCache(this.prefs);

  static const _key = 'feed.cache.firstPage.v1';
  static const _maxAge = Duration(hours: 24);

  /// Persist the first-page payload. `articles` are stored as the same
  /// JSON shape the API returns, which means [load] can rehydrate them
  /// through the existing [ArticleModel.fromJson] without a separate
  /// model. `total` is kept so the header can still show "X stories".
  Future<void> save({
    required List<ArticleModel> articles,
    required int total,
  }) async {
    final payload = jsonEncode({
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'total': total,
      'articles': articles.map((a) => _toJson(a)).toList(),
    });
    await prefs.setString(_key, payload);
  }

  /// Returns the cached page if present and within the staleness cap, else
  /// `null`. The 24h cap is a hard cliff: a stale cache from yesterday's
  /// finale is a fine fallback; a cache from a week ago is misleading.
  CachedFeed? load() {
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt =
          DateTime.tryParse(json['savedAt']?.toString() ?? '')?.toUtc();
      if (savedAt == null) return null;
      if (DateTime.now().toUtc().difference(savedAt) > _maxAge) return null;
      final articlesJson = (json['articles'] as List? ?? const []);
      final articles = articlesJson
          .whereType<Map<String, dynamic>>()
          .map(ArticleModel.fromJson)
          .toList();
      final total = (json['total'] as num?)?.toInt() ?? articles.length;
      return CachedFeed(articles: articles, total: total, savedAt: savedAt);
    } catch (_) {
      // Corrupt cache (schema change, partial write, etc.) — drop it.
      prefs.remove(_key);
      return null;
    }
  }

  /// `ArticleModel` doesn't expose `toJson` so we mirror the API shape here.
  /// Centralised in the cache layer so the model stays free of persistence
  /// concerns and the cache schema can evolve independently.
  Map<String, dynamic> _toJson(ArticleModel a) => {
        'id': a.id,
        'feed_id': a.feedId,
        'title': a.title,
        'description': a.description,
        'url': a.url,
        'image_url': a.imageUrl,
        'published_at': a.publishedAt.toUtc().toIso8601String(),
        'category': a.category,
        'region': a.region,
        'discipline': a.discipline,
        'cluster_count': a.clusterCount,
      };
}

class CachedFeed {
  final List<ArticleModel> articles;
  final int total;
  final DateTime savedAt;
  const CachedFeed({
    required this.articles,
    required this.total,
    required this.savedAt,
  });
}
