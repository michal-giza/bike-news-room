import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Two-step consent flow shown during onboarding. ATT first (iOS only),
/// UMP second (both platforms). Apple rejects combined privacy dialogs,
/// so each step is invoked from a separate onboarding page.
///
/// IMPORTANT: UMP itself counts as a tracking SDK on iOS. Never call
/// `requestUmp()` before `requestAtt()` on iOS — the order matters for
/// App Review.
class ConsentService {
  /// True when both consent steps have been resolved at least once. We
  /// don't persist this flag separately; the onboarding-complete flag
  /// in `UserPreferences` already gates re-prompting.
  bool _attResolved = false;
  bool _umpResolved = false;

  bool get attResolved => _attResolved;
  bool get umpResolved => _umpResolved;

  /// Whether the user granted IDFA tracking (iOS). On non-iOS platforms
  /// always returns true since the concept doesn't apply — Android uses
  /// the GAID toggle in system settings, which AdMob picks up automatically.
  Future<bool> isAttGranted() async {
    if (!Platform.isIOS) return true;
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      return status == TrackingStatus.authorized;
    } catch (_) {
      return false;
    }
  }

  /// Step 1 — request ATT (iOS only). Shows Apple's native dialog.
  /// On non-iOS this is an immediate no-op.
  ///
  /// Call from a dedicated onboarding page, NEVER from `main()` and
  /// NEVER on the same screen as the UMP request.
  Future<TrackingStatus> requestAtt() async {
    if (!Platform.isIOS) {
      _attResolved = true;
      return TrackingStatus.notSupported;
    }
    try {
      // Pre-check current status — `requestTrackingAuthorization` only
      // shows the dialog once per install, otherwise returns the cached
      // value silently.
      final current = await AppTrackingTransparency.trackingAuthorizationStatus;
      final result = (current == TrackingStatus.notDetermined)
          ? await AppTrackingTransparency.requestTrackingAuthorization()
          : current;
      _attResolved = true;
      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('ConsentService: ATT failed: $e');
      _attResolved = true;
      return TrackingStatus.notDetermined;
    }
  }

  /// Step 2 — request UMP (Google's IAB-TCF GDPR consent form). Runs on
  /// both iOS and Android; on iOS it MUST come after ATT has been
  /// resolved, since requesting UMP is itself a tracking-SDK touchpoint.
  ///
  /// On platforms where the user is outside a UMP-required jurisdiction,
  /// the form is not shown and this returns immediately.
  Future<void> requestUmp() async {
    try {
      final params = ConsentRequestParameters();
      // Bridge to a Completer so the callback-based API plays well with
      // async/await without requiring the caller to manage state.
      await _runConsentUpdate(params);
      final status =
          await ConsentInformation.instance.getConsentStatus();
      if (status == ConsentStatus.required) {
        await _showConsentForm();
      }
      _umpResolved = true;
    } catch (e) {
      if (kDebugMode) debugPrint('ConsentService: UMP failed: $e');
      _umpResolved = true;
    }
  }

  Future<void> _runConsentUpdate(ConsentRequestParameters params) {
    final c = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        if (!c.isCompleted) c.complete();
      },
      (err) {
        if (!c.isCompleted) c.complete();
      },
    );
    return c.future;
  }

  Future<void> _showConsentForm() {
    final c = Completer<void>();
    ConsentForm.loadConsentForm(
      (form) {
        form.show((_) {
          if (!c.isCompleted) c.complete();
        });
      },
      (err) {
        if (!c.isCompleted) c.complete();
      },
    );
    return c.future;
  }
}
