import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Static long-form pages: About, Privacy Policy, Terms of Service.
/// All text comes from the ARB files in `lib/l10n/`. Last-updated date
/// is fixed in source — bump it when you ship a material change.
class InfoPage extends StatelessWidget {
  /// Which tab to open by default. The footer links pass this so a "Privacy"
  /// link doesn't dump the user on the About tab.
  final InfoTab initial;
  const InfoPage({super.key, this.initial = InfoTab.about});

  /// Bumped manually when the user-visible content of any of the three tabs
  /// changes in a material way. Translators see the same date — that's fine,
  /// the date is metadata, not a translatable string.
  static const _lastUpdated = '2026-05-02';

  static Future<void> show(BuildContext context, {InfoTab tab = InfoTab.about}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => InfoPage(initial: tab)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      initialIndex: initial.index,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.appName),
          bottom: TabBar(
            tabs: [
              Tab(text: l.aboutTitle.toUpperCase()),
              Tab(text: l.settingsPrivacy.toUpperCase()),
              Tab(text: l.settingsTerms.toUpperCase()),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Doc(
              title: l.aboutTitle,
              lastUpdated: _lastUpdated,
              sections: [
                _Section(l.aboutH1, l.aboutB1),
                _Section(l.aboutH2, l.aboutB2),
                _Section(l.aboutH3, l.aboutB3),
                _Section(l.aboutH4, l.aboutB4),
              ],
            ),
            _Doc(
              title: l.privacyTitle,
              lastUpdated: _lastUpdated,
              sections: [
                _Section(l.privacyH1, l.privacyB1),
                _Section(l.privacyH2, l.privacyB2),
                _Section(l.privacyH3, l.privacyB3),
                _Section(l.privacyH4, l.privacyB4),
                _Section(l.privacyH5, l.privacyB5),
              ],
            ),
            _Doc(
              title: l.termsTitle,
              lastUpdated: _lastUpdated,
              sections: [
                _Section(l.termsH1, l.termsB1),
                _Section(l.termsH2, l.termsB2),
                _Section(l.termsH3, l.termsB3),
                _Section(l.termsH4, l.termsB4),
                _Section(l.termsH5, l.termsB5),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum InfoTab { about, privacy, terms }

class _Doc extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<_Section> sections;

  const _Doc({
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        BnrSpacing.s6,
        BnrSpacing.s6,
        BnrSpacing.s6,
        BnrSpacing.s12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.serif(
                  size: 32,
                  weight: FontWeight.w600,
                  letterSpacing: -0.025,
                  color: ext.fg0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.infoLastUpdated(lastUpdated),
                style: AppTheme.mono(
                  size: 11,
                  color: ext.fg2,
                  letterSpacing: 0.14,
                ),
              ),
              const SizedBox(height: BnrSpacing.s6),
              for (final s in sections) ...[
                Text(
                  s.heading,
                  style: AppTheme.serif(
                    size: 20,
                    weight: FontWeight.w600,
                    color: ext.fg0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.body,
                  style: AppTheme.sans(
                    size: 15,
                    color: ext.fg1,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: BnrSpacing.s5),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Section {
  final String heading;
  final String body;
  const _Section(this.heading, this.body);
}
