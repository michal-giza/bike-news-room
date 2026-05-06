import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../network/api_client.dart';
import 'notifications_provider.dart';

/// Workmanager task identifier — stable across app upgrades so the OS
/// can find existing scheduled tasks after an install. Exported so the
/// background callback (a top-level function in this file) can compare
/// against it.
const String kArticlePollerTaskName = 'bnr.notifications.articlePoller';

/// On-device transport: flutter_local_notifications for the rendering,
/// workmanager for the periodic fetch. No third-party SDK, no costs,
/// no Apple Developer key shenanigans.
///
/// Trade-off vs. real push: cadence is OS-controlled. Android's
/// Workmanager honours the 15-minute floor reasonably well. iOS's
/// BGTaskScheduler typically fires 2–6× per day and never on demand —
/// fine for cycling news, not fine for live race updates. If we add
/// live-race alerts later, an FCM provider can implement the same
/// [NotificationsProvider] interface and slot in via DI without any
/// service-layer changes.
class LocalNotificationsProvider implements NotificationsProvider {
  LocalNotificationsProvider({
    FlutterLocalNotificationsPlugin? plugin,
    Workmanager? wm,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _wm = wm ?? Workmanager();

  final FlutterLocalNotificationsPlugin _plugin;
  final Workmanager _wm;

  bool _initialized = false;

  @override
  String get name => 'local';

  static bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> initialize() async {
    if (_initialized || !_isSupportedPlatform) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Permission requested explicitly later so the prompt fires
          // when the user flips the toggle (good UX), not when the
          // first notification tries to render.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _wm.initialize(
      notificationsCallbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    _initialized = true;
  }

  @override
  Future<bool> requestOsPermission() async {
    if (!_isSupportedPlatform) return false;
    try {
      if (Platform.isIOS) {
        final iosPlugin = _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        return await iosPlugin?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LocalNotifications: permission threw: $e');
      }
      return false;
    }
  }

  @override
  Future<void> schedulePeriodicCheck() async {
    if (!_isSupportedPlatform) return;
    if (Platform.isAndroid) {
      await _wm.registerPeriodicTask(
        kArticlePollerTaskName,
        kArticlePollerTaskName,
        // 15min is the OS-enforced minimum for periodic tasks. Doze
        // mode + battery saver may extend it; that's acceptable for
        // a news app.
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
    } else if (Platform.isIOS) {
      // iOS periodic-task frequency is advisory — the OS decides actual
      // cadence based on usage signals. Register so the callback is
      // wired; let the OS handle when.
      await _wm.registerPeriodicTask(
        kArticlePollerTaskName,
        kArticlePollerTaskName,
        frequency: const Duration(hours: 1),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
    }
  }

  @override
  Future<void> cancelScheduledChecks() async {
    if (!_isSupportedPlatform) return;
    try {
      await _wm.cancelByUniqueName(kArticlePollerTaskName);
    } catch (_) {}
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    // Local transport: topics are filter strings the bg task reads from
    // SharedPreferences (written by the cubit). Nothing to do here —
    // the provider has no per-topic registration with an external SDK.
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    // Same as `subscribeToTopic`: no external state to flip.
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      id,
      title,
      body,
      _details(),
      payload: payload,
    );
  }

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'bnr_news_alerts',
          'News alerts',
          channelDescription:
              'Breaking cycling news for the disciplines you follow.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );
}

// ────────────────────────── BACKGROUND FETCHER ──────────────────────────
//
// SharedPreferences keys the bg isolate reads. They are written by the
// foreground app (PreferencesRepository / cubit) on every relevant user
// action; the bg isolate sees the same on-disk file via the platform
// plugin. Keys are duplicated rather than imported because the bg
// dispatcher must keep its dependency graph minimal — the AOT compiler
// only includes code reachable from the entrypoint.

const String _kPrefNotifEnabled = 'pref.notifications.enabled';
const String _kPrefNotifDisciplines = 'pref.notifications.disciplines';
const String _kPrefDigestMode = 'pref.notifications.digestMode';
const String _kPrefDigestHour = 'pref.notifications.digestHour';
const String _kPrefHideKeywords = 'pref.notifications.hideKeywords';
const String _kPrefRegions = 'pref.regions';
const String _kBgLastFetchAt = 'notif.bg.lastFetchAt';
const String _kBgSeenIds = 'notif.bg.seenIds';

/// Per-fire cap on user-visible notifications. We don't want a bg fire
/// after a long offline period to spam 50 stories at once — show the
/// first few, log the rest.
const int _kPerFireNotificationCap = 3;

/// Lifetime cap on the seen-ids list. Without this it grows unbounded
/// (~1 article id per surfaced notification × forever). 500 is plenty
/// to dedupe across multi-week reactivation gaps.
const int _kSeenIdsCap = 500;

/// Top-level workmanager callback. MUST be `@pragma('vm:entry-point')`
/// — Workmanager spawns a fresh isolate to invoke it, and the AOT
/// compiler tree-shakes anything not reachable from the entrypoint.
///
/// On every fire we:
///   1. Read user prefs from the foreground SharedPreferences bag.
///   2. If notifications are disabled or no disciplines are picked,
///      bail out cheap.
///   3. Pull the digest mode + hour. In digest mode, only fire once
///      per day (at the user-set hour); silently return otherwise.
///   4. Fetch /api/articles?since=<lastFetchAt>&disciplines=<csv> for
///      the active region(s). Dedupe against the persisted seen-ids
///      list and the user's hide-keyword list.
///   5. Surface up to [_kPerFireNotificationCap] notifications via
///      flutter_local_notifications. Persist the new seen ids +
///      lastFetchAt for the next fire.
///
/// All exceptions are caught; the worker always returns `true` so the
/// OS treats the run as success and keeps the periodic schedule alive.
@pragma('vm:entry-point')
void notificationsCallbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != kArticlePollerTaskName) return true;
    try {
      await _runBgFetch();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('LocalNotifications: bg task failed: $e\n$st');
      }
    }
    return true;
  });
}

