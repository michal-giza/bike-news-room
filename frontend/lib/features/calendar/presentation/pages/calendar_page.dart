import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/url/safe_url.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/calendar_bloc.dart';
import '../widgets/race_card.dart';

/// Race calendar page — upcoming races grouped by month.
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  static const _disciplines = [
    ('road', 'Road'),
    ('mtb', 'MTB'),
    ('gravel', 'Gravel'),
    ('cx', 'CX'),
    ('track', 'Track'),
  ];

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;

    return Scaffold(
      backgroundColor: ext.bg0,
      appBar: AppBar(
        backgroundColor: ext.bg0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ext.fg0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Race calendar',
          style: AppTheme.serif(
            size: 22,
            weight: FontWeight.w600,
            letterSpacing: -0.02,
            color: ext.fg0,
          ),
        ),
      ),
      body: BlocBuilder<CalendarBloc, CalendarState>(
        builder: (context, state) {
          return Column(
            children: [
              _filterRow(context, state),
              Expanded(child: _body(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _filterRow(BuildContext context, CalendarState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BnrSpacing.s4, BnrSpacing.s2, BnrSpacing.s4, BnrSpacing.s4,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(context, label: AppLocalizations.of(context).calendarFilterAll, selected: state.discipline == null,
                onTap: () => context.read<CalendarBloc>()
                    .add(const CalendarDisciplineChanged(null))),
            for (final d in _disciplines)
              _filterChip(context,
                  label: d.$2.toUpperCase(),
                  selected: state.discipline == d.$1,
                  disciplineId: d.$1,
                  onTap: () {
                    final next = state.discipline == d.$1 ? null : d.$1;
                    context.read<CalendarBloc>()
                        .add(CalendarDisciplineChanged(next));
                  }),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(BuildContext context,
      {required String label,
      required bool selected,
      String? disciplineId,
      required VoidCallback onTap}) {
    final ext = context.bnr;
    final accent = disciplineId != null
        ? BnrColors.disciplineColor(disciplineId)
        : BnrColors.accent;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BnrRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? ext.bg3 : ext.bg1,
            border: Border.all(color: selected ? accent : ext.line),
            borderRadius: BorderRadius.circular(BnrRadius.pill),
          ),
          child: Text(
            label,
            style: AppTheme.mono(
              size: 11,
              color: selected ? ext.fg0 : ext.fg2,
              weight: FontWeight.w600,
              letterSpacing: 0.10,
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, CalendarState state) {
    if (state.status == CalendarStatus.loading && state.races.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == CalendarStatus.error && state.races.isEmpty) {
      return _errorState(context, state.errorMessage);
    }
    if (state.races.isEmpty) {
      return _emptyState(context);
    }

    // Group races by year-month.
    final grouped = <String, List<dynamic>>{};
    for (final race in state.races) {
      final key = '${race.startDate.year}-${race.startDate.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(race);
    }
    final keys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        BnrSpacing.s4, 0, BnrSpacing.s4, BnrSpacing.s12,
      ),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final key = keys[i];
        final races = grouped[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _monthHeader(context, key),
            for (final race in races)
              RaceCard(
                race: race,
                onTap: race.url == null ? null : () => _open(race.url),
              ),
            const SizedBox(height: BnrSpacing.s4),
          ],
        );
      },
    );
  }

  Widget _monthHeader(BuildContext context, String key) {
    final parts = key.split('-');
    final year = parts[0];
    final monthIdx = int.parse(parts[1]) - 1;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final ext = context.bnr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, BnrSpacing.s4, 0, BnrSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            months[monthIdx],
            style: AppTheme.serif(
              size: 22,
              weight: FontWeight.w600,
              letterSpacing: -0.02,
              color: ext.fg0,
              height: 1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            year,
            style: AppTheme.mono(
              size: 11,
              color: ext.fg2,
              letterSpacing: 0.12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final ext = context.bnr;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BnrSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, color: ext.fg2, size: 40),
            const SizedBox(height: BnrSpacing.s4),
            Text(AppLocalizations.of(context).calendarEmpty,
                style: AppTheme.serif(size: 24, color: ext.fg0)),
          ],
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, String? msg) {
    final ext = context.bnr;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BnrSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, color: ext.fg2, size: 40),
            const SizedBox(height: BnrSpacing.s4),
            Text(AppLocalizations.of(context).calendarError,
                style: AppTheme.serif(size: 24, color: ext.fg0)),
            const SizedBox(height: 8),
            if (msg != null)
              Text(msg,
                  textAlign: TextAlign.center,
                  style: AppTheme.sans(size: 14, color: ext.fg2)),
            const SizedBox(height: BnrSpacing.s5),
            FilledButton(
              onPressed: () =>
                  context.read<CalendarBloc>().add(const CalendarRequested()),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = safeUri(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
