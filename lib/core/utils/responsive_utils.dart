import 'package:flutter/material.dart';

/// Responsive design utilities for scaling UI elements
class ResponsiveUtils {
  static late MediaQueryData _mediaQueryData;
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _blockSizeHorizontal;
  static late double _blockSizeVertical;
  static late double _textScaleFactor;

  /// Initialize with context (call once in main widget)
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    _screenWidth = _mediaQueryData.size.width;
    _screenHeight = _mediaQueryData.size.height;
    _blockSizeHorizontal = _screenWidth / 100;
    _blockSizeVertical = _screenHeight / 100;
    _textScaleFactor = _mediaQueryData.textScaleFactor;
  }

  /// Screen width
  static double get screenWidth => _screenWidth;

  /// Screen height
  static double get screenHeight => _screenHeight;

  /// Width percentage (e.g., wp(50) = 50% of screen width)
  static double wp(double percentage) => _blockSizeHorizontal * percentage;

  /// Height percentage (e.g., hp(50) = 50% of screen height)
  static double hp(double percentage) => _blockSizeVertical * percentage;

  /// Scaled pixel for fonts (maintains readability)
  static double sp(double size) {
    // Base design width (iPhone 14 Pro)
    const double baseWidth = 393.0;
    final double scaleFactor = _screenWidth / baseWidth;
    return size * scaleFactor.clamp(0.8, 1.3); // Limit scaling range
  }

  /// Check if device is tablet (width > 600)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  /// Check if device is large tablet (width > 900)
  static bool isLargeTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isLargeTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  /// Get responsive grid column count
  static int responsiveGridCount(BuildContext context) {
    if (isLargeTablet(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  /// Get responsive font size
  static double responsiveFontSize(BuildContext context, double baseSize) {
    if (isLargeTablet(context)) {
      return baseSize * 1.2;
    } else if (isTablet(context)) {
      return baseSize * 1.1;
    }
    return baseSize;
  }
}
