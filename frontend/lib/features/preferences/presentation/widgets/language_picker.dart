import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/user_preferences.dart';
import '../cubit/preferences_cubit.dart';

/// Language dropdown for the Settings page. Each option label is shown
/// in the language it represents (endonym) so a user landing in the
/// wrong language can still find their own. The "System" option clears
/// the user override and falls back to the device locale.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  /// Endonyms — each language's own name for itself. Keep this list in
  /// sync with the ARB files in `lib/l10n/`.
  static const _languages = <String, String>{
    'en': 'English',
    'pl': 'Polski',
    'es': 'Español',
    'fr': 'Français',
    'it': 'Italiano',
    'de': 'Deutsch',
    'nl': 'Nederlands',
    'pt': 'Português',
    'ja': '日本語',
  };

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final l = AppLocalizations.of(context);
    return BlocBuilder<PreferencesCubit, UserPreferences>(
      buildWhen: (a, b) => a.localeCode != b.localeCode,
      builder: (context, prefs) {
        final current = prefs.localeCode;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.settingsLanguage,
              style: AppTheme.sans(size: 15, color: ext.fg0),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: current,
              isDense: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: ext.bg1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BnrRadius.r2),
                  borderSide: BorderSide(color: ext.lineSoft),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BnrRadius.r2),
                  borderSide: BorderSide(color: ext.lineSoft),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: BnrSpacing.s4,
                  vertical: BnrSpacing.s2,
                ),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l.settingsLanguageSystem),
                ),
                ..._languages.entries.map(
                  (e) => DropdownMenuItem<String?>(
                    value: e.key,
                    child: Text(e.value),
                  ),
                ),
              ],
              onChanged: (code) =>
                  context.read<PreferencesCubit>().setLocale(code),
            ),
          ],
        );
      },
    );
  }
}
