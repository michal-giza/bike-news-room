import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/tokens.dart';
import '../domain/entities/user_preferences.dart';

/// SharedPreferences-backed store. No backend involvement.
class PreferencesRepository {
  final SharedPreferences prefs;
  PreferencesRepository(this.prefs);

  static const _kTheme = 'pref.theme';
  static const _kPersona = 'pref.persona';
  static const _kDensity = 'pref.density';
  static const _kRegions = 'pref.regions';
  static const _kDisciplines = 'pref.disciplines';
  static const _kHiddenSources = 'pref.hiddenSources';
  static const _kBookmarks = 'pref.bookmarks';
  static const _kReducedMotion = 'pref.reducedMotion';
  static const _kOnboarding = 'pref.onboardingComplete';
  static const _kLastSeen = 'pref.lastSeenArticleId';
  static const _kLocale = 'pref.localeCode';
  static const _kNotifEnabled = 'pref.notifications.enabled';
  static const _kNotifDisciplines = 'pref.notifications.disciplines';

  UserPreferences load() {
    return UserPreferences(
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_kTheme),
        orElse: () => AppThemeMode.dark,
      ),
      persona: PersonaScale.values.firstWhere(
        (p) => p.name == prefs.getString(_kPersona),
        orElse: () => PersonaScale.younger,
      ),
      density: CardDensity.values.firstWhere(
        (d) => d.name == prefs.getString(_kDensity),
        orElse: () => CardDensity.comfort,
      ),
      preferredRegions: (prefs.getStringList(_kRegions) ?? const []).toSet(),
      preferredDisciplines:
          (prefs.getStringList(_kDisciplines) ?? const []).toSet(),
      hiddenSourceIds: (prefs.getStringList(_kHiddenSources) ?? const [])
          .map(int.tryParse)
          .whereType<int>()
          .toSet(),
      bookmarkedArticleIds: (prefs.getStringList(_kBookmarks) ?? const [])
          .map(int.tryParse)
          .whereType<int>()
          .toSet(),
      reducedMotion: prefs.getBool(_kReducedMotion) ?? false,
      onboardingComplete: prefs.getBool(_kOnboarding) ?? false,
      lastSeenArticleId: prefs.getInt(_kLastSeen),
      localeCode: prefs.getString(_kLocale),
      notificationsEnabled: prefs.getBool(_kNotifEnabled) ?? false,
      notificationDisciplines:
          (prefs.getStringList(_kNotifDisciplines) ?? const []).toSet(),
    );
  }

  Future<void> save(UserPreferences p) async {
    await prefs.setString(_kTheme, p.themeMode.name);
    await prefs.setString(_kPersona, p.persona.name);
    await prefs.setString(_kDensity, p.density.name);
    await prefs.setStringList(_kRegions, p.preferredRegions.toList());
    await prefs.setStringList(_kDisciplines, p.preferredDisciplines.toList());
    await prefs.setStringList(
        _kHiddenSources, p.hiddenSourceIds.map((e) => '$e').toList());
    await prefs.setStringList(
        _kBookmarks, p.bookmarkedArticleIds.map((e) => '$e').toList());
    await prefs.setBool(_kReducedMotion, p.reducedMotion);
    await prefs.setBool(_kOnboarding, p.onboardingComplete);
    final lastSeen = p.lastSeenArticleId;
    if (lastSeen == null) {
      await prefs.remove(_kLastSeen);
    } else {
      await prefs.setInt(_kLastSeen, lastSeen);
    }
    final loc = p.localeCode;
    if (loc == null) {
      await prefs.remove(_kLocale);
    } else {
      await prefs.setString(_kLocale, loc);
    }
    await prefs.setBool(_kNotifEnabled, p.notificationsEnabled);
    await prefs.setStringList(
      _kNotifDisciplines,
      p.notificationDisciplines.toList(),
    );
  }
}
