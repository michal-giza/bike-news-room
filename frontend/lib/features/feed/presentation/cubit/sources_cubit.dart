import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/feed_source.dart';
import '../../domain/usecases/get_feed_sources.dart';

/// Loads feed sources once on startup and exposes a `feedId → title` lookup.
/// Cards use this to render real source names instead of the placeholder.
class SourcesState extends Equatable {
  final Map<int, FeedSource> byId;
  final bool loading;
  const SourcesState({this.byId = const {}, this.loading = false});

  /// Stable display string for a feedId, falling back to a useful placeholder
  /// so cards never show literal "Source".
  String displayFor(int? feedId) {
    if (feedId == null) return 'Source';
    return byId[feedId]?.title ?? 'Source';
  }

  @override
  List<Object?> get props => [byId, loading];
}

class SourcesCubit extends Cubit<SourcesState> {
  final GetFeedSources getFeedSources;

  SourcesCubit({required this.getFeedSources}) : super(const SourcesState());

  Future<void> load() async {
    emit(const SourcesState(loading: true));
    final result = await getFeedSources(const NoParams());
    result.fold(
      (_) => emit(const SourcesState()),
      (list) => emit(SourcesState(
        byId: {for (final s in list) s.id: s},
      )),
    );
  }
}
