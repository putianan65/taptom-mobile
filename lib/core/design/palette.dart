import 'package:flutter/material.dart';

/// Raw colour ramps. Screens should read semantic colours from [AppPalette]
/// instead of these values so light and dark themes stay consistent.
abstract final class Swatch {
  // Leaf green: a grounded, slightly warm green taken from young kratom
  // leaves. 700 is the brand colour in light mode.
  static const green950 = Color(0xFF0C1F13);
  static const green900 = Color(0xFF13321D);
  static const green800 = Color(0xFF1B4427);
  static const green700 = Color(0xFF245A33);
  static const green600 = Color(0xFF2F7041);
  static const green500 = Color(0xFF468A55);
  static const green400 = Color(0xFF6CA874);
  static const green300 = Color(0xFF98C79A);
  static const green200 = Color(0xFFC4E0C0);
  static const green100 = Color(0xFFE2EFDC);
  static const green50 = Color(0xFFF1F6EC);

  // Clean neutrals with the faintest green cast, so white reads crisp rather
  // than clinical next to the brand greens.
  static const paper0 = Color(0xFFFFFFFF);
  static const paper50 = Color(0xFFF8F9F7);
  static const paper100 = Color(0xFFF2F4F1);
  static const paper200 = Color(0xFFE6E9E4);
  static const paper300 = Color(0xFFD3D8D1);
  static const ink400 = Color(0xFF8A9189);
  static const ink500 = Color(0xFF6C746C);
  static const ink600 = Color(0xFF4C554D);
  static const ink800 = Color(0xFF263028);
  static const ink900 = Color(0xFF161D18);

  // Night neutrals for dark mode.
  static const night950 = Color(0xFF0B110D);
  static const night900 = Color(0xFF111914);
  static const night850 = Color(0xFF162019);
  static const night800 = Color(0xFF1C2820);
  static const night700 = Color(0xFF26342A);
  static const night600 = Color(0xFF34443A);

  // Rice gold. Used sparingly for highlights and the pending state.
  static const gold700 = Color(0xFF8A5D0E);
  static const gold500 = Color(0xFFC8931F);
  static const gold300 = Color(0xFFE9C46A);
  static const gold100 = Color(0xFFFDF1CC);

  // Laterite clay for destructive and rejected states.
  static const clay700 = Color(0xFF9A3A27);
  static const clay500 = Color(0xFFC0553D);
  static const clay300 = Color(0xFFE59A84);
  static const clay100 = Color(0xFFF6E1DA);

  // River slate for neutral information.
  static const slate700 = Color(0xFF34576A);
  static const slate300 = Color(0xFF9BBCCB);
  static const slate100 = Color(0xFFE1ECF0);
}

