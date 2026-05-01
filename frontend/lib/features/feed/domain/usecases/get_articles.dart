import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/article.dart';
import '../repositories/feed_repository.dart';

class GetArticles extends UseCase<ArticlePage, ArticleFilter> {
  final FeedRepository repository;
  GetArticles(this.repository);

  @override
  Future<Either<Failure, ArticlePage>> call(ArticleFilter params) =>
      repository.getArticles(params);
}
