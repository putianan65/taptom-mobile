import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';
import 'tokens.dart';
import 'typography.dart';

/// Builds the light and dark [ThemeData] from the palette and type scale.
abstract final class AppTheme {
  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final text = AppTypeScale.textTheme(p.ink, p.inkMuted);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.brand,
      onPrimary: p.onBrand,
      primaryContainer: p.brandSoft,
      onPrimaryContainer: p.brandStrong,
      secondary: p.accent,
      onSecondary: p.inkInverse,
      secondaryContainer: p.accentSoft,
      onSecondaryContainer: p.ink,
      tertiary: p.info,
      onTertiary: p.inkInverse,
      error: p.danger,
      onError: isDark ? p.inkInverse : Colors.white,
      errorContainer: p.dangerSoft,
      onErrorContainer: p.danger,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.inkMuted,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceMuted,
      surfaceContainerHigh: p.surfaceSunken,
      surfaceContainerHighest: p.surfaceSunken,
      outline: p.lineStrong,
      outlineVariant: p.line,
      shadow: p.shadow,
      scrim: p.scrim,
      inverseSurface: p.ink,
      onInverseSurface: p.inkInverse,
      inversePrimary: p.brandSoft,
    );

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: Radii.control,
          borderSide: BorderSide(color: c, width: w),
        );

    const buttonShape = WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: Radii.control),
    );
    const buttonPadding = WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );
    final buttonText = WidgetStatePropertyAll<TextStyle?>(text.labelLarge);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [p],
      fontFamily: AppFonts.text,
      textTheme: text,
      primaryTextTheme: text,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SoftRisePageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: SoftRisePageTransitionsBuilder(),
          TargetPlatform.windows: SoftRisePageTransitionsBuilder(),
          TargetPlatform.fuchsia: SoftRisePageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: Space.sm,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: p.ink, size: 22),
        actionsIconTheme: IconThemeData(color: p.ink, size: 22),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.card,
          side: BorderSide(color: p.line),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.inkMuted, size: 22),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: buttonText,
          minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? p.surfaceSunken : p.brand),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? p.inkSubtle : p.onBrand),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: buttonText,
          minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? p.surfaceSunken : p.brand),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? p.inkSubtle : p.onBrand),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          padding: buttonPadding,
          textStyle: buttonText,
          minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
          foregroundColor: WidgetStatePropertyAll(p.ink),
          side: WidgetStatePropertyAll(BorderSide(color: p.lineStrong)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          textStyle: buttonText,
          foregroundColor: WidgetStatePropertyAll(p.brand),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(p.ink),
          minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.brand,
        foregroundColor: p.onBrand,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: Radii.control),
        extendedTextStyle: text.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceSunken,
        isDense: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(p.brand, 1.6),
        errorBorder: border(p.danger),
        focusedErrorBorder: border(p.danger, 1.6),
        disabledBorder: border(Colors.transparent),
        labelStyle: text.bodyMedium?.copyWith(color: p.inkMuted),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: p.brand),
        hintStyle: text.bodyMedium?.copyWith(color: p.inkSubtle),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: p.danger),
        prefixIconColor: p.inkSubtle,
        suffixIconColor: p.inkSubtle,
        iconColor: p.inkSubtle,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.brandSoft,
        disabledColor: p.surfaceSunken,
        side: BorderSide(color: p.line),
        labelStyle: text.labelMedium?.copyWith(color: p.ink),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: p.brandStrong),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.card),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.inkMuted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: p.lineStrong,
        dragHandleSize: const Size(40, 4),
        shape: const RoundedRectangleBorder(borderRadius: Radii.sheet),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? p.surfaceSunken : p.ink,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: isDark ? p.ink : p.inkInverse,
        ),
        actionTextColor: isDark ? p.brand : Swatch.green200,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.control),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.inkMuted,
        textColor: p.ink,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 12,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.onBrand : p.surface),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.brand : p.lineStrong),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.brand : Colors.transparent),
        checkColor: WidgetStatePropertyAll(p.onBrand),
        side: BorderSide(color: p.lineStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.brand : p.lineStrong),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.brand,
        linearTrackColor: p.surfaceSunken,
        circularTrackColor: p.surfaceSunken,
        linearMinHeight: 6,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.ink,
        unselectedLabelColor: p.inkSubtle,
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: p.brand,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: p.line,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.ink,
          borderRadius: BorderRadius.circular(Radii.xs),
        ),
        textStyle: text.labelMedium?.copyWith(color: p.inkInverse),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: p.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.control,
          side: BorderSide(color: p.line),
        ),
        textStyle: text.bodyMedium,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.hero,
        headerForegroundColor: p.heroInk,
        shape: const RoundedRectangleBorder(borderRadius: Radii.card),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.brand,
        selectionColor: p.brand.withValues(alpha: 0.25),
        selectionHandleColor: p.brand,
      ),
    );
  }
}

/// Default page transition on Android and desktop: the incoming page rises a
/// few pixels while fading in, the outgoing page dims slightly. Calmer than
/// the stock zoom and consistent across platforms.
class SoftRisePageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftRisePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: Motion.emphasized,
      reverseCurve: Motion.exit,
    );
    final exit = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Motion.standard,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.92).animate(exit),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(enter),
        child: FadeTransition(opacity: enter, child: child),
      ),
    );
  }
}