/// Semantic colour roles exposed through the theme.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceSunken,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.inkInverse,
    required this.brand,
    required this.brandStrong,
    required this.brandSoft,
    required this.onBrand,
    required this.hero,
    required this.heroInk,
    required this.heroLine,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
    required this.scrim,
    required this.shadow,
  });

  /// Page background.
  final Color background;

  /// Cards, sheets and grouped lists.
  final Color surface;

  /// Slightly tinted surface for secondary panels.
  final Color surfaceMuted;

  /// Input fills and wells.
  final Color surfaceSunken;

  /// Hairline borders and separators.
  final Color line;
  final Color lineStrong;

  /// Text roles.
  final Color ink;
  final Color inkMuted;
  final Color inkSubtle;
  final Color inkInverse;

  /// Brand green and its tints.
  final Color brand;
  final Color brandStrong;
  final Color brandSoft;
  final Color onBrand;

  /// Deep green used for hero headers and the contour backdrop.
  final Color hero;
  final Color heroInk;
  final Color heroLine;

  /// Rice-gold accent.
  final Color accent;
  final Color accentSoft;

  /// Status roles. The "soft" variant is a background tint for badges.
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;

  final Color scrim;
  final Color shadow;

  static const light = AppPalette(
    background: Swatch.paper0,
    surface: Swatch.paper0,
    surfaceMuted: Swatch.green50,
    surfaceSunken: Swatch.paper100,
    line: Swatch.paper200,
    lineStrong: Swatch.paper300,
    ink: Swatch.ink900,
    inkMuted: Swatch.ink600,
    inkSubtle: Swatch.ink500,
    inkInverse: Swatch.paper50,
    brand: Swatch.green700,
    brandStrong: Swatch.green800,
    brandSoft: Swatch.green100,
    onBrand: Swatch.paper0,
    hero: Swatch.green800,
    heroInk: Swatch.paper50,
    heroLine: Swatch.green400,
    accent: Swatch.gold500,
    accentSoft: Swatch.paper100,
    success: Swatch.green600,
    successSoft: Swatch.green100,
    warning: Swatch.gold700,
    warningSoft: Swatch.gold100,
    danger: Swatch.clay700,
    dangerSoft: Swatch.clay100,
    info: Swatch.slate700,
    infoSoft: Swatch.slate100,
    scrim: Color(0x99101812),
    shadow: Color(0x1A13321D),
  );

  static const dark = AppPalette(
    background: Swatch.night950,
    surface: Swatch.night900,
    surfaceMuted: Swatch.night850,
    surfaceSunken: Swatch.night800,
    line: Swatch.night700,
    lineStrong: Swatch.night600,
    ink: Color(0xFFE9EDE6),
    inkMuted: Color(0xFFB2BCB2),
    inkSubtle: Color(0xFF8A958B),
    inkInverse: Swatch.ink900,
    brand: Swatch.green300,
    brandStrong: Swatch.green200,
    brandSoft: Color(0xFF1E3A26),
    onBrand: Swatch.green950,
    hero: Color(0xFF12291A),
    heroInk: Color(0xFFE9EDE6),
    heroLine: Swatch.green500,
    accent: Swatch.gold300,
    accentSoft: Color(0xFF3A2F17),
    success: Swatch.green300,
    successSoft: Color(0xFF1E3A26),
    warning: Swatch.gold300,
    warningSoft: Color(0xFF3A2F17),
    danger: Swatch.clay300,
    dangerSoft: Color(0xFF3D211B),
    info: Swatch.slate300,
    infoSoft: Color(0xFF1C2E36),
    scrim: Color(0xB3050806),
    shadow: Color(0x66000000),
  );

  @override
  AppPalette copyWith({Color? brand, Color? hero}) {
    return AppPalette(
      background: background,
      surface: surface,
      surfaceMuted: surfaceMuted,
      surfaceSunken: surfaceSunken,
      line: line,
      lineStrong: lineStrong,
      ink: ink,
      inkMuted: inkMuted,
      inkSubtle: inkSubtle,
      inkInverse: inkInverse,
      brand: brand ?? this.brand,
      brandStrong: brandStrong,
      brandSoft: brandSoft,
      onBrand: onBrand,
      hero: hero ?? this.hero,
      heroInk: heroInk,
      heroLine: heroLine,
      accent: accent,
      accentSoft: accentSoft,
      success: success,
      successSoft: successSoft,
      warning: warning,
      warningSoft: warningSoft,
      danger: danger,
      dangerSoft: dangerSoft,
      info: info,
      infoSoft: infoSoft,
      scrim: scrim,
      shadow: shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      line: l(line, other.line),
      lineStrong: l(lineStrong, other.lineStrong),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      inkSubtle: l(inkSubtle, other.inkSubtle),
      inkInverse: l(inkInverse, other.inkInverse),
      brand: l(brand, other.brand),
      brandStrong: l(brandStrong, other.brandStrong),
      brandSoft: l(brandSoft, other.brandSoft),
      onBrand: l(onBrand, other.onBrand),
      hero: l(hero, other.hero),
      heroInk: l(heroInk, other.heroInk),
      heroLine: l(heroLine, other.heroLine),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      info: l(info, other.info),
      infoSoft: l(infoSoft, other.infoSoft),
      scrim: l(scrim, other.scrim),
      shadow: l(shadow, other.shadow),
    );
  }
}

/// Status tones shared by badges, banners and toasts.
enum Tone { neutral, brand, success, warning, danger, info }

extension ToneColors on AppPalette {
  Color toneColor(Tone tone) => switch (tone) {
        Tone.neutral => inkMuted,
        Tone.brand => brand,
        Tone.success => success,
        Tone.warning => warning,
        Tone.danger => danger,
        Tone.info => info,
      };

  Color toneSoft(Tone tone) => switch (tone) {
        Tone.neutral => surfaceSunken,
        Tone.brand => brandSoft,
        Tone.success => successSoft,
        Tone.warning => warningSoft,
        Tone.danger => dangerSoft,
        Tone.info => infoSoft,
      };
}
