import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../calendar/data/datasources/calendar_remote_data_source.dart';
import '../../../calendar/domain/entities/race.dart';
import '../../../feed/data/datasources/article_snapshot_store.dart';
import '../../../feed/domain/entities/article.dart';
import '../../../feed/domain/usecases/get_articles.dart';
import '../../../feed/presentation/bookmark_action.dart';
import '../../../feed/presentation/cubit/sources_cubit.dart';
import '../../../feed/presentation/pages/article_detail_modal.dart';
import '../../../feed/presentation/widgets/article_card.dart';
import '../../../preferences/presentation/cubit/preferences_cubit.dart';
import '../../domain/entities/watched_entity.dart';

/// Per-race archive view, opened from the Following list when the user
/// taps a race chip. Shows three vertically-stacked sections:
///
///   1. **Latest articles** — articles tagged for this race in
///      `race_articles`, newest first. Backed by
///      `/api/articles?race_slug=…` so the matcher's permanent links
///      surface even if the article itself has fallen out of the home
///      feed's recency window.
///   2. **Upcoming editions** — `/api/races?upcoming=true` filtered
///      client-side by name. Lets the user see when the next edition
///      starts.
///   3. **Past editions** — `/api/races?upcoming=false` filtered
///      similarly. Each past edition is tappable; tapping queries the
///      same article archive but constrained with `before` ≤ end of
///      that edition + 14 days.
///
/// Articles render through the existing `ArticleCard` so styling stays
/// consistent with the home feed and bookmarks pages. Snapshot store
/// gets populated on view so race articles persist locally too.
class RaceDetailPage extends StatefulWidget {
  final WatchedEntity race;
  const RaceDetailPage({super.key, required this.race});

  static Future<void> show(BuildContext context, WatchedEntity race) {
    if (race.kind != WatchedKind.race) {
      throw ArgumentError('RaceDetailPage requires a race entity');
    }
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RaceDetailPage(race: race)),
    );
  }

  @override
  State<RaceDetailPage> createState() => _RaceDetailPageState();
}

class _RaceDetailPageState extends State<RaceDetailPage> {
  late Future<List<Article>> _articles;
  late Future<List<Race>> _upcoming;
  late Future<List<Race>> _past;

  @override
  void initState() {
    super.initState();
    _articles = _loadArticles();
    _upcoming = _loadEditions(upcoming: true);
    _past = _loadEditions(upcoming: false);
  }

  /// Fetch race-tagged articles via the backend's `race_slug` filter,
  /// then snapshot them so they survive offline / retention.
  Future<List<Article>> _loadArticles() async {
    final result = await getIt<GetArticles>()(ArticleFilter(
      page: 1,
      limit: 100,
      raceSlug: widget.race.id,
    ));
    return result.fold(
      (_) => const <Article>[],
      (page) {
        // Fire-and-forget snapshot writes — keep the user's race
        // archive available offline. We don't await so the UI doesn't
        // wait on disk for the page render.
        () async {
          for (final a in page.articles) {
            try {
              await getIt<ArticleSnapshotStore>().save(a as dynamic);
            } catch (_) {/* skip */}
          }
        }();
        return page.articles;
      },
    );
  }

