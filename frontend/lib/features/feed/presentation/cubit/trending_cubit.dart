import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/trending_remote_data_source.dart';

class TrendingState extends Equatable {
  final List<TrendingTerm> terms;
  final bool loading;
  final String? errorMessage;

  const TrendingState({
    this.terms = const [],
    this.loading = false,
    this.errorMessage,
  });

  TrendingState copyWith({
    List<TrendingTerm>? terms,
    bool? loading,
    Object? errorMessage = _sentinel,
  }) =>
      TrendingState(
        terms: terms ?? this.terms,
        loading: loading ?? this.loading,
        errorMessage: identical(errorMessage, _sentinel)
            ? this.errorMessage
            : errorMessage as String?,
      );

  static const _sentinel = Object();

  @override
  List<Object?> get props => [terms, loading, errorMessage];
}

/// Owns the trending-terms list. Re-fetches on demand (initial load,
/// pull-to-refresh, periodic re-fetch). Failures don't show a banner —
/// the chip strip just stays as it was, since trending is a
/// nice-to-have, not a critical surface.
class TrendingCubit extends Cubit<TrendingState> {
  final TrendingRemoteDataSource remote;

  TrendingCubit({required this.remote}) : super(const TrendingState());

  Future<void> load({int limit = 8}) async {
    emit(state.copyWith(loading: true, errorMessage: null));
    try {
      final terms = await remote.fetch(limit: limit);
      emit(state.copyWith(terms: terms, loading: false));
    } catch (e) {
      // Silent failure: keep previous terms list, surface error only
      // for log/dev debugging. The widget stays usable.
      emit(state.copyWith(loading: false, errorMessage: e.toString()));
    }
  }
}
