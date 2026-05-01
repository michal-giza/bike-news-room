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
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    final id = _slugify(cleanName);
    if (id.isEmpty) return;
    if (state.following.any((e) => e.id == id)) return;
    await follow(WatchedEntity(
      id: id,
      kind: kind,
      name: cleanName,
      aliases: const [],
      fromCatalogue: false,
    ));
  }

  /// Build a URL-safe slug from a human name.
  ///
  /// We map common Latin accents to their ASCII base before stripping —
  /// so "Tadej Pogačar" → "tadej-pogacar", not the previous broken
  /// "tadej-pog-ar" that came from running `[^a-z0-9]+` on the raw string.
  static String _slugify(String input) {
    final lowered = input.toLowerCase();
    const accents = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ā': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ě': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ō': 'o', 'ø': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ů': 'u',
      'ý': 'y', 'ÿ': 'y',
      'ñ': 'n', 'ń': 'n',
      'ç': 'c', 'č': 'c', 'ć': 'c',
      'š': 's', 'ś': 's',
      'ž': 'z', 'ź': 'z', 'ż': 'z',
      'ł': 'l',
      'ř': 'r',
      'ď': 'd',
      'ť': 't',
    };
    final ascii = StringBuffer();
    for (final code in lowered.runes) {
      final ch = String.fromCharCode(code);
      ascii.write(accents[ch] ?? ch);
    }
    return ascii
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
