import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/race.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_remote_data_source.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDataSource remote;
  CalendarRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<Race>>> getUpcoming({
    String? discipline,
    int limit = 40,
  }) async {
    try {
      final races = await remote.fetchUpcoming(
        discipline: discipline,
        limit: limit,
      );
      return Right(races);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return Left(NetworkFailure(e.message ?? 'connection failed'));
        default:
          return Left(ServerFailure(
            e.message ?? 'server error',
            statusCode: e.response?.statusCode,
          ));
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
