import 'package:flutter_test/flutter_test.dart';
import 'package:taptom/features/traceability/screens/qr_scanner_screen.dart';

void main() {
  test('reads a bare lot code', () {
    expect(QrScannerScreen.lotFrom(' TPT-2568-0042 '), 'TPT-2568-0042');
  });

  test('reads the lot from a traceability link', () {
    expect(QrScannerScreen.lotFrom('https://taptom.app/traceability/TPT-2568-0042?ref=box'), 'TPT-2568-0042');
  });

  test('rejects free text', () {
    expect(QrScannerScreen.lotFrom('hello world'), isNull);
    expect(QrScannerScreen.lotFrom('https://taptom.app/traceability/'), isNull);
  });
}
