import 'package:flutter/widgets.dart';

/// 4-point spacing scale.
abstract final class Space {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double x3 = 32;
  static const double x4 = 40;
  static const double x5 = 56;

  /// Horizontal page gutter on phones.
  static const double gutter = 20;
}

abstract final class Radii {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius control = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(xl));
}

/// Motion tokens. Durations are short; easing is decelerating so content
/// settles into place rather than bouncing.
abstract final class Motion {
  static const Duration instant = Duration(milliseconds: 90);
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 380);
  static const Duration slower = Duration(milliseconds: 560);

  /// Delay between items in a staggered list entrance.
  static const Duration stagger = Duration(milliseconds: 45);

  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve emphasized = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve exit = Cubic(0.3, 0.0, 0.8, 0.15);
}

/// Width breakpoints, following Material 3 window size classes.
enum WindowSize { compact, medium, expanded }

abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 1024;

  /// Readable content never stretches wider than this.
  static const double maxContent = 760;
  static const double maxForm = 520;

  /// Side padding that centres [maxWidth] of content in [width], never less
  /// than the phone gutter. Matches the left edge of ContentWidth.
  static double gutterFor(double width, {double maxWidth = maxContent}) {
    if (width <= maxWidth) return Space.gutter;
    return Space.gutter + (width - maxWidth) / 2;
  }

  static WindowSize of(double width) {
    if (width >= expanded) return WindowSize.expanded;
    if (width >= medium) return WindowSize.medium;
    return WindowSize.compact;
  }
}
