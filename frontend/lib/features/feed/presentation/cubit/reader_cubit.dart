import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/reader_remote_data_source.dart';

enum ReaderStatus { initial, loading, loaded, unavailable, error }

class ReaderState extends Equatable {
  final ReaderStatus status;
  final ReaderResult? result;
  final String? errorMessage;

  const ReaderState({
    this.status = ReaderStatus.initial,
    this.result,
    this.errorMessage,
  });

  ReaderState copyWith({
    ReaderStatus? status,
    Object? result = _sentinel,
    Object? errorMessage = _sentinel,
  }) =>
      ReaderState(
        status: status ?? this.status,
        result: identical(result, _sentinel)
            ? this.result
            : result as ReaderResult?,
        errorMessage: identical(errorMessage, _sentinel)
            ? this.errorMessage
            : errorMessage as String?,
      );

  static const _sentinel = Object();

  @override
  List<Object?> get props => [status, result, errorMessage];
}

/// Per-article reader-mode controller. Created on first toggle inside
/// [ArticleDetailModal]; one instance per modal open, disposed when
/// the modal closes. State is intentionally NOT shared across modals
/// because the typical user flow is "open → read → close → open
/// different article" — caching across modals would just hold dead
/// state in memory.
class ReaderCubit extends Cubit<ReaderState> {
  final ReaderRemoteDataSource remote;

  ReaderCubit({required this.remote}) : super(const ReaderState());

  Future<void> load(int articleId) async {
    emit(state.copyWith(status: ReaderStatus.loading, errorMessage: null));
    try {
      final result = await remote.fetch(articleId);
      if (result == null || result.fullText.trim().isEmpty) {
        emit(state.copyWith(status: ReaderStatus.unavailable));
        return;
      }
      emit(state.copyWith(status: ReaderStatus.loaded, result: result));
    } catch (e) {
      emit(state.copyWith(
        status: ReaderStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
