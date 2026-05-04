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
Future<void> configureDependencies() async {
  // Singletons
  final apiClient = ApiClient.create();
  getIt.registerSingleton<ApiClient>(apiClient);

  final sharedPrefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPrefs);
  getIt.registerSingleton<PreferencesRepository>(
    PreferencesRepository(sharedPrefs),
  );
  getIt.registerSingleton<WatchlistRepository>(
    WatchlistRepository(sharedPrefs),
  );
  getIt.registerSingleton<ArticleSnapshotStore>(
    ArticleSnapshotStore(sharedPrefs),
  );

  // Feed feature
  getIt.registerLazySingleton<FeedRemoteDataSource>(
    () => FeedRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<FeedRepository>(
    () => FeedRepositoryImpl(getIt<FeedRemoteDataSource>()),
  );
  getIt.registerLazySingleton<GetArticles>(
    () => GetArticles(getIt<FeedRepository>()),
  );
  getIt.registerLazySingleton<GetArticleById>(
    () => GetArticleById(getIt<FeedRepository>()),
  );
  getIt.registerLazySingleton<GetFeedSources>(
    () => GetFeedSources(getIt<FeedRepository>()),
  );

  // Calendar feature
  getIt.registerLazySingleton<CalendarRemoteDataSource>(
    () => CalendarRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(getIt<CalendarRemoteDataSource>()),
  );
  getIt.registerLazySingleton<GetUpcomingRaces>(
    () => GetUpcomingRaces(getIt<CalendarRepository>()),
  );

  // User-submitted sources feature
  getIt.registerLazySingleton<SourcesRemoteDataSource>(
    () => SourcesRemoteDataSourceImpl(getIt<ApiClient>().dio),
  );
  getIt.registerLazySingleton<SourcesRepository>(
    () => SourcesRepositoryImpl(getIt<SourcesRemoteDataSource>()),
  );
  getIt.registerLazySingleton<AddSource>(
    () => AddSource(getIt<SourcesRepository>()),
  );

  // ── Ads + consent ─────────────────────────────────────────────────
  // ALWAYS register against the abstract `IAdService` so tests can
  // override with `NoopAdService`. Concrete `AdMobService` is created
  // here but never directly resolved — the rest of the app reads
  // `getIt<IAdService>()` only.
  getIt.registerSingleton<IAdService>(AdMobService());
  getIt.registerSingleton<ConsentService>(ConsentService());
}
