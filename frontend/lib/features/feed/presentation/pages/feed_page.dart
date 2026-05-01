import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../preferences/domain/entities/user_preferences.dart';
import '../../../preferences/presentation/cubit/preferences_cubit.dart';
import '../../../preferences/presentation/pages/onboarding_page.dart';
import '../bloc/feed_bloc.dart';
import '../cubit/sources_cubit.dart';
import '../widgets/active_filter_chips.dart';
import '../widgets/article_card.dart';
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
    // Trigger initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedBloc>().add(const FeedRequested());
    });
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Couldn't load more: ${state.errorMessage}"),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () =>
                    context.read<FeedBloc>().add(const FeedLoadMoreRequested()),
              ),
            ),
          );
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: TopBar(onSearchTap: _openSearch),
          drawer: showBottomNav ? _buildDrawer(context) : null,
        body: Row(
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
                  const Center(child: CircularProgressIndicator()),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeedHeader(
          total: state.total,
          newestAt: state.articles.isEmpty ? null : state.articles.first.publishedAt,
        ),
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
                  context.read<PreferencesCubit>().toggleBookmark(article.id),
            ),
          );
        }

        final feedIndex = index - breakingOffset;
        if (feedIndex >= feedArticles.length) {
          return _Footer(
              loading: state.status == FeedStatus.loadingMore,
              hasMore: state.hasMore);
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
                context.read<PreferencesCubit>().toggleBookmark(article.id),
          ),
          onBookmark: () =>
              context.read<PreferencesCubit>().toggleBookmark(article.id),
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

  String _agoLabel(DateTime? t) {
    if (t == null) return 'UPDATED · ';
    final mins = DateTime.now().difference(t).inMinutes;
    if (mins < 1) return 'UPDATED JUST NOW · ';
    if (mins < 60) return 'UPDATED ${mins}M AGO · ';
    final h = mins ~/ 60;
    if (h < 24) return 'UPDATED ${h}H AGO · ';
    return 'UPDATED ${h ~/ 24}D AGO · ';
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Today's wire",
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
              '${_agoLabel(newestAt)}$total STORIES',
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
                hasMore ? 'SCROLL FOR MORE' : '— END OF FEED —',
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

class _ErrorState extends StatelessWidget {
  final String? message;
  const _ErrorState({this.message});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BnrSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, color: ext.fg2, size: 40),
            const SizedBox(height: BnrSpacing.s4),
            Text(
              "Couldn't reach the news room",
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
              child: const Text('Retry'),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BnrSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, color: ext.fg2, size: 40),
            const SizedBox(height: BnrSpacing.s4),
            Text(
              'No articles match these filters',
              style: AppTheme.serif(size: 24, color: ext.fg0),
            ),
            const SizedBox(height: 8),
            Text(
              'Try broadening or clearing your filters.',
              style: AppTheme.sans(size: 14, color: ext.fg2),
            ),
          ],
        ),
      ),
    );
  }
}
