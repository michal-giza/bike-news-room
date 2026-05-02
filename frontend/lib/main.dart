import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const BikeNewsRoomApp());
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
