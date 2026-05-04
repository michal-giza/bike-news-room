import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ads/ad_service.dart';
import '../../../../core/ads/consent_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
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

  /// Regions are listed by (id, emoji-flag) only. The display name and
  /// the short description come from `AppLocalizations` so they translate
  /// per locale. Emoji flags are universal — no localization needed.
  static const _regionIds = [
    ('world', '🌍'),
    ('eu', '🇪🇺'),
    ('poland', '🇵🇱'),
    ('spain', '🇪🇸'),
  ];
  static const _disciplineIds = ['road', 'mtb', 'gravel', 'track', 'cx', 'bmx'];

  String _regionName(AppLocalizations l, String id) => switch (id) {
        'world' => l.nameWorld,
        'eu' => l.nameEu,
        'poland' => l.namePoland,
        'spain' => l.nameSpain,
        _ => id,
      };
  String _regionDesc(AppLocalizations l, String id) => switch (id) {
        'world' => l.descWorld,
        'eu' => l.descEu,
        'poland' => l.descPoland,
        'spain' => l.descSpain,
        _ => '',
      };
  String _disciplineName(AppLocalizations l, String id) => switch (id) {
        'road' => l.disciplineRoad,
        'mtb' => l.disciplineMtb,
        'gravel' => l.disciplineGravel,
        'track' => l.disciplineTrack,
        'cx' => l.disciplineCxLong,
        'bmx' => l.disciplineBmx,
        _ => id,
      };
  String _disciplineDesc(AppLocalizations l, String id) => switch (id) {
        'road' => l.descRoad,
        'mtb' => l.descMtb,
        'gravel' => l.descGravel,
        'track' => l.descTrack,
        'cx' => l.descCx,
        'bmx' => l.descBmx,
        _ => '',
      };

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
              AppLocalizations.of(context).onboardingStepCounter(_step + 1, 3),
              style: AppTheme.mono(
                size: 11,
                color: ext.fg2,
                letterSpacing: 0.18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _stepName(context, _step),
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

  String _stepName(BuildContext context, int step) {
    final l = AppLocalizations.of(context);
    return switch (step) {
      0 => l.onboardingStepRegions,
      1 => l.onboardingStepDisciplines,
      _ => l.onboardingStepDensity,
    };
  }

  Widget _stepBody(BnrThemeExt ext) {
    return switch (_step) {
      0 => _regionsStep(ext),
      1 => _disciplinesStep(ext),
      _ => _densityStep(ext),
    };
  }

  Widget _regionsStep(BnrThemeExt ext) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.onbRegionsTitle,
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
          l.onbRegionsSub,
          style: AppTheme.sans(size: 17, color: ext.fg1, height: 1.5),
        ),
        const SizedBox(height: BnrSpacing.s8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final r in _regionIds)
              _OptCard(
                title: _regionName(l, r.$1),
                sub: _regionDesc(l, r.$1),
                emoji: r.$2,
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
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.onbDisciplinesTitle,
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
          l.onbDisciplinesSub,
          style: AppTheme.sans(size: 17, color: ext.fg1, height: 1.5),
        ),
        const SizedBox(height: BnrSpacing.s8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final id in _disciplineIds)
              _OptCard(
                title: _disciplineName(l, id),
                sub: _disciplineDesc(l, id),
                disciplineId: id,
                selected: _disciplines.contains(id),
                onTap: () => setState(() {
                  if (_disciplines.contains(id)) {
                    _disciplines.remove(id);
                  } else {
                    _disciplines.add(id);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _densityStep(BnrThemeExt ext) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.onbDensityTitle,
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
          l.onbDensitySub,
          style: AppTheme.sans(size: 17, color: ext.fg1, height: 1.5),
        ),
        const SizedBox(height: BnrSpacing.s8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _OptCard(
              title: l.settingsDensityCompact,
              sub: l.onbCompactSub,
              selected: _density == CardDensity.compact,
              onTap: () => setState(() => _density = CardDensity.compact),
            ),
            _OptCard(
              title: l.settingsDensityComfort,
              sub: l.onbComfortSub,
              selected: _density == CardDensity.comfort,
              onTap: () => setState(() => _density = CardDensity.comfort),
            ),
            _OptCard(
              title: l.settingsDensityLarge,
              sub: l.onbLargeSub,
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
    final l = AppLocalizations.of(context);
    final canAdvance = _step != 0 || _regions.isNotEmpty;
    return Row(
      children: [
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step--),
            child: Text(
              l.onboardingBack,
              style: AppTheme.sans(
                size: 13,
                color: ext.fg2,
              ),
            ),
          ),
        TextButton(
          // ValueKey for integration tests: locale-independent finder so
          // Patrol/flutter_test can drive the onboarding without parsing
          // translated strings ("Skip" / "Pomiń" / "Saltar" / …).
          key: const ValueKey('onboardingSkipBtn'),
          onPressed: _skip,
          child: Text(
            l.onboardingSkip,
            style: AppTheme.sans(size: 13, color: ext.fg2),
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          key: const ValueKey('onboardingAdvanceBtn'),
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
            _step == 2 ? l.onboardingFinish : l.onboardingNext,
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
    // Mobile only — request ATT first (iOS), then UMP (both platforms).
    // ATT must come before UMP because UMP itself is a tracking-SDK
    // touchpoint on iOS. Each request shows on its own screen (Apple's
    // native ATT dialog, then Google's UMP form), so Apple reviewers
    // see two separate consent surfaces.
    await _runConsentFlowOnMobile();

    if (!mounted) return;
    await context.read<PreferencesCubit>().completeOnboarding(
          regions: _regions,
          disciplines: _disciplines,
          density: _density,
        );

    // Layer 4 — initialize consent-dependent services AFTER ATT + UMP.
    // The skill mandates this order: never call MobileAds.instance.initialize()
    // before consent has been resolved.
    await _initPostConsentServices();

    if (!mounted) return;
    widget.onComplete();
  }

  Future<void> _runConsentFlowOnMobile() async {
    if (kIsWeb) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;
    final consent = getIt<ConsentService>();
    try {
      await consent.requestAtt();
    } catch (e) {
      debugPrint('Onboarding: ATT request failed: $e');
    }
    if (!mounted) return;
    try {
      await consent.requestUmp();
    } catch (e) {
      debugPrint('Onboarding: UMP request failed: $e');
    }
  }

  Future<void> _initPostConsentServices() async {
    try {
      await getIt<IAdService>().init();
    } catch (e) {
      debugPrint('Onboarding: ad service init failed: $e');
    }
    // When Firebase is added later, re-enable Analytics + Crashlytics here:
    //   await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    //   await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    //   final attGranted = !Platform.isIOS ||
    //       (await getIt<ConsentService>().isAttGranted());
    //   await FirebaseAnalytics.instance.setConsent(
    //     analyticsStorageConsentGranted: true,
    //     adStorageConsentGranted: attGranted,
    //     adUserDataConsentGranted: attGranted,
    //     adPersonalizationSignalsConsentGranted: attGranted,
    //   );
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
