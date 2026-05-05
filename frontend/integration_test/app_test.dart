// Integration tests for Bike News Room — exercised on a real Android
// or iOS device via `flutter test integration_test/`.
//
// Coverage matrix (must stay green before any release):
//
//   Success paths:
//     1. Cold-start boots without exception (returning user → feed)
//     2. Cold-start with empty prefs renders onboarding step 1
//     3. Feed renders article cards from a populated backend
//     4. Tap article card → ArticleDetailModal opens
//     5. Tap settings icon → SettingsPage opens, pop returns to feed
//     6. Tap bookmarks icon → BookmarksPage opens
//
//   Failure / corrupted paths:
//     7. Backend returns empty articles → feed shows empty state
//     8. Backend returns 500 → feed shows error state
//     9. Backend returns 404 → feed shows error state
//
// Drivers:
//   • TestHarness.launch / .launchFeedWith register a MockApi adapter
//     so tests don't depend on the live backend. Failure modes (500,
//     network error) are simulated by stubbing the matching path.
//   • All finders are by ValueKey so the suite works under any of our
//     9 locales without translating strings.
//   • Onboarding is bypassed by default (pref.onboardingComplete=true)
//     because the production Skip flow tunnels through the UMP consent
//     SDK + AdMobService.initialize(), which can't resolve in a test
//     environment. Test 2 explicitly opts in.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/mock_api.dart';
import 'helpers/test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ───────── Success paths ─────────

  testWidgets('boot: returning user lands on the feed', (tester) async {
    await TestHarness.launchFeedWith(tester, articles: const []);
    expect(
      find.byKey(const ValueKey('topBarSettingsBtn')),
      findsOneWidget,
      reason: 'top bar settings icon must be present on the feed',
    );
  });

  testWidgets('boot: cold start with empty prefs shows onboarding', (
    tester,
  ) async {
    final api = MockApi()..onAnyGet();
    await TestHarness.launch(
      tester,
      api: api,
      prefs: <String, dynamic>{},
      seedOnboardingComplete: false,
    );
    expect(
      find.byKey(const ValueKey('onboardingSkipBtn')),
      findsOneWidget,
      reason: 'first-run user must see the onboarding Skip button',
    );
  });

  testWidgets('feed: renders article cards from populated backend', (
    tester,
  ) async {
    await TestHarness.launchFeedWith(tester, articles: [
      stubArticle(id: 101, title: 'Pogačar wins Giro stage 4'),
      stubArticle(id: 102, title: 'Vingegaard prepares for Tour'),
      stubArticle(id: 103, title: 'Van der Poel skips classics'),
    ]);
    // Only assert on the first card — phone viewports may not lay out
    // the third before the user scrolls. Finding any card is enough
    // proof that the list-builder rendered the data.
    expect(
      find.byKey(const ValueKey('articleCard_101')),
      findsOneWidget,
      reason: 'first article card from a populated feed must render',
    );
    expect(
      find.byKey(const ValueKey('feedEmptyState')),
      findsNothing,
      reason: 'when the backend has data, the empty-state must NOT show',
    );
  });

  testWidgets('article: tap card opens detail modal', (tester) async {
    await TestHarness.launchFeedWith(tester, articles: [
      stubArticle(id: 201, title: 'Stage 5 results'),
    ]);
    await tester.tap(find.byKey(const ValueKey('articleCard_201')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // ArticleDetailModal renders via showGeneralDialog (not showDialog),
    // so it doesn't push a Material `Dialog` widget. We anchor on the
    // ValueKey we added to the modal's content frame instead.
    expect(
      find.byKey(const ValueKey('articleDetailModal')),
      findsOneWidget,
      reason: 'tapping an article card must push the article detail modal',
    );
  });

  testWidgets('settings: opens from top bar and dismisses cleanly', (
    tester,
  ) async {
    await TestHarness.launchFeedWith(tester, articles: const []);

    await tester.tap(find.byKey(const ValueKey('topBarSettingsBtn')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('settingsPageScaffold')), findsOneWidget);

    final NavigatorState nav = tester.state(find.byType(Navigator).first);
    nav.pop();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('settingsPageScaffold')), findsNothing);
    expect(find.byKey(const ValueKey('topBarSettingsBtn')), findsOneWidget);
  });

  testWidgets('bookmarks: opens from top bar', (tester) async {
    await TestHarness.launchFeedWith(tester, articles: const []);
    await tester.tap(find.byKey(const ValueKey('topBarBookmarksBtn')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('bookmarksPageScaffold')), findsOneWidget);
  });

  // ───────── Failure paths ─────────

  testWidgets('failure: backend empty → feed shows empty state', (
    tester,
  ) async {
    await TestHarness.launchFeedWith(tester, articles: const []);
    expect(
      find.byKey(const ValueKey('feedEmptyState')),
      findsOneWidget,
      reason: 'empty backend must trigger the empty-state widget',
    );
  });

  testWidgets('failure: backend 500 → feed shows error state', (tester) async {
    final api = MockApi()
      ..onGetMatchingFails('/api/articles', statusCode: 500)
      ..onGetMatching('/api/feeds', json: {'feeds': []})
      ..onGetMatching('/api/categories', json: {'categories': []})
      ..onGetMatching('/api/live-ticker', json: {'entries': []})
      ..onGetMatching('/api/sources/candidates', json: {'candidates': []})
      ..onAnyGet();
    await TestHarness.launch(tester, api: api);
    expect(
      find.byKey(const ValueKey('feedErrorState')),
      findsOneWidget,
      reason: 'a 500 from /api/articles must surface the error widget',
    );
  });

  testWidgets('failure: backend 404 → feed shows error state', (tester) async {
    final api = MockApi()
      ..onGetMatchingFails('/api/articles', statusCode: 404)
      ..onGetMatching('/api/feeds', json: {'feeds': []})
      ..onGetMatching('/api/categories', json: {'categories': []})
      ..onGetMatching('/api/live-ticker', json: {'entries': []})
      ..onGetMatching('/api/sources/candidates', json: {'candidates': []})
      ..onAnyGet();
    await TestHarness.launch(tester, api: api);
    expect(
      find.byKey(const ValueKey('feedErrorState')),
      findsOneWidget,
      reason: 'a 404 from /api/articles must surface the error widget',
    );
  });
}
