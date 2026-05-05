import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../feed/domain/usecases/get_articles.dart';
import '../../../feed/presentation/bookmark_action.dart';
import '../../../feed/presentation/cubit/sources_cubit.dart';
import '../../../feed/presentation/pages/article_detail_modal.dart';
import '../../../feed/presentation/widgets/article_card.dart';
import '../../../preferences/presentation/cubit/preferences_cubit.dart';
import '../../domain/entities/watched_entity.dart';
import '../bloc/following_feed_bloc.dart';
import '../cubit/watchlist_cubit.dart';
import 'race_detail_page.dart';

/// "Following" — watched riders/teams + the articles that match them.
///
/// Owns its own [FollowingFeedBloc] so we fetch matching articles directly
/// from the API instead of filtering whatever's already loaded into the
/// home feed (which would miss anything past page 1).
class FollowingPage extends StatelessWidget {
  const FollowingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FollowingFeedBloc>(
      create: (_) {
        final bloc = FollowingFeedBloc(getArticles: getIt<GetArticles>());
        // Kick off the fetch with whatever the user follows right now.
        final following = context.read<WatchlistCubit>().state.following;
        bloc.add(FollowingFeedRequested(following));
        return bloc;
      },
      child: const _FollowingView(),
    );
  }
}

class _FollowingView extends StatelessWidget {
  const _FollowingView();

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final watchlist = context.watch<WatchlistCubit>().state;
    final following = watchlist.following;

    // Re-fetch whenever the user follows / unfollows someone here. The bloc
    // de-dupes identical re-runs on its own.
    return BlocListener<WatchlistCubit, WatchlistState>(
      listenWhen: (a, b) => a.following != b.following,
      listener: (context, state) {
        context
            .read<FollowingFeedBloc>()
            .add(FollowingFeedRequested(state.following));
      },
      child: Scaffold(
        key: const ValueKey('followingPageScaffold'),
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
            if (following.isNotEmpty)
              _FollowingChips(following: following),
            Expanded(
              child: !watchlist.ready
                  ? const Center(child: CircularProgressIndicator())
                  : following.isEmpty
                      ? const _EmptyFollowState()
                      : const _MatchesList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowingChips extends StatelessWidget {
  final List<WatchedEntity> following;
  const _FollowingChips({required this.following});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        BnrSpacing.s4, BnrSpacing.s3, BnrSpacing.s4, BnrSpacing.s4,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ext.lineSoft)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final entity in following) _EntityChip(entity: entity),
        ],
      ),
    );
  }
}

class _EntityChip extends StatelessWidget {
  final WatchedEntity entity;
  const _EntityChip({required this.entity});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final accent = BnrColors.disciplineColor(entity.discipline);
    // Race chips open the per-race archive page on tap. Rider/team
    // chips don't need a detail view — their content already aggregates
    // into the parent FollowingFeedBloc.
    final tappable = entity.kind == WatchedKind.race;
    final body = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          switch (entity.kind) {
            WatchedKind.team => Icons.groups_outlined,
            WatchedKind.race => Icons.flag_outlined,
            WatchedKind.rider => Icons.person_outline,
          },
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
          tooltip: AppLocalizations.of(context).tooltipUnfollow,
          icon: Icon(Icons.close, size: 14, color: ext.fg2),
          onPressed: () =>
              context.read<WatchlistCubit>().unfollow(entity.id),
        ),
      ],
    );
    final container = Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: ext.bg2,
        border: Border.all(color: accent.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(BnrRadius.pill),
      ),
      child: body,
    );
    if (!tappable) return container;
    return InkWell(
      onTap: () => RaceDetailPage.show(context, entity),
      borderRadius: BorderRadius.circular(BnrRadius.pill),
      child: container,
    );
  }
}

class _MatchesList extends StatelessWidget {
  const _MatchesList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FollowingFeedBloc, FollowingFeedState>(
      builder: (context, state) {
        if (state.loading && state.articles.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.errorMessage != null && state.articles.isEmpty) {
          return _ErrorState(message: state.errorMessage!);
        }
        if (state.articles.isEmpty) {
          return const _NoMatches();
        }

        final prefs = context.watch<PreferencesCubit>().state;
        final sources = context.watch<SourcesCubit>().state;
        final watchlist = context.watch<WatchlistCubit>().state;

        return RefreshIndicator(
          onRefresh: () async {
            context
                .read<FollowingFeedBloc>()
                .add(FollowingFeedRequested(watchlist.following));
            await context
                .read<FollowingFeedBloc>()
                .stream
                .firstWhere((s) => !s.loading);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              BnrSpacing.s4, BnrSpacing.s4, BnrSpacing.s4, BnrSpacing.s12,
            ),
            itemCount: state.articles.length,
            itemBuilder: (context, i) {
              final article = state.articles[i];
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
                  bookmarked:
                      prefs.bookmarkedArticleIds.contains(article.id),
                  onBookmark: () => toggleBookmark(context, article),
                ),
                onBookmark: () => toggleBookmark(context, article),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyFollowState extends StatelessWidget {
  const _EmptyFollowState();

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final touchHint = _isTouchPlatform()
        ? 'Tap the search icon and start typing a rider or team name.'
        : 'Press ⌘K (or click search) and start typing a rider or team name.';

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
              "$touchHint\nYou'll see a “+ Follow” suggestion at the top of the results.",
              textAlign: TextAlign.center,
              style: AppTheme.sans(size: 14, color: ext.fg2),
            ),
          ],
        ),
      ),
    );
  }

  /// Heuristic: Web on a phone-sized layout is treated as touch-only. We
  /// can't reliably detect a physical keyboard from Dart on the web, so we
  /// approximate via `MediaQuery` width — but we do that at call sites
  /// where context is available. Here we bias to "touch" on iOS/Android.
  static bool _isTouchPlatform() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
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

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final watchlist = context.read<WatchlistCubit>().state;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BnrSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined, color: ext.fg2, size: 40),
            const SizedBox(height: BnrSpacing.s4),
            Text(
              "Couldn't load matches",
              style: AppTheme.serif(size: 22, color: ext.fg0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.sans(size: 14, color: ext.fg2),
            ),
            const SizedBox(height: BnrSpacing.s5),
            FilledButton(
              onPressed: () => context
                  .read<FollowingFeedBloc>()
                  .add(FollowingFeedRequested(watchlist.following)),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}

