import 'package:flutter/material.dart';

import 'palette.dart';
import 'tokens.dart';

extension DesignContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  TextTheme get text => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// True when the user asked the platform to reduce motion.
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;

  WindowSize get windowSize => Breakpoints.of(MediaQuery.sizeOf(this).width);

  bool get isCompact => windowSize == WindowSize.compact;

  /// Horizontal padding that grows with the window so content stays centred
  /// and readable on tablets and the web. Inside a page beside a navigation
  /// rail, prefer [Breakpoints.gutterFor] on the layout width.
  double get pageGutter => Breakpoints.gutterFor(MediaQuery.sizeOf(this).width);
}
