import 'package:equatable/equatable.dart';

/// What sort of cycling subject the user is following.
///
/// `race` covers any event a user might want a permanent feed of —
/// Grand Tours, Monuments, MTB World Cup rounds, Red Bull Rampage, etc.
/// Year-agnostic: "Tour de France" matches every edition, with the year
/// disambiguated by article body content rather than separate entities.
enum WatchedKind { rider, team, race }

/// A rider or team the user is following.
///
/// `aliases` includes display variants (e.g. "Pogačar" / "Pogacar" / "Pog")
/// — they're matched case-insensitively against article titles + descriptions.
/// User-added entities have an empty alias list initially; they can be edited.
class WatchedEntity extends Equatable {
  /// Stable slug used as the persistence key, e.g. "pogacar", "uae-team-emirates".
  final String id;
  final WatchedKind kind;
  final String name;
  final List<String> aliases;
  /// "road" / "mtb" / etc. — used to colour the chip on cards.
  final String? discipline;
  /// True when this entity came from the bundled JSON catalogue, false when
  /// the user added it manually. We use this to show "Custom" chips a bit
  /// differently in settings.
  final bool fromCatalogue;

  const WatchedEntity({
    required this.id,
    required this.kind,
    required this.name,
    this.aliases = const [],
    this.discipline,
    this.fromCatalogue = false,
  });

  /// All match terms — `name` plus aliases. Lowercased.
  List<String> get matchTerms =>
      [name, ...aliases].map((s) => s.toLowerCase()).toList();

  /// Does any term in this entity appear as a whole word in `text`?
  /// Word-boundary check avoids matching "Pog" inside "Poggio".
  bool matches(String? text) {
    if (text == null || text.isEmpty) return false;
    // Normalise: replace every non-letter/non-digit with a space, collapse
    // whitespace runs. This makes punctuation transparent — "Pogačar's win",
    // "(Pogacar)", "Pogacar." all resolve to the same token sequence.
    final normalised =
        ' ${text.toLowerCase().replaceAll(_nonWord, ' ').replaceAll(_runs, ' ').trim()} ';
    for (final term in matchTerms) {
      if (term.isEmpty) continue;
      final normTerm =
          term.replaceAll(_nonWord, ' ').replaceAll(_runs, ' ').trim();
      if (normTerm.isEmpty) continue;
      if (normalised.contains(' $normTerm ')) return true;
    }
    return false;
  }

  // Unicode-aware: `\p{L}` matches accented letters too, so "Pogačar"
  // collapses to "pogačar" not "pog ar".
  static final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
  static final _runs = RegExp(r'\s+');

  WatchedEntity copyWith({
    String? id,
    WatchedKind? kind,
    String? name,
    List<String>? aliases,
    String? discipline,
    bool? fromCatalogue,
  }) =>
      WatchedEntity(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        name: name ?? this.name,
        aliases: aliases ?? this.aliases,
        discipline: discipline ?? this.discipline,
        fromCatalogue: fromCatalogue ?? this.fromCatalogue,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'name': name,
        'aliases': aliases,
        'discipline': discipline,
        'fromCatalogue': fromCatalogue,
      };

  factory WatchedEntity.fromJson(Map<String, dynamic> json) => WatchedEntity(
        id: json['id'] as String,
        kind: WatchedKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => WatchedKind.rider,
        ),
        name: json['name'] as String,
        aliases: (json['aliases'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        discipline: json['discipline'] as String?,
        fromCatalogue: json['fromCatalogue'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, kind, name, aliases, discipline, fromCatalogue];
}
