import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/added_source.dart';
import '../../domain/repositories/sources_repository.dart';
import '../datasources/sources_remote_data_source.dart';

class SourcesRepositoryImpl implements SourcesRepository {
  final SourcesRemoteDataSource remote;
  SourcesRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, AddedSource>> addSource(
      AddSourceRequest req) async {
    try {
      final added = await remote.postSource(req);
      return Right(added);
    } on DioException catch (e) {
      // Surface backend's specific error message when present so toast can
      // tell the user *why* (e.g. "URL must be http/https" vs generic).
      final body = e.response?.data;
      final detail = (body is Map && body['error'] is String)
          ? body['error'] as String
          : (e.message ?? 'request failed');
      switch (e.response?.statusCode) {
        case 400:
        case 422:
          return Left(ServerFailure(detail, statusCode: e.response?.statusCode));
        case 413:
          return Left(ServerFailure('Source page too large', statusCode: 413));
        case 502:
          return Left(NetworkFailure('Could not reach that URL'));
        default:
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout) {
            return Left(NetworkFailure(detail));
          }
          return Left(ServerFailure(detail, statusCode: e.response?.statusCode));
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
