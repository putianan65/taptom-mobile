import 'package:maplibre_gl/maplibre_gl.dart';

class GeoJsonUtils {
  /// Convert List of LatLng to GeoJSON Polygon Map
  static Map<String, dynamic> toPolygon(List<LatLng> points) {
    if (points.isEmpty) return {};

    // GeoJSON requires the first and last point to be the same to close the polygon
    final coordinates = points.map((p) => [p.longitude, p.latitude]).toList();

    if (points.first != points.last) {
      coordinates.add([points.first.longitude, points.first.latitude]);
    }

    return {
      'type': 'Polygon',
      'coordinates': [coordinates],
    };
  }

  /// Convert GeoJSON Map to List of LatLng
  static List<LatLng> fromPolygon(Map<String, dynamic> geoJson) {
    try {
      final coordinates = (geoJson['coordinates'] as List)[0] as List;
      return coordinates
          .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
