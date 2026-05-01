import 'package:flutter/material.dart';

import 'tokens.dart';

/// Custom theme extension exposing the surface tokens that Material 3's
/// `ColorScheme` doesn't naturally model (bg0/bg1/bg2/bg3 + fg tiers).
///
/// Read it via `Theme.of(context).extension<BnrThemeExt>()!`.
class BnrThemeExt extends ThemeExtension<BnrThemeExt> {
  final Color bg0;
  final Color bg1;
  final Color bg2;
  final Color bg3;
  final Color line;
  final Color lineSoft;
  final Color fg0;
  final Color fg1;
  final Color fg2;
  final Color fg3;

  const BnrThemeExt({
    required this.bg0,
    required this.bg1,
    required this.bg2,
    required this.bg3,
    required this.line,
    required this.lineSoft,
    required this.fg0,
    required this.fg1,
    required this.fg2,
    required this.fg3,
  });

  static const dark = BnrThemeExt(
    bg0: BnrColors.darkBg0,
    bg1: BnrColors.darkBg1,
    bg2: BnrColors.darkBg2,
    bg3: BnrColors.darkBg3,
    line: BnrColors.darkLine,
    lineSoft: BnrColors.darkLineSoft,
    fg0: BnrColors.darkFg0,
    fg1: BnrColors.darkFg1,
    fg2: BnrColors.darkFg2,
    fg3: BnrColors.darkFg3,
  );

  static const light = BnrThemeExt(
    bg0: BnrColors.lightBg0,
    bg1: BnrColors.lightBg1,
    bg2: BnrColors.lightBg2,
    bg3: BnrColors.lightBg3,
    line: BnrColors.lightLine,
    lineSoft: BnrColors.lightLineSoft,
    fg0: BnrColors.lightFg0,
    fg1: BnrColors.lightFg1,
    fg2: BnrColors.lightFg2,
    fg3: BnrColors.lightFg3,
  );

  @override
  BnrThemeExt copyWith({
    Color? bg0,
    Color? bg1,
    Color? bg2,
    Color? bg3,
    Color? line,
    Color? lineSoft,
    Color? fg0,
    Color? fg1,
    Color? fg2,
    Color? fg3,
  }) =>
      BnrThemeExt(
        bg0: bg0 ?? this.bg0,
        bg1: bg1 ?? this.bg1,
        bg2: bg2 ?? this.bg2,
        bg3: bg3 ?? this.bg3,
        line: line ?? this.line,
        lineSoft: lineSoft ?? this.lineSoft,
        fg0: fg0 ?? this.fg0,
        fg1: fg1 ?? this.fg1,
        fg2: fg2 ?? this.fg2,
        fg3: fg3 ?? this.fg3,
      );

  @override
  BnrThemeExt lerp(ThemeExtension<BnrThemeExt>? other, double t) {
    if (other is! BnrThemeExt) return this;
    return BnrThemeExt(
      bg0: Color.lerp(bg0, other.bg0, t)!,
      bg1: Color.lerp(bg1, other.bg1, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      bg3: Color.lerp(bg3, other.bg3, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineSoft: Color.lerp(lineSoft, other.lineSoft, t)!,
      fg0: Color.lerp(fg0, other.fg0, t)!,
      fg1: Color.lerp(fg1, other.fg1, t)!,
      fg2: Color.lerp(fg2, other.fg2, t)!,
      fg3: Color.lerp(fg3, other.fg3, t)!,
    );
  }
}

extension BnrContext on BuildContext {
  BnrThemeExt get bnr => Theme.of(this).extension<BnrThemeExt>()!;
}
