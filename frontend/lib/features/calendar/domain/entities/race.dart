import 'package:equatable/equatable.dart';

/// A scheduled cycling race — pulled from the backend race calendar.
class Race extends Equatable {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final String? country;
  final String? category; // e.g. "2.UWT", "1.Pro"
  final String discipline; // road | mtb | gravel | cx | track
  final String? url;

  const Race({
    required this.id,
    required this.name,
    required this.startDate,
    required this.discipline,
    this.endDate,
    this.country,
    this.category,
    this.url,
  });

  /// Days until this race begins. Negative if it's already started.
  int daysUntil(DateTime now) =>
      startDate.difference(DateTime(now.year, now.month, now.day)).inDays;

  /// True if the race straddles or includes [now].
  bool isOngoing(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (startDate.isAfter(today)) return false;
    final end = endDate ?? startDate;
    return !today.isAfter(end);
  }

  @override
  List<Object?> get props =>
      [id, name, startDate, endDate, country, category, discipline, url];
}
