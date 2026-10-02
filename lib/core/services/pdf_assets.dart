import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Fonts and partner logos embedded in generated PDFs. Everything ships in
/// the app bundle so reports and certificates work offline.
abstract final class PdfAssets {
  static pw.Font? _regular;
  static pw.Font? _bold;
  static final Map<String, pw.MemoryImage?> _images = {};

  static Future<pw.Font> regular() async =>
      _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Sarabun-Regular.ttf'));

  static Future<pw.Font> bold() async =>
      _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Sarabun-Bold.ttf'));

  static Future<pw.MemoryImage?> _image(String path) async {
    if (_images.containsKey(path)) return _images[path];
    try {
      final data = await rootBundle.load(path);
      return _images[path] = pw.MemoryImage(data.buffer.asUint8List());
    } on Object catch (_) {
      return _images[path] = null;
    }
  }

  static Future<pw.MemoryImage?> gapMark() => _image('assets/images/partners/gap-mark.png');
  static Future<pw.MemoryImage?> oncbSeal() => _image('assets/images/partners/oncb-seal.png');
  static Future<pw.MemoryImage?> gistnu() => _image('assets/images/partners/gistnu.png');
}
