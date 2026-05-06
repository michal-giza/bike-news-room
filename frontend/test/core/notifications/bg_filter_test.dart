// Tests for the pure helpers that drive the bg notification fetcher.
// These functions are deliberately decoupled from SharedPreferences /
// Workmanager so we can assert their behaviour without the platform
// channel.

import 'package:bike_news_room/core/notifications/providers/local_notifications_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filterArticlesForNotification', () {
    test('drops articles whose id is already in seenIds', () {
      final articles = [
        {'id': 1, 'title': 'A'},
        {'id': 2, 'title': 'B'},
      ];
      final out = filterArticlesForNotification(
        articles: articles,
        seenIds: {'1'},
        hideKeywords: const [],
      );
      expect(out.length, 1);
      expect(out.first['id'], 2);
    });

    test('drops articles whose title or description matches a hide kw',
        () {
      final articles = [
        {'id': 1, 'title': 'Doping scandal at Worlds'},
        {'id': 2, 'title': 'Pogačar wins stage'},
        {'id': 3, 'title': 'Stage 5 results', 'description': 'Doping cleared'},
      ];
      final out = filterArticlesForNotification(
        articles: articles,
        seenIds: const {},
        hideKeywords: const ['doping'],
      );
      expect(out.length, 1);
      expect(out.first['id'], 2);
    });

    test('keyword match is case-insensitive', () {
      final articles = [
        {'id': 1, 'title': 'ESCAPE Collective stage 9 recap'},
      ];
      final out = filterArticlesForNotification(
        articles: articles,
        seenIds: const {},
        hideKeywords: const ['ESCAPE'],
      );
      expect(out, isEmpty);
    });

    test('skips entries without an id (defensive against malformed data)',
        () {
      final articles = [
        {'title': 'Missing id'},
        {'id': 1, 'title': 'Has id'},
      ];
      final out = filterArticlesForNotification(
        articles: articles,
        seenIds: const {},
        hideKeywords: const [],
      );
      expect(out.length, 1);
      expect(out.first['id'], 1);
    });

    test('empty input returns empty list', () {
      expect(
        filterArticlesForNotification(
          articles: const [],
          seenIds: const {},
          hideKeywords: const [],
        ),
        isEmpty,
      );
    });

    test('preserves backend ordering', () {
      // The bg fire surfaces the OLDEST first up to N. Backend already
      // returns DESC-ordered, so preserving order here is the contract.
      final articles = List.generate(5, (i) {
        return {'id': i, 'title': 'A$i'};
      });
      final out = filterArticlesForNotification(
        articles: articles,
        seenIds: const {},
        hideKeywords: const [],
      );
      expect(out.map((a) => a['id']).toList(), [0, 1, 2, 3, 4]);
    });
  });
}
