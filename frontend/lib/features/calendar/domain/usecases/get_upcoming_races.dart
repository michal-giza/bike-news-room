import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/race.dart';
import '../repositories/calendar_repository.dart';

class UpcomingRacesParams extends Equatable {
  final String? discipline;
  final int limit;
  const UpcomingRacesParams({this.discipline, this.limit = 40});
  @override
  List<Object?> get props => [discipline, limit];
}

class GetUpcomingRaces extends UseCase<List<Race>, UpcomingRacesParams> {
  final CalendarRepository repository;
  GetUpcomingRaces(this.repository);

  @override
  Future<Either<Failure, List<Race>>> call(UpcomingRacesParams params) =>
      repository.getUpcoming(
        discipline: params.discipline,
        limit: params.limit,
      );
}
