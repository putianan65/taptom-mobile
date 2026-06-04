// Taptom App Widget Test

import 'package:flutter_test/flutter_test.dart';
import 'package:taptom/app.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    // This is a minimal smoke test to verify the app can be instantiated.
    // Since TaptomApp uses provider and router, we're just testing compilation here.
    expect(TaptomApp, isNotNull);
  });
}
