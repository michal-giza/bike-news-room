import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/ads/ad_service.dart';
import 'core/di/injection.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_extensions.dart';
import 'core/theme/tokens.dart';
import 'features/feed/domain/usecases/get_articles.dart';
import 'features/feed/domain/usecases/get_feed_sources.dart';
import 'features/feed/presentation/bloc/feed_bloc.dart';
import 'features/feed/presentation/cubit/sources_cubit.dart';
import 'features/feed/presentation/pages/feed_page.dart';
import 'features/preferences/data/preferences_repository.dart';
import 'features/preferences/domain/entities/user_preferences.dart';
import 'features/preferences/presentation/cubit/preferences_cubit.dart';
import 'features/sources/domain/usecases/add_source.dart';
import 'features/sources/presentation/cubit/sources_cubit.dart';
import 'features/watchlist/data/watchlist_repository.dart';
import 'features/watchlist/presentation/cubit/watchlist_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // ── Step 1 — Flutter bindings + local-only DI. Nothing on the
  //              network or any tracking SDK runs in this step. ──
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  // ── Step 2 — Firebase init + Layer 2/3 disables ──
  // The native Layer 1 flags in Info.plist + AndroidManifest already
  // deactivated Analytics, Crashlytics, and consent-v2 at SDK load.
  // When Firebase is added, uncomment the block below as the belt-and-
  // suspenders Dart-layer disable. Until then, the native flags are
  // sufficient because no Firebase SDK is loaded yet.
  //
  // try {
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //   await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
  //   await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  //   await FirebaseAnalytics.instance.setConsent(
  //     analyticsStorageConsentGranted: false,
  //     adStorageConsentGranted: false,
  //     adUserDataConsentGranted: false,
  //     adPersonalizationSignalsConsentGranted: false,
  //   );
  //   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  //   PlatformDispatcher.instance.onError = (error, stack) {
  //     FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //     return true;
  //   };
  // } catch (e) { debugPrint('Firebase init: $e'); }

  // ── Step 3 — For returning users (onboarding already done, ATT + UMP
  //              already resolved), initialize ads now. First-run users
  //              go through onboarding which runs this same path after
  //              consent is collected. ──
  final prefs = getIt<PreferencesRepository>().load();
  if (prefs.onboardingComplete) {
    await _initPostConsentServices();
  }

  runApp(const BikeNewsRoomApp());
}

/// Layer 4 — initialize every consent-dependent service. NEVER call
/// this before ATT + UMP have been resolved by onboarding (or, for
/// returning users, by a prior session that completed onboarding).
Future<void> _initPostConsentServices() async {
  try {
    await getIt<IAdService>().init();
  } catch (e) {
    if (kDebugMode) debugPrint('Post-consent ad init failed: $e');
  }
  // When Firebase is added, re-enable Analytics + Crashlytics here too:
  //   await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  //   await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  //   final attGranted = !Platform.isIOS || await getIt<ConsentService>().isAttGranted();
  //   await FirebaseAnalytics.instance.setConsent(
  //     analyticsStorageConsentGranted: true,
  //     adStorageConsentGranted: attGranted,
  //     adUserDataConsentGranted: attGranted,
  //     adPersonalizationSignalsConsentGranted: attGranted,
  //   );
}

/// Root app — wires preferences first so theme + persona are reactive,
/// then exposes the FeedBloc to the feed subtree.
class BikeNewsRoomApp extends StatelessWidget {
  const BikeNewsRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PreferencesCubit>(
          create: (_) => PreferencesCubit(getIt<PreferencesRepository>()),
        ),
        BlocProvider<WatchlistCubit>(
          create: (_) => WatchlistCubit(getIt<WatchlistRepository>())..load(),
        ),
        BlocProvider<UserSourcesCubit>(
          create: (_) => UserSourcesCubit(
            addSource: getIt<AddSource>(),
            prefs: getIt<SharedPreferences>(),
          )..load(),
        ),
      ],
      child: BlocBuilder<PreferencesCubit, UserPreferences>(
        builder: (context, prefs) {
          final scale = TypeScale.forPersona(prefs.persona);
          final dark = AppTheme.darkTheme(scale).copyWith(
            extensions: const [BnrThemeExt.dark],
          );
          final light = AppTheme.lightTheme(scale).copyWith(
            extensions: const [BnrThemeExt.light],
          );
          final mode = switch (prefs.themeMode) {
            AppThemeMode.dark => ThemeMode.dark,
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.system => ThemeMode.system,
          };

          return MaterialApp(
            title: 'Bike News Room',
            debugShowCheckedModeBanner: false,
            theme: light,
            darkTheme: dark,
            themeMode: mode,
            // Locale resolution: explicit user choice wins; null = follow
            // the device. The supportedLocales list controls Material's
            // best-fit fallback (e.g. de-AT → de).
            locale: prefs.localeCode == null
                ? null
                : Locale(prefs.localeCode!),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MultiBlocProvider(
              providers: [
                BlocProvider<FeedBloc>(
                  create: (_) => FeedBloc(getArticles: getIt<GetArticles>()),
                ),
                BlocProvider<SourcesCubit>(
                  create: (_) => SourcesCubit(
                    getFeedSources: getIt<GetFeedSources>(),
                  )..load(),
                ),
              ],
              child: const FeedPage(),
            ),
          );
        },
      ),
    );
  }
}
