import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/article.dart';
import '../../domain/entities/category_count.dart';
import '../../domain/entities/feed_source.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_data_source.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource remote;
  FeedRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, ArticlePage>> getArticles(ArticleFilter filter) =>
      _guarded(() => remote.fetchArticles(filter));

  @override
  Future<Either<Failure, Article>> getArticleById(int id) =>
      _guarded(() => remote.fetchArticleById(id));

  @override
  Future<Either<Failure, List<Article>>> getCluster(int canonicalId) =>
      _guarded(() => remote.fetchCluster(canonicalId));

  @override
  Future<Either<Failure, List<FeedSource>>> getFeeds() =>
      _guarded(() => remote.fetchFeeds());

  @override
  Future<Either<Failure, List<CategoryCount>>> getCategories() =>
      _guarded(() => remote.fetchCategories());

  /// Maps Dio exceptions to typed failures so the UI can render appropriate
  /// states (offline indicator vs. server error vs. unknown).
  Future<Either<Failure, T>> _guarded<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on DioException catch (e) {
      return Left(_dioToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Failure _dioToFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkFailure(e.message ?? 'connection failed');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 404) return const NotFoundFailure('not found');
        return ServerFailure(e.message ?? 'server error', statusCode: code);
      default:
        return UnknownFailure(e.message ?? 'unknown error');
    }
  }
}
