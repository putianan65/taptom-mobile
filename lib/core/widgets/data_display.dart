import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../design/design.dart';
import 'pressable.dart';

/// Animates a number from its previous value to [value].
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    this.style,
    this.decimals = 0,
    this.suffix = '',
    this.duration = Motion.slower,
  });

  final num value;
  final TextStyle? style;
  final int decimals;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.decimalPatternDigits(
      locale: 'th',
      decimalDigits: decimals,
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: context.reduceMotion ? Duration.zero : duration,
      curve: Motion.emphasized,
      builder: (context, v, _) => Text(
        '${format.format(v)}$suffix',
        style: (style ?? context.text.headlineMedium)?.tabular,
      ),
    );
  }
}

/// Number with a label, used in stat strips. Tappable tiles act as filters.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.tone = Tone.neutral,
    this.onTap,
    this.selected = false,
    this.suffix = '',
    this.dense = false,
  });

  final num value;
  final String label;
  final IconData? icon;
  final Tone tone;
  final VoidCallback? onTap;
  final bool selected;
  final String suffix;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = tone == Tone.neutral ? p.ink : p.toneColor(tone);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.standard,
        padding: EdgeInsets.all(dense ? Space.md : Space.lg),
        decoration: BoxDecoration(
          color: selected ? p.toneSoft(tone == Tone.neutral ? Tone.brand : tone) : p.surface,
          borderRadius: Radii.card,
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.45) : p.line,
          ),
        ),
        child: dense ? _dense(context, accent) : _regular(context, accent),
      ),
    );
  }

  TextStyle? _valueStyle(BuildContext context, Color accent) =>
      (dense ? context.text.headlineSmall : context.text.headlineMedium)?.copyWith(
        fontFamily: AppFonts.text,
        fontWeight: FontWeight.w600,
        color: accent,
        height: 1.1,
      );

  Widget _regular(BuildContext context, Color accent) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: tone == Tone.neutral ? p.inkSubtle : accent),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label,
                style: context.text.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        CountUpText(value: value, suffix: suffix, style: _valueStyle(context, accent)),
      ],
    );
  }

  /// Compact tiles put the number first and give the label the full width,
  /// so three tiles fit a 360px phone without truncating Thai labels.
  Widget _dense(BuildContext context, Color accent) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: CountUpText(value: value, suffix: suffix, style: _valueStyle(context, accent)),
            ),
            if (icon != null)
              Icon(icon, size: 18, color: tone == Tone.neutral ? p.inkSubtle : accent),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: context.text.labelMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Circular progress with an animated sweep and centred label.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 72,
    this.stroke = 7,
    this.color,
    this.trackColor,
    this.child,
  });

  /// 0..1
  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1).toDouble()),
      duration: context.reduceMotion ? Duration.zero : Motion.slower,
      curve: Motion.emphasized,
      builder: (context, v, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            value: v,
            stroke: stroke,
            color: color ?? p.brand,
            track: trackColor ?? p.surfaceSunken,
          ),
          child: Center(
            child: child ??
                Text(
                  '${(v * 100).round()}%',
                  style: context.text.titleSmall?.tabular,
                ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.color,
    required this.track,
  });

  final double value;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Thin linear progress bar with rounded ends and animated fill.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
  });

  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0, 1).toDouble()),
          duration: context.reduceMotion ? Duration.zero : Motion.slow,
          curve: Motion.emphasized,
          builder: (context, v, _) => Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: p.surfaceSunken)),
              FractionallySizedBox(
                widthFactor: v,
                child: ColoredBox(color: color ?? p.brand),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Initials on a tinted circle, or a network photo when available.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.photoUrl,
    this.tone = Tone.brand,
  });

  final String name;
  final double size;
  final String? photoUrl;
  final Tone tone;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    if (parts.isEmpty) return '?';
    final chars = parts.take(2).map((s) => String.fromCharCode(s.runes.first));
    return chars.join();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.toneSoft(tone),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials,
        style: TextStyle(
          fontFamily: AppFonts.text,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.36,
          color: p.toneColor(tone),
          height: 1,
        ),
      ),
    );
    final url = photoUrl;
    if (url == null || url.isEmpty) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

/// Segmented control with an animated indicator. Works for filters and
/// small tab sets.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final List<(T, String)> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final index = segments.indexWhere((s) => s.$1 == value);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final segWidth = (width - 8) / segments.length;
        return Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: p.surfaceSunken,
            borderRadius: Radii.control,
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: context.reduceMotion ? Duration.zero : Motion.base,
                curve: Motion.emphasized,
                left: segWidth * (index < 0 ? 0 : index),
                top: 0,
                bottom: 0,
                width: segWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    boxShadow: [
                      BoxShadow(
                        color: p.shadow,
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final s in segments)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (s.$1 == value) return;
                          HapticFeedback.selectionClick();
                          onChanged(s.$1);
                        },
                        child: Semantics(
                          selected: s.$1 == value,
                          button: true,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: Motion.quick,
                              style: context.text.labelLarge!.copyWith(
                                fontSize: 14,
                                color: s.$1 == value ? p.ink : p.inkSubtle,
                                fontWeight: s.$1 == value
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                              child: Text(
                                s.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Horizontally scrolling filter chips with a count.
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.padding = EdgeInsets.zero,
  });

  /// (value, label, optional count)
  final List<(T, String, int?)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final o in options) ...[
            Pressable(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: Motion.quick,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: o.$1 == value ? p.ink : p.surface,
                  borderRadius: Radii.chip,
                  border: Border.all(color: o.$1 == value ? p.ink : p.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      o.$2,
                      style: context.text.labelLarge?.copyWith(
                        fontSize: 14,
                        color: o.$1 == value ? p.inkInverse : p.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (o.$3 != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${o.$3}',
                        style: context.text.labelMedium?.copyWith(
                          color: o.$1 == value
                              ? p.inkInverse.withValues(alpha: 0.7)
                              : p.inkSubtle,
                        ).tabular,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: Space.sm),
          ],
        ],
      ),
    );
  }
}
