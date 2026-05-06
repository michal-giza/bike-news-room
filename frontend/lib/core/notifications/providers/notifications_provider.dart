/// The transport-layer contract behind [INotificationsService].
///
/// A [NotificationsProvider] knows HOW to deliver notifications — local
/// only, FCM, OneSignal, APNs direct — but knows nothing about WHEN
/// (consent gating) or WHO (per-discipline opt-in). The service layer
/// owns all that and orchestrates the provider's primitives:
///
/// ```
///   INotificationsService     ← consent gating + topic state
///         │
///         ▼ (composition, single source-of-truth: DI)
///   NotificationsProvider     ← the swappable transport
///         │
///         ▼ (multiple impls, picked at DI registration)
///   ┌─────────┬──────────┬─────────────┐
///   │ Local   │ Firebase │ OneSignal   │  (etc.)
///   └─────────┴──────────┴─────────────┘
/// ```
///
/// Why this split: when we eventually want sub-15-min cadence or
/// rich-media notifications, swapping in an FCM provider should not
/// touch the cubit, the Settings page, or any test. Conversely, when
/// FCM costs/complexity become a problem, swapping the transport back
/// to local should be one DI line.
///
/// Provider methods are deliberately atomic — the service composes them
/// into the higher-level `init` / `setTopics` / `revokeConsent` flow.
abstract class NotificationsProvider {
  /// One-time setup of the underlying SDK (plugin init, channel
  /// registration, etc). Idempotent. Safe to call before the user has
  /// granted OS permission — actual user-facing prompts happen in
  /// [requestOsPermission].
  Future<void> initialize();

  /// Show the system permission prompt (Android 13+ POST_NOTIFICATIONS,
  /// iOS APNS alert dialog) and return whether the user granted it.
  Future<bool> requestOsPermission();

  /// Cap the recurring background fetch / push registration. The
  /// concrete cadence is provider-specific:
  /// - Local: schedule a Workmanager periodic task (15min Android,
  ///   opportunistic iOS) that calls [showNotification].
  /// - Remote (FCM etc.): subscribe to the configured topics so the
  ///   server-side trigger can fan out push.
  ///
  /// Idempotent: calling twice is a no-op; replacing the schedule is
  /// done by [cancelScheduledChecks] then re-scheduling.
  Future<void> schedulePeriodicCheck();

  /// Cancel any scheduled background work + clear delivered
  /// notifications. Used by `revokeConsent`.
  Future<void> cancelScheduledChecks();

  /// Subscribe to a transport-specific topic. For local-only this is a
  /// pref store (topic strings drive the bg fetch's filter); for FCM
  /// it's a real `subscribeToTopic` call.
  Future<void> subscribeToTopic(String topic);

  /// Counterpart to [subscribeToTopic].
  Future<void> unsubscribeFromTopic(String topic);

  /// Display a single local notification with a title + body. For local
  /// providers this drives flutter_local_notifications directly. Remote
  /// providers may delegate to the server side and ignore this call —
  /// the contract is "best effort, user-visible if possible".
  ///
  /// `id` lets callers dedupe (the article id in our case) so the same
  /// piece of news doesn't pop twice if the bg task re-fires.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  /// Diagnostic-only label used in debug logs / Settings page footer
  /// ("News alerts powered by: Local"). Lowercase, single word.
  String get name;
}
