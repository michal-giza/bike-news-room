import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/user_preferences.dart';
import '../cubit/preferences_cubit.dart';

/// 3-step onboarding: regions → disciplines → density.
/// Persists to PreferencesCubit and pops on completion.
class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _step = 0;
  final Set<String> _regions = {};
  final Set<String> _disciplines = {};
  CardDensity _density = CardDensity.comfort;

  static const _allRegions = [
    ('world', 'World', '🌍', 'Everything, everywhere.'),
    ('eu', 'EU', '🇪🇺', 'European racing focus.'),
    ('poland', 'Poland', '🇵🇱', 'PL races + riders.'),
    ('spain', 'Spain', '🇪🇸', 'ES races + riders.'),
  ];

  static const _allDisciplines = [
    ('road', 'Road', 'GC, classics, sprints.'),
    ('mtb', 'MTB', 'XC, DH, enduro, freeride.'),
    ('gravel', 'Gravel', 'Long-format off-tarmac.'),
    ('track', 'Track', 'Velodrome racing.'),
    ('cx', 'Cyclocross', 'Mud, sand, barriers.'),
    ('bmx', 'BMX', 'Race + freestyle.'),
  ];

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return Scaffold(
      backgroundColor: ext.bg0,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BnrSpacing.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stepHeader(ext),
                const SizedBox(height: BnrSpacing.s5),
                _stepBody(ext),
                const SizedBox(height: BnrSpacing.s8),
                _stepFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepHeader(BnrThemeExt ext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'STEP ${_step + 1} / 3',
              style: AppTheme.mono(
                size: 11,
                color: ext.fg2,
                letterSpacing: 0.18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _stepNames[_step],
              style: AppTheme.mono(
                size: 11,
                color: ext.fg1,
                letterSpacing: 0.18,
              ),
            ),
          ],
        ),
        const SizedBox(height: BnrSpacing.s4),
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                height: 2,
                decoration: BoxDecoration(
                  color: i <= _step ? BnrColors.accent : ext.bg3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  static const _stepNames = ['REGIONS', 'DISCIPLINES', 'DENSITY'];

  Widget _stepBody(BnrThemeExt ext) {
    return switch (_step) {
      0 => _regionsStep(ext),
      1 => _disciplinesStep(ext),
      _ => _densityStep(ext),
    };
  }

  Widget _regionsStep(BnrThemeExt ext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where should the wire focus?',
          style: AppTheme.serif(
            size: 48,
            weight: FontWeight.w600,
            letterSpacing: -0.03,
            color: ext.fg0,
            height: 1.05,
          ),
        ),
        const SizedBox(height: BnrSpacing.s3),
        Text(
          "You'll always see global racing. Pick which regions get extra weight.",
          style: AppTheme.sans(size: 17, color: ext.fg1, height: 1.5),
        ),
        const SizedBox(height: BnrSpacing.s8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final r in _allRegions)
              _OptCard(
                title: r.$2,
                sub: r.$4,
                emoji: r.$3,
                selected: _regions.contains(r.$1),
                onTap: () => setState(() {
                  if (_regions.contains(r.$1)) {
                    _regions.remove(r.$1);
                  } else {
                    _regions.add(r.$1);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _disciplinesStep(BnrThemeExt ext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which bikes pull you in?',
          style: AppTheme.serif(
            size: 48,
            weight: FontWeight.w600,
            letterSpacing: -0.03,
            color: ext.fg0,
            height: 1.05,
          ),
        ),
        const SizedBox(height: BnrSpacing.s3),
        Text(
          'Pick all that apply — we use this to colour-tag and prioritise stories.',
          style: AppTheme.sans(size: 17, color: ext.fg1, height: 1.5),
        ),
        const SizedBox(height: BnrSpacing.s8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final d in _allDisciplines)
              _OptCard(
                title: d.$2,
                sub: d.$3,
                disciplineId: d.$1,
                selected: _disciplines.contains(d.$1),
                onTap: () => setState(() {
                  if (_disciplines.contains(d.$1)) {
                    _disciplines.remove(d.$1);
                  } else {
                    _disciplines.add(d.$1);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _densityStep(BnrThemeExt ext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How dense should the feed be?',
          style: AppTheme.serif(
            size: 48,
            weight: FontWeight.w600,
            letterSpacing: -0.03,
            color: ext.fg0,
            height: 1.05,
          ),
        ),
        const SizedBox(height: BnrSpacing.s3),
        Text(
          'You can change this any time from the feed.',
          style: AppTheme.sans(size: 17, color: ext.fg1, height: 1.5),
        ),
        const SizedBox(height: BnrSpacing.s8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _OptCard(
              title: 'Compact',
              sub: 'Maximum stories. List rows, no images.',
              selected: _density == CardDensity.compact,
              onTap: () => setState(() => _density = CardDensity.compact),
            ),
            _OptCard(
              title: 'Comfort',
              sub: 'Balanced. Image + body.',
              selected: _density == CardDensity.comfort,
              onTap: () => setState(() => _density = CardDensity.comfort),
            ),
            _OptCard(
              title: 'Large',
              sub: 'Editorial hero cards.',
              selected: _density == CardDensity.large,
              onTap: () => setState(() => _density = CardDensity.large),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepFooter() {
    final ext = context.bnr;
    final canAdvance = _step != 0 || _regions.isNotEmpty;
    return Row(
      children: [
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step--),
            child: Text(
              'Back',
              style: AppTheme.sans(
                size: 13,
                color: ext.fg2,
              ),
            ),
          ),
        TextButton(
          onPressed: _skip,
          child: Text(
            'Skip',
            style: AppTheme.sans(size: 13, color: ext.fg2),
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: canAdvance ? _advance : null,
          style: FilledButton.styleFrom(
            backgroundColor: BnrColors.accent,
            foregroundColor: BnrColors.accentInk,
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BnrRadius.r2),
            ),
          ),
          icon: Icon(
            _step == 2 ? Icons.check : Icons.arrow_forward,
            size: 16,
          ),
          label: Text(
            _step == 2 ? 'Show me the wire' : 'Next',
            style: AppTheme.sans(
              size: 14,
              weight: FontWeight.w600,
              color: BnrColors.accentInk,
            ),
          ),
        ),
      ],
    );
  }

  void _advance() {
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    _finish();
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    await context.read<PreferencesCubit>().completeOnboarding(
          regions: _regions,
          disciplines: _disciplines,
          density: _density,
        );
    if (!mounted) return;
    widget.onComplete();
  }
}

class _OptCard extends StatelessWidget {
  final String title;
  final String sub;
  final String? emoji;
  final String? disciplineId;
  final bool selected;
  final VoidCallback onTap;

  const _OptCard({
    required this.title,
    required this.sub,
    this.emoji,
    this.disciplineId,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final accentColor = disciplineId != null
        ? BnrColors.disciplineColor(disciplineId)
        : BnrColors.accent;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BnrRadius.r2),
        child: AnimatedContainer(
          duration: BnrMotion.m2,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? ext.bg2 : ext.bg1,
            border: Border.all(color: selected ? accentColor : ext.line),
            borderRadius: BorderRadius.circular(BnrRadius.r2),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji != null) ...[
                    Text(emoji!, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    title,
                    style: AppTheme.serif(
                      size: 18,
                      weight: FontWeight.w600,
                      letterSpacing: -0.015,
                      color: ext.fg0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: AppTheme.sans(size: 12, color: ext.fg2),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 11,
                      color: BnrColors.accentInk,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
