import 'package:flutter/material.dart';

/// Type families bundled with the app (see `assets/fonts`).
///
/// * [display] Noto Serif Thai for page titles and brand moments. It gives
///   headings the calm, printed feel of an agricultural almanac.
/// * [text] Anuphan for everything else; a loopless Thai sans with sturdy
///   numerals that stays legible for older farmers outdoors.
/// * [mono] IBM Plex Mono for lot numbers, coordinates and IDs.
abstract final class AppFonts {
  static const display = 'NotoSerifThai';
  static const text = 'Anuphan';
  static const mono = 'IBMPlexMono';

  static const tabular = [FontFeature.tabularFigures()];
}

/// The type scale. Thai script needs generous line height for stacked vowels
/// and tone marks, so body styles sit around 1.5.
abstract final class AppTypeScale {
  static TextTheme textTheme(Color ink, Color muted) {
    TextStyle display(double size, FontWeight weight, double height) =>
        TextStyle(
          fontFamily: AppFonts.display,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: ink,
          letterSpacing: -0.2,
        );
    TextStyle text(
      double size,
      FontWeight weight,
      double height, {
      Color? color,
      double letterSpacing = 0,
    }) =>
        TextStyle(
          fontFamily: AppFonts.text,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color ?? ink,
          letterSpacing: letterSpacing,
        );

    return TextTheme(
      displayLarge: display(40, FontWeight.w700, 1.15),
      displayMedium: display(34, FontWeight.w700, 1.18),
      displaySmall: display(28, FontWeight.w700, 1.22),
      headlineLarge: display(26, FontWeight.w700, 1.25),
      headlineMedium: display(23, FontWeight.w700, 1.28),
      headlineSmall: display(20, FontWeight.w600, 1.3),
      titleLarge: text(19, FontWeight.w600, 1.35),
      titleMedium: text(16.5, FontWeight.w600, 1.4),
      titleSmall: text(15, FontWeight.w600, 1.4),
      bodyLarge: text(16.5, FontWeight.w400, 1.55),
      bodyMedium: text(15, FontWeight.w400, 1.55),
      bodySmall: text(13.5, FontWeight.w400, 1.5, color: muted),
      labelLarge: text(15, FontWeight.w600, 1.3),
      labelMedium: text(13, FontWeight.w500, 1.3, color: muted),
      labelSmall: text(11.5, FontWeight.w600, 1.3,
          color: muted, letterSpacing: 0.4),
    );
  }
}

extension TextStyleX on TextStyle {
  /// Monospaced variant for codes, keeping size and colour.
  TextStyle get mono => copyWith(
        fontFamily: AppFonts.mono,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      );

  /// Equal-width digits so counters do not jitter while animating.
  TextStyle get tabular => copyWith(fontFeatures: AppFonts.tabular);

  TextStyle get w500 => copyWith(fontWeight: FontWeight.w500);
  TextStyle get w600 => copyWith(fontWeight: FontWeight.w600);
  TextStyle get w700 => copyWith(fontWeight: FontWeight.w700);

  TextStyle tint(Color color) => copyWith(color: color);
}
