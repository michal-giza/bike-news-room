import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/article.dart';
import '../entities/category_count.dart';
import '../entities/feed_source.dart';

/// Domain contract for the feed feature. Implemented in the data layer.
abstract class FeedRepository {
  Future<Either<Failure, ArticlePage>> getArticles(ArticleFilter filter);

  Future<Either<Failure, Article>> getArticleById(int id);

  /// Returns the duplicate-cluster siblings of a canonical article.
  Future<Either<Failure, List<Article>>> getCluster(int canonicalId);

  Future<Either<Failure, List<FeedSource>>> getFeeds();

  Future<Either<Failure, List<CategoryCount>>> getCategories();
}
