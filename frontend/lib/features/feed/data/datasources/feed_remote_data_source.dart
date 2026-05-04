import 'package:dio/dio.dart';

import '../../domain/entities/article.dart';
import '../models/article_model.dart';
import '../models/category_count_model.dart';
import '../models/feed_source_model.dart';

/// Thin HTTP layer — no error mapping (that lives in the repository).
abstract class FeedRemoteDataSource {
  Future<ArticlePageModel> fetchArticles(ArticleFilter filter);
  Future<ArticleModel> fetchArticleById(int id);
  Future<List<ArticleModel>> fetchCluster(int canonicalId);
  Future<List<FeedSourceModel>> fetchFeeds();
  Future<List<CategoryCountModel>> fetchCategories();
}

class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  final Dio dio;
  FeedRemoteDataSourceImpl(this.dio);

  @override
  Future<ArticlePageModel> fetchArticles(ArticleFilter filter) async {
    final params = <String, dynamic>{
      'page': filter.page,
      'limit': filter.limit,
      if (filter.region != null) 'region': filter.region,
      if (filter.discipline != null) 'discipline': filter.discipline,
      if (filter.category != null) 'category': filter.category,
      if (filter.search != null && filter.search!.isNotEmpty)
        'search': filter.search,
      if (filter.since != null) 'since': filter.since!.toIso8601String(),
      if (filter.before != null) 'before': filter.before!.toIso8601String(),
      if (filter.raceSlug != null && filter.raceSlug!.isNotEmpty)
        'race_slug': filter.raceSlug,
    };
    final response = await dio.get<Map<String, dynamic>>(
      '/api/articles',
      queryParameters: params,
    );
    return ArticlePageModel.fromJson(response.data ?? const {});
  }

  @override
  Future<ArticleModel> fetchArticleById(int id) async {
    final response = await dio.get<Map<String, dynamic>>('/api/articles/$id');
    return ArticleModel.fromJson(response.data ?? const {});
  }

  @override
  Future<List<ArticleModel>> fetchCluster(int canonicalId) async {
    final response = await dio.get<List<dynamic>>(
      '/api/articles/$canonicalId/cluster',
    );
    return (response.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ArticleModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<FeedSourceModel>> fetchFeeds() async {
    final response = await dio.get<Map<String, dynamic>>('/api/feeds');
    final list = (response.data?['feeds'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(FeedSourceModel.fromJson)
        .toList(growable: false);
    return list;
  }

  @override
  Future<List<CategoryCountModel>> fetchCategories() async {
    final response = await dio.get<Map<String, dynamic>>('/api/categories');
    final list = (response.data?['categories'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CategoryCountModel.fromJson)
        .toList(growable: false);
    return list;
  }
}
