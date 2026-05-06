import 'package:bike_news_room/features/feed/domain/entities/article.dart';
import 'package:bike_news_room/features/feed/presentation/pages/feed_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Article art({required int id, required String title, String? desc}) =>
      Article(
        id: id,
        feedId: 1,
        title: title,
        description: desc,
        url: 'https://example.com/$id',
        publishedAt: DateTime(2026, 5, 7),
        fetchedAt: DateTime(2026, 5, 7),
      );

  group('filterArticlesByHiddenKeywords', () {
    test('returns input unchanged when keywords set is empty', () {
      final articles = [art(id: 1, title: 'a'), art(id: 2, title: 'b')];
      expect(
        filterArticlesByHiddenKeywords(articles, const {}),
        equals(articles),
      );
    });

    test('drops articles whose title matches any keyword (case-insensitive)',
        () {
      final articles = [
        art(id: 1, title: 'Tadej Pogačar wins stage'),
        art(id: 2, title: 'Doping cleared, no charges'),
        art(id: 3, title: 'Stage 8 results'),
      ];
      final out = filterArticlesByHiddenKeywords(articles, {'doping'});
      expect(out.length, 2);
      expect(out.map((a) => a.id), [1, 3]);
    });

    test('matches against description too', () {
      final articles = [
        art(id: 1, title: 'Stage 5', desc: 'Crash in the final km'),
        art(id: 2, title: 'Stage 6', desc: 'Sprint finish'),
      ];
      final out = filterArticlesByHiddenKeywords(articles, {'crash'});
      expect(out.length, 1);
      expect(out.first.id, 2);
    });

    test('whitespace-only keywords are ignored', () {
      final articles = [art(id: 1, title: 'a')];
      final out = filterArticlesByHiddenKeywords(articles, {'  ', '\n'});
      expect(out.length, 1,
          reason: 'an all-whitespace blocklist must not nuke the feed');
    });

    test('multiple keywords: any match drops the article', () {
      final articles = [
        art(id: 1, title: 'Doping news'),
        art(id: 2, title: 'Crash news'),
        art(id: 3, title: 'Equipment review'),
      ];
      final out =
          filterArticlesByHiddenKeywords(articles, {'doping', 'crash'});
      expect(out.length, 1);
      expect(out.first.id, 3);
    });
  });
}
