import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Abstract interface so tests can swap a fake in via get_it without
/// pulling in the real AdMob SDK. NEVER register the concrete
/// `AdMobService` directly with `getIt<AdMobService>()` — always
/// register against `IAdService`.
abstract class IAdService {
  /// Idempotent. Initializes the AdMob SDK on supported platforms.
  /// MUST be called only AFTER ATT (iOS) and UMP (GDPR) consent have
  /// been resolved by the onboarding flow. Calling earlier is a
  /// reviewer-visible privacy violation on iOS.
  Future<void> init();

  /// Whether ads can currently be shown. Reflects: SDK initialised,
  /// supported platform, and either non-personalized fallback or full
  /// personalization based on consent.
  bool get isReady;

  /// Build a banner ad ready for placement, or `null` on unsupported
  /// platforms / pre-init / missing unit ID.
  BannerAd? makeFeedBanner({required AdSize size});
}

/// Concrete AdMob-backed implementation. Web/desktop builds fall through
/// `init()` and `makeFeedBanner()` to no-ops thanks to AdConfig guards.
class AdMobService implements IAdService {
  bool _initialized = false;

  @override
  bool get isReady => _initialized;

  @override
  Future<void> init() async {
    if (_initialized) return;
    if (!AdConfig.isSupportedPlatform) {
      if (kDebugMode) debugPrint('AdMobService: unsupported platform, skipping');
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      if (kDebugMode) debugPrint('AdMobService: initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('AdMobService: init failed: $e');
    }
  }

  @override
  BannerAd? makeFeedBanner({required AdSize size}) {
    if (!_initialized) return null;
    final unit = AdConfig.feedBanner;
    if (unit == null || unit.isEmpty) return null;
    return BannerAd(
      adUnitId: unit,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, err) {
          if (kDebugMode) debugPrint('Banner load failed: $err');
          ad.dispose();
        },
      ),
    );
  }
}

/// No-op stand-in for tests, web, and any path where ads must not run.
class NoopAdService implements IAdService {
  @override
  bool get isReady => false;

  @override
  Future<void> init() async {}

  @override
  BannerAd? makeFeedBanner({required AdSize size}) => null;
}
