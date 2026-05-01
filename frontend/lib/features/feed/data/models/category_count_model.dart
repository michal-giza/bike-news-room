import '../../domain/entities/category_count.dart';

class CategoryCountModel extends CategoryCount {
  const CategoryCountModel({required super.category, required super.count});

  factory CategoryCountModel.fromJson(Map<String, dynamic> json) =>
      CategoryCountModel(
        category: json['category'] as String? ?? 'uncategorized',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}
