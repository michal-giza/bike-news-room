import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/race.dart';

abstract class CalendarRepository {
  /// Upcoming races, optionally filtered by discipline. `limit` clamps result size.
  Future<Either<Failure, List<Race>>> getUpcoming({
    String? discipline,
    int limit = 40,
  });
}
