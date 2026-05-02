import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/added_source.dart';
import '../../domain/repositories/sources_repository.dart';
import '../../domain/usecases/add_source.dart';

class UserSourcesState extends Equatable {
  final List<AddedSource> mySources;

  /// `true` while a probe is in flight on the backend.
  final bool submitting;

  /// Last error string from a failed `add` — cleared on the next successful
  /// add or on `reset`.
  final String? errorMessage;

  /// Last successfully added source — used to drive a one-shot toast in
  /// the UI without leaking persistent state. Cleared by `consumeJustAdded`.
  final AddedSource? justAdded;

  const UserSourcesState({
    this.mySources = const [],
    this.submitting = false,
    this.errorMessage,
    this.justAdded,
  });

  UserSourcesState copyWith({
    List<AddedSource>? mySources,
    bool? submitting,
    Object? errorMessage = _sentinel,
    Object? justAdded = _sentinel,
  }) =>
      UserSourcesState(
        mySources: mySources ?? this.mySources,
        submitting: submitting ?? this.submitting,
        errorMessage: identical(errorMessage, _sentinel)
            ? this.errorMessage
            : errorMessage as String?,
        justAdded: identical(justAdded, _sentinel)
            ? this.justAdded
            : justAdded as AddedSource?,
      );

  static const _sentinel = Object();

  @override
  List<Object?> get props => [mySources, submitting, errorMessage, justAdded];
}

/// Owns the user's locally-persisted list of submitted sources + a
/// flight indicator + the last toast payload.
class UserSourcesCubit extends Cubit<UserSourcesState> {
  final AddSource _addSource;
  final SharedPreferences _prefs;

  static const _kKey = 'sources.mySources';

  UserSourcesCubit({
    required AddSource addSource,
    required SharedPreferences prefs,
  })  : _addSource = addSource,
        _prefs = prefs,
        super(const UserSourcesState());

  Future<void> load() async {
    final raw = _prefs.getStringList(_kKey) ?? const [];
    final list = raw
        .map((s) {
          try {
            return AddedSource.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<AddedSource>()
        .toList();
    emit(state.copyWith(mySources: list));
  }

  Future<bool> submit(AddSourceRequest req) async {
    emit(state.copyWith(submitting: true, errorMessage: null));
    final result = await _addSource(req);
    return result.fold(
      (failure) {
        emit(state.copyWith(submitting: false, errorMessage: failure.message));
        return false;
      },
      (added) async {
        // Avoid dupes by feedId — if the user re-submits the same URL the
        // backend gives the same id back; we just refresh the timestamp.
        final next = [
          ...state.mySources.where((s) => s.feedId != added.feedId),
          added,
        ]..sort((a, b) => b.addedAt.compareTo(a.addedAt));
        emit(state.copyWith(
          mySources: next,
          submitting: false,
          errorMessage: null,
          justAdded: added,
        ));
        await _persist(next);
        return true;
      },
    );
  }

  /// Clear `justAdded` after the UI shows its one-shot toast.
  void consumeJustAdded() {
    if (state.justAdded != null) {
      emit(state.copyWith(justAdded: null));
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      emit(state.copyWith(errorMessage: null));
    }
  }

  Future<void> remove(int feedId) async {
    final next =
        state.mySources.where((s) => s.feedId != feedId).toList();
    emit(state.copyWith(mySources: next));
    await _persist(next);
  }

  Future<void> _persist(List<AddedSource> list) async {
    await _prefs.setStringList(
      _kKey,
      list.map((s) => jsonEncode(s.toJson())).toList(growable: false),
    );
  }
}
