import 'package:bike_news_room/core/di/injection.dart';
import 'package:bike_news_room/core/network/api_client.dart';
import 'package:bike_news_room/features/preferences/domain/entities/user_preferences.dart';
import 'package:bike_news_room/main.dart' as app;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_api.dart';

/// Pre-built launch helpers for integration tests.
///
/// Every call gives the test:
///   - A clean get_it container (existing registrations cleared).
///   - Mocked SharedPreferences with the test's chosen seed.
///   - A pre-registered `ApiClient` whose Dio uses the supplied
///     `MockApi` adapter, so the app talks to a deterministic local
///     responder rather than the live backend.
///   - `app.main()` invoked, then `pumpAndSettle` until the first
///     frame is laid out.
///
/// The harness deliberately pre-seeds `pref.onboardingComplete=true`
/// by default. The full onboarding → consent → AdMob.init chain
/// hangs in test environments because UMP makes a network call to
/// Google. Tests that need to exercise onboarding explicitly should
/// pass `seedOnboardingComplete: false`.
class TestHarness {
  /// Boots the app with [api] as the canned backend and [prefs] as the
  /// initial SharedPreferences map.
  static Future<void> launch(
    WidgetTester tester, {
    required MockApi api,
    Map<String, dynamic>? prefs,
    bool seedOnboardingComplete = true,
    Duration settle = const Duration(seconds: 5),
  }) async {
    // Reset the DI container — every test starts from a known empty state.
    await getIt.reset();

    // Pre-seed prefs. The defaults (theme=dark, density=comfort,
    // onboardingComplete=true) reflect the most-common returning-user
    // profile, so feed-page tests don't have to walk through onboarding.
    final seeded = <String, Object>{
      'pref.theme': AppThemeMode.dark.name,
      'pref.density': CardDensity.comfort.name,
      'pref.regions': <String>[],
      'pref.disciplines': <String>[],
      'pref.hiddenSources': <String>[],
      'pref.bookmarks': <String>[],
      'pref.reducedMotion': false,
      'pref.onboardingComplete': seedOnboardingComplete,
      ...?prefs,
    };
    SharedPreferences.setMockInitialValues(seeded);

    // Pre-register a Dio whose HttpClientAdapter is the mock. The
    // idempotent `configureDependencies()` will then SKIP its own
    // ApiClient registration and reuse this one for every downstream
    // service (FeedRemoteDataSource, CalendarRemoteDataSource, etc.).
    final dio = Dio(BaseOptions(
      baseUrl: 'https://mock.test',
      // Short timeouts so misconfigured stubs surface fast in tests
      // instead of hanging the suite.
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
      responseType: ResponseType.json,
    ))
      ..httpClientAdapter = api;
    getIt.registerSingleton<ApiClient>(ApiClient.testWith(dio));

    // Now boot the real app — DI fills in everything else.
    await app.main();
    await tester.pumpAndSettle(settle);
  }

  /// Convenience for the most-common test case: app boots showing the
  /// feed page populated with [articles]. Caller passes a list of
  /// `stubArticle(...)` maps and the harness wires them as the response
  /// to `/api/articles`. Other endpoints get default-empty stubs so
  /// the app doesn't trip on missing responses (calendar, races, etc.).
  static Future<MockApi> launchFeedWith(
    WidgetTester tester, {
    required List<Map<String, dynamic>> articles,
    Map<String, dynamic>? prefs,
    Duration settle = const Duration(seconds: 5),
  }) async {
    final api = MockApi()
      ..onGetMatching('/api/articles', json: stubArticlesPage(articles: articles))
      ..onGetMatching('/api/feeds', json: {'feeds': []})
      ..onGetMatching('/api/categories', json: {'categories': []})
      ..onGetMatching('/api/races', json: {'races': []})
      ..onGetMatching('/api/live-ticker', json: {'entries': []})
      ..onGetMatching('/api/sources/candidates', json: {'candidates': []})
      // Fallback so any other endpoint (sources, etc.) returns 200 + {}
      // rather than 404 — keeps tests resilient when new code paths
      // appear without their own stub.
      ..onAnyGet();
    await launch(tester, api: api, prefs: prefs, settle: settle);
    return api;
  }
}