Future<void> _runBgFetch() async {
  final prefs = await SharedPreferences.getInstance();

  // Hard gates: anything missing → no work, no notifications.
  final enabled = prefs.getBool(_kPrefNotifEnabled) ?? false;
  if (!enabled) return;
  final disciplines =
      (prefs.getStringList(_kPrefNotifDisciplines) ?? const <String>[])
          .where((d) => d.isNotEmpty)
          .toList();
  if (disciplines.isEmpty) return;

  // Digest gating — when on, fire once per day at user-set hour.
  final digestMode = prefs.getString(_kPrefDigestMode) ?? 'instant';
  final digestHour = prefs.getInt(_kPrefDigestHour) ?? 8;
  if (digestMode == 'daily' && !_isDigestWindow(digestHour)) {
    if (kDebugMode) {
      debugPrint(
        'LocalNotifications: digest mode on, outside hour=$digestHour window',
      );
    }
    return;
  }

  // Last-fetch baseline — initial fire seeds with "an hour ago" so a
  // fresh install doesn't immediately notify the user about every
  // article in the database.
  final lastFetchedRaw = prefs.getString(_kBgLastFetchAt);
  final since = lastFetchedRaw ??
      DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 1))
          .toIso8601String();

  // Pull the user's selected regions so we don't notify them about
  // areas they don't care about. The cubit stores the full set; we
  // forward all of them as a comma-separated list.
  final regions =
      (prefs.getStringList(_kPrefRegions) ?? const <String>[]).toList();

  final api = ApiClient.create().dio;
  final params = <String, dynamic>{
    'since': since,
    'disciplines': disciplines.join(','),
    'limit': 20,
    if (regions.isNotEmpty) 'regions': regions.join(','),
  };

  Response<dynamic>? res;
  try {
    res = await api.get<dynamic>('/api/articles', queryParameters: params);
  } catch (e) {
    if (kDebugMode) debugPrint('LocalNotifications: fetch failed: $e');
    return;
  }
  final body = res.data;
  if (body is! Map) return;
  final articles = (body['articles'] as List? ?? const [])
      .whereType<Map>()
      .map((m) => Map<String, dynamic>.from(m))
      .toList();
  if (articles.isEmpty) {
    await prefs.setString(
      _kBgLastFetchAt,
      DateTime.now().toUtc().toIso8601String(),
    );
    return;
  }

  // Apply the user's hide-keyword list, dedupe by id.
  final hideKeywords =
      prefs.getStringList(_kPrefHideKeywords) ?? const <String>[];
  final seenIds =
      (prefs.getStringList(_kBgSeenIds) ?? const <String>[]).toSet();
  final fresh = filterArticlesForNotification(
    articles: articles,
    seenIds: seenIds,
    hideKeywords: hideKeywords,
  );

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  // Digest mode collapses the batch into one summary notification.
  if (digestMode == 'daily' && fresh.isNotEmpty) {
    await plugin.show(
      // Stable digest id — replaces yesterday's digest if the user
      // hasn't tapped it yet.
      1000000,
      'Today in cycling',
      _digestSummary(fresh),
      _bgNotificationDetails(),
      payload: jsonEncode({'kind': 'digest', 'count': fresh.length}),
    );
  } else {
    var rendered = 0;
    for (final raw in fresh) {
      if (rendered >= _kPerFireNotificationCap) break;
      final id = (raw['id'] as num).toInt();
      final title = (raw['title'] as String?) ?? '';
      final desc = (raw['description'] as String?) ?? '';
      await plugin.show(
        id,
        title,
        desc,
        _bgNotificationDetails(),
        payload: jsonEncode({'kind': 'article', 'id': id}),
      );
      rendered += 1;
    }
  }

  // Persist seen ids + last-fetch baseline. Cap the seen list so a
  // long-running install doesn't bloat shared_preferences.
  for (final raw in fresh) {
    final id = (raw['id'] as num).toInt();
    seenIds.add('$id');
  }
  final cappedSeen = seenIds.length > _kSeenIdsCap
      ? seenIds.toList().sublist(seenIds.length - _kSeenIdsCap)
      : seenIds.toList();
  await prefs.setStringList(_kBgSeenIds, cappedSeen);
  await prefs.setString(
    _kBgLastFetchAt,
    DateTime.now().toUtc().toIso8601String(),
  );
}

