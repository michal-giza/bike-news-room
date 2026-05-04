import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../preferences/presentation/cubit/preferences_cubit.dart';
import '../../data/datasources/article_snapshot_store.dart';
import '../../data/models/article_model.dart';
import '../../domain/entities/article.dart';
import '../bookmark_action.dart';
import '../cubit/sources_cubit.dart';
import '../widgets/article_card.dart';
import 'article_detail_modal.dart';

/// Saved articles, served from the on-device `ArticleSnapshotStore` (not
/// from the in-memory feed list). The snapshot is populated at the
/// moment the user taps the bookmark icon, so the page survives:
///   • Backend retention sweeps (article deleted server-side after 90d)
///   • Cold starts (FeedBloc hasn't paginated to that article yet)
///   • Network outages (snapshot is fully local)
///
/// We rebuild on every PreferencesCubit emission so adding/removing a
/// bookmark elsewhere reflects here without needing a manual refresh.
class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return BlocBuilder<PreferencesCubit, dynamic>(
      builder: (context, _) {
        final prefs = context.watch<PreferencesCubit>().state;
        final sources = context.watch<SourcesCubit>().state;
        // Insertion-order set: most-recently-bookmarked last. We render
        // most-recent-first by reversing so the freshest save is on top.
        final ids = prefs.bookmarkedArticleIds.toList().reversed.toList();

        return Scaffold(
          backgroundColor: ext.bg0,
          appBar: AppBar(
            backgroundColor: ext.bg0,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: ext.fg0),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Bookmarks',
              style: AppTheme.serif(
                size: 22,
                weight: FontWeight.w600,
                letterSpacing: -0.02,
                color: ext.fg0,
              ),
            ),
          ),
          body: ids.isEmpty
              ? _emptyState(context)
              : FutureBuilder<List<ArticleModel>>(
                  future: getIt<ArticleSnapshotStore>().loadAll(ids),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final articles = snap.data!;
                    // Reorder by the user's bookmark order (insertion order
                    // from the cubit), since loadAll doesn't guarantee it.
                    final byId = {for (final a in articles) a.id: a};
                    final ordered = <ArticleModel>[
                      for (final id in ids)
                        if (byId[id] != null) byId[id]!,
                    ];

                    if (ordered.isEmpty) return _emptyState(context);

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        BnrSpacing.s4,
                        BnrSpacing.s4,
                        BnrSpacing.s4,
                        BnrSpacing.s12,
                      ),
                      itemCount: ordered.length,
                      itemBuilder: (context, i) {
                        final article = ordered[i];
                        return ArticleCard(
                          article: article,
                          density: prefs.density,
                          bookmarked: true,
                          sourceName: sources.displayFor(article.feedId),
                          onTap: () => _open(
                            context,
                            article,
                            sources,
                            prefs.bookmarkedArticleIds,
                          ),
                          onBookmark: () => toggleBookmark(context, article),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  void _open(
    BuildContext context,
    Article article,
    SourcesState sources,
    Set<int> bookmarks,
  ) {
    ArticleDetailModal.show(
      context,
      article: article,
      sourceName: sources.displayFor(article.feedId),
      bookmarked: bookmarks.contains(article.id),
      onBookmark: () => toggleBookmark(context, article),
    );
  }

  Widget _emptyState(BuildContext context) {
    final ext = context.bnr;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BnrSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, color: ext.fg2, size: 40),
            const SizedBox(height: BnrSpacing.s4),
            Text(
              'No bookmarks yet',
              style: AppTheme.serif(size: 24, color: ext.fg0),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the bookmark icon on any card to save it here.',
              textAlign: TextAlign.center,
              style: AppTheme.sans(size: 14, color: ext.fg2),
            ),
          ],
        ),
      ),
    );
  }
}
