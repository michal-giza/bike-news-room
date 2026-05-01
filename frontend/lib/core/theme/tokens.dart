import 'package:flutter/material.dart';

/// Design tokens ported from `tokens.css`. Keep in sync.
///
/// Theme split (dark/light) lives in [AppTheme]. Persona-driven type scaling
/// (younger/bridge/older) lives in [TypeScale]. All colors are derived from
/// the OKLCH source spec — converted to closest sRGB equivalents.
class BnrColors {
  BnrColors._();

  // ── Dark theme (default) ──────────────────────────────────────────
  static const darkBg0 = Color(0xFF0E0F11); // page
  static const darkBg1 = Color(0xFF15171B); // card
  static const darkBg2 = Color(0xFF1C1F24); // hover/inset
  static const darkBg3 = Color(0xFF262A30); // selected
  static const darkLine = Color(0xB34A4F58); // 70% alpha
  static const darkLineSoft = Color(0x594A4F58);

  static const darkFg0 = Color(0xFFF6F4EE); // primary text
  static const darkFg1 = Color(0xFFB8B5AC); // secondary
  static const darkFg2 = Color(0xFF7E7C75); // meta
  static const darkFg3 = Color(0xFF53524D); // disabled

  // ── Light theme ───────────────────────────────────────────────────
  static const lightBg0 = Color(0xFFF8F7F3);
  static const lightBg1 = Color(0xFFFFFFFF);
  static const lightBg2 = Color(0xFFEFEEE9);
  static const lightBg3 = Color(0xFFE0DED8);
  static const lightLine = Color(0xFFC8C5BD);
  static const lightLineSoft = Color(0x99C8C5BD);

  static const lightFg0 = Color(0xFF1A1D22);
  static const lightFg1 = Color(0xFF454850);
  static const lightFg2 = Color(0xFF72757A);
  static const lightFg3 = Color(0xFFA3A4A6);

  // ── Accent (sodium yellow) ────────────────────────────────────────
  static const accent = Color(0xFFE8C54A);
  static const accentInk = Color(0xFF2A220D);

  // ── Live (red pulse) ──────────────────────────────────────────────
  static const live = Color(0xFFE85948);
  static const liveSoft = Color(0x29E85948);

  // ── Discipline hues (used quietly: 1px bars, hover ring, fills) ───
  static const discRoad = Color(0xFF7AAEF1);
  static const discMtb = Color(0xFF6CC58E);
  static const discGravel = Color(0xFFE0B66E);
  static const discTrack = Color(0xFFB28BE6);
  static const discCx = Color(0xFFE38470);
  static const discBmx = Color(0xFFE08CB6);

  static Color disciplineColor(String? id) {
    switch (id) {
      case 'road':
        return discRoad;
      case 'mtb':
        return discMtb;
      case 'gravel':
        return discGravel;
      case 'track':
        return discTrack;
      case 'cx':
        return discCx;
      case 'bmx':
        return discBmx;
      default:
        return discRoad;
    }
  }
}

/// Spacing scale in logical pixels.
class BnrSpacing {
  BnrSpacing._();

  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
}

/// Border radii.
class BnrRadius {
  BnrRadius._();

  static const double r1 = 4;
  static const double r2 = 8;
  static const double r3 = 12;
  static const double r4 = 16;
  static const double pill = 999;
}

/// Motion timings + easing.
class BnrMotion {
  BnrMotion._();

  static const Duration m1 = Duration(milliseconds: 120);
  static const Duration m2 = Duration(milliseconds: 220);
  static const Duration m3 = Duration(milliseconds: 360);

  /// Smooth, default easing curve.
  static const Curve ease = Cubic(0.22, 0.61, 0.36, 1);

  /// Sharper material-style easing for transitions.
  static const Curve easeSharp = Cubic(0.4, 0, 0.2, 1);
}

/// Three persona scales as defined in the design tokens.
enum PersonaScale { younger, bridge, older }

/// Resolved type sizes for the active persona.
class TypeScale {
  final double meta;
  final double body;
  final double lede;
  final double hS;
  final double hM;
  final double hL;
  final double hXl;
  final double display;

  const TypeScale({
    required this.meta,
    required this.body,
    required this.lede,
    required this.hS,
    required this.hM,
    required this.hL,
    required this.hXl,
    required this.display,
  });

  static const younger = TypeScale(
    meta: 11,
    body: 14,
    lede: 15,
    hS: 17,
    hM: 22,
    hL: 32,
    hXl: 48,
    display: 64,
  );

  static const bridge = TypeScale(
    meta: 11,
    body: 15,
    lede: 16,
    hS: 18,
    hM: 24,
    hL: 34,
    hXl: 52,
    display: 68,
  );

  static const older = TypeScale(
    meta: 12,
    body: 16,
    lede: 17,
    hS: 19,
    hM: 26,
    hL: 38,
    hXl: 56,
    display: 72,
  );

  static TypeScale forPersona(PersonaScale p) => switch (p) {
        PersonaScale.younger => younger,
        PersonaScale.bridge => bridge,
        PersonaScale.older => older,
      };
}
