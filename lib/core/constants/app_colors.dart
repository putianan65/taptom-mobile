import 'package:flutter/material.dart';

import '../design/palette.dart';

/// Static colour aliases kept for screens that cannot reach a [BuildContext].
///
/// They mirror the light palette in [AppPalette]. Widgets should prefer
/// `context.palette`, which also follows dark mode.
abstract final class AppColors {
  static const Color primary = Swatch.green700;
  static const Color primaryLight = Swatch.green600;
  static const Color primaryLighter = Swatch.green500;
  static const Color primaryDark = Swatch.green800;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Swatch.green700, Swatch.green800],
  );

  static const Color background = Swatch.paper0;
  static const Color surface = Swatch.paper0;
  static const Color surfaceVariant = Swatch.paper100;

  static const Color textPrimary = Swatch.ink900;
  static const Color textSecondary = Swatch.ink600;
  static const Color textTertiary = Swatch.ink500;
  static const Color textLight = Swatch.paper0;
  static const Color textMain = textPrimary;

  /// Secondary accents collapse into the brand family to keep colour use
  /// restrained; status colours below carry meaning.
  static const Color secondary = Swatch.slate700;
  static const Color success = Swatch.green600;
  static const Color warning = Swatch.gold700;
  static const Color error = Swatch.clay700;
  static const Color info = Swatch.slate700;

  static const Color border = Swatch.paper200;
  static const Color borderLight = Swatch.paper100;
  static const Color divider = Swatch.paper200;

  static const Color shadowLight = Color(0x0F13321D);
  static const Color shadowMedium = Color(0x1A13321D);
  static const Color shadowStrong = Color(0x2913321D);

  static const Color darkBackground = Swatch.night950;
  static const Color darkSurface = Swatch.night900;
  static const Color darkSurfaceVariant = Swatch.night800;

  static const Color gradientStart = Swatch.green700;
  static const Color gradientEnd = Swatch.green600;
  static const Color gradientSurface = Swatch.green50;

  // Roles share the brand palette; role is shown with a label, not a colour.
  static const Color adminPrimary = Swatch.green700;
  static const Color adminLight = Swatch.green600;
  static const Color adminLighter = Swatch.green500;
  static const Color adminDark = Swatch.green800;
  static const LinearGradient adminGradient = primaryGradient;
  static const Color superAdminPrimary = Swatch.green800;
  static const Color superAdminLight = Swatch.green600;
  static const Color superAdminLighter = Swatch.green300;
  static const Color superAdminDark = Swatch.green900;
  static const LinearGradient superAdminGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Swatch.green900, Swatch.green800],
  );

  static const Color neutralGray = Swatch.ink500;
  static const Color pendingStatus = Swatch.gold700;
  static const Color approvedStatus = success;
  static const Color rejectedStatus = error;
  static const Color noneStatus = Swatch.ink500;

  static const Color surfaceLight = Swatch.paper50;
  static const Color surfaceCard = Swatch.paper0;
  static const Color surfaceDimmed = Swatch.paper100;
  static const Color textHint = Swatch.ink400;
  static const Color textOnDark = Swatch.paper0;

  // GAP categories are distinguished by number and icon, not colour.
  static const Color gapGeneral = primary;
  static const Color gapInputs = primary;
  static const Color gapManagement = primary;
  static const Color gapHarvest = primary;
  static const Color gapPostHarvest = primary;
  static const Color gapSafety = primary;
  static const Color gapTraceability = primary;

  static Color roleColor(String? role) => primary;

  static Color statusColor(String? status) => switch (status?.toUpperCase()) {
        'PENDING' => pendingStatus,
        'APPROVED' => approvedStatus,
        'REJECTED' => rejectedStatus,
        _ => noneStatus,
      };

  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}

/// Former neon "luxury" palette for the super admin area, now folded into
/// the shared design. Kept as aliases while screens migrate.
abstract final class LuxuryTheme {
  static const Color midnightBlue = Swatch.paper50;
  static const Color deepSpace = Swatch.paper100;
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Swatch.paper50, Swatch.paper50],
  );
  static const Color glassSurface = Swatch.paper0;
  static const Color glassBorder = Swatch.paper200;
  static const double glassBlur = 0;
  static const Color cyanNeon = Swatch.green700;
  static const Color goldNeon = Swatch.gold700;
  static const Color purpleNeon = Swatch.slate700;
  static const Color emeraldNeon = Swatch.green600;
  static const Color textPrimary = Swatch.ink900;
  static const Color textSecondary = Swatch.ink600;
  static const Color textDisabled = Swatch.ink400;

  static List<BoxShadow> neonShadow(Color color) => const [];
}
