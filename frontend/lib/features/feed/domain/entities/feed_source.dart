import 'package:equatable/equatable.dart';

class FeedSource extends Equatable {
  final int id;
  final String url;
  final String title;
  final String region;
  final String? discipline;
  final String? language;
  final DateTime? lastFetchedAt;
  final int errorCount;

  const FeedSource({
    required this.id,
    required this.url,
    required this.title,
    required this.region,
    required this.errorCount,
    this.discipline,
    this.language,
    this.lastFetchedAt,
  });

  @override
  List<Object?> get props =>
      [id, url, title, region, discipline, language, lastFetchedAt, errorCount];
}
