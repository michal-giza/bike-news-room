// Tests the service-layer orchestration against a fake provider. The
// real LocalNotificationsProvider is not exercised here — its surface
// is platform-plugin code that's tested via the integration suite on
// a real device.

import 'package:bike_news_room/core/notifications/notifications_service.dart';
import 'package:bike_news_room/core/notifications/providers/noop_notifications_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('topicForDiscipline', () {
    test('prefixes with discipline_ for grep-able server-side namespace', () {
      expect(topicForDiscipline('road'), 'discipline_road');
      expect(topicForDiscipline('mtb'), 'discipline_mtb');
      expect(topicForDiscipline('cx'), 'discipline_cx');
    });

    test('supported set covers exactly the onboarded disciplines', () {
      // If you add a new discipline to OnboardingPage._disciplineIds,
      // add it here too — otherwise users can pick it during onboarding
      // but never receive notifications for it (the master switch
      // defaults to that set).
      expect(
        kSupportedNotificationDisciplines,
        equals({'road', 'mtb', 'gravel', 'track', 'cx', 'bmx'}),
      );
    });

    test('every supported discipline yields a valid FCM-spec topic name', () {
      // Even though v1.1 ships the local-only provider, topic strings
      // must satisfy the FCM regex `[a-zA-Z0-9-_.~%]+` so we can swap
      // in an FCM provider later without renaming anything.
      final regex = RegExp(r'^[a-zA-Z0-9\-_\.~%]+$');
      for (final id in kSupportedNotificationDisciplines) {
        expect(regex.hasMatch(topicForDiscipline(id)), isTrue);
      }
    });
  });

  group('NotificationsService composition', () {
    late NoopNotificationsProvider provider;
    late NotificationsService service;

    setUp(() {
      provider = NoopNotificationsProvider();
      service = NotificationsService(provider);
    });

    test('init(consentGranted:false) initializes provider but stays inert',
        () async {
      await service.init(consentGranted: false);
      expect(provider.initialized, isTrue,
          reason: 'plugin/SDK init must happen so a later consent-grant '
              'has nothing to set up.');
      expect(provider.scheduled, isFalse,
          reason: 'no consent → no background schedule.');
      expect(service.isReady, isFalse);
    });

    test('init(consentGranted:true) requests permission + schedules check',
        () async {
      provider.permissionResponse = true;
      await service.init(consentGranted: true);
      expect(provider.scheduled, isTrue);
      expect(service.isReady, isTrue);
    });

    test('init(consentGranted:true) but permission denied keeps inert',
        () async {
      provider.permissionResponse = false;
      await service.init(consentGranted: true);
      expect(provider.scheduled, isFalse);
      expect(service.isReady, isFalse);
    });

    test('setTopics computes diff: subscribes new, unsubscribes removed',
        () async {
      await service.init(consentGranted: true);
      await service.setTopics({'discipline_road', 'discipline_mtb'});
      expect(
        provider.topics,
        equals({'discipline_road', 'discipline_mtb'}),
      );
      // Replacing the set: gravel is added, road is removed; mtb stays.
      await service.setTopics({'discipline_mtb', 'discipline_gravel'});
      expect(
        provider.topics,
        equals({'discipline_mtb', 'discipline_gravel'}),
        reason: 'service must compute the diff and reconcile via the '
            'provider, not just clobber state.',
      );
    });

    test('revokeConsent cancels schedule + clears topics', () async {
      await service.init(consentGranted: true);
      await service.setTopics({'discipline_road'});
      await service.revokeConsent();
      expect(service.isReady, isFalse);
      expect(service.activeTopics, isEmpty);
      expect(provider.scheduled, isFalse);
      expect(provider.topics, isEmpty);
    });

    test('providerName surfaces the transport for diagnostics', () {
      expect(service.providerName, 'noop');
    });
  });

  group('NoopNotificationsService', () {
    late NoopNotificationsService service;

    setUp(() {
      service = NoopNotificationsService();
    });

    test('reports not-ready and noop provider name', () {
      expect(service.isReady, isFalse);
      expect(service.providerName, 'noop');
      expect(service.activeTopics, isEmpty);
    });

    test('all methods are safe no-ops', () async {
      await service.init(consentGranted: true);
      await service.setTopics({'discipline_road'});
      await service.revokeConsent();
      // The Noop variant records topics for the cubit's optimistic UI
      // but doesn't pretend to be ready.
    });
  });
}
