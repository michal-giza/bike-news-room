import 'package:bike_news_room/features/feed/data/models/article_model.dart';
import 'package:bike_news_room/features/feed/domain/entities/article.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArticleModel.fromJson', () {
    test('parses RFC3339 dates', () {
      final m = ArticleModel.fromJson({
        'id': 1,
        'feed_id': 2,
        'title': 'Stage 5',
        'url': 'https://example.com/a',
        'published_at': '2026-05-01T12:00:00+00:00',
      });
      expect(m.id, 1);
      expect(m.feedId, 2);
      expect(m.title, 'Stage 5');
      expect(m.publishedAt.toUtc().hour, 12);
    });

    test('parses SQLite-style space-separated dates', () {
      final m = ArticleModel.fromJson({
        'id': 1,
        'feed_id': 2,
        'title': 'x',
        'url': 'https://example.com',
        'published_at': '2026-05-01 12:00:00',
      });
      expect(m.publishedAt.year, 2026);
    });

    test('falls back to now() on missing dates', () {
      final m = ArticleModel.fromJson({
        'id': 1,
        'feed_id': 2,
        'title': 'x',
        'url': 'https://example.com',
      });
      expect(m.publishedAt, isA<DateTime>());
    });

    test('isLive flips false after an hour', () {
      final old = Article(
        id: 1,
        feedId: 1,
        title: 't',
        url: 'u',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(old.isLive, isFalse);
    });

    test('isLive is true for recent articles', () {
      final fresh = Article(
        id: 1,
        feedId: 1,
        title: 't',
        url: 'u',
        publishedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      expect(fresh.isLive, isTrue);
    });
  });

  group('ArticlePageModel.fromJson', () {
    test('reads articles, total, page, has_more', () {
      final p = ArticlePageModel.fromJson({
        'articles': [
          {
            'id': 1,
            'feed_id': 1,
            'title': 'a',
            'url': 'https://example.com/1',
            'published_at': '2026-05-01T12:00:00+00:00',
          }
        ],
        'total': 5,
        'page': 1,
        'has_more': true,
      });
      expect(p.articles.length, 1);
      expect(p.total, 5);
      expect(p.page, 1);
      expect(p.hasMore, isTrue);
    });

    test('handles empty articles array', () {
      final p = ArticlePageModel.fromJson({
        'articles': [],
        'total': 0,
        'page': 1,
        'has_more': false,
      });
      expect(p.articles, isEmpty);
      expect(p.total, 0);
    });
  });

  group('ArticleFilter.copyWith', () {
    test('preserves existing values', () {
      const f = ArticleFilter(page: 2, region: 'spain', discipline: 'mtb');
      final updated = f.copyWith(page: 3);
      expect(updated.page, 3);
      expect(updated.region, 'spain');
      expect(updated.discipline, 'mtb');
    });

    test('null sentinel actually nulls the field', () {
      const f = ArticleFilter(region: 'spain');
      final updated = f.copyWith(region: null);
      expect(updated.region, isNull);
    });
  });
}
