import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../preferences/domain/entities/user_preferences.dart';
import '../../../preferences/presentation/cubit/preferences_cubit.dart';
import '../cubit/sources_cubit.dart';

/// "Suggested sources" chip list shown above the URL input in the
/// `AddSourceModal`.
///
/// Why this exists: the resolution waterfall in
/// `add_user_source_use_case.rs` covers most CMS-based sites, but real-
/// world cycling publishers ship a long tail of edge cases (Cloudflare-
/// fronted Italian sites, sitemap-only Japanese ones, JSON-feed-only
/// Belgian outlets…). Hand-curating the top sites per locale guarantees
/// the most-popular targets work even when auto-discovery would fail.
///
/// Tap a chip → URL + name + region + discipline + language pre-fill.
/// User can still tweak before submitting.
class SuggestedSources extends StatefulWidget {
  /// Called when the user picks a chip — the modal uses this to pre-fill
  /// its form fields.
  final void Function(CatalogueEntry entry) onPick;
  const SuggestedSources({super.key, required this.onPick});

  @override
  State<SuggestedSources> createState() => _SuggestedSourcesState();
}

class _SuggestedSourcesState extends State<SuggestedSources> {
  Future<List<CatalogueEntry>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCatalogue();
  }

  Future<List<CatalogueEntry>> _loadCatalogue() async {
    final raw = await rootBundle
        .loadString('assets/catalogue/cycling_sources.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final list = (json['sources'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CatalogueEntry.fromJson)
        .toList();
    return list;
  }

  /// Rank entries: matches against the user's locale + onboarded regions
  /// first, then the rest. Cap at 8 visible chips so the modal stays
  /// compact on phones.
  List<CatalogueEntry> _rank(
    List<CatalogueEntry> all,
    UserPreferences prefs,
  ) {
    final localeCode = (prefs.localeCode ?? '').toLowerCase();
    final preferredRegions = prefs.preferredRegions;
    final preferredDisciplines = prefs.preferredDisciplines;

    int score(CatalogueEntry e) {
      var s = 0;
      if (localeCode.isNotEmpty &&
          e.language.toLowerCase() == localeCode) {
        s += 4;
      }
      if (preferredRegions.contains(e.region)) s += 2;
      if (preferredDisciplines.contains(e.discipline) ||
          e.discipline == 'all') {
        s += 1;
      }
      return s;
    }

    final sorted = [...all]..sort((a, b) => score(b).compareTo(score(a)));
    return sorted.take(12).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final prefs = context.watch<PreferencesCubit>().state;
    final knownUrls = context
        .watch<UserSourcesCubit>()
        .state
        .mySources
        .map((s) => s.url)
        .toSet();

    return FutureBuilder<List<CatalogueEntry>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final entries = _rank(snap.data!, prefs)
            .where((e) => !knownUrls.contains(e.url))
            .toList();
        if (entries.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: BnrSpacing.s2),
              child: Text(
                'SUGGESTED · TAP TO PRE-FILL',
                style: AppTheme.mono(
                  size: 10,
                  color: ext.fg2,
                  letterSpacing: 0.16,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in entries)
                  InkWell(
                    onTap: () => widget.onPick(e),
                    borderRadius: BorderRadius.circular(BnrRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: ext.bg2,
                        border: Border.all(color: ext.lineSoft),
                        borderRadius: BorderRadius.circular(BnrRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: BnrColors.disciplineColor(e.discipline),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            e.name,
                            style: AppTheme.sans(
                              size: 12,
                              color: ext.fg1,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: BnrSpacing.s4),
          ],
        );
      },
    );
  }
}

class CatalogueEntry {
  final String name;
  final String url;
  final String homepage;
  final String region;
  final String discipline;
  final String language;

  const CatalogueEntry({
    required this.name,
    required this.url,
    required this.homepage,
    required this.region,
    required this.discipline,
    required this.language,
  });

  factory CatalogueEntry.fromJson(Map<String, dynamic> j) => CatalogueEntry(
        name: j['name'] as String? ?? '',
        url: j['url'] as String? ?? '',
        homepage: j['homepage'] as String? ?? '',
        region: j['region'] as String? ?? 'world',
        discipline: j['discipline'] as String? ?? 'all',
        language: j['language'] as String? ?? 'en',
      );
}

