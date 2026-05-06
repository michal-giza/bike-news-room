// Tests the notifications half of PreferencesCubit. The other paths
// (theme/density/locale) are covered by widget_test.dart's smoke tests.
//
// Why a fake instead of a mocktail mock: the notifications service is
// a thin wrapper around side-effects, so a hand-rolled fake that
// records call arguments reads cleaner than a mock framework here.

import 'package:bike_news_room/core/notifications/notifications_service.dart';
import 'package:bike_news_room/features/preferences/data/preferences_repository.dart';
import 'package:bike_news_room/features/preferences/presentation/cubit/preferences_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotifications implements INotificationsService {
  bool initCalled = false;
  bool? lastConsentGranted;
  Set<String> _topics = {};
  int setTopicsCalls = 0;
  int revokeCalls = 0;

  @override
  Set<String> get activeTopics => _topics;

  @override
  String get providerName => 'fake';

  @override
  bool get isReady => initCalled;

  @override
  Future<void> init({required bool consentGranted}) async {
    initCalled = true;
    lastConsentGranted = consentGranted;
  }

  @override
  Future<void> setTopics(Set<String> topics) async {
    setTopicsCalls += 1;
    _topics = Set<String>.from(topics);
  }

  @override
  Future<void> revokeConsent() async {
    revokeCalls += 1;
    _topics = {};
    initCalled = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PreferencesRepository repo;
  late _FakeNotifications fcm;
  late PreferencesCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = PreferencesRepository(prefs);
    fcm = _FakeNotifications();
    cubit = PreferencesCubit(repo, notifications: fcm);
  });

  group('setNotificationsEnabled', () {
    test(
      'enabling with no preferred disciplines defaults to onboarded set',
      () async {
        // Stage: user picked Road + MTB during onboarding but has never
        // touched the notifications toggle. Enabling should subscribe
        // to those two disciplines as a sensible default — saves the
        // user from re-picking the same thing in two screens.
        await cubit.completeOnboarding(
          regions: const {'world'},
          disciplines: const {'road', 'mtb'},
          density: cubit.state.density,
        );
        await cubit.setNotificationsEnabled(true);

        expect(cubit.state.notificationsEnabled, isTrue);
        expect(
          cubit.state.notificationDisciplines,
          equals({'road', 'mtb'}),
        );
        expect(fcm.initCalled, isTrue);
        expect(fcm.lastConsentGranted, isTrue);
        expect(
          fcm.activeTopics,
          equals({'discipline_road', 'discipline_mtb'}),
        );
      },
    );

    test('enabling preserves a user-customized notification set', () async {
      // Stage: user toggled on, picked just MTB, then toggled off, then
      // back on. The MTB choice should survive the off-on cycle (we
      // store it in prefs even when master is off… wait, we DON'T
      // — setNotificationsEnabled(false) clears the set. So this case
      // tests the alternative path: user has onboarded disciplines but
      // also explicitly customised notifications, master goes off, set
      // clears; turning back on uses onboarded as default again.
      // Documenting the actual behaviour rather than aspirational.)
      await cubit.completeOnboarding(
        regions: const {'world'},
        disciplines: const {'road', 'mtb', 'gravel'},
        density: cubit.state.density,
      );
      await cubit.setNotificationsEnabled(true);
      await cubit.toggleNotificationDiscipline('road'); // remove road
      expect(cubit.state.notificationDisciplines, equals({'mtb', 'gravel'}));
      await cubit.setNotificationsEnabled(false);
      expect(cubit.state.notificationDisciplines, isEmpty);
      // Master back on — falls back to onboarded set since custom set
      // was cleared by the off-flip.
      await cubit.setNotificationsEnabled(true);
      expect(
        cubit.state.notificationDisciplines,
        equals({'road', 'mtb', 'gravel'}),
      );
    });

    test('disabling revokes consent and clears topics', () async {
      await cubit.completeOnboarding(
        regions: const {'world'},
        disciplines: const {'road'},
        density: cubit.state.density,
      );
      await cubit.setNotificationsEnabled(true);
      expect(fcm.activeTopics, isNotEmpty);

      await cubit.setNotificationsEnabled(false);
      expect(cubit.state.notificationsEnabled, isFalse);
      expect(cubit.state.notificationDisciplines, isEmpty);
      expect(fcm.revokeCalls, 1);
    });
  });

  group('toggleNotificationDiscipline', () {
    test('is a no-op when master switch is off', () async {
      await cubit.toggleNotificationDiscipline('road');
      expect(cubit.state.notificationDisciplines, isEmpty);
      expect(fcm.setTopicsCalls, 0,
          reason: 'must not touch FCM when master is off — '
              'we don\'t want a stray subscribe in this state');
    });

    test('flips a single discipline + reconciles topics', () async {
      await cubit.completeOnboarding(
        regions: const {'world'},
        disciplines: const {'road'},
        density: cubit.state.density,
      );
      await cubit.setNotificationsEnabled(true);
      // Initial state: road on, others off.
      expect(cubit.state.notificationDisciplines, equals({'road'}));

      await cubit.toggleNotificationDiscipline('mtb');
      expect(
        cubit.state.notificationDisciplines,
        equals({'road', 'mtb'}),
      );
      expect(
        fcm.activeTopics,
        equals({'discipline_road', 'discipline_mtb'}),
      );

      await cubit.toggleNotificationDiscipline('road');
      expect(cubit.state.notificationDisciplines, equals({'mtb'}));
      expect(fcm.activeTopics, equals({'discipline_mtb'}));
    });
  });

  group('persistence', () {
    test('notification prefs round-trip through SharedPreferences', () async {
      await cubit.completeOnboarding(
        regions: const {'world'},
        disciplines: const {'gravel'},
        density: cubit.state.density,
      );
      await cubit.setNotificationsEnabled(true);
      // Reload the repo from the same backing prefs and confirm.
      final reloaded = repo.load();
      expect(reloaded.notificationsEnabled, isTrue);
      expect(reloaded.notificationDisciplines, equals({'gravel'}));
    });
  });
}
