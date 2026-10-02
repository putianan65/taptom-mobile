import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';

/// GeoJSON conversion and land-area maths for plot boundaries.
class GeoJsonUtils {
  /// Closed GeoJSON Polygon from an open ring of points.
  static Map<String, dynamic> toPolygon(List<LatLng> points) {
    if (points.isEmpty) return {};
    final coordinates = [for (final p in points) [p.longitude, p.latitude]];
    if (points.first != points.last) {
      coordinates.add([points.first.longitude, points.first.latitude]);
    }
    return {
      'type': 'Polygon',
      'coordinates': [coordinates],
    };
  }

  /// Outer ring of a GeoJSON Polygon, without the closing point.
  static List<LatLng> fromPolygon(Map<String, dynamic> geoJson) {
    try {
      final ring = (geoJson['coordinates'] as List)[0] as List;
      final points = [
        for (final c in ring) LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
      if (points.length > 1 && points.first == points.last) points.removeLast();
      return points;
    } on Object catch (_) {
      return [];
    }
  }

  /// Area of a simple polygon in square metres. Projects onto a local
  /// equirectangular plane around the ring's mean latitude, which is
  /// accurate to well under one percent at farm-plot scale.
  static double areaSqm(List<LatLng> ring) {
    if (ring.length < 3) return 0;
    const r = 6371008.8;
    final lat0 = ring.map((p) => p.latitude).reduce((a, b) => a + b) / ring.length * math.pi / 180;
    final k = math.cos(lat0);
    double x(LatLng p) => p.longitude * math.pi / 180 * r * k;
    double y(LatLng p) => p.latitude * math.pi / 180 * r;
    var sum = 0.0;
    for (var i = 0; i < ring.length; i++) {
      final a = ring[i];
      final b = ring[(i + 1) % ring.length];
      sum += x(a) * y(b) - x(b) * y(a);
    }
    return sum.abs() / 2;
  }
}

/// Thai land units: 1 rai = 4 ngan = 400 square wah = 1,600 square metres.
class ThaiArea {
  const ThaiArea(this.rai, this.ngan, this.wah);

  factory ThaiArea.fromSqm(double sqm) {
    final wahTotal = sqm / 4;
    final rai = wahTotal ~/ 400;
    final ngan = (wahTotal - rai * 400) ~/ 100;
    final wah = (wahTotal - rai * 400 - ngan * 100).round();
    // Rounding can carry 100 square wah into the next ngan.
    if (wah == 100) return ngan == 3 ? ThaiArea(rai + 1, 0, 0) : ThaiArea(rai, ngan + 1, 0);
    return ThaiArea(rai, ngan, wah);
  }

  final int rai;
  final int ngan;
  final int wah;

  /// Decimal rai, as stored by the API.
  double get inRai => rai + ngan / 4 + wah / 400;

  @override
  String toString() => '$rai ไร่ $ngan งาน $wah ตร.ว.';
}
