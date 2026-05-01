import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/article.dart';
import '../repositories/feed_repository.dart';

class GetArticleById extends UseCase<Article, int> {
  final FeedRepository repository;
  GetArticleById(this.repository);

  @override
  Future<Either<Failure, Article>> call(int params) =>
      repository.getArticleById(params);
}
