import 'package:flutter/material.dart';

/// Production-ready Color System
/// Design Philosophy: Clean, Professional, Sustainable
class AppColors {
  // ═══════════════════════════════════════════════════════════
  // PRIMARY BRAND COLORS - Green Palette
  // ═══════════════════════════════════════════════════════════

  /// Main brand green - Professional, deep forest green (Production-ready)
  /// Darker than before for better contrast and premium feel
  static const Color primary = Color(0xFF1B5E3F); // Deep professional green

  /// Light variant for hover states and backgrounds
  static const Color primaryLight = Color(0xFF2E7D52);

  /// Lighter tint for subtle backgrounds
  static const Color primaryLighter = Color(0xFF4A9D6F);

  /// Dark variant for depth and contrast - nearly black-green
  static const Color primaryDark = Color(0xFF0D3D28);

  // ═══════════════════════════════════════════════════════════
  // GRADIENTS - Soft, Sophisticated
  // ═══════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4A9D6F), // Mint green
      Color(0xFF2D7A4F), // Forest green
    ],
  );

  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF8FAF9), // Nearly white with green tint
      Color(0xFFFFFFFF), // Pure white
    ],
  );

  // ═══════════════════════════════════════════════════════════
  // NEUTRAL PALETTE - Warm Grays
  // ═══════════════════════════════════════════════════════════

  /// Main background - off-white with warmth
  static const Color background = Color(0xFFF8F9FA);

  /// Card and elevated surface color
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle surface variant (for inputs, etc)
  static const Color surfaceVariant = Color(0xFFF4F5F7);

  // ═══════════════════════════════════════════════════════════
  // TEXT COLORS - High Contrast, Readable
  // ═══════════════════════════════════════════════════════════

  /// Primary text - dark gray, not black
  static const Color textPrimary = Color(0xFF1F2937);

  /// Secondary text - medium gray
  static const Color textSecondary = Color(0xFF6B7280);

  /// Tertiary text - light gray (placeholders, disabled)
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Text on dark backgrounds
  static const Color textLight = Color(0xFFFFFFFF);

  /// Main text alias for compatibility
  static const Color textMain = textPrimary;

  // ═══════════════════════════════════════════════════════════
  // SEMANTIC COLORS - Status Communication
  // ═══════════════════════════════════════════════════════════

  /// Secondary accent (kept minimal, use sparingly)
  static const Color secondary = Color(0xFF3B82F6);

  /// Success state
  static const Color success = Color(0xFF10B981);

  /// Warning state
  static const Color warning = Color(0xFFF59E0B);

  /// Error state
  static const Color error = Color(0xFFEF4444);

  /// Info state
  static const Color info = Color(0xFF3B82F6);

  // ═══════════════════════════════════════════════════════════
  // BORDER & DIVIDER COLORS
  // ═══════════════════════════════════════════════════════════

  /// Default border color
  static const Color border = Color(0xFFE5E7EB);

  /// Subtle border
  static const Color borderLight = Color(0xFFF3F4F6);

  /// Divider color
  static const Color divider = Color(0xFFE5E7EB);

  // ═══════════════════════════════════════════════════════════
  // SHADOW COLORS
  // ═══════════════════════════════════════════════════════════

  /// Subtle shadow for cards
  static Color shadowLight = const Color(0xFF000000).withOpacity(0.04);

  /// Medium shadow for elevated elements
  static Color shadowMedium = const Color(0xFF000000).withOpacity(0.08);

  /// Strong shadow for floating elements
  static Color shadowStrong = const Color(0xFF000000).withOpacity(0.12);

  // ═══════════════════════════════════════════════════════════
  // DARK MODE PALETTE (Future-proof)
  // ═══════════════════════════════════════════════════════════

  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkSurfaceVariant = Color(0xFF374151);

  // ═══════════════════════════════════════════════════════════
  // LEGACY COMPATIBILITY (Do not remove)
  // ═══════════════════════════════════════════════════════════

  // Missing Gradient Colors
  static const Color gradientStart = Color(0xFF2E7D32); // Deep Green
  static const Color gradientEnd = Color(0xFF43A047); // Lighter Green
  static const Color gradientSurface = Color(0xFFE8F5E9);

  // ═══════════════════════════════════════════════════════════
  // ROLE-BASED COLORS - Admin & Super Admin Identity
  // ═══════════════════════════════════════════════════════════

  /// Admin role accent - Green (Matching User App)
  static const Color adminPrimary = primary; // Was Orange
  static const Color adminLight = primaryLight;   // Was Orange
  static const Color adminLighter = primaryLighter; // Was Light Orange
  static const Color adminDark = primaryDark;    // Was Dark Orange

  /// Admin gradient - Green
  static const LinearGradient adminGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2E7D32), // Dark Green
      Color(0xFF66BB6A), // Light Green
    ],
  );

  /// Super Admin role accent - Royal Blue & Black (The King of System)
  static const Color superAdminPrimary = Color(0xFF1565C0); // Royal Blue
  static const Color superAdminLight = Color(0xFF42A5F5);   // Lighter Blue
  static const Color superAdminLighter = Color(0xFF90CAF9); // Pale Blue
  static const Color superAdminDark = Color(0xFF0D47A1);    // Deep Blue
  
  /// Super Admin gradients - Royal Blue to Black
  static const LinearGradient superAdminGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF000000), // Black
      Color(0xFF1565C0), // Royal Blue
    ],
  );

  static const Color neutralGray = Color(0xFF757575);

  // Missing Semantic Status Colors
  static const Color pendingStatus = Color(0xFFFFAB40);
  static const Color approvedStatus = success;
  static const Color rejectedStatus = error;
  static const Color noneStatus = Color(0xFF9E9E9E);

  // Missing Surface Colors
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceCard = Colors.white;
  static const Color surfaceDimmed = Color(0xFFF5F5F5);

  // Missing Text Colors
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnDark = Colors.white;

  // ═══════════════════════════════════════════════════════════
  // GAP CATEGORY COLORS
  // ═══════════════════════════════════════════════════════════

  static const Color gapGeneral = Color(0xFF1B5E3F);      // Primary green
  static const Color gapInputs = Color(0xFF2E7D52);       // Primary light
  static const Color gapManagement = Color(0xFF4A9D6F);   // Primary lighter
  static const Color gapHarvest = Color(0xFFFF6F00);      // Admin primary
  static const Color gapPostHarvest = Color(0xFF3B82F6);  // Info blue
  static const Color gapSafety = Color(0xFFEF4444);       // Error red
  static const Color gapTraceability = Color(0xFF8B5CF6); // Purple

  // ═══════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════

  /// Get color based on user role
  static Color roleColor(String? role) {
    switch (role?.toUpperCase()) {
      case 'SUPER_ADMIN':
        return superAdminPrimary;
      case 'ADMIN':
        return adminPrimary;
      default:
        return primary;
    }
  }

  /// Get color based on membership status
  static Color statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return pendingStatus;
      case 'APPROVED':
        return approvedStatus;
      case 'REJECTED':
        return rejectedStatus;
      default:
        return noneStatus;
    }
  }

  /// Generate a lighter tint of any color
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Generate a darker shade of any color
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

/// Luxury Theme for Super Admin (Midnight Blue & Neon)
class LuxuryTheme {
  // Backgrounds
  static const Color midnightBlue = Color(0xFF0F172A); // Deepest Blue
  static const Color deepSpace = Color(0xFF020617);    // Nearly Black
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A), // Midnight Blue
      Color(0xFF020617), // Deep Space
    ],
  );

  // Glassmorphism
  static Color glassSurface = const Color(0xFFFFFFFF).withOpacity(0.03); // Very transparent white
  static Color glassBorder = const Color(0xFFFFFFFF).withOpacity(0.15);  // Subtle white border
  static const double glassBlur = 10.0;

  // Accents (Neon)
  static const Color cyanNeon = Color(0xFF00E5FF);     // Bright Cyan
  static const Color goldNeon = Color(0xFFFFD700);     // Bright Gold
  static const Color purpleNeon = Color(0xFFD500F9);   // Bright Purple
  static const Color emeraldNeon = Color(0xFF00E676);  // Bright Green

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textDisabled = Colors.white30;

  // Shadows
  static List<BoxShadow> neonShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.15),
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];
}
