import 'package:equatable/equatable.dart';

import '../../../../core/theme/tokens.dart';

enum AppThemeMode { dark, light, system }

enum CardDensity { compact, comfort, large }

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
      ];
}
