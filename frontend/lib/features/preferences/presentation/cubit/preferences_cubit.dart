import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/tokens.dart';
import '../../data/preferences_repository.dart';
import '../../domain/entities/user_preferences.dart';

/// Single source of truth for user preferences. Persists every mutation.
class PreferencesCubit extends Cubit<UserPreferences> {
  final PreferencesRepository repository;

  PreferencesCubit(this.repository) : super(repository.load());

  Future<void> _update(UserPreferences updated) async {
    emit(updated);
    await repository.save(updated);
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setPersona(PersonaScale persona) =>
      _update(state.copyWith(persona: persona));

  Future<void> setDensity(CardDensity density) =>
      _update(state.copyWith(density: density));

  Future<void> setReducedMotion(bool enabled) =>
      _update(state.copyWith(reducedMotion: enabled));

  /// Set the user's preferred locale. Pass `null` to fall back to the
  /// device locale (the default Flutter behaviour).
  Future<void> setLocale(String? code) =>
      _update(state.copyWith(localeCode: code));

  /// Mark the highest article id the user has now seen. Only advances —
  /// never moves backwards, so refreshing an older feed page doesn't reset
  /// the "what's new" baseline.
  Future<void> markLastSeenArticleId(int articleId) {
    final current = state.lastSeenArticleId ?? 0;
    if (articleId <= current) return Future.value();
    return _update(state.copyWith(lastSeenArticleId: articleId));
  }

  /// Soft cap so a long-running app doesn't grow shared_preferences without
  /// bound. We keep insertion order via a [LinkedHashSet] so the oldest
  /// bookmark is the one we drop.
  static const _bookmarkCap = 200;

  Future<void> toggleBookmark(int articleId) {
    // Preserve insertion order: re-add at the tail when toggling back on.
    final ids = <int>{...state.bookmarkedArticleIds};
    if (ids.contains(articleId)) {
      ids.remove(articleId);
    } else {
      ids.add(articleId);
      while (ids.length > _bookmarkCap) {
        // Drop the oldest bookmark (first item in iteration order).
        ids.remove(ids.first);
      }
    }
    return _update(state.copyWith(bookmarkedArticleIds: ids));
  }

  Future<void> hideSource(int feedId) {
    final ids = Set<int>.from(state.hiddenSourceIds)..add(feedId);
    return _update(state.copyWith(hiddenSourceIds: ids));
  }

  Future<void> unhideSource(int feedId) {
    final ids = Set<int>.from(state.hiddenSourceIds)..remove(feedId);
    return _update(state.copyWith(hiddenSourceIds: ids));
  }

  /// Reset the onboarding gate so the user is taken back through the
  /// region/discipline/density picker. Bookmarks and watchlist stay intact —
  /// only the gate flag flips. Called from the Settings page.
  Future<void> restartOnboarding() => _update(
        UserPreferences(
          themeMode: state.themeMode,
          persona: state.persona,
          density: state.density,
          preferredRegions: const {},
          preferredDisciplines: const {},
          hiddenSourceIds: state.hiddenSourceIds,
          bookmarkedArticleIds: state.bookmarkedArticleIds,
          reducedMotion: state.reducedMotion,
          onboardingComplete: false,
          lastSeenArticleId: state.lastSeenArticleId,
        ),
      );

  Future<void> completeOnboarding({
    required Set<String> regions,
    required Set<String> disciplines,
    required CardDensity density,
  }) =>
      _update(state.copyWith(
        preferredRegions: regions,
        preferredDisciplines: disciplines,
        density: density,
        onboardingComplete: true,
      ));
}