  Future<List<Race>> _loadEditions({required bool upcoming}) async {
    try {
      final ds = getIt<CalendarRemoteDataSource>();
      final all = await ds.fetchRaces(
        discipline: null,
        limit: 200,
        upcoming: upcoming,
      );
      // Match editions by checking whether the race's display name +
      // primary alias appear in the catalogue race name. This covers
      // "Tour de France 2026" matching the "Tour de France" follow as
      // well as edition-stamped variants.
      final terms = <String>{
        widget.race.name.toLowerCase(),
        ...widget.race.aliases.map((a) => a.toLowerCase()),
      };
      return all.where((r) {
        final n = r.name.toLowerCase();
        return terms.any(n.contains);
      }).toList();
    } catch (_) {
      return const <Race>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return Scaffold(
      backgroundColor: ext.bg0,
      appBar: AppBar(
        backgroundColor: ext.bg0,
        elevation: 0,
        title: Text(
          widget.race.name,
          style: AppTheme.serif(
            size: 22,
            weight: FontWeight.w600,
            letterSpacing: -0.02,
            color: ext.fg0,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BnrSpacing.s4,
          BnrSpacing.s4,
          BnrSpacing.s4,
          BnrSpacing.s12,
        ),
        children: [
          _SectionHeader(label: 'NEXT EDITION'),
          FutureBuilder<List<Race>>(
            future: _upcoming,
            builder: (_, snap) =>
                _editionList(snap.data, isPast: false, ext: ext),
          ),
          const SizedBox(height: BnrSpacing.s6),
          _SectionHeader(label: 'PAST EDITIONS'),
          FutureBuilder<List<Race>>(
            future: _past,
            builder: (_, snap) =>
                _editionList(snap.data, isPast: true, ext: ext),
          ),
          const SizedBox(height: BnrSpacing.s6),
          _SectionHeader(label: 'ARTICLES'),
          FutureBuilder<List<Article>>(
            future: _articles,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: BnrSpacing.s6),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final articles = snap.data!;
              if (articles.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: BnrSpacing.s6),
                  child: Text(
                    'No articles tagged for this race yet. Coverage builds '
                    'as new stories come in — keep this race followed and '
                    "we'll backfill any past edition we can.",
                    style: AppTheme.sans(
                      size: 14,
                      color: ext.fg2,
                      height: 1.5,
                    ),
                  ),
                );
              }
              final prefs = context.watch<PreferencesCubit>().state;
              final sources = context.watch<SourcesCubit>().state;
              return Column(
                children: [
                  for (final a in articles)
                    ArticleCard(
                      article: a,
                      density: prefs.density,
                      bookmarked: prefs.bookmarkedArticleIds.contains(a.id),
                      sourceName: sources.displayFor(a.feedId),
                      onTap: () => ArticleDetailModal.show(
                        context,
                        article: a,
                        sourceName: sources.displayFor(a.feedId),
                        bookmarked: prefs.bookmarkedArticleIds.contains(a.id),
                        onBookmark: () => toggleBookmark(context, a),
                      ),
                      onBookmark: () => toggleBookmark(context, a),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _editionList(List<Race>? races, {required bool isPast, required BnrThemeExt ext}) {
    if (races == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: BnrSpacing.s4),
        child: SizedBox(
          height: 24,
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    if (races.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BnrSpacing.s2),
        child: Text(
          isPast
              ? 'No past editions in our calendar yet.'
              : 'No upcoming edition scheduled.',
          style: AppTheme.sans(size: 13, color: ext.fg2),
        ),
      );
    }
    // Show at most 3 editions per direction so the page stays scannable.
    final shown = races.take(3).toList();
    return Column(
      children: [
        for (final r in shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _EditionRow(race: r, isPast: isPast),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return Padding(
      padding: const EdgeInsets.only(top: BnrSpacing.s4, bottom: BnrSpacing.s3),
      child: Text(
        label,
        style: AppTheme.mono(
          size: 11,
          color: ext.fg2,
          letterSpacing: 0.18,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EditionRow extends StatelessWidget {
  final Race race;
  final bool isPast;
  const _EditionRow({required this.race, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BnrSpacing.s4,
        vertical: BnrSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: ext.bg1,
        border: Border.all(color: ext.lineSoft),
        borderRadius: BorderRadius.circular(BnrRadius.r2),
      ),
      child: Row(
        children: [
          Icon(
            isPast ? Icons.history : Icons.event,
            size: 14,
            color: ext.fg2,
          ),
          const SizedBox(width: BnrSpacing.s3),
          Expanded(
            child: Text(
              race.name,
              style: AppTheme.sans(
                size: 13,
                color: ext.fg0,
                weight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            _formatDate(race.startDate, race.endDate),
            style: AppTheme.mono(
              size: 11,
              color: ext.fg2,
              letterSpacing: 0.06,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime start, DateTime? end) {
    final s = '${start.day}/${start.month}/${start.year}';
    if (end == null || end == start) return s;
    return '$s → ${end.day}/${end.month}';
  }
}
