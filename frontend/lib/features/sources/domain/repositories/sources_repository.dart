import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/added_source.dart';

/// Submission payload — only the URL is required; everything else is
/// optional and the backend supplies sensible defaults.
class AddSourceRequest {
  final String url;
  final String? name;
  final String? region;
  final String? discipline;
  final String? language;

  const AddSourceRequest({
    required this.url,
    this.name,
    this.region,
    this.discipline,
    this.language,
  });
}

abstract class SourcesRepository {
  /// POST /api/sources — backend probes the URL, returns a registered feed.
  Future<Either<Failure, AddedSource>> addSource(AddSourceRequest req);
}
