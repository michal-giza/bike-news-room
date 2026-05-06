import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/notifications_service.dart';
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
      key: const ValueKey('settingsPageScaffold'),
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
              _SectionHeader(l.settingsNotifications),
              SwitchListTile(
                key: const ValueKey('settingsNotificationsToggle'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l.settingsNotificationsTitle,
                  style: AppTheme.sans(size: 15, color: ext.fg0),
                ),
                subtitle: Text(
                  l.settingsNotificationsDesc,
                  style: AppTheme.sans(size: 13, color: ext.fg2),
                ),
                value: prefs.notificationsEnabled,
                activeThumbColor: BnrColors.accent,
                onChanged: cubit.setNotificationsEnabled,
              ),
              if (prefs.notificationsEnabled) ...[
                const SizedBox(height: BnrSpacing.s2),
                Text(
                  l.settingsNotificationsTopicsLabel,
                  style: AppTheme.mono(
                    size: 11,
                    color: ext.fg2,
                    letterSpacing: 0.06,
                  ),
                ),
                const SizedBox(height: BnrSpacing.s2),
                ...kSupportedNotificationDisciplines.map(
                  (id) => _DisciplineToggle(
                    discipline: id,
                    enabled: prefs.notificationDisciplines.contains(id),
                    onTap: () =>
                        cubit.toggleNotificationDiscipline(id),
                  ),
                ),
                const SizedBox(height: BnrSpacing.s4),
                _DigestModePicker(
                  mode: prefs.notificationsDigestMode,
                  hour: prefs.notificationsDigestHour,
                  onModeChanged: cubit.setNotificationsDigestMode,
                  onHourChanged: cubit.setNotificationsDigestHour,
                ),
              ],
              const SizedBox(height: BnrSpacing.s4),
              _HiddenKeywordsEditor(
                keywords: prefs.hiddenKeywords,
                onAdd: cubit.addHiddenKeyword,
                onRemove: cubit.removeHiddenKeyword,
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

/// Tap-to-toggle row for a single notification topic. The colour swatch
/// reuses the discipline-color palette from [BnrColors] so the row reads
/// like a chip in the feed sidebar — same visual language across screens.
class _DisciplineToggle extends StatelessWidget {
  final String discipline;
  final bool enabled;
  final VoidCallback onTap;

  const _DisciplineToggle({
    required this.discipline,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final color = BnrColors.disciplineColor(discipline);
    final label = AppLocalizations.of(context);
    final displayLabel = switch (discipline) {
      'road' => label.disciplineRoad,
      'mtb' => label.disciplineMtb,
      'gravel' => label.disciplineGravel,
      'track' => label.disciplineTrack,
      'cx' => label.disciplineCx,
      'bmx' => label.disciplineBmx,
      _ => discipline,
    };
    return InkWell(
      key: ValueKey('settingsNotifDiscipline_$discipline'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: BnrSpacing.s3),
            Expanded(
              child: Text(
                displayLabel,
                style: AppTheme.sans(size: 14, color: ext.fg0),
              ),
            ),
            Icon(
              enabled ? Icons.check_circle : Icons.radio_button_unchecked,
              color: enabled ? color : ext.fg3,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Digest-vs-instant mode picker. The cycling-news cadence (~5 stories
/// at peak race weekends) means the default 15-min "instant" mode can
/// feel spammy; daily-digest collapses everything into one summary at
/// a user-set hour.
class _DigestModePicker extends StatelessWidget {
  final String mode;
  final int hour;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<int> onHourChanged;

  const _DigestModePicker({
    required this.mode,
    required this.hour,
    required this.onModeChanged,
    required this.onHourChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.settingsNotificationsDeliveryLabel,
          style: AppTheme.mono(
            size: 11,
            color: ext.fg2,
            letterSpacing: 0.06,
          ),
        ),
        const SizedBox(height: BnrSpacing.s2),
        Row(
          children: [
            Expanded(
              child: _SegmentedTile(
                label: l.settingsNotificationsDeliveryInstant,
                selected: mode == 'instant',
                onTap: () => onModeChanged('instant'),
              ),
            ),
            const SizedBox(width: BnrSpacing.s2),
            Expanded(
              child: _SegmentedTile(
                label: l.settingsNotificationsDeliveryDaily,
                selected: mode == 'daily',
                onTap: () => onModeChanged('daily'),
              ),
            ),
          ],
        ),
        if (mode == 'daily') ...[
          const SizedBox(height: BnrSpacing.s2),
          // 0–23 picker via a horizontally-scrollable row of hour
          // chips. Compact and locale-independent (numbers + a colon).
          SizedBox(
            height: 38,
            child: ListView.separated(
              key: const ValueKey('settingsDigestHourPicker'),
              scrollDirection: Axis.horizontal,
              itemCount: 24,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: BnrSpacing.s1),
              itemBuilder: (_, h) {
                final selected = h == hour;
                return GestureDetector(
                  onTap: () => onHourChanged(h),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? BnrColors.accent : ext.bg1,
                      border: Border.all(
                        color: selected ? BnrColors.accent : ext.line,
                      ),
                      borderRadius: BorderRadius.circular(BnrRadius.r2),
                    ),
                    child: Text(
                      '${h.toString().padLeft(2, '0')}:00',
                      style: AppTheme.mono(
                        size: 12,
                        color: selected
                            ? BnrColors.accentInk
                            : ext.fg1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SegmentedTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentedTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BnrSpacing.s3,
          vertical: BnrSpacing.s3,
        ),
        decoration: BoxDecoration(
          color: selected ? BnrColors.accent : ext.bg1,
          border: Border.all(color: selected ? BnrColors.accent : ext.line),
          borderRadius: BorderRadius.circular(BnrRadius.r2),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.sans(
              size: 13,
              weight: FontWeight.w600,
              color: selected ? BnrColors.accentInk : ext.fg1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Local-only keyword blocklist. Substrings are matched case-
/// insensitively against title + description on both the foreground
/// feed and the bg notification fetcher. Pairs with a mini-input that
/// adds on submit + a row of dismissible chips.
class _HiddenKeywordsEditor extends StatefulWidget {
  final Set<String> keywords;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _HiddenKeywordsEditor({
    required this.keywords,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_HiddenKeywordsEditor> createState() =>
      _HiddenKeywordsEditorState();
}

class _HiddenKeywordsEditorState extends State<_HiddenKeywordsEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return;
    widget.onAdd(clean);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.settingsHiddenKeywordsLabel,
          style: AppTheme.mono(
            size: 11,
            color: ext.fg2,
            letterSpacing: 0.06,
          ),
        ),
        const SizedBox(height: BnrSpacing.s1),
        Text(
          l.settingsHiddenKeywordsDesc,
          style: AppTheme.sans(size: 12, color: ext.fg2),
        ),
        const SizedBox(height: BnrSpacing.s2),
        TextField(
          key: const ValueKey('settingsHideKeywordInput'),
          controller: _controller,
          textInputAction: TextInputAction.done,
          onSubmitted: _submit,
          decoration: InputDecoration(
            hintText: l.settingsHiddenKeywordsHint,
            hintStyle: AppTheme.sans(size: 13, color: ext.fg3),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BnrRadius.r2),
              borderSide: BorderSide(color: ext.line),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: () => _submit(_controller.text),
            ),
          ),
        ),
        if (widget.keywords.isNotEmpty) ...[
          const SizedBox(height: BnrSpacing.s2),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.keywords
                .map(
                  (k) => InputChip(
                    key: ValueKey('settingsHideKw_$k'),
                    label: Text(
                      k,
                      style: AppTheme.sans(size: 12, color: ext.fg0),
                    ),
                    onDeleted: () => widget.onRemove(k),
                    backgroundColor: ext.bg1,
                    side: BorderSide(color: ext.line),
                    deleteIcon: const Icon(Icons.close, size: 14),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
