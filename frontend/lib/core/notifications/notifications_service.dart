import 'package:flutter/foundation.dart';

import 'providers/notifications_provider.dart';

/// User-facing contract: consent gating, topic-set state, idempotent
/// init/revoke. The actual transport (local notifications +
/// workmanager / FCM / OneSignal / …) is plugged in via a
/// [NotificationsProvider] at construction time so we can swap
/// transports without touching the cubit, the Settings page, or any
/// test that uses [NoopNotificationsProvider].
///
/// Same shape as [IAdService] — register against the abstract type in
/// DI, never the concrete one.
abstract class INotificationsService {
  /// Idempotent. Called from `_initPostConsentServices` at app boot
  /// (with the persisted opt-in flag) and from the Settings cubit when
  /// the user toggles the switch on. When `consentGranted=false` the
  /// service tears down any existing background work + clears any
  /// pending notifications.
  Future<void> init({required bool consentGranted});

  /// True when the OS-level pieces are wired and the periodic check is
  /// scheduled.
  bool get isReady;

  /// Bring the live topic subscription set in line with [topics].
  /// Topics are arbitrary strings — for v1.1 they're discipline ids
  /// like `discipline_road`. The set is stored in-memory and persisted
  /// by the cubit; the service reconciles subscribe/unsubscribe calls
  /// against the provider on every change.
  Future<void> setTopics(Set<String> topics);

  /// Tear-down: cancel scheduled work, clear delivered notifications,
  /// and forget every topic. Used when the user flips the master
  /// switch off in Settings.
  Future<void> revokeConsent();

  /// Snapshot of the topic set the device is currently subscribed to.
  Set<String> get activeTopics;

  /// Diagnostic-only: which transport is wired. Surfaced in Settings
  /// debug footer + integration logs ("News alerts powered by: local").
  String get providerName;
}

/// Concrete service that composes a [NotificationsProvider]. Pure
/// orchestration — no platform code, no plugin imports. That makes it
/// trivially unit-testable with a fake provider.
class NotificationsService implements INotificationsService {
  NotificationsService(this._provider);

  final NotificationsProvider _provider;

  bool _initialized = false;
  bool _enabled = false;
  final Set<String> _topics = {};

  @override
  bool get isReady => _initialized && _enabled;

  @override
  Set<String> get activeTopics => Set.unmodifiable(_topics);

  @override
  String get providerName => _provider.name;

  @override
  Future<void> init({required bool consentGranted}) async {
    try {
      if (!_initialized) {
        await _provider.initialize();
        _initialized = true;
      }
      if (!consentGranted) {
        await _teardown();
        return;
      }
      final granted = await _provider.requestOsPermission();
      if (!granted) {
        if (kDebugMode) {
          debugPrint('Notifications: OS permission denied');
        }
        await _teardown();
        return;
      }
      await _provider.schedulePeriodicCheck();
      _enabled = true;
      if (kDebugMode) {
        debugPrint(
          'Notifications: ready (provider=${_provider.name})',
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Notifications: init failed: $e');
    }
  }

  @override
  Future<void> setTopics(Set<String> topics) async {
    if (!_initialized) return;
    final toSubscribe = topics.difference(_topics);
    final toUnsubscribe = _topics.difference(topics);
    for (final t in toSubscribe) {
      try {
        await _provider.subscribeToTopic(t);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Notifications: subscribe $t failed: $e');
        }
      }
    }
    for (final t in toUnsubscribe) {
      try {
        await _provider.unsubscribeFromTopic(t);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Notifications: unsubscribe $t failed: $e');
        }
      }
    }
    _topics
      ..clear()
      ..addAll(topics);
  }

  @override
  Future<void> revokeConsent() async {
    await _teardown();
    // Best-effort unsubscribe so the provider's internal state matches
    // ours — local provider no-ops, FCM provider does the real call.
    for (final t in _topics.toList()) {
      try {
        await _provider.unsubscribeFromTopic(t);
      } catch (_) {}
    }
    _topics.clear();
  }

  Future<void> _teardown() async {
    try {
      await _provider.cancelScheduledChecks();
    } catch (_) {}
    _enabled = false;
  }
}

/// No-op for tests / web / desktop — same semantics as the original
/// service when no transport is plumbed. Kept around so existing
/// integration tests that pre-register a no-op service via
/// `getIt.registerSingleton<INotificationsService>(...)` keep working.
class NoopNotificationsService implements INotificationsService {
  final Set<String> _topics = {};

  @override
  bool get isReady => false;

  @override
  Set<String> get activeTopics => Set.unmodifiable(_topics);

  @override
  String get providerName => 'noop';

  @override
  Future<void> init({required bool consentGranted}) async {}

  @override
  Future<void> setTopics(Set<String> topics) async {
    _topics
      ..clear()
      ..addAll(topics);
  }

  @override
  Future<void> revokeConsent() async {
    _topics.clear();
  }
}

/// Map a discipline id to a stable topic name. Persisted by the cubit
/// as a plain string; FCM-style providers use it directly as the topic
/// name on the server side.
String topicForDiscipline(String disciplineId) => 'discipline_$disciplineId';

/// Disciplines the app surfaces as opt-in topics. Stays in sync with
/// `OnboardingPage._disciplineIds`; the test in
/// `notifications_service_test.dart` enforces the invariant.
const Set<String> kSupportedNotificationDisciplines = {
  'road',
  'mtb',
  'gravel',
  'track',
  'cx',
  'bmx',
};
