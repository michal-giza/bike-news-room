import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../preferences/presentation/cubit/preferences_cubit.dart';
import '../../domain/entities/article.dart';
import '../bloc/feed_bloc.dart';
import '../cubit/sources_cubit.dart';
import '../widgets/article_card.dart';
import 'article_detail_modal.dart';

/// Saved articles. Filters the current feed list to bookmarked IDs only.
/// (Once a backend bookmarks endpoint exists, we'll fetch by ID rather than
/// relying on the in-memory feed list.)
class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final prefs = context.watch<PreferencesCubit>().state;
    final feedState = context.watch<FeedBloc>().state;
    final sources = context.watch<SourcesCubit>().state;

    final saved = feedState.articles
        .where((a) => prefs.bookmarkedArticleIds.contains(a.id))
        .toList();

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
      body: saved.isEmpty
          ? _emptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                BnrSpacing.s4,
                BnrSpacing.s4,
                BnrSpacing.s4,
                BnrSpacing.s12,
              ),
              itemCount: saved.length,
              itemBuilder: (context, i) {
                final article = saved[i];
                return ArticleCard(
                  article: article,
                  density: prefs.density,
                  bookmarked: true,
                  sourceName: sources.displayFor(article.feedId),
                  onTap: () => _open(context, article, sources, prefs.bookmarkedArticleIds),
                  onBookmark: () => context
                      .read<PreferencesCubit>()
                      .toggleBookmark(article.id),
                );
              },
            ),
    );
  }

  void _open(BuildContext context, Article article, SourcesState sources, Set<int> bookmarks) {
    ArticleDetailModal.show(
      context,
      article: article,
      sourceName: sources.displayFor(article.feedId),
      bookmarked: bookmarks.contains(article.id),
      onBookmark: () =>
          context.read<PreferencesCubit>().toggleBookmark(article.id),
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
