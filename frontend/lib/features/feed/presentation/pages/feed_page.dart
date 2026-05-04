import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../preferences/domain/entities/user_preferences.dart';
import '../../../preferences/presentation/cubit/preferences_cubit.dart';
import '../../../preferences/presentation/pages/onboarding_page.dart';
import '../bloc/feed_bloc.dart';
import '../cubit/sources_cubit.dart';
import '../widgets/active_filter_chips.dart';
import '../widgets/article_card.dart';
import '../widgets/article_card_skeleton.dart';
import '../widgets/digest_signup.dart';
import '../widgets/live_ticker_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/breaking_panel.dart';
import '../widgets/filter_drawer.dart';
import '../widgets/search_overlay.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import '../../../calendar/domain/usecases/get_upcoming_races.dart';
import '../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../../watchlist/presentation/cubit/watchlist_cubit.dart';
import '../../../watchlist/presentation/pages/following_page.dart';
import '../../../../core/di/injection.dart';
import '../../../preferences/presentation/pages/settings_page.dart';
import '../bookmark_action.dart';
import 'article_detail_modal.dart';
import 'bookmarks_page.dart';

/// Three-pane shell: sidebar / feed / (preview rail collapsed for now).
/// Adapts to mobile by hiding the sidebar at < 900px.
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  BnrTab _activeTab = BnrTab.feed;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedBloc>().add(const FeedRequested());
      _maybeOpenDeepLinkedArticle();
    });
  }

  /// On the web, when a user lands at `?article=<id>` (typically from a
  /// shared link that hit our backend's /article/:id and 302'd to the SPA),
  /// open the article detail modal automatically once the feed has loaded.
  ///
  /// We watch the FeedBloc state instead of fetching the article up-front
  /// because (a) the article will likely be in the first page of the feed
  /// anyway, (b) if not, we can still show its modal once the user scrolls
  /// it into view, and (c) we avoid the extra round-trip on every cold
  /// load. The `_deepLinkHandled` flag prevents repeat-opens.
  bool _deepLinkHandled = false;
  void _maybeOpenDeepLinkedArticle() {
    final raw = Uri.base.queryParameters['article'];
    final id = int.tryParse(raw ?? '');
    if (id == null || _deepLinkHandled) return;
    _deepLinkHandled = true;
    _waitForArticleAndOpen(id);
  }

  Future<void> _waitForArticleAndOpen(int articleId) async {
    // Poll the FeedBloc state until the article shows up — at most ~6s.
    for (var i = 0; i < 12; i++) {
      if (!mounted) return;
      final state = context.read<FeedBloc>().state;
      final match = state.articles
          .where((a) => a.id == articleId)
          .firstOrNull;
      if (match != null) {
        if (!mounted) return;
        final prefs = context.read<PreferencesCubit>().state;
        final sources = context.read<SourcesCubit>().state;
        ArticleDetailModal.show(
          context,
          article: match,
          sourceName: sources.displayFor(match.feedId),
          bookmarked: prefs.bookmarkedArticleIds.contains(match.id),
          onBookmark: () =>
              toggleBookmark(context, match),
        );
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    // Article not in the first page — silently give up. Acceptable degraded
    // behaviour: user lands on the home feed, which is fine.
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 600) {
      context.read<FeedBloc>().add(const FeedLoadMoreRequested());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openSearch() {
    SearchOverlay.show(
      context,
      onSubmit: (query) =>
          context.read<FeedBloc>().add(FeedFilterChanged(search: query)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesCubit>().state;
    // First-launch onboarding takes over the whole shell.
    if (!prefs.onboardingComplete) {
      return OnboardingPage(onComplete: () => setState(() {}));
    }

    final width = MediaQuery.of(context).size.width;
    final showSidebar = width >= 900;
    final showBottomNav = width < 900;

    return CmdKShortcut(
      onTrigger: _openSearch,
      child: BlocListener<FeedBloc, FeedState>(
        // Surface paginated load-more errors as a transient snackbar — the
        // existing articles stay visible (we don't want to wipe the list on
        // a network blip), but we acknowledge the failure to the user.
        listenWhen: (a, b) =>
            a.errorMessage != b.errorMessage &&
            b.errorMessage != null &&
            b.articles.isNotEmpty,
        listener: (context, state) {
          final t = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.couldntLoadMore(state.errorMessage ?? '')),
              action: SnackBarAction(
                label: t.retry,
                onPressed: () =>
                    context.read<FeedBloc>().add(const FeedLoadMoreRequested()),
              ),
            ),
          );
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: TopBar(
            onSearchTap: _openSearch,
            onSettingsTap: () => SettingsPage.show(context),
          ),
          drawer: showBottomNav ? _buildDrawer(context) : null,
        body: Column(
          children: [
            const LiveTickerBar(),
            Expanded(
              child: Row(
                children: [
                  if (showSidebar)
              SizedBox(
                width: 280,
                child: BlocBuilder<FeedBloc, FeedState>(
                  buildWhen: (a, b) => a.filter != b.filter,
                  builder: (context, state) => Sidebar(
                    filter: state.filter,
                    onDisciplineChanged: (v) => context.read<FeedBloc>().add(
                          FeedFilterChanged(
                            discipline: v,
                            clearDiscipline: v == null,
                          ),
                        ),
                    onRegionChanged: (v) => context.read<FeedBloc>().add(
                          FeedFilterChanged(
                            region: v,
                            clearRegion: v == null,
                          ),
                        ),
                    onCategoryChanged: (v) => context.read<FeedBloc>().add(
                          FeedFilterChanged(
                            category: v,
                            clearCategory: v == null,
                          ),
                        ),
                    onClearAll: () => context
                        .read<FeedBloc>()
                        .add(const FeedFiltersCleared()),
                  ),
                ),
              ),
                  Expanded(child: _feedColumn(context)),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: showBottomNav
            ? BottomNav(
                active: _activeTab,
                onTap: (tab) {
                  switch (tab) {
                    case BnrTab.feed:
                      _scrollController.animateTo(
                        0,
                        duration: BnrMotion.m3,
                        curve: BnrMotion.ease,
                      );
                    case BnrTab.search:
                      _openSearch();
                    case BnrTab.bookmarks:
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(
                                value: context.read<FeedBloc>(),
                              ),
                              BlocProvider.value(
                                value: context.read<PreferencesCubit>(),
                              ),
                              BlocProvider.value(
                                value: context.read<SourcesCubit>(),
                              ),
                            ],
                            child: const BookmarksPage(),
                          ),
                        ),
                      );
                    case BnrTab.calendar:
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider<CalendarBloc>(
                            create: (_) => CalendarBloc(
                              getUpcoming: getIt<GetUpcomingRaces>(),
                            )..add(const CalendarRequested()),
                            child: const CalendarPage(),
                          ),
                        ),
                      );
                    case BnrTab.following:
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(value: context.read<FeedBloc>()),
                              BlocProvider.value(
                                  value: context.read<PreferencesCubit>()),
                              BlocProvider.value(
                                  value: context.read<SourcesCubit>()),
                              BlocProvider.value(
                                  value: context.read<WatchlistCubit>()),
                            ],
                            child: const FollowingPage(),
                          ),
                        ),
                      );
                  }
                  setState(() => _activeTab = tab);
                },
              )
            : null,
        floatingActionButton: showBottomNav
            ? FloatingActionButton(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                backgroundColor: BnrColors.accent,
                foregroundColor: BnrColors.accentInk,
                child: const Icon(Icons.tune),
              )
            : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: BlocBuilder<FeedBloc, FeedState>(
        buildWhen: (a, b) => a.filter != b.filter,
        builder: (context, state) => FilterDrawer(
          filter: state.filter,
          onDisciplineChanged: (v) {
            context.read<FeedBloc>().add(
                  FeedFilterChanged(discipline: v, clearDiscipline: v == null),
                );
            Navigator.of(context).pop();
          },
          onRegionChanged: (v) {
            context.read<FeedBloc>().add(
                  FeedFilterChanged(region: v, clearRegion: v == null),
                );
            Navigator.of(context).pop();
          },
          onCategoryChanged: (v) {
            context.read<FeedBloc>().add(
                  FeedFilterChanged(category: v, clearCategory: v == null),
                );
            Navigator.of(context).pop();
          },
          onClearAll: () {
            context.read<FeedBloc>().add(const FeedFiltersCleared());
            Navigator.of(context).pop();
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _feedColumn(BuildContext context) {
    return BlocBuilder<FeedBloc, FeedState>(
      builder: (context, state) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                BnrSpacing.s8,
                BnrSpacing.s6,
                BnrSpacing.s8,
                BnrSpacing.s16,
              ),
              child: switch (state.status) {
                FeedStatus.initial || FeedStatus.loading
                    when state.articles.isEmpty =>
                  _SkeletonList(
                    density: context.watch<PreferencesCubit>().state.density,
                  ),
                FeedStatus.error when state.articles.isEmpty =>
                  _ErrorState(message: state.errorMessage),
                _ when state.articles.isEmpty => _EmptyState(),
                _ => _content(context, state),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, FeedState state) {
    final prefs = context.watch<PreferencesCubit>().state;

    final newestId =
        state.articles.isEmpty ? null : state.articles.first.id;
    final lastSeen = prefs.lastSeenArticleId;
    // Count articles newer than the user's last visit. Only meaningful when
    // we have a baseline; on first launch we silently set the baseline below.
    final newSinceCount = (lastSeen == null)
        ? 0
        : state.articles.where((a) => a.id > lastSeen).length;

    // Establish the baseline silently the very first time the feed loads,
    // and quietly advance it once the user has acknowledged "what's new"
    // (we treat the pill tap as the acknowledgment — see _NewSincePill).
    if (lastSeen == null && newestId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<PreferencesCubit>().markLastSeenArticleId(newestId);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeedHeader(
          total: state.total,
          newestAt: state.articles.isEmpty ? null : state.articles.first.publishedAt,
        ),
        if (newSinceCount > 0 && newestId != null) ...[
          const SizedBox(height: BnrSpacing.s4),
          _NewSincePill(
            label: AppLocalizations.of(context)
                .newSinceLastVisit(newSinceCount),
            onTap: () {
              context
                  .read<PreferencesCubit>()
                  .markLastSeenArticleId(newestId);
              _scrollController.animateTo(
                0,
                duration: BnrMotion.m3,
                curve: BnrMotion.ease,
              );
            },
          ),
        ],
        const SizedBox(height: BnrSpacing.s6),
        ActiveFilterChips(
          filter: state.filter,
          density: prefs.density,
          onDensityChanged: (d) =>
              context.read<PreferencesCubit>().setDensity(d),
          onClearAll: () =>
              context.read<FeedBloc>().add(const FeedFiltersCleared()),
          onRemove: (kind) {
            final bloc = context.read<FeedBloc>();
            switch (kind) {
              case 'region':
                bloc.add(const FeedFilterChanged(clearRegion: true));
              case 'discipline':
                bloc.add(const FeedFilterChanged(clearDiscipline: true));
              case 'category':
                bloc.add(const FeedFilterChanged(clearCategory: true));
              case 'search':
                bloc.add(const FeedFilterChanged(clearSearch: true));
            }
          },
        ),
        Expanded(child: _list(context, state, prefs)),
      ],
    );
  }

  Widget _list(BuildContext context, FeedState state, UserPreferences prefs) {
    final sources = context.watch<SourcesCubit>().state;
    final watchlist = context.watch<WatchlistCubit>().state;
    final breaking = BreakingPanel.selectBreaking(state.articles);
    final breakingIds = breaking.map((a) => a.id).toSet();
    // Hide the breaking-panel articles from the regular feed list to avoid duplication.
    final feedArticles =
        state.articles.where((a) => !breakingIds.contains(a.id)).toList();
    final hasBreaking = breaking.isNotEmpty;
    final breakingOffset = hasBreaking ? 1 : 0;
    final itemCount = feedArticles.length + breakingOffset + 1; // +1 footer

    return ListView.builder(
      controller: _scrollController,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (hasBreaking && index == 0) {
          return BreakingPanel(
            articles: breaking,
            sourceNameOf: (id) => sources.displayFor(id),
            onTapArticle: (article) => ArticleDetailModal.show(
              context,
              article: article,
              sourceName: sources.displayFor(article.feedId),
              bookmarked: prefs.bookmarkedArticleIds.contains(article.id),
              onBookmark: () =>
                  toggleBookmark(context, article),
            ),
          );
        }

        final feedIndex = index - breakingOffset;
        if (feedIndex >= feedArticles.length) {
          return Column(
            children: [
              // Show the digest signup once we've reached the end of the
              // feed (i.e. there's no more pagination). Showing it mid-load
              // would feel premature.
              if (!state.hasMore) const DigestSignup(),
              _Footer(
                loading: state.status == FeedStatus.loadingMore,
                hasMore: state.hasMore,
              ),
            ],
          );
        }

        final article = feedArticles[feedIndex];
        final sourceName = sources.displayFor(article.feedId);
        final watchedMatches = watchlist
            .matches(title: article.title, description: article.description)
            .map((e) => e.name)
            .toList();
        return ArticleCard(
          article: article,
          density: prefs.density,
          bookmarked: prefs.bookmarkedArticleIds.contains(article.id),
          watchedNames: watchedMatches,
          onTap: () => ArticleDetailModal.show(
            context,
            article: article,
            sourceName: sourceName,
            bookmarked: prefs.bookmarkedArticleIds.contains(article.id),
            onBookmark: () =>
                toggleBookmark(context, article),
          ),
          onBookmark: () =>
              toggleBookmark(context, article),
          sourceName: sourceName,
        );
      },
    );
  }
}

class _FeedHeader extends StatelessWidget {
  /// Newest article timestamp from the current feed; we treat that as "last
  /// updated" because we don't have a separate `/api/health` poll wired in.
  final DateTime? newestAt;
  final int total;
  const _FeedHeader({required this.total, this.newestAt});

  String _agoLabel(BuildContext context, DateTime? t) {
    final l = AppLocalizations.of(context);
    if (t == null) return '';
    final mins = DateTime.now().difference(t).inMinutes;
    if (mins < 1) return l.updatedJustNow;
    if (mins < 60) return l.updatedMinutesAgo(mins);
    final h = mins ~/ 60;
    if (h < 24) return l.updatedHoursAgo(h);
    return l.updatedDaysAgo(h ~/ 24);
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final l = AppLocalizations.of(context);
    final agoLabel = _agoLabel(context, newestAt);
    final separator = agoLabel.isEmpty ? '' : ' · ';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l.todaysWire,
          style: AppTheme.serif(
            size: 32,
            weight: FontWeight.w600,
            letterSpacing: -0.025,
            color: ext.fg0,
            height: 1,
          ),
        ),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: BnrColors.live,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$agoLabel$separator${l.storiesCount(total)}',
              style: AppTheme.mono(
                size: 11,
                color: ext.fg2,
                letterSpacing: 0.12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final bool loading;
  final bool hasMore;
  const _Footer({required this.loading, required this.hasMore});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BnrSpacing.s8),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                hasMore
                    ? AppLocalizations.of(context).scrollForMore
                    : AppLocalizations.of(context).endOfFeed,
                style: AppTheme.mono(
                  size: 11,
                  color: ext.fg2,
                  letterSpacing: 0.18,
                ),
              ),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  final CardDensity density;
  const _SkeletonList({required this.density});

  @override
  Widget build(BuildContext context) {
    // 6 cards is enough to fill a typical viewport; the real list will swap
    // in well before scroll engages.
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => ArticleCardSkeleton(density: density),
    );
  }
}

