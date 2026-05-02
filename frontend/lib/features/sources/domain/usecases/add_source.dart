import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/added_source.dart';
import '../repositories/sources_repository.dart';

class AddSource extends UseCase<AddedSource, AddSourceRequest> {
  final SourcesRepository repository;
  AddSource(this.repository);

  @override
  Future<Either<Failure, AddedSource>> call(AddSourceRequest params) =>
      repository.addSource(params);
}
