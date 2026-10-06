import 'package:flutter_test/flutter_test.dart';
import 'package:taptom/core/utils/thai_date.dart';

void main() {
  group('ThaiDate.parseParts', () {
    test('accepts Buddhist-era years', () {
      expect(ThaiDate.parseParts('15', '01', '2540'), DateTime(1997, 1, 15));
    });

    test('accepts Gregorian years', () {
      expect(ThaiDate.parseParts('5', '7', '1990'), DateTime(1990, 7, 5));
    });

    test('rejects impossible and future dates', () {
      expect(ThaiDate.parseParts('31', '02', '2540'), isNull);
      expect(ThaiDate.parseParts('1', '13', '2540'), isNull);
      expect(ThaiDate.parseParts('', '1', '2540'), isNull);
      final nextYear = DateTime.now().year + 544;
      expect(ThaiDate.parseParts('1', '1', '$nextYear'), isNull);
    });
  });

  test('toIso pads month and day', () {
    expect(ThaiDate.toIso(DateTime(1997, 1, 5)), '1997-01-05');
  });

  test('short formats in the Buddhist era', () {
    expect(ThaiDate.short(DateTime(2026, 3, 9)), '9 มี.ค. 2569');
  });

  test('relative describes recent times', () {
    final now = DateTime(2026, 10, 2, 12);
    expect(ThaiDate.relative(now.subtract(const Duration(seconds: 20)), now: now), 'เมื่อสักครู่');
    expect(ThaiDate.relative(now.subtract(const Duration(minutes: 5)), now: now), '5 นาทีที่แล้ว');
    expect(ThaiDate.relative(now.subtract(const Duration(days: 1)), now: now), 'เมื่อวาน');
  });
}