class _NewSincePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NewSincePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: BnrColors.accent,
        borderRadius: BorderRadius.circular(BnrRadius.r3),
        child: InkWell(
          borderRadius: BorderRadius.circular(BnrRadius.r3),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BnrSpacing.s4,
              vertical: BnrSpacing.s2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: BnrColors.accentInk,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTheme.mono(
                    size: 11,
                    color: BnrColors.accentInk,
                    letterSpacing: 0.14,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_upward,
                    size: 13, color: BnrColors.accentInk),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String? message;
  const _ErrorState({this.message});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BnrSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, color: ext.fg2, size: 40),
            const SizedBox(height: BnrSpacing.s4),
            Text(
              l.couldNotReachNewsRoom,
              style: AppTheme.serif(size: 24, color: ext.fg0),
            ),
            const SizedBox(height: 8),
            if (message != null)
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTheme.sans(size: 14, color: ext.fg2),
              ),
            const SizedBox(height: BnrSpacing.s5),
            FilledButton(
              onPressed: () =>
                  context.read<FeedBloc>().add(const FeedRefreshRequested()),
              child: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BnrSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, color: ext.fg2, size: 40),
            const SizedBox(height: BnrSpacing.s4),
            Text(
              l.noArticlesMatch,
              style: AppTheme.serif(size: 24, color: ext.fg0),
            ),
            const SizedBox(height: 8),
            Text(
              l.tryBroadeningFilters,
              style: AppTheme.sans(size: 14, color: ext.fg2),
            ),
          ],
        ),
      ),
    );
  }
}
