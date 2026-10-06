import 'package:flutter_test/flutter_test.dart';
import 'package:taptom/features/auth/screens/set_pin_screen.dart';

void main() {
  group('weak PIN detection', () {
    test('rejects repeated digits', () {
      expect(PinRules.weak('000000'), isNotNull);
      expect(PinRules.weak('77777777'), isNotNull);
    });

    test('rejects straight runs', () {
      expect(PinRules.weak('123456'), isNotNull);
      expect(PinRules.weak('987654'), isNotNull);
    });

    test('accepts ordinary PINs', () {
      expect(PinRules.weak('482915'), isNull);
      expect(PinRules.weak('30570812'), isNull);
    });
  });
}
