import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Base contract for all use cases.
///
/// Each use case is a single-method service that the presentation layer calls
/// to invoke business logic. Returning [Either] forces callers to handle the
/// failure case at compile time.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Marker for use cases that take no parameters.
class NoParams {
  const NoParams();
}
