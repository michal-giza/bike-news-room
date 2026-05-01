import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Maps the design-token system into Material 3 [ThemeData].
///
/// Most components style themselves directly from [BnrColors] / [TypeScale]
/// rather than relying on Material's role tokens — this is intentional:
/// the design is editorial and doesn't follow Material conventions.
class AppTheme {
  AppTheme._();

  /// Newsreader serif — for editorial headlines.
  static TextStyle serif({
    double? size,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = -0.018,
    Color? color,
    double height = 1.2,
  }) =>
      GoogleFonts.newsreader(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
        height: height,
      );

  /// Inter Tight sans — for UI/body.
  static TextStyle sans({
    double? size,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
    Color? color,
    double height = 1.5,
  }) =>
      GoogleFonts.interTight(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
        height: height,
      );

  /// JetBrains Mono — for meta lines, timestamps, labels.
  static TextStyle mono({
    double? size,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0.06,
    Color? color,
    double height = 1.4,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
        height: height,
      );

  static ThemeData darkTheme(TypeScale scale) => _build(
        brightness: Brightness.dark,
        bg0: BnrColors.darkBg0,
        bg1: BnrColors.darkBg1,
        fg0: BnrColors.darkFg0,
        fg1: BnrColors.darkFg1,
        fg2: BnrColors.darkFg2,
        scale: scale,
      );

  static ThemeData lightTheme(TypeScale scale) => _build(
        brightness: Brightness.light,
        bg0: BnrColors.lightBg0,
        bg1: BnrColors.lightBg1,
        fg0: BnrColors.lightFg0,
        fg1: BnrColors.lightFg1,
        fg2: BnrColors.lightFg2,
        scale: scale,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg0,
    required Color bg1,
    required Color fg0,
    required Color fg1,
    required Color fg2,
    required TypeScale scale,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg0,
      canvasColor: bg0,
      cardColor: bg1,
      dividerColor: brightness == Brightness.dark
          ? BnrColors.darkLine
          : BnrColors.lightLine,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: BnrColors.accent,
        onPrimary: BnrColors.accentInk,
        secondary: BnrColors.accent,
        onSecondary: BnrColors.accentInk,
        error: BnrColors.live,
        onError: Colors.white,
        surface: bg1,
        onSurface: fg0,
      ),
      textTheme: TextTheme(
        displayLarge: serif(size: scale.display, color: fg0, height: 1.05),
        displayMedium: serif(size: scale.hXl, color: fg0, height: 1.05),
        headlineLarge: serif(size: scale.hL, color: fg0, height: 1.1),
        headlineMedium: serif(size: scale.hM, color: fg0, height: 1.18),
        headlineSmall: serif(size: scale.hS, color: fg0, height: 1.25),
        titleLarge: sans(size: scale.lede, color: fg0, weight: FontWeight.w600),
        bodyLarge: sans(size: scale.lede, color: fg1, height: 1.55),
        bodyMedium: sans(size: scale.body, color: fg1, height: 1.5),
        labelLarge: sans(size: scale.body, color: fg0, weight: FontWeight.w600),
        labelMedium: mono(size: scale.meta, color: fg2, letterSpacing: 0.08),
        labelSmall: mono(size: 10, color: fg2, letterSpacing: 0.18),
      ),
    );
  }
}
