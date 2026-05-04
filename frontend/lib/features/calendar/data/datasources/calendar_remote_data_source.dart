import 'package:dio/dio.dart';

import '../models/race_model.dart';

abstract class CalendarRemoteDataSource {
  Future<List<RaceModel>> fetchUpcoming({String? discipline, int limit = 40});

  /// Generic fetch for both directions in time. `upcoming = true` is the
  /// existing calendar-page behaviour (preserved by the default in
  /// `fetchUpcoming`); `upcoming = false` returns past races newest-first.
  Future<List<RaceModel>> fetchRaces({
    required bool upcoming,
    String? discipline,
    int limit = 40,
  });
}

class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  final Dio dio;
  CalendarRemoteDataSourceImpl(this.dio);

  @override
  Future<List<RaceModel>> fetchUpcoming({String? discipline, int limit = 40}) =>
      fetchRaces(upcoming: true, discipline: discipline, limit: limit);

  @override
  Future<List<RaceModel>> fetchRaces({
    required bool upcoming,
    String? discipline,
    int limit = 40,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/api/races',
      queryParameters: {
        if (discipline != null) 'discipline': discipline,
        'limit': limit,
        // Only send the param when explicitly past — keeps the URL on
        // the calendar page identical to before.
        if (!upcoming) 'upcoming': 'false',
      },
    );
    final list = (response.data?['races'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RaceModel.fromJson)
        .toList(growable: false);
    return list;
  }
}
