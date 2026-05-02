import 'package:dio/dio.dart';

import '../../domain/entities/added_source.dart';
import '../../domain/repositories/sources_repository.dart';

abstract class SourcesRemoteDataSource {
  Future<AddedSource> postSource(AddSourceRequest req);
}

class SourcesRemoteDataSourceImpl implements SourcesRemoteDataSource {
  final Dio dio;
  SourcesRemoteDataSourceImpl(this.dio);

  @override
  Future<AddedSource> postSource(AddSourceRequest req) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/sources',
      data: {
        'url': req.url,
        if (req.name != null) 'name': req.name,
        if (req.region != null) 'region': req.region,
        if (req.discipline != null) 'discipline': req.discipline,
        if (req.language != null) 'language': req.language,
      },
    );
    final body = response.data ?? const {};
    return AddedSource(
      feedId: (body['feed_id'] as num).toInt(),
      kind: body['kind'] == 'crawl'
          ? AddedSourceKind.crawl
          : AddedSourceKind.rss,
      title: body['title'] as String? ?? '',
      url: body['url'] as String? ?? req.url,
      sampleCount: (body['sample_count'] as num?)?.toInt() ?? 0,
      addedAt: DateTime.now(),
    );
  }
}
