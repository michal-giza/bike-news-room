// Integration tests for Bike News Room. Covers the critical-path
// scenarios that have to be working before any release ships:
//
//   1. App boots without exceptions
//   2. Onboarding can be skipped — first-run user lands on the feed
//   3. From the feed, the Settings page is reachable + dismissable
//   4. Returning user (onboarding already complete) goes straight
//      to the feed without seeing onboarding again
//
// Drivers:
//   • `tester.pumpAndSettle()` waits up to 10 s for animations + initial
//     network response. We do NOT mock the network — these tests run
//     against the production-deployed backend so failures here mirror
//     the real user-visible behaviour. If the backend is unhealthy, the
//     feed test will still pass (we only assert structure, not content)
//     but the article-load assertion would flake; we avoid asserting on
//     remote content for that reason.
//
// Locale-stable finders: every interactive widget the tests poke at has
// a `ValueKey('<feature><Action>Btn')`. Tests should never `find.text()`
// translated strings because the same UI ships in 9 locales and CI
// could run under any of them.

import 'package:bike_news_room/features/preferences/data/preferences_repository.dart';
import 'package:bike_news_room/features/preferences/domain/entities/user_preferences.dart';
import 'package:bike_news_room/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Ensure clean prefs before each test so the onboarding tests aren't
  // skewed by a previous run's state.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('cold start with no prefs renders onboarding step 1', (
    tester,
  ) async {
    await app.main();
    // pump + settle gives the app time to wire DI, run main.dart's
    // post-consent init no-op (ATT not requested on Android), and lay
    // out the onboarding scaffold.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // The Skip button is the most stable widget on the onboarding step
    // (visible on every step, locale-key driven).
    expect(
      find.byKey(const ValueKey('onboardingSkipBtn')),
      findsOneWidget,
      reason: 'first-run user must see the onboarding Skip button',
    );
  });

  testWidgets('skipping onboarding lands on the feed', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Tap Skip — this calls completeOnboarding(empty regions/disciplines)
    // and pops the user out to the feed.
    await tester.tap(find.byKey(const ValueKey('onboardingSkipBtn')));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // The feed page exposes the TopBar's settings icon as a stable
    // anchor — onboarding doesn't have one, so its presence is proof
    // we're on the feed.
    expect(
      find.byKey(const ValueKey('topBarSettingsBtn')),
      findsOneWidget,
      reason: 'after skipping onboarding the feed top bar must be visible',
    );
  });

  testWidgets('returning user (onboarding done) skips straight to feed', (
    tester,
  ) async {
    // Pre-seed prefs with `onboardingComplete=true` to simulate a user
    // who's been here before. This bypasses the onboarding gate in
    // `BikeNewsRoomApp.build`.
    SharedPreferences.setMockInitialValues({
      // Mirror the keys PreferencesRepository.save() writes.
      'pref.theme': AppThemeMode.dark.name,
      'pref.density': CardDensity.comfort.name,
      'pref.regions': <String>[],
      'pref.disciplines': <String>[],
      'pref.hiddenSources': <String>[],
      'pref.bookmarks': <String>[],
      'pref.reducedMotion': false,
      'pref.onboardingComplete': true,
    });
    // Re-load prefs through the repository so the test asserts on the
    // same code path the app uses at boot.
    final prefs = await SharedPreferences.getInstance();
    final repo = PreferencesRepository(prefs);
    expect(
      repo.load().onboardingComplete,
      isTrue,
      reason: 'pre-seed must take effect before app starts',
    );

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(
      find.byKey(const ValueKey('topBarSettingsBtn')),
      findsOneWidget,
      reason: 'returning user must land on feed without onboarding',
    );
    expect(
      find.byKey(const ValueKey('onboardingSkipBtn')),
      findsNothing,
      reason: 'onboarding must NOT be visible to a returning user',
    );
  });

  testWidgets('settings page opens from top bar and pops back', (tester) async {
    SharedPreferences.setMockInitialValues({
      'pref.theme': AppThemeMode.dark.name,
      'pref.density': CardDensity.comfort.name,
      'pref.regions': <String>[],
      'pref.disciplines': <String>[],
      'pref.hiddenSources': <String>[],
      'pref.bookmarks': <String>[],
      'pref.reducedMotion': false,
      'pref.onboardingComplete': true,
    });

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Open settings via the gear icon.
    await tester.tap(find.byKey(const ValueKey('topBarSettingsBtn')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(
      find.byKey(const ValueKey('settingsPageScaffold')),
      findsOneWidget,
      reason: 'tapping the settings icon must push SettingsPage',
    );

    // Close via system back / AppBar back leading.
    final NavigatorState nav = tester.state(find.byType(Navigator).first);
    nav.pop();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(
      find.byKey(const ValueKey('settingsPageScaffold')),
      findsNothing,
      reason: 'popping must dismiss the SettingsPage',
    );
    expect(
      find.byKey(const ValueKey('topBarSettingsBtn')),
      findsOneWidget,
      reason: 'after pop user must be back on the feed',
    );
  });
}
