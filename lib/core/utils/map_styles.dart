import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../config/env.dart';

/// Map styles used across the app.
///
/// With a MapTiler key the app uses MapTiler's hybrid style (imagery with
/// labels). Without one it falls back to a raster style over Esri World
/// Imagery, so maps never render blank in development or demos.
abstract final class MapStyles {
  static String get satellite {
    final key = Env.mapTilerApiKey;
    if (key.isNotEmpty) {
      return 'https://api.maptiler.com/maps/hybrid/style.json?key=$key';
    }
    // On the web the plugin turns an inline style into a prototype-less JS
    // object that MapLibre cannot pass to its worker, so the same style is
    // served as a file instead (web/map-styles/imagery.json).
    if (kIsWeb) return Uri.base.resolve('map-styles/imagery.json').toString();
    return jsonEncode(imagery);
  }

  /// Keyless imagery style. Mirrored in web/map-styles/imagery.json.
  static const Map<String, dynamic> imagery = {
    'version': 8,
    // Required by the plugin's symbol annotation layer, even when no labels
    // are drawn.
    'glyphs': 'https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf',
    'sources': {
      'imagery': {
        'type': 'raster',
        'tiles': [
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        ],
        'tileSize': 256,
        'maxzoom': 19,
        'attribution': 'Imagery © Esri, Maxar, Earthstar Geographics',
      },
    },
    'layers': [
      // Shown while tiles load, or when imagery is unreachable offline.
      {
        'id': 'ground',
        'type': 'background',
        'paint': {'background-color': '#22301F'},
      },
      {'id': 'imagery', 'type': 'raster', 'source': 'imagery'},
    ],
  };

  /// Default camera over central Thailand.
  static const thailand = CameraPosition(
    target: LatLng(15.87, 100.99),
    zoom: 5.4,
  );

  /// Brand colours for plot overlays, as hex strings MapLibre expects.
  static const plotFill = '#2F7041';
  static const plotLine = '#E9F2E4';
  static const pendingFill = '#C8931F';
  static const rejectedFill = '#C0553D';

  static String fillFor(String? status) => switch (status?.toUpperCase()) {
        'PENDING' => pendingFill,
        'REJECTED' => rejectedFill,
        _ => plotFill,
      };

  /// [fillFor] as a Flutter colour, for legends and chips.
  static Color colorFor(String? status) =>
      Color(int.parse('FF${fillFor(status).substring(1)}', radix: 16));
}
