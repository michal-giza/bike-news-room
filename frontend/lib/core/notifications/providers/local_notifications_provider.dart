import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

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

/// Top-level workmanager callback. MUST be `@pragma('vm:entry-point')`
/// — Workmanager spawns a fresh isolate to invoke it, and the AOT
/// compiler tree-shakes anything not reachable from the entrypoint.
///
/// v1.1 ships this as registered-but-empty. v1.2 fills in the actual
/// `/api/articles?since=…&disciplines=…` fetch + notification render.
/// Registering NOW means no migration when v1.2 lands — the periodic
/// schedule is already running on every install.
@pragma('vm:entry-point')
void notificationsCallbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != kArticlePollerTaskName) return true;
    try {
      if (kDebugMode) {
        debugPrint(
          'LocalNotifications: bg task fired (v1.1: noop placeholder)',
        );
      }
      // v1.2: fetch articles, dedupe, surface up to N as local notifs.
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LocalNotifications: bg task failed: $e');
      }
    }
    return true;
  });
}
