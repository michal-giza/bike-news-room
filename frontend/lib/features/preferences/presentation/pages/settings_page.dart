import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../info/presentation/pages/info_page.dart';
import '../widgets/language_picker.dart';
import '../cubit/preferences_cubit.dart';
import '../../domain/entities/user_preferences.dart';

/// Single-screen settings surface — everything a returning user might want
/// to tweak after onboarding: theme, density, motion, and exits to the
/// privacy/terms pages and a one-click bookmark export.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<PreferencesCubit>(),
          child: const SettingsPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: BlocBuilder<PreferencesCubit, UserPreferences>(
        builder: (context, prefs) {
          final cubit = context.read<PreferencesCubit>();
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: BnrSpacing.s5,
              vertical: BnrSpacing.s4,
            ),
            children: [
              _SectionHeader(l.settingsAppearance),
              _OptionGroup<AppThemeMode>(
                label: l.settingsTheme,
                value: prefs.themeMode,
                options: {
                  AppThemeMode.dark: l.settingsThemeDark,
                  AppThemeMode.light: l.settingsThemeLight,
                  AppThemeMode.system: l.settingsThemeSystem,
                },
                onChanged: cubit.setThemeMode,
              ),
              const SizedBox(height: BnrSpacing.s4),
              _OptionGroup<CardDensity>(
                label: l.settingsCardDensity,
                value: prefs.density,
                options: {
                  CardDensity.compact: l.settingsDensityCompact,
                  CardDensity.comfort: l.settingsDensityComfort,
                  CardDensity.large: l.settingsDensityLarge,
                },
                onChanged: cubit.setDensity,
              ),
              const SizedBox(height: BnrSpacing.s4),
              const LanguagePicker(),
              const SizedBox(height: BnrSpacing.s4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l.settingsReducedMotion,
                  style: AppTheme.sans(size: 15, color: ext.fg0),
                ),
                subtitle: Text(
                  l.settingsReducedMotionDesc,
                  style: AppTheme.sans(size: 13, color: ext.fg2),
                ),
                value: prefs.reducedMotion,
                activeThumbColor: BnrColors.accent,
                onChanged: cubit.setReducedMotion,
              ),
              const Divider(height: BnrSpacing.s8),
              _SectionHeader(l.settingsYourData),
              _ActionTile(
                icon: Icons.bookmark_outline,
                label: l.settingsExportBookmarks,
                subtitle: l.settingsExportBookmarksDesc(
                    prefs.bookmarkedArticleIds.length),
                onTap: () => _exportBookmarks(context, prefs),
              ),
              _ActionTile(
                icon: Icons.refresh,
                label: l.settingsRedoOnboarding,
                subtitle: l.settingsRedoOnboardingDesc,
                onTap: () => _redoOnboarding(context, cubit),
              ),
              const Divider(height: BnrSpacing.s8),
              _SectionHeader(l.settingsAbout),
              _ActionTile(
                icon: Icons.info_outline,
                label: l.settingsAboutApp,
                onTap: () => InfoPage.show(context, tab: InfoTab.about),
              ),
              _ActionTile(
                icon: Icons.shield_outlined,
                label: l.settingsPrivacy,
                onTap: () => InfoPage.show(context, tab: InfoTab.privacy),
              ),
              _ActionTile(
                icon: Icons.gavel_outlined,
                label: l.settingsTerms,
                onTap: () => InfoPage.show(context, tab: InfoTab.terms),
              ),
              const SizedBox(height: BnrSpacing.s6),
              Center(
                child: Text(
                  l.settingsVersionLine('1.0'),
                  style: AppTheme.mono(
                    size: 10,
                    color: ext.fg2,
                    letterSpacing: 0.18,
                  ),
                ),
              ),
              const SizedBox(height: BnrSpacing.s8),
            ],
          );
        },
      ),
    );
  }

  void _exportBookmarks(BuildContext context, UserPreferences prefs) {
    final ids = prefs.bookmarkedArticleIds.toList()..sort();
    final payload = jsonEncode({
      'kind': 'bike-news-room.bookmarks',
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'article_ids': ids,
    });
    Clipboard.setData(ClipboardData(text: payload));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).settingsBookmarksCopied(ids.length),
        ),
      ),
    );
  }

  Future<void> _redoOnboarding(
    BuildContext context,
    PreferencesCubit cubit,
  ) async {
    final l = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsRedoOnboardingDialogTitle),
        content: Text(l.settingsRedoOnboardingDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.redo),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await cubit.restartOnboarding();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return Padding(
      padding: const EdgeInsets.only(bottom: BnrSpacing.s3),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.mono(
          size: 11,
          color: ext.fg2,
          letterSpacing: 0.18,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OptionGroup<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _OptionGroup({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.sans(size: 15, color: ext.fg0)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries
              .map((e) => ChoiceChip(
                    label: Text(e.value),
                    selected: e.key == value,
                    onSelected: (s) {
                      if (s) onChanged(e.key);
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: ext.fg1),
      title: Text(label, style: AppTheme.sans(size: 15, color: ext.fg0)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTheme.sans(size: 13, color: ext.fg2),
            ),
      trailing: Icon(Icons.chevron_right, color: ext.fg2),
      onTap: onTap,
    );
  }
}
