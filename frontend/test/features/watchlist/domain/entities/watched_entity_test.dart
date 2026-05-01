import 'package:bike_news_room/features/watchlist/domain/entities/watched_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WatchedEntity.matches', () {
    final pogacar = WatchedEntity(
      id: 'pogacar',
      kind: WatchedKind.rider,
      name: 'Tadej Pogačar',
      aliases: const ['Pogacar', 'Pogačar', 'Pog'],
    );

    test('matches by name', () {
      expect(pogacar.matches('Tadej Pogačar wins stage 5'), isTrue);
    });

    test('matches by alias', () {
      expect(pogacar.matches('Pogacar gets the lead'), isTrue);
    });

    test('case-insensitive', () {
      expect(pogacar.matches('POGACAR wins again'), isTrue);
    });

    test('does not match substrings inside other words', () {
      // "Pog" should not fire on "Poggio" — that's a famous Sanremo climb name.
      // We rely on whole-word match.
      final pogShort = WatchedEntity(
        id: 'pog-short',
        kind: WatchedKind.rider,
        name: 'Pog',
      );
      expect(pogShort.matches('The Poggio climb decided it'), isFalse);
    });

    test('matches at start of string', () {
      expect(pogacar.matches('Pogacar is back'), isTrue);
    });

    test('matches at end of string', () {
      expect(pogacar.matches('Stage won by Pogacar'), isTrue);
    });

    test('returns false for null/empty', () {
      expect(pogacar.matches(null), isFalse);
      expect(pogacar.matches(''), isFalse);
    });

    test('returns false for non-matching text', () {
      expect(pogacar.matches('Vingegaard takes the win'), isFalse);
    });

    test('matches across punctuation', () {
      // The previous implementation missed these because the term + period
      // doesn't equal " term ".
      expect(pogacar.matches('Pogacar.'), isTrue);
      expect(pogacar.matches('(Pogacar)'), isTrue);
      expect(pogacar.matches('"Pogacar wins"'), isTrue);
      expect(pogacar.matches("Pogacar's win"), isTrue);
      expect(pogacar.matches('Pogacar—solo'), isTrue);
    });

    test('matches accented Unicode names', () {
      expect(pogacar.matches('Tadej Pogačar wins'), isTrue);
      expect(pogacar.matches('Pogačar.'), isTrue);
    });
  });

  group('WatchedEntity.toJson / fromJson', () {
    test('round-trips', () {
      final original = WatchedEntity(
        id: 'roglic',
        kind: WatchedKind.rider,
        name: 'Primož Roglič',
        aliases: const ['Roglic', 'Roglič'],
        discipline: 'road',
        fromCatalogue: true,
      );
      final restored = WatchedEntity.fromJson(original.toJson());
      expect(restored, equals(original));
    });
  });
}
