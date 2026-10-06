import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../design/design.dart';

/// Draws a plot boundary as a small survey-style thumbnail: a faint grid,
/// the polygon and its corner pegs. Cheap enough for long lists, works
/// offline and avoids spinning up a native map view per row.
class PlotShape extends StatelessWidget {
  const PlotShape({
    super.key,
    required this.points,
    this.size = 64,
    this.color,
    this.background,
    this.showGrid = true,
    this.radius = Radii.sm,
  });

  final List<LatLng> points;
  final double size;
  final Color? color;
  final Color? background;
  final bool showGrid;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _PlotShapePainter(
            points: points,
            color: color ?? p.brand,
            background: background ?? p.surfaceMuted,
            grid: showGrid ? p.line : null,
          ),
        ),
      ),
    );
  }
}

class _PlotShapePainter extends CustomPainter {
  _PlotShapePainter({
    required this.points,
    required this.color,
    required this.background,
    required this.grid,
  });

  final List<LatLng> points;
  final Color color;
  final Color background;
  final Color? grid;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    if (grid != null) {
      final g = Paint()
        ..color = grid!
        ..strokeWidth = 1;
      final step = size.width / 4;
      for (var i = 1; i < 4; i++) {
        canvas
          ..drawLine(Offset(step * i, 0), Offset(step * i, size.height), g)
          ..drawLine(Offset(0, step * i), Offset(size.width, step * i), g);
      }
    }
    if (points.length < 3) {
      _placeholder(canvas, size);
      return;
    }

    var minLat = double.infinity, maxLat = -double.infinity;
    var minLng = double.infinity, maxLng = -double.infinity;
    for (final pt in points) {
      minLat = math.min(minLat, pt.latitude);
      maxLat = math.max(maxLat, pt.latitude);
      minLng = math.min(minLng, pt.longitude);
      maxLng = math.max(maxLng, pt.longitude);
    }
    // Longitude degrees shrink with latitude; correct so shapes keep their
    // real proportions.
    final k = math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final w = math.max((maxLng - minLng) * k, 1e-9);
    final h = math.max(maxLat - minLat, 1e-9);
    final pad = size.width * 0.16;
    final scale = math.min((size.width - pad * 2) / w, (size.height - pad * 2) / h);
    final ox = (size.width - w * scale) / 2;
    final oy = (size.height - h * scale) / 2;

    Offset project(LatLng pt) => Offset(
          ox + (pt.longitude - minLng) * k * scale,
          oy + (maxLat - pt.latitude) * scale,
        );

    final path = Path()..moveTo(project(points.first).dx, project(points.first).dy);
    for (final pt in points.skip(1)) {
      final o = project(pt);
      path.lineTo(o.dx, o.dy);
    }
    path.close();

    canvas
      ..drawPath(path, Paint()..color = color.withValues(alpha: 0.2))
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round,
      );
    final peg = Paint()..color = color;
    final ring = Paint()..color = background;
    final r = math.max(1.6, size.width / 40);
    for (final pt in points) {
      final o = project(pt);
      canvas
        ..drawCircle(o, r + 1, ring)
        ..drawCircle(o, r, peg);
    }
  }

  void _placeholder(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final r = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.5,
      height: size.height * 0.4,
    );
    final dash = Path()..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)));
    for (final metric in dash.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PlotShapePainter old) =>
      old.points != points || old.color != color || old.background != background;
}
