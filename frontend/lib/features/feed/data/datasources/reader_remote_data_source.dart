import 'package:dio/dio.dart';

class ReaderResult {
  final int articleId;
  final String sourceUrl;

  /// Plain-text body, paragraph-broken with `\n\n`. Capped server-side
  /// at 80,000 chars; widget can render it as-is in a SelectableText
  /// inside a SingleChildScrollView.
  final String fullText;

  /// `true` when the backend served from `articles.full_text` cache;
  /// `false` when it just scraped the publisher. Currently surfaced
  /// only in debug logs.
  final bool fromCache;

  const ReaderResult({
    required this.articleId,
    required this.sourceUrl,
    required this.fullText,
    required this.fromCache,
  });

  factory ReaderResult.fromJson(Map<String, dynamic> json) => ReaderResult(
        articleId: (json['article_id'] as num?)?.toInt() ?? 0,
        sourceUrl: (json['source_url'] as String?) ?? '',
        fullText: (json['full_text'] as String?) ?? '',
        fromCache: (json['from_cache'] as bool?) ?? false,
      );
}

abstract class ReaderRemoteDataSource {
  /// Fetch the in-app reader body for [articleId]. Returns `null` when
  /// the publisher 404s, opts out via robots `noarchive`, or the
  /// article id is unknown.
  Future<ReaderResult?> fetch(int articleId);
}

class ReaderRemoteDataSourceImpl implements ReaderRemoteDataSource {
  final Dio dio;
  ReaderRemoteDataSourceImpl(this.dio);

  @override
  Future<ReaderResult?> fetch(int articleId) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/api/articles/$articleId/reader',
      );
      if (res.data == null) return null;
      return ReaderResult.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
