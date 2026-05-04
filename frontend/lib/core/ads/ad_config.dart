import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Ad-unit ID registry. NEVER hard-code unit IDs anywhere else.
///
/// Default ships with `useProductionIds = false`, which routes every slot to
/// Google's official test IDs — safe to ship through dev and TestFlight.
/// Flip to `true` only at the production cutover, after the AdMob app ID
/// has been replaced in Info.plist + AndroidManifest with the real value
/// from the AdMob console.
///
/// Web has no AdMob SDK, so every getter returns null on web and the
/// `AdMobService` no-ops at that layer.
class AdConfig {
  /// Toggle this to `true` only when production ad units are live and
  /// validated. Until then, every slot below returns Google's documented
  /// test ID — Apple/Google both accept these in builds you submit.
  static const bool useProductionIds = false;

  // ── Test IDs (Google's published test units) ────────────────────────
  // Source: https://developers.google.com/admob/ios/test-ads
  //         https://developers.google.com/admob/android/test-ads
  static const _iosTestBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const _androidTestBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosTestInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _androidTestInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  // ── Production IDs ──────────────────────────────────────────────────
  // TODO(majksquare): replace these with real unit IDs from AdMob console.
  // Until they exist, leaving them as empty strings means a misconfigured
  // production build will visibly fail to load ads — better than silently
  // pulling test creatives in production.
  static const _iosProdBanner = '';
  static const _androidProdBanner = '';
  static const _iosProdInterstitial = '';
  static const _androidProdInterstitial = '';

  /// Banner ad unit for the feed. Returns `null` on web (no AdMob SDK).
  static String? get feedBanner {
    if (kIsWeb) return null;
    if (Platform.isIOS) {
      return useProductionIds ? _iosProdBanner : _iosTestBanner;
    }
    if (Platform.isAndroid) {
      return useProductionIds ? _androidProdBanner : _androidTestBanner;
    }
    return null;
  }

  /// Interstitial unit shown sparingly between deep navigations (e.g.
  /// after the user has read 5 articles). Returns `null` on web.
  static String? get interstitial {
    if (kIsWeb) return null;
    if (Platform.isIOS) {
      return useProductionIds ? _iosProdInterstitial : _iosTestInterstitial;
    }
    if (Platform.isAndroid) {
      return useProductionIds
          ? _androidProdInterstitial
          : _androidTestInterstitial;
    }
    return null;
  }

  /// True iff the current platform supports AdMob at all. Used by service
  /// init paths so web/macOS/linux/windows builds can early-return.
  static bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);
}
