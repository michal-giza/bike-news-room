import 'package:dio/dio.dart';

/// One trending term — what's spiking in the last 24h compared to a
/// 7-day baseline. Surfaced in the chip strip above the feed; tapping
/// a chip seeds the search query.
class TrendingTerm {
  final String term;
  final int recentCount;
  final int baselineCount;
  final double score;

  const TrendingTerm({
    required this.term,
    required this.recentCount,
    required this.baselineCount,
    required this.score,
  });

  factory TrendingTerm.fromJson(Map<String, dynamic> json) => TrendingTerm(
        term: (json['term'] as String?) ?? '',
        recentCount: (json['recent_count'] as num?)?.toInt() ?? 0,
        baselineCount: (json['baseline_count'] as num?)?.toInt() ?? 0,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Thin HTTP wrapper around `/api/trending`. Consumed by
/// `TrendingCubit` which polls every ~10 minutes when the feed is
/// foregrounded.
abstract class TrendingRemoteDataSource {
  Future<List<TrendingTerm>> fetch({int limit = 8});
}

class TrendingRemoteDataSourceImpl implements TrendingRemoteDataSource {
  final Dio dio;
  TrendingRemoteDataSourceImpl(this.dio);

  @override
  Future<List<TrendingTerm>> fetch({int limit = 8}) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/api/trending',
      queryParameters: {'limit': limit},
    );
    final list = (res.data?['terms'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(TrendingTerm.fromJson)
        .toList(growable: false);
  }
}
