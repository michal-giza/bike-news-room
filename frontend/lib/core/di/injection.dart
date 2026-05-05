import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/feed/data/datasources/article_snapshot_store.dart';
import '../ads/ad_service.dart';
import '../ads/consent_service.dart';

import '../../features/calendar/data/datasources/calendar_remote_data_source.dart';
import '../../features/calendar/data/repositories/calendar_repository_impl.dart';
import '../../features/calendar/domain/repositories/calendar_repository.dart';
import '../../features/calendar/domain/usecases/get_upcoming_races.dart';
import '../../features/feed/data/datasources/feed_remote_data_source.dart';
import '../../features/feed/data/repositories/feed_repository_impl.dart';
import '../../features/feed/domain/repositories/feed_repository.dart';
import '../../features/feed/domain/usecases/get_article_by_id.dart';
import '../../features/feed/domain/usecases/get_articles.dart';
import '../../features/feed/domain/usecases/get_feed_sources.dart';
import '../../features/preferences/data/preferences_repository.dart';
import '../../features/sources/data/datasources/sources_remote_data_source.dart';
import '../../features/sources/data/repositories/sources_repository_impl.dart';
import '../../features/sources/domain/repositories/sources_repository.dart';
import '../../features/sources/domain/usecases/add_source.dart';
import '../../features/watchlist/data/watchlist_repository.dart';
import '../network/api_client.dart';

final getIt = GetIt.instance;

/// Wire up all singletons. Call from `main` before `runApp`.
///
/// Idempotent on a per-type basis: each `registerSingleton` is guarded
/// with `if (!getIt.isRegistered<T>())`. This makes it safe to:
///   1. Pre-register mocks in integration tests before calling
///      `app.main()`. The real registration is then a no-op for the
///      mocked types and the rest of the wiring proceeds normally.
///   2. Call `app.main()` more than once across a `setUp` chain
///      without `getIt.reset()` (e.g. when individual tests just want
///      to clobber prefs without rebuilding everything).
///
/// `registerLazySingleton` is naturally idempotent in get_it 8 when
/// the factory hasn't been called yet, but we apply the same guard for
/// consistency.
Future<void> configureDependencies() async {
  if (!getIt.isRegistered<ApiClient>()) {
    getIt.registerSingleton<ApiClient>(ApiClient.create());
  }

  if (!getIt.isRegistered<SharedPreferences>()) {
    final sharedPrefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(sharedPrefs);
  }
  final sharedPrefs = getIt<SharedPreferences>();

  if (!getIt.isRegistered<PreferencesRepository>()) {
    getIt.registerSingleton<PreferencesRepository>(
      PreferencesRepository(sharedPrefs),
    );
  }
  if (!getIt.isRegistered<WatchlistRepository>()) {
    getIt.registerSingleton<WatchlistRepository>(
      WatchlistRepository(sharedPrefs),
    );
  }
  if (!getIt.isRegistered<ArticleSnapshotStore>()) {
    getIt.registerSingleton<ArticleSnapshotStore>(
      ArticleSnapshotStore(sharedPrefs),
    );
  }

  // Feed feature
  if (!getIt.isRegistered<FeedRemoteDataSource>()) {
    getIt.registerLazySingleton<FeedRemoteDataSource>(
      () => FeedRemoteDataSourceImpl(getIt<ApiClient>().dio),
    );
  }
  if (!getIt.isRegistered<FeedRepository>()) {
    getIt.registerLazySingleton<FeedRepository>(
      () => FeedRepositoryImpl(getIt<FeedRemoteDataSource>()),
    );
  }
  if (!getIt.isRegistered<GetArticles>()) {
    getIt.registerLazySingleton<GetArticles>(
      () => GetArticles(getIt<FeedRepository>()),
    );
  }
  if (!getIt.isRegistered<GetArticleById>()) {
    getIt.registerLazySingleton<GetArticleById>(
      () => GetArticleById(getIt<FeedRepository>()),
    );
  }
  if (!getIt.isRegistered<GetFeedSources>()) {
    getIt.registerLazySingleton<GetFeedSources>(
      () => GetFeedSources(getIt<FeedRepository>()),
    );
  }

  // Calendar feature
  if (!getIt.isRegistered<CalendarRemoteDataSource>()) {
    getIt.registerLazySingleton<CalendarRemoteDataSource>(
      () => CalendarRemoteDataSourceImpl(getIt<ApiClient>().dio),
    );
  }
  if (!getIt.isRegistered<CalendarRepository>()) {
    getIt.registerLazySingleton<CalendarRepository>(
      () => CalendarRepositoryImpl(getIt<CalendarRemoteDataSource>()),
    );
  }
  if (!getIt.isRegistered<GetUpcomingRaces>()) {
    getIt.registerLazySingleton<GetUpcomingRaces>(
      () => GetUpcomingRaces(getIt<CalendarRepository>()),
    );
  }

  // User-submitted sources feature
  if (!getIt.isRegistered<SourcesRemoteDataSource>()) {
    getIt.registerLazySingleton<SourcesRemoteDataSource>(
      () => SourcesRemoteDataSourceImpl(getIt<ApiClient>().dio),
    );
  }
  if (!getIt.isRegistered<SourcesRepository>()) {
    getIt.registerLazySingleton<SourcesRepository>(
      () => SourcesRepositoryImpl(getIt<SourcesRemoteDataSource>()),
    );
  }
  if (!getIt.isRegistered<AddSource>()) {
    getIt.registerLazySingleton<AddSource>(
      () => AddSource(getIt<SourcesRepository>()),
    );
  }

  // ── Ads + consent ─────────────────────────────────────────────────
  // ALWAYS register against the abstract `IAdService` so tests can
  // override with `NoopAdService` by pre-registering before calling
  // `configureDependencies()`. Concrete `AdMobService` is created here
  // but never directly resolved — the rest of the app reads
  // `getIt<IAdService>()` only.
  if (!getIt.isRegistered<IAdService>()) {
    getIt.registerSingleton<IAdService>(AdMobService());
  }
  if (!getIt.isRegistered<ConsentService>()) {
    getIt.registerSingleton<ConsentService>(ConsentService());
  }
}
