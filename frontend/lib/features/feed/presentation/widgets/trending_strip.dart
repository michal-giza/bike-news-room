import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../cubit/trending_cubit.dart';

/// Horizontally-scrolling chip strip showing what's spiking in the
/// last 24 hours. Tap a chip → seed the feed search with that term.
///
/// The strip self-hides when the trending list is empty (no chips =
/// no rendered chrome) so users with a quiet news day don't see a
/// blank row above the feed.
class TrendingStrip extends StatelessWidget {
  /// Called when the user taps a chip. Passed the raw term string;
  /// the parent typically dispatches `FeedFilterChanged(search: term)`.
  final ValueChanged<String> onTermTap;

  const TrendingStrip({super.key, required this.onTermTap});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final l = AppLocalizations.of(context);
    return BlocBuilder<TrendingCubit, TrendingState>(
      buildWhen: (a, b) => a.terms != b.terms,
      builder: (context, state) {
        if (state.terms.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BnrSpacing.s4,
            vertical: BnrSpacing.s2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: BnrSpacing.s1),
                child: Text(
                  l.trendingHeader,
                  style: AppTheme.mono(
                    size: 11,
                    color: ext.fg2,
                    letterSpacing: 0.06,
                  ),
                ),
              ),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  key: const ValueKey('trendingStripList'),
                  scrollDirection: Axis.horizontal,
                  itemCount: state.terms.length,
                  separatorBuilder: (_, __) => const SizedBox(
                    width: BnrSpacing.s2,
                  ),
                  itemBuilder: (context, i) {
                    final term = state.terms[i];
                    return _TrendingChip(
                      term: term.term,
                      lift: term.score,
                      onTap: () => onTermTap(term.term),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrendingChip extends StatelessWidget {
  final String term;
  final double lift;
  final VoidCallback onTap;

  const _TrendingChip({
    required this.term,
    required this.lift,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    // Highlight high-lift chips with the accent — visual hierarchy so
    // users can spot what's REALLY trending vs. mildly elevated.
    final isHot = lift >= 3.0;
    return Material(
      color: isHot
          ? BnrColors.accent.withValues(alpha: 0.18)
          : ext.bg1,
      shape: StadiumBorder(
        side: BorderSide(color: isHot ? BnrColors.accent : ext.line),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BnrSpacing.s3,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHot) ...[
                Icon(Icons.local_fire_department, size: 12, color: BnrColors.accent),
                const SizedBox(width: 4),
              ],
              Text(
                term.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  letterSpacing: 0.08,
                  color: isHot ? BnrColors.accentInk : ext.fg1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
