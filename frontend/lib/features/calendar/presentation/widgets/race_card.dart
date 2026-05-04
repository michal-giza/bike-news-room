import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/race.dart';

/// Single row in the race calendar — date strip + name + meta.
class RaceCard extends StatefulWidget {
  final Race race;
  final VoidCallback? onTap;
  const RaceCard({super.key, required this.race, this.onTap});

  @override
  State<RaceCard> createState() => _RaceCardState();
}

class _RaceCardState extends State<RaceCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final disc = BnrColors.disciplineColor(widget.race.discipline);
    final now = DateTime.now();
    final daysUntil = widget.race.daysUntil(now);
    final ongoing = widget.race.isOngoing(now);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: BnrMotion.m2,
          margin: const EdgeInsets.only(bottom: BnrSpacing.s2),
          padding: const EdgeInsets.symmetric(
            horizontal: BnrSpacing.s4,
            vertical: BnrSpacing.s3,
          ),
          decoration: BoxDecoration(
            color: _hover ? ext.bg2 : ext.bg1,
            border: Border.all(color: _hover ? ext.line : ext.lineSoft),
            borderRadius: BorderRadius.circular(BnrRadius.r2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _dateStrip(context, ongoing: ongoing, daysUntil: daysUntil, disc: disc),
              const SizedBox(width: BnrSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.race.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.serif(
                        size: 17,
                        weight: FontWeight.w600,
                        letterSpacing: -0.012,
                        color: ext.fg0,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _metaRow(context, disc: disc, ongoing: ongoing),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateStrip(
    BuildContext context, {
    required bool ongoing,
    required int daysUntil,
    required Color disc,
  }) {
    final ext = context.bnr;
    final d = widget.race.startDate.toLocal();
    final monthShort = const [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ][d.month - 1];

    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: ongoing
            ? BnrColors.live.withValues(alpha: 0.12)
            : ext.bg2,
        border: Border.all(
          color: ongoing ? BnrColors.live : disc.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(BnrRadius.r1),
      ),
      child: Column(
        children: [
          Text(
            monthShort,
            style: AppTheme.mono(
              size: 10,
              color: ongoing ? BnrColors.live : ext.fg2,
              weight: FontWeight.w600,
              letterSpacing: 0.12,
            ),
          ),
          Text(
            '${d.day}',
            style: AppTheme.serif(
              size: 24,
              weight: FontWeight.w700,
              color: ongoing ? BnrColors.live : ext.fg0,
              height: 1.0,
              letterSpacing: -0.02,
            ),
          ),
          Text(
            ongoing
                ? AppLocalizations.of(context).raceCardNow
                : (daysUntil <= 0
                    ? AppLocalizations.of(context).raceCardToday
                    : (daysUntil == 1
                        ? AppLocalizations.of(context).raceCardTomorrow
                        : AppLocalizations.of(context).raceCardDays(daysUntil))),
            style: AppTheme.mono(
              size: 9,
              color: ongoing ? BnrColors.live : ext.fg3,
              letterSpacing: 0.08,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(BuildContext context, {required Color disc, required bool ongoing}) {
    final ext = context.bnr;
    final children = <Widget>[
      Text(
        widget.race.discipline.toUpperCase(),
        style: AppTheme.mono(
          size: 11,
          color: disc,
          weight: FontWeight.w600,
          letterSpacing: 0.08,
        ),
      ),
    ];
    if (widget.race.country != null) {
      children.add(_dot(ext.fg3));
      children.add(Text(
        widget.race.country!,
        style: AppTheme.mono(size: 11, color: ext.fg2, letterSpacing: 0.06),
      ));
    }
    if (widget.race.category != null) {
      children.add(_dot(ext.fg3));
      children.add(Text(
        widget.race.category!,
        style: AppTheme.mono(size: 11, color: ext.fg2, letterSpacing: 0.06),
      ));
    }
    if (ongoing) {
      children.add(_dot(ext.fg3));
      children.add(Text(
        'ONGOING',
        style: AppTheme.mono(
          size: 11,
          color: BnrColors.live,
          weight: FontWeight.w600,
          letterSpacing: 0.12,
        ),
      ));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  Widget _dot(Color c) => Container(
        width: 2, height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}
