import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:taptom/core/utils/geo_json_utils.dart';

void main() {
  // A square roughly 40 m on each side near Phitsanulok (1,600 sq m = 1 rai).
  const lat = 16.84;
  const dLat = 40 / 111195.0;
  final dLng = 40 / (111195.0 * 0.95711); // cos(16.84 deg)
  final square = [
    const LatLng(lat, 100.43),
    LatLng(lat, 100.43 + dLng),
    LatLng(lat + dLat, 100.43 + dLng),
    const LatLng(lat + dLat, 100.43),
  ];

  test('areaSqm is close to the true area of a small square', () {
    expect(GeoJsonUtils.areaSqm(square), closeTo(1600, 8));
  });

  test('areaSqm ignores degenerate rings', () {
    expect(GeoJsonUtils.areaSqm(square.take(2).toList()), 0);
  });

  test('ThaiArea splits square metres into rai, ngan and square wah', () {
    final a = ThaiArea.fromSqm(1600 * 2 + 400 * 3 + 4 * 25);
    expect((a.rai, a.ngan, a.wah), (2, 3, 25));
    expect(a.inRai, closeTo(2.8125, 1e-9));
  });

  test('ThaiArea carries rounding into the next unit', () {
    final a = ThaiArea.fromSqm(4 * 399.8);
    expect((a.rai, a.ngan, a.wah), (1, 0, 0));
  });

  test('polygon round trip drops the closing point', () {
    final geo = GeoJsonUtils.toPolygon(square);
    expect((geo['coordinates'] as List).first, hasLength(5));
    expect(GeoJsonUtils.fromPolygon(geo), hasLength(4));
  });
}
