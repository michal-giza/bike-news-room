import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/watchlist_repository.dart';
import '../../domain/entities/watched_entity.dart';

class WatchlistState extends Equatable {
  final List<WatchedEntity> catalogue;
  final List<WatchedEntity> following;
  final bool ready;

  const WatchlistState({
    this.catalogue = const [],
    this.following = const [],
    this.ready = false,
  });

  WatchlistState copyWith({
    List<WatchedEntity>? catalogue,
    List<WatchedEntity>? following,
    bool? ready,
  }) =>
      WatchlistState(
        catalogue: catalogue ?? this.catalogue,
        following: following ?? this.following,
        ready: ready ?? this.ready,
      );

  /// True if the article matches any followed entity (by name/alias word match).
  bool isWatched({String? title, String? description}) {
    if (following.isEmpty) return false;
    final text = '${title ?? ""} ${description ?? ""}';
    return following.any((e) => e.matches(text));
  }

  /// All followed entities that match the article, used to render chips.
  List<WatchedEntity> matches({String? title, String? description}) {
    if (following.isEmpty) return const [];
    final text = '${title ?? ""} ${description ?? ""}';
    return following.where((e) => e.matches(text)).toList();
  }

  /// Search the catalogue by name/alias prefix or substring (case-insensitive),
  /// excluding entities already followed.
  List<WatchedEntity> searchCatalogue(String query) {
    if (query.trim().isEmpty) return const [];
    final q = query.toLowerCase().trim();
    final followingIds = following.map((e) => e.id).toSet();
    return catalogue
        .where((e) => !followingIds.contains(e.id))
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.aliases.any((a) => a.toLowerCase().contains(q)))
        .take(8)
        .toList();
  }

  @override
  List<Object?> get props => [catalogue, following, ready];
}

class WatchlistCubit extends Cubit<WatchlistState> {
  final WatchlistRepository repository;

  WatchlistCubit(this.repository) : super(const WatchlistState());

  Future<void> load() async {
    final catalogue = await repository.loadCatalogue();
    final following = await repository.loadFollowing();
    emit(state.copyWith(
      catalogue: catalogue,
      following: following,
      ready: true,
    ));
  }

  Future<void> follow(WatchedEntity entity) async {
    if (state.following.any((e) => e.id == entity.id)) return;
    final next = [...state.following, entity];
    emit(state.copyWith(following: next));
    await repository.saveFollowing(next);
  }

  Future<void> unfollow(String id) async {
    final next = state.following.where((e) => e.id != id).toList();
    emit(state.copyWith(following: next));
    await repository.saveFollowing(next);
  }

  /// Add a brand-new entity (custom, not from catalogue).
  Future<void> followCustom({
    required String name,
    required WatchedKind kind,
  }) async {
    final id = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (id.isEmpty) return;
    if (state.following.any((e) => e.id == id)) return;
    await follow(WatchedEntity(
      id: id,
      kind: kind,
      name: name.trim(),
      aliases: const [],
      fromCatalogue: false,
    ));
  }
}
