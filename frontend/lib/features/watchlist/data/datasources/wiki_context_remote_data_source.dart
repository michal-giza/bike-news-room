import 'package:dio/dio.dart';

class WikiContext {
  /// Title as Wikipedia knows it (may differ from our catalogue id).
  final String title;

  /// One-paragraph plain-text summary, ~120 words.
  final String extract;

  /// "Read more on Wikipedia" link target.
  final String sourceUrl;

  /// Thumbnail image URL when Wikipedia has one, else `null`.
  final String? thumbnailUrl;

  /// Locale Wikipedia served the summary in. Useful for fall-back debugging.
  final String lang;

  /// `true` when the body came from the backend's 7-day SQLite cache.
  final bool fromCache;

  const WikiContext({
    required this.title,
    required this.extract,
    required this.sourceUrl,
    this.thumbnailUrl,
    required this.lang,
    required this.fromCache,
  });

  factory WikiContext.fromJson(Map<String, dynamic> json) => WikiContext(
        title: (json['title'] as String?) ?? '',
        extract: (json['extract'] as String?) ?? '',
        sourceUrl: (json['source_url'] as String?) ?? '',
        thumbnailUrl: json['thumbnail_url'] as String?,
        lang: (json['lang'] as String?) ?? 'en',
        fromCache: (json['from_cache'] as bool?) ?? false,
      );
}

abstract class WikiContextRemoteDataSource {
  /// Fetch the Wikipedia summary for [title] in [lang]. Returns `null`
  /// when Wikipedia has no article in either the requested locale or
  /// the English fallback.
  Future<WikiContext?> fetch({required String title, required String lang});
}

class WikiContextRemoteDataSourceImpl implements WikiContextRemoteDataSource {
  final Dio dio;
  WikiContextRemoteDataSourceImpl(this.dio);

  @override
  Future<WikiContext?> fetch({
    required String title,
    required String lang,
  }) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/api/wiki/${Uri.encodeComponent(title)}',
        queryParameters: {'lang': lang},
      );
      if (res.data == null) return null;
      return WikiContext.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
