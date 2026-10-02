import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/design.dart';

/// The TAPTOM mark: a kratom leaf with a rice-gold sun on a leaf-green tile.
/// Mirrors `assets/brand/logo-mark.svg`, which generates the launcher icons.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 56, this.tile = true});

  final double size;

  /// Draw the rounded green tile behind the leaf.
  final bool tile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'TAPTOM',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _LogoPainter(tile: tile)),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.tile});

  final bool tile;

  static const _green = Swatch.green700;
  static const _cream = Color(0xFFF3EEDC);
  static const _sun = Color(0xFFE3B34C);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas
      ..save()
      ..scale(s);

    if (tile) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 100, 100),
          const Radius.circular(24),
        ),
        Paint()..color = _green,
      );
    }
    canvas.drawCircle(const Offset(27, 27), 7, Paint()..color = _sun);

    canvas
      ..save()
      ..translate(50, 52)
      ..rotate(38 * math.pi / 180);

    final leaf = Path()
      ..moveTo(0, 33)
      ..cubicTo(17, 29, 26, 11, 24, -5)
      ..cubicTo(22, -21, 9, -32, 0, -41)
      ..cubicTo(-9, -32, -22, -21, -24, -5)
      ..cubicTo(-26, 11, -17, 29, 0, 33)
      ..close();
    canvas
      ..drawPath(leaf, Paint()..color = _cream)
      ..drawLine(
        const Offset(0, 33),
        const Offset(0, 42),
        Paint()
          ..color = _cream
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round,
      );

    final vein = Paint()
      ..color = tile ? _green : Swatch.green700
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(0, 31),
      const Offset(0, -35),
      vein..strokeWidth = 2.6,
    );
    vein.strokeWidth = 2;
    const veins = [
      [20.0, 8.0, 17.0, 15.0, 8.0],
      [8.0, 9.0, 4.0, 17.0, -6.0],
      [-4.0, 8.0, -8.0, 14.0, -18.0],
      [-15.0, 6.0, -19.0, 9.0, -27.0],
    ];
    for (final v in veins) {
      for (final side in const [1.0, -1.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(0, v[0])
            ..quadraticBezierTo(v[1] * side, v[2], v[3] * side, v[4]),
          vein,
        );
      }
    }
    canvas
      ..restore()
      ..restore();
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.tile != tile;
}

/// Logo mark with the product name set in the display serif.
class Wordmark extends StatelessWidget {
  const Wordmark({
    super.key,
    this.markSize = 40,
    this.color,
    this.subtitle,
  });

  final double markSize;
  final Color? color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? context.palette.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMark(size: markSize),
        SizedBox(width: markSize * 0.3),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TAPTOM',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: markSize * 0.52,
                height: 1.05,
                letterSpacing: markSize * 0.03,
                color: ink,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: context.text.labelMedium?.copyWith(
                  color: ink.withValues(alpha: 0.72),
                  fontSize: math.max(11, markSize * 0.27),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
