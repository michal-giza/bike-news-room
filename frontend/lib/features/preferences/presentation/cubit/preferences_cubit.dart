import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/notifications_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../data/preferences_repository.dart';
import '../../domain/entities/user_preferences.dart';

/// Single source of truth for user preferences. Persists every mutation.
class PreferencesCubit extends Cubit<UserPreferences> {
  final PreferencesRepository repository;

  /// Optional — when wired, the cubit reconciles topic subscriptions
  /// with the latest [UserPreferences.notificationDisciplines] on
  /// every notifications mutation. Tests typically pass
  /// [NoopNotificationsService] (or nothing) so they don't touch real
  /// platform plugins.
  final INotificationsService? notifications;

  PreferencesCubit(this.repository, {this.notifications})
      : super(repository.load());

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

  /// Master switch for news alerts. Off → bg task is cancelled, every
  /// topic unsubscribed. On → the device subscribes to every discipline
  /// in [state.notificationDisciplines] (or the user's onboarded
  /// disciplines as a sensible default if the set is empty).
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      // If the user has never picked notification disciplines, default
      // to whatever they chose during onboarding so they don't have to
      // reconfigure the same thing twice.
      final defaults = state.notificationDisciplines.isEmpty
          ? state.preferredDisciplines
          : state.notificationDisciplines;
      await _update(state.copyWith(
        notificationsEnabled: true,
        notificationDisciplines: defaults,
      ));
      await notifications?.init(consentGranted: true);
      await notifications?.setTopics(
        defaults.map(topicForDiscipline).toSet(),
      );
    } else {
      await _update(state.copyWith(
        notificationsEnabled: false,
        notificationDisciplines: const {},
      ));
      await notifications?.revokeConsent();
    }
  }

  /// Toggle a single discipline subscription. The master switch must be
  /// on; if off this method is a no-op (UI guards this anyway).
  Future<void> toggleNotificationDiscipline(String discipline) async {
    if (!state.notificationsEnabled) return;
    final next = Set<String>.from(state.notificationDisciplines);
    if (next.contains(discipline)) {
      next.remove(discipline);
    } else {
      next.add(discipline);
    }
    await _update(state.copyWith(notificationDisciplines: next));
    await notifications?.setTopics(next.map(topicForDiscipline).toSet());
  }

  /// Switch between `'instant'` (default — every workmanager fire,
  /// up to 3 articles) and `'daily'` (one summary at the user-set
  /// hour). The bg isolate reads the mode on every fire, so changes
  /// take effect immediately without re-scheduling.
  Future<void> setNotificationsDigestMode(String mode) =>
      _update(state.copyWith(notificationsDigestMode: mode));

  /// 0–23, local time. Only used in `'daily'` digest mode.
  Future<void> setNotificationsDigestHour(int hour) =>
      _update(state.copyWith(
        notificationsDigestHour: hour.clamp(0, 23),
      ));

  /// Add a substring to the hide-keyword list. Articles whose title or
  /// description contain it (case-insensitive) get suppressed in the
  /// foreground feed AND the bg notification fetcher.
  Future<void> addHiddenKeyword(String keyword) async {
    final clean = keyword.trim();
    if (clean.isEmpty) return;
    final next = {...state.hiddenKeywords, clean};
    await _update(state.copyWith(hiddenKeywords: next));
  }

  Future<void> removeHiddenKeyword(String keyword) async {
    final next = Set<String>.from(state.hiddenKeywords)..remove(keyword);
    await _update(state.copyWith(hiddenKeywords: next));
  }
}
