import 'package:bike_news_room/features/feed/domain/entities/article.dart';
import 'package:bike_news_room/features/feed/presentation/widgets/breaking_panel.dart';
import 'package:flutter_test/flutter_test.dart';

Article _make({
  required int id,
  required Duration ago,
  String? category,
}) =>
    Article(
      id: id,
      feedId: 1,
      title: 'Article $id',
      url: 'https://example.com/$id',
      publishedAt: DateTime.now().subtract(ago),
      category: category,
    );

void main() {
  group('BreakingPanel.selectBreaking', () {
    test('returns empty when no recent articles', () {
      final list = [
        _make(id: 1, ago: const Duration(hours: 3)),
        _make(id: 2, ago: const Duration(days: 1)),
      ];
      expect(BreakingPanel.selectBreaking(list), isEmpty);
    });

    test('only keeps last-hour articles', () {
      final list = [
        _make(id: 1, ago: const Duration(minutes: 30)),
        _make(id: 2, ago: const Duration(minutes: 90)), // too old
        _make(id: 3, ago: const Duration(minutes: 5)),
      ];
      final breaking = BreakingPanel.selectBreaking(list);
      expect(breaking.map((a) => a.id), containsAll([1, 3]));
      expect(breaking.length, 2);
    });

    test('prioritises results category', () {
      final list = [
        _make(
            id: 1, ago: const Duration(minutes: 50), category: 'general'),
        _make(
            id: 2, ago: const Duration(minutes: 40), category: 'results'),
        _make(
            id: 3, ago: const Duration(minutes: 30), category: 'transfers'),
      ];
      final breaking = BreakingPanel.selectBreaking(list);
      // results-category article ranks first even though it's older than #3.
      expect(breaking.first.id, 2);
    });

    test('caps at 4 articles', () {
      final list = List.generate(
        10,
        (i) => _make(
            id: i, ago: Duration(minutes: i * 5), category: 'results'),
      );
      expect(BreakingPanel.selectBreaking(list).length, 4);
    });

    test('within same category, newer articles rank first', () {
      final list = [
        _make(
            id: 1, ago: const Duration(minutes: 50), category: 'results'),
        _make(
            id: 2, ago: const Duration(minutes: 5), category: 'results'),
      ];
      final breaking = BreakingPanel.selectBreaking(list);
      expect(breaking.first.id, 2);
    });
  });
}
