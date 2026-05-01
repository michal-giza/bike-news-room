import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/feed_source.dart';
import '../repositories/feed_repository.dart';

class GetFeedSources extends UseCase<List<FeedSource>, NoParams> {
  final FeedRepository repository;
  GetFeedSources(this.repository);

  @override
  Future<Either<Failure, List<FeedSource>>> call(NoParams params) =>
      repository.getFeeds();
}
