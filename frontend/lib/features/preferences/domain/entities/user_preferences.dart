import 'package:equatable/equatable.dart';

import '../../../../core/theme/tokens.dart';

enum AppThemeMode { dark, light, system }

enum CardDensity { compact, comfort, large }

const _sentinel = Object();

class UserPreferences extends Equatable {
  final AppThemeMode themeMode;
  final PersonaScale persona;
  final CardDensity density;
  final Set<String> preferredRegions;
  final Set<String> preferredDisciplines;
  final Set<int> hiddenSourceIds;
  final Set<int> bookmarkedArticleIds;
  final bool reducedMotion;
  final bool onboardingComplete;

  /// Newest article id the user has seen on a previous visit. Used by the
  /// home feed to show a "X new since you last looked" pill — gives users
  /// a reason to click through and feels alive between visits.
  /// `null` until the user has loaded the feed at least once.
  final int? lastSeenArticleId;

  /// User's preferred locale code (e.g. `en`, `pl`, `es`). `null` means
  /// "follow the device locale" — the standard Flutter behaviour.
  final String? localeCode;

  /// Master switch for news alerts. Default `false` so the user must
  /// explicitly opt in via Settings — Play's Data Safety form requires
  /// opt-in for any post-install behaviour that touches network or
  /// platform notification surfaces.
  final bool notificationsEnabled;

  /// Discipline ids the user wants to receive notifications for. Empty
  /// when the master switch is off. The NotificationsService reconciles
  /// this set with the live transport (local-only / FCM / etc.) on
  /// every change via the abstract `setTopics` contract.
  final Set<String> notificationDisciplines;

  /// `'instant'` — surface up to 3 fresh articles every workmanager
  /// fire (~every 15 min Android). `'daily'` — collapse the day's
  /// articles into a single digest fired once per day at
  /// [notificationsDigestHour]. Default `'instant'` matches the v1.1
  /// behaviour; users who opt into digest get it via Settings.
  final String notificationsDigestMode;

  /// Local hour (0-23) when the daily digest fires. Only consulted when
  /// `notificationsDigestMode == 'daily'`. Default 8 — most cycling
  /// news lands in the evening EU time, so 8am the next morning makes
  /// sense for the typical "what did I miss overnight" use case.
  final int notificationsDigestHour;

  /// Substrings that suppress an article from the foreground feed AND
  /// the bg notification fetcher. Case-insensitive; matched against
  /// title + description. Stored locally only.
  final Set<String> hiddenKeywords;

  const UserPreferences({
    this.themeMode = AppThemeMode.dark,
    this.persona = PersonaScale.younger,
    this.density = CardDensity.comfort,
    this.preferredRegions = const {},
    this.preferredDisciplines = const {},
    this.hiddenSourceIds = const {},
    this.bookmarkedArticleIds = const {},
    this.reducedMotion = false,
    this.onboardingComplete = false,
    this.lastSeenArticleId,
    this.localeCode,
    this.notificationsEnabled = false,
    this.notificationDisciplines = const {},
    this.notificationsDigestMode = 'instant',
    this.notificationsDigestHour = 8,
    this.hiddenKeywords = const {},
  });

  UserPreferences copyWith({
    AppThemeMode? themeMode,
    PersonaScale? persona,
    CardDensity? density,
    Set<String>? preferredRegions,
    Set<String>? preferredDisciplines,
    Set<int>? hiddenSourceIds,
    Set<int>? bookmarkedArticleIds,
    bool? reducedMotion,
    bool? onboardingComplete,
    Object? lastSeenArticleId = _sentinel,
    Object? localeCode = _sentinel,
    bool? notificationsEnabled,
    Set<String>? notificationDisciplines,
    String? notificationsDigestMode,
    int? notificationsDigestHour,
    Set<String>? hiddenKeywords,
  }) =>
      UserPreferences(
        themeMode: themeMode ?? this.themeMode,
        persona: persona ?? this.persona,
        density: density ?? this.density,
        preferredRegions: preferredRegions ?? this.preferredRegions,
        preferredDisciplines: preferredDisciplines ?? this.preferredDisciplines,
        hiddenSourceIds: hiddenSourceIds ?? this.hiddenSourceIds,
        bookmarkedArticleIds:
            bookmarkedArticleIds ?? this.bookmarkedArticleIds,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        lastSeenArticleId: identical(lastSeenArticleId, _sentinel)
            ? this.lastSeenArticleId
            : lastSeenArticleId as int?,
        localeCode: identical(localeCode, _sentinel)
            ? this.localeCode
            : localeCode as String?,
        notificationsEnabled:
            notificationsEnabled ?? this.notificationsEnabled,
        notificationDisciplines:
            notificationDisciplines ?? this.notificationDisciplines,
        notificationsDigestMode:
            notificationsDigestMode ?? this.notificationsDigestMode,
        notificationsDigestHour:
            notificationsDigestHour ?? this.notificationsDigestHour,
        hiddenKeywords: hiddenKeywords ?? this.hiddenKeywords,
      );

  @override
  List<Object?> get props => [
        themeMode,
        persona,
        density,
        preferredRegions,
        preferredDisciplines,
        hiddenSourceIds,
        bookmarkedArticleIds,
        reducedMotion,
        onboardingComplete,
        lastSeenArticleId,
        localeCode,
        notificationsEnabled,
        notificationDisciplines,
        notificationsDigestMode,
        notificationsDigestHour,
        hiddenKeywords,
      ];
}
