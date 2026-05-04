import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/article_model.dart';

/// On-device snapshot of full article payloads for any article the user
/// has chosen to keep — bookmarks, race-follow matches, anything we need
/// to survive after the backend retention sweep deletes the source row.
///
/// Why this exists: backend retention deletes articles older than
/// ARTICLE_RETENTION_DAYS (default 90). Without a snapshot, every
/// bookmark older than 90 days silently vanishes from the user's view —
/// the bookmark id stays in shared prefs but `/api/articles/{id}` returns
/// 404 and the in-memory feed list never had it loaded. The fix is to
/// persist the article *content* at save-time, not just the id.
///
/// Storage: SharedPreferences with a single JSON-encoded map keyed by
/// article id. At ~500 articles cap × ~1KB per article that's 500KB
/// worst-case, well under the per-key cap on every platform we support.
///
/// Eviction: 1-year staleness cap, plus FIFO trim when the cap is hit.
/// We never evict an article that's currently bookmarked — caller passes
/// `protectIds` to [trimToCap] so user-intent always wins over LRU.
class ArticleSnapshotStore {
  final SharedPreferences prefs;
  ArticleSnapshotStore(this.prefs);

  static const _key = 'articles.snapshot.v1';
  static const _maxEntries = 500;
  static const _maxAge = Duration(days: 365);

  /// Persist the article. Idempotent — re-saving overwrites silently and
  /// refreshes `savedAt`, keeping recently-touched entries off the FIFO
  /// chopping block.
  Future<void> save(ArticleModel article) async {
    final all = _readMap();
    all[article.id.toString()] = {
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'article': _articleToJson(article),
    };
    await _writeMap(all);
  }

  /// Pull every snapshot whose id is in [ids]. Caller is the bookmarks
  /// page or the race-detail screen; both want "give me what I have
  /// locally, in any order" — sorting happens upstream.
  Future<List<ArticleModel>> loadAll(Iterable<int> ids) async {
    final all = _readMap();
    final out = <ArticleModel>[];
    for (final id in ids) {
      final entry = all[id.toString()];
      if (entry is! Map<String, dynamic>) continue;
      final json = entry['article'];
      if (json is! Map<String, dynamic>) continue;
      try {
        out.add(ArticleModel.fromJson(json));
      } catch (_) {
        // Schema drift — drop the corrupt entry on next save.
      }
    }
    return out;
  }

  /// Load one snapshot if present, else null. Bookmarks page falls back
  /// to this when `/api/articles/{id}` returns 404.
  Future<ArticleModel?> loadOne(int id) async {
    final all = _readMap();
    final entry = all[id.toString()];
    if (entry is! Map<String, dynamic>) return null;
    final json = entry['article'];
    if (json is! Map<String, dynamic>) return null;
    try {
      return ArticleModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Drop a single snapshot. Called when the user un-bookmarks an
  /// article AND has no other reason to keep it cached (no race-link).
  Future<void> remove(int id) async {
    final all = _readMap();
    if (all.remove(id.toString()) != null) {
      await _writeMap(all);
    }
  }

  /// Run staleness + FIFO eviction. Pass [protectIds] to spare currently
  /// bookmarked entries so the user never loses an active save just
  /// because a race-follow flooded the cache.
  Future<void> trimToCap({Set<int> protectIds = const {}}) async {
    final all = _readMap();
    final now = DateTime.now().toUtc();

    // Pass 1 — drop entries older than the staleness cap, unless protected.
    all.removeWhere((id, entry) {
      if (protectIds.contains(int.tryParse(id) ?? -1)) return false;
      if (entry is! Map) return true;
      final ts = DateTime.tryParse(entry['savedAt']?.toString() ?? '')?.toUtc();
      if (ts == null) return true;
      return now.difference(ts) > _maxAge;
    });

    // Pass 2 — if still over cap, evict oldest non-protected first.
    if (all.length > _maxEntries) {
      final sortable = all.entries.toList()
        ..sort((a, b) {
          final ta = a.value is Map
              ? DateTime.tryParse(
                      (a.value as Map)['savedAt']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0)
              : DateTime.fromMillisecondsSinceEpoch(0);
          final tb = b.value is Map
              ? DateTime.tryParse(
                      (b.value as Map)['savedAt']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0)
              : DateTime.fromMillisecondsSinceEpoch(0);
          return ta.compareTo(tb);
        });
      final toDrop = sortable.length - _maxEntries;
      var dropped = 0;
      for (final e in sortable) {
        if (dropped >= toDrop) break;
        if (protectIds.contains(int.tryParse(e.key) ?? -1)) continue;
        all.remove(e.key);
        dropped++;
      }
    }

    await _writeMap(all);
  }

  Map<String, dynamic> _readMap() {
    final raw = prefs.getString(_key);
    if (raw == null) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {/* fall through */}
    return <String, dynamic>{};
  }

  Future<void> _writeMap(Map<String, dynamic> all) =>
      prefs.setString(_key, jsonEncode(all));

  /// Mirror the API JSON shape so [ArticleModel.fromJson] can rehydrate
  /// without a separate model. Centralised here so the cache schema can
  /// evolve independently of the wire model.
  Map<String, dynamic> _articleToJson(ArticleModel a) => {
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
        'language': a.language,
        'cluster_count': a.clusterCount,
      };
}
