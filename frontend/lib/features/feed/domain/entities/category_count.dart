import 'package:equatable/equatable.dart';

class CategoryCount extends Equatable {
  final String category;
  final int count;

  const CategoryCount({required this.category, required this.count});

  @override
  List<Object?> get props => [category, count];
}
