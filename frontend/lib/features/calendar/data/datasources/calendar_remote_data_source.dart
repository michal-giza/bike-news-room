import 'package:dio/dio.dart';

import '../models/race_model.dart';

abstract class CalendarRemoteDataSource {
  Future<List<RaceModel>> fetchUpcoming({String? discipline, int limit = 40});
}

class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  final Dio dio;
  CalendarRemoteDataSourceImpl(this.dio);

  @override
  Future<List<RaceModel>> fetchUpcoming({String? discipline, int limit = 40}) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/api/races',
      queryParameters: {
        if (discipline != null) 'discipline': discipline,
        'limit': limit,
      },
    );
    final list = (response.data?['races'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RaceModel.fromJson)
        .toList(growable: false);
    return list;
  }
}
