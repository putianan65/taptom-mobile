import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taptom/core/utils/map_styles.dart';

void main() {
  test('web imagery style mirrors the inline style', () {
    final file = File('web/map-styles/imagery.json');
    expect(file.existsSync(), isTrue);
    expect(jsonDecode(file.readAsStringSync()), MapStyles.imagery);
  });

  test('status colours match the fill hex codes', () {
    expect(MapStyles.colorFor('PENDING').toARGB32(), 0xFFC8931F);
    expect(MapStyles.colorFor('APPROVED').toARGB32(), 0xFF2F7041);
  });
}
