import 'package:bike_news_room/features/calendar/domain/entities/race.dart';
import 'package:bike_news_room/features/calendar/domain/usecases/race_to_ics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Race buildRace({
    int id = 42,
    String name = "Tour de France",
    DateTime? start,
    DateTime? end,
    String discipline = 'road',
    String? country = 'France',
    String? url = 'https://example.com/tdf',
  }) =>
      Race(
        id: id,
        name: name,
        startDate: start ?? DateTime(2026, 7, 4),
        endDate: end,
        discipline: discipline,
        country: country,
        url: url,
      );

  group('raceToIcs', () {
    test('emits a well-formed VCALENDAR / VEVENT block', () {
      final race = buildRace(
        end: DateTime(2026, 7, 26),
      );
      final ics = raceToIcs(
        race,
        now: DateTime.utc(2026, 5, 7, 12, 30, 45),
      );

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('UID:42@bike-news-room.pages.dev'));
      expect(ics, contains('DTSTAMP:20260507T123045Z'));
      expect(ics, contains('DTSTART;VALUE=DATE:20260704'));
      // End date is exclusive: race ends 2026-07-26 → DTEND 2026-07-27.
      expect(ics, contains('DTEND;VALUE=DATE:20260727'));
      expect(ics, contains('SUMMARY:Tour de France'));
      expect(ics, contains('LOCATION:France'));
      expect(ics, contains('URL:https://example.com/tdf'));
      expect(ics, contains('CATEGORIES:ROAD'));
      expect(ics, contains('END:VEVENT'));
      expect(ics, contains('END:VCALENDAR'));
    });

    test('single-day race: DTEND is the day after DTSTART', () {
      final race = buildRace(
        start: DateTime(2026, 4, 5),
        end: null, // one-day race
      );
      final ics = raceToIcs(race);
      expect(ics, contains('DTSTART;VALUE=DATE:20260405'));
      expect(ics, contains('DTEND;VALUE=DATE:20260406'));
    });

    test('skips optional fields when missing', () {
      final race = buildRace(country: null, url: null);
      final ics = raceToIcs(race);
      expect(ics, isNot(contains('LOCATION:')));
      expect(ics, isNot(contains('URL:')));
    });

    test('escapes commas, semicolons and newlines in TEXT values per RFC 5545',
        () {
      final race = buildRace(name: 'Stage 5; tricky, name\nwith newline');
      final ics = raceToIcs(race);
      expect(
        ics,
        contains(r'SUMMARY:Stage 5\; tricky\, name\nwith newline'),
      );
    });
  });

  group('suggestedIcsFilename', () {
    test('slugs the name + appends start year', () {
      final race = buildRace();
      expect(suggestedIcsFilename(race), 'tour-de-france-2026.ics');
    });

    test('strips non-alphanumeric chars + collapses runs', () {
      final race = buildRace(name: "Paris–Roubaix '26  (Hell of the North)");
      final filename = suggestedIcsFilename(race);
      expect(filename.endsWith('.ics'), isTrue);
      expect(
        RegExp(r'^[a-z0-9-]+-\d{4}\.ics$').hasMatch(filename),
        isTrue,
        reason:
            'filename must be ASCII-safe and end -<year>.ics; got $filename',
      );
    });

    test('falls back to "race" when name has no alphanumeric content', () {
      final race = buildRace(name: '— !! ?? ---');
      expect(suggestedIcsFilename(race), 'race-2026.ics');
    });
  });
}
