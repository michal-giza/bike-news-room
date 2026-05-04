import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../features/preferences/presentation/cubit/preferences_cubit.dart';
import '../data/datasources/article_snapshot_store.dart';
import '../data/models/article_model.dart';
import '../domain/entities/article.dart';

/// Single entry-point every "bookmark" tap goes through. Handles two
/// concerns at once:
///
///   1. Toggle the boolean in `PreferencesCubit` so the bookmark icon
///      lights up immediately on the next rebuild.
///   2. Persist (or remove) the full article payload via
///      `ArticleSnapshotStore`, so when the backend's retention sweep
///      eventually deletes the source row, the bookmarks page can still
///      render the article from the local snapshot.
///
/// Live separately from `PreferencesCubit` so the preferences feature
/// stays decoupled from the feed-domain `Article` type. The call site
/// already has the full Article in hand on every tap, so passing it
/// through is free.
Future<void> toggleBookmark(BuildContext context, Article article) async {
  final cubit = context.read<PreferencesCubit>();
  final wasBookmarked = cubit.state.bookmarkedArticleIds.contains(article.id);
  await cubit.toggleBookmark(article.id);
  final store = getIt<ArticleSnapshotStore>();
  if (wasBookmarked) {
    // Removing — only drop the snapshot if no other reason to keep it.
    // For v1 we simply drop on un-bookmark; race-link snapshots will
    // re-save on the next FollowingFeedBloc cycle when Layer 1 fan-out
    // matches them again.
    await store.remove(article.id);
  } else {
    // Adding — persist the full article. We rehydrate via the same
    // ArticleModel.fromJson the API uses, so the cast is safe whether
    // the in-memory `Article` was originally a model or a domain entity.
    await store.save(_asModel(article));
  }
}

/// Convert a domain `Article` to the `ArticleModel` shape the snapshot
/// store serialises. Most call sites already pass an ArticleModel
/// instance via inheritance — this is a defensive copy for the rare
/// case where someone constructs a plain Article in code.
ArticleModel _asModel(Article a) {
  if (a is ArticleModel) return a;
  return ArticleModel(
    id: a.id,
    feedId: a.feedId,
    title: a.title,
    description: a.description,
    url: a.url,
    imageUrl: a.imageUrl,
    publishedAt: a.publishedAt,
    fetchedAt: a.fetchedAt,
    category: a.category,
    region: a.region,
    discipline: a.discipline,
    language: a.language,
    clusterCount: a.clusterCount,
  );
}
