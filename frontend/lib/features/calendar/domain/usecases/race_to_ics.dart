import '../entities/race.dart';

/// Convert a [Race] into an RFC-5545 VCALENDAR / VEVENT string suitable
/// for handing to a system calendar via the OS share sheet.
///
/// Pure function — no I/O — so it's trivially unit-testable. The widget
/// layer wraps the result in a tmp file and calls share_plus on it.
///
/// Why not the `icalendar` pub package: a single VEVENT is ~15 lines of
/// fixed-format text, the spec is short, and pulling another dep for
/// 30 lines of formatting is overkill. RFC 5545 §3.4 is the authority;
/// we hit the required components only (PRODID, VERSION, UID, DTSTAMP,
/// DTSTART, DTEND, SUMMARY, optional URL + LOCATION + CATEGORIES).
String raceToIcs(Race race, {DateTime? now}) {
  final ts = (now ?? DateTime.now().toUtc());
  final dtStamp = _formatUtc(ts);

  // All-day events use the DATE value-type per RFC 5545 §3.3.4 — note
  // the trailing `;VALUE=DATE`. End is exclusive: a one-day stage from
  // May 5 has DTSTART=20260505 + DTEND=20260506. For the typical
  // multi-day Grand Tour the end-date is the day AFTER the last stage.
  final dtStart = _formatDate(race.startDate);
  final endDay = (race.endDate ?? race.startDate).add(const Duration(days: 1));
  final dtEnd = _formatDate(endDay);

  final buf = StringBuffer()
    ..writeln('BEGIN:VCALENDAR')
    ..writeln('VERSION:2.0')
    ..writeln('PRODID:-//Bike News Room//Race calendar//EN')
    ..writeln('CALSCALE:GREGORIAN')
    ..writeln('METHOD:PUBLISH')
    ..writeln('BEGIN:VEVENT')
    // UID must be globally unique; race.id alone could collide with
    // another app's events. Suffix with our reverse-DNS guarantees it.
    ..writeln('UID:${race.id}@bike-news-room.pages.dev')
    ..writeln('DTSTAMP:$dtStamp')
    ..writeln('DTSTART;VALUE=DATE:$dtStart')
    ..writeln('DTEND;VALUE=DATE:$dtEnd')
    ..writeln('SUMMARY:${_escape(race.name)}');
  final country = race.country;
  if (country != null && country.isNotEmpty) {
    buf.writeln('LOCATION:${_escape(country)}');
  }
  final url = race.url;
  if (url != null && url.isNotEmpty) {
    buf.writeln('URL:${_escape(url)}');
  }
  if (race.discipline.isNotEmpty) {
    buf.writeln('CATEGORIES:${_escape(race.discipline.toUpperCase())}');
  }
  buf
    ..writeln('END:VEVENT')
    ..writeln('END:VCALENDAR');
  return buf.toString();
}

/// `YYYYMMDD` for DATE values.
String _formatDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '$y$m$dd';
}

/// `YYYYMMDDTHHMMSSZ` for DATE-TIME UTC values (DTSTAMP).
String _formatUtc(DateTime d) {
  final u = d.toUtc();
  final base = _formatDate(u);
  final h = u.hour.toString().padLeft(2, '0');
  final mn = u.minute.toString().padLeft(2, '0');
  final s = u.second.toString().padLeft(2, '0');
  return '${base}T$h$mn${s}Z';
}

/// RFC 5545 §3.3.11 mandates escaping `;`, `,`, `\` and newlines in
/// TEXT values. We don't escape the colon (intentionally — most
/// implementations are lenient) but we do collapse internal newlines
/// to `\n` literals so a multi-line race description survives.
String _escape(String input) => input
    .replaceAll(r'\\', r'\\\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll('\n', r'\n');

/// Suggested filename for the share-sheet hand-off. Keep ASCII-safe
/// because some Android share targets reject Unicode filenames.
String suggestedIcsFilename(Race race) {
  final slug = race.name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final yr = race.startDate.year.toString();
  return '${slug.isEmpty ? "race" : slug}-$yr.ics';
}
