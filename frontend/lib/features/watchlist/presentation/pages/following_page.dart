import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../feed/domain/entities/article.dart';
import '../../../feed/presentation/bloc/feed_bloc.dart';
import '../../../feed/presentation/cubit/sources_cubit.dart';
import '../../../feed/presentation/pages/article_detail_modal.dart';
import '../../../feed/presentation/widgets/article_card.dart';
import '../../../preferences/presentation/cubit/preferences_cubit.dart';
import '../../domain/entities/watched_entity.dart';
import '../cubit/watchlist_cubit.dart';

/// "Following" page — shows the user's watched riders/teams (with unfollow
/// chips) and a feed of articles that match them.
class FollowingPage extends StatelessWidget {
  const FollowingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final watchlist = context.watch<WatchlistCubit>().state;
    final feed = context.watch<FeedBloc>().state;
    final prefs = context.watch<PreferencesCubit>().state;
    final sources = context.watch<SourcesCubit>().state;

    final matchingArticles = feed.articles
        .where((a) =>
            watchlist.isWatched(title: a.title, description: a.description))
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
          'Following',
          style: AppTheme.serif(
            size: 22,
            weight: FontWeight.w600,
            letterSpacing: -0.02,
            color: ext.fg0,
          ),
        ),
      ),
      body: Column(
        children: [
          if (watchlist.following.isNotEmpty)
            _followingChips(context, watchlist.following),
          Expanded(
            child: watchlist.following.isEmpty
                ? _emptyState(context)
                : matchingArticles.isEmpty
                    ? _noMatches(context)
                    : _matchesList(
                        context, matchingArticles, prefs, sources, watchlist),
          ),
        ],
      ),
    );
  }

  Widget _followingChips(
      BuildContext context, List<WatchedEntity> following) {
    final ext = context.bnr;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          BnrSpacing.s4, BnrSpacing.s3, BnrSpacing.s4, BnrSpacing.s4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ext.lineSoft)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final entity in following) _entityChip(context, entity),
        ],
      ),
    );
  }

  Widget _entityChip(BuildContext context, WatchedEntity entity) {
    final ext = context.bnr;
    final accent = BnrColors.disciplineColor(entity.discipline);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: ext.bg2,
        border: Border.all(color: accent.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(BnrRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            entity.kind == WatchedKind.team
                ? Icons.groups_outlined
                : Icons.person_outline,
            size: 12,
            color: accent,
          ),
          const SizedBox(width: 6),
          Text(
            entity.name,
            style: AppTheme.sans(
              size: 12,
              color: ext.fg0,
              weight: FontWeight.w500,
            ),
          ),
          IconButton(
            iconSize: 14,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
            tooltip: 'Unfollow',
            icon: Icon(Icons.close, size: 14, color: ext.fg2),
            onPressed: () =>
                context.read<WatchlistCubit>().unfollow(entity.id),
          ),
        ],
      ),
    );
  }

  Widget _matchesList(
    BuildContext context,
    List<Article> articles,
    dynamic prefs,
    SourcesState sources,
    WatchlistState watchlist,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        BnrSpacing.s4, BnrSpacing.s4, BnrSpacing.s4, BnrSpacing.s12,
      ),
      itemCount: articles.length,
      itemBuilder: (context, i) {
        final article = articles[i];
        final names = watchlist
            .matches(title: article.title, description: article.description)
            .map((e) => e.name)
            .toList();
        return ArticleCard(
          article: article,
          density: prefs.density,
          bookmarked: prefs.bookmarkedArticleIds.contains(article.id),
          watchedNames: names,
          sourceName: sources.displayFor(article.feedId),
          onTap: () => ArticleDetailModal.show(
            context,
            article: article,
            sourceName: sources.displayFor(article.feedId),
            bookmarked: prefs.bookmarkedArticleIds.contains(article.id),
            onBookmark: () =>
                context.read<PreferencesCubit>().toggleBookmark(article.id),
          ),
          onBookmark: () =>
              context.read<PreferencesCubit>().toggleBookmark(article.id),
        );
      },
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
            Icon(Icons.person_search_outlined, color: ext.fg2, size: 40),
            const SizedBox(height: BnrSpacing.s4),
            Text(
              'Not following anyone yet',
              style: AppTheme.serif(size: 24, color: ext.fg0),
            ),
            const SizedBox(height: 8),
            Text(
              'Press ⌘K (or tap search) and start typing a rider or team name.\n'
              'You\'ll see a "+ Follow" suggestion at the top of the results.',
              textAlign: TextAlign.center,
              style: AppTheme.sans(size: 14, color: ext.fg2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noMatches(BuildContext context) {
    final ext = context.bnr;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BnrSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, color: ext.fg2, size: 40),
            const SizedBox(height: BnrSpacing.s4),
            Text(
              'Nothing today from your followed list',
              style: AppTheme.serif(size: 22, color: ext.fg0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "We'll show articles here as soon as your riders or teams make news.",
              textAlign: TextAlign.center,
              style: AppTheme.sans(size: 14, color: ext.fg2),
            ),
          ],
        ),
      ),
    );
  }
}
