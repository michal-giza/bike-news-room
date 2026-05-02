import 'package:equatable/equatable.dart';

enum AddedSourceKind { rss, crawl }

/// A source the user submitted via the "+ Add a source" UX.
///
/// Stored locally per-browser (we have no auth). The backend persists the
/// feed in the global `feeds` table; we keep a thin pointer here so the
/// "My sources" view can show what *this user* added.
class AddedSource extends Equatable {
  final int feedId;
  final AddedSourceKind kind;
  final String title;
  final String url;
  final int sampleCount;
  final DateTime addedAt;

  const AddedSource({
    required this.feedId,
    required this.kind,
    required this.title,
    required this.url,
    required this.sampleCount,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'feedId': feedId,
        'kind': kind.name,
        'title': title,
        'url': url,
        'sampleCount': sampleCount,
        'addedAt': addedAt.toIso8601String(),
      };

  factory AddedSource.fromJson(Map<String, dynamic> json) => AddedSource(
        feedId: (json['feedId'] as num).toInt(),
        kind: AddedSourceKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => AddedSourceKind.rss,
        ),
        title: json['title'] as String,
        url: json['url'] as String,
        sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 0,
        addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [feedId, kind, title, url, sampleCount, addedAt];
}