bool _isDigestWindow(int hour) {
  // Workmanager's 15-min cadence means we get up to 4 fires per hour.
  // We want exactly one digest at the configured hour, so accept any
  // fire whose local hour matches AND whose minute is in the first
  // quarter — gives us one match per day under normal scheduling.
  final now = DateTime.now();
  return now.hour == hour && now.minute < 15;
}

String _digestSummary(List<Map<String, dynamic>> fresh) {
  final n = fresh.length;
  if (n == 0) return '';
  if (n == 1) return (fresh.first['title'] as String?) ?? '';
  // First headline + " · +N more" — surfaces a real story rather
  // than a bare count, gives the user a reason to tap.
  final lead = (fresh.first['title'] as String?) ?? '';
  return '$lead  ·  +${n - 1} more';
}

NotificationDetails _bgNotificationDetails() => const NotificationDetails(
      android: AndroidNotificationDetails(
        'bnr_news_alerts',
        'News alerts',
        channelDescription:
            'Breaking cycling news for the disciplines you follow.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

/// Pure helper exposed for tests. Filters [articles] against [seenIds]
/// + [hideKeywords] and returns the keepers in original order. The bg
/// dispatcher above calls this; the public surface lets us assert
/// behaviour without booting SharedPreferences.
List<Map<String, dynamic>> filterArticlesForNotification({
  required List<Map<String, dynamic>> articles,
  required Set<String> seenIds,
  required List<String> hideKeywords,
}) {
  final out = <Map<String, dynamic>>[];
  final lowered = hideKeywords
      .map((k) => k.trim().toLowerCase())
      .where((k) => k.isNotEmpty)
      .toList();
  for (final a in articles) {
    final id = (a['id'] as num?)?.toInt();
    if (id == null) continue;
    if (seenIds.contains('$id')) continue;
    final title = (a['title'] as String? ?? '').toLowerCase();
    final desc = (a['description'] as String? ?? '').toLowerCase();
    final hay = '$title $desc';
    if (lowered.any(hay.contains)) continue;
    out.add(a);
  }
  return out;
}
