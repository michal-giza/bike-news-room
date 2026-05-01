import '../../domain/entities/race.dart';

class RaceModel extends Race {
  const RaceModel({
    required super.id,
    required super.name,
    required super.startDate,
    required super.discipline,
    super.endDate,
    super.country,
    super.category,
    super.url,
  });

  factory RaceModel.fromJson(Map<String, dynamic> json) {
    return RaceModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      startDate:
          DateTime.tryParse(json['start_date'] as String? ?? '') ?? DateTime.now(),
      endDate: _parse(json['end_date']),
      country: json['country'] as String?,
      category: json['category'] as String?,
      discipline: json['discipline'] as String? ?? 'road',
      url: json['url'] as String?,
    );
  }

  static DateTime? _parse(Object? v) {
    if (v is! String || v.isEmpty) return null;
    return DateTime.tryParse(v);
  }
}
