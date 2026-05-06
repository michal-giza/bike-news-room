import 'notifications_provider.dart';

/// Test / web / desktop fallback. Records arguments so unit tests can
/// assert against the call sequence without booting platform plugins.
///
/// We intentionally surface what was called via `lastShown` /
/// `topics` getters rather than counting calls — assertions like
/// "did the service call schedule after enabling" read more clearly
/// than "did it call schedule N times".
class NoopNotificationsProvider implements NotificationsProvider {
  bool initialized = false;
  bool scheduled = false;
  bool permissionResponse = true;
  final Set<String> topics = {};
  final List<({int id, String title, String body, String? payload})>
      shown = [];

  @override
  String get name => 'noop';

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<bool> requestOsPermission() async => permissionResponse;

  @override
  Future<void> schedulePeriodicCheck() async {
    scheduled = true;
  }

  @override
  Future<void> cancelScheduledChecks() async {
    scheduled = false;
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    topics.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    topics.remove(topic);
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    shown.add((id: id, title: title, body: body, payload: payload));
  }
}
