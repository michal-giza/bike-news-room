import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/watched_entity.dart';

/// Persists the user's followed riders/teams.
///
/// Two stores:
///   - the bundled catalogue (read-only, loaded once from `assets/.../watchlist_seed.json`)
///   - the user's selections + custom additions (SharedPreferences)
class WatchlistRepository {
  final SharedPreferences prefs;
  WatchlistRepository(this.prefs);

  static const _kFollowing = 'watchlist.following';

  List<WatchedEntity>? _catalogueCache;

  /// Load the catalogue once, cache in memory.
  Future<List<WatchedEntity>> loadCatalogue() async {
    if (_catalogueCache != null) return _catalogueCache!;
    try {
      final raw =
          await rootBundle.loadString('assets/catalogue/watchlist_seed.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = <WatchedEntity>[];

      for (final r in (json['riders'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()) {
        list.add(WatchedEntity(
          id: r['id'] as String,
          kind: WatchedKind.rider,
          name: r['name'] as String,
          aliases: (r['aliases'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
          discipline: r['discipline'] as String?,
          fromCatalogue: true,
        ));
      }
      for (final t in (json['teams'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()) {
        list.add(WatchedEntity(
          id: t['id'] as String,
          kind: WatchedKind.team,
          name: t['name'] as String,
          aliases: (t['aliases'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
          discipline: t['discipline'] as String?,
          fromCatalogue: true,
        ));
      }
      for (final r in (json['races'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()) {
        list.add(WatchedEntity(
          id: r['id'] as String,
          kind: WatchedKind.race,
          name: r['name'] as String,
          aliases: (r['aliases'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
          discipline: r['discipline'] as String?,
          fromCatalogue: true,
        ));
      }
      _catalogueCache = list;
      return list;
    } catch (_) {
      _catalogueCache = const [];
      return const [];
    }
  }

  /// The user's currently followed entities.
  Future<List<WatchedEntity>> loadFollowing() async {
    final list = prefs.getStringList(_kFollowing) ?? const [];
    return list
        .map((s) {
          try {
            return WatchedEntity.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<WatchedEntity>()
        .toList();
  }

  Future<void> saveFollowing(List<WatchedEntity> following) async {
    final encoded =
        following.map((e) => jsonEncode(e.toJson())).toList(growable: false);
    await prefs.setStringList(_kFollowing, encoded);
  }
}
