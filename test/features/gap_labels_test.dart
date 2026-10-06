import 'package:flutter_test/flutter_test.dart';
import 'package:taptom/features/gap/gap_categories.dart';
import 'package:taptom/features/gap/gap_labels.dart';

void main() {
  test('enum codes become Thai labels', () {
    expect(GapLabels.value('waterSource', 'GROUNDWATER'), 'น้ำบาดาล');
    expect(GapLabels.value('farmingSystem', 'organic'), 'เกษตรอินทรีย์');
    expect(GapLabels.value('anything', null), '-');
    expect(GapLabels.value('x', ['KG', 'LITER']), 'กก., ลิตร');
  });

  test('unknown values pass through untouched', () {
    expect(GapLabels.value('cropVariety', 'ก้านแดง'), 'ก้านแดง');
  });

  test('general info skips empty fields and falls back to the plot name', () {
    final rows = GapLabels.general({'waterSource': 'POND', 'soilType': null}, plotName: 'แปลงทดลอง');
    expect(rows, contains(('ชื่อแปลง', 'แปลงทดลอง')));
    expect(rows, contains(('แหล่งน้ำ', 'สระน้ำ')));
    expect(rows.any((r) => r.$1 == 'ชนิดดิน'), isFalse);
  });

  test('harvest entries read amount, unit and lot', () {
    final e = GapLabels.entry(
      GapCategory.traceability,
      {'yieldAmount': 120, 'yieldUnit': 'KG', 'lotNumber': 'TPT-2568-0042'},
      0,
    );
    expect(e.title, 'TPT-2568-0042');
    expect(e.fields, contains(('ปริมาณ', '120 กก.')));
  });

  test('summary counts records', () {
    const p = GapProgress(
      general: null,
      inputs: [{}, {}],
      activities: [],
      harvests: [],
      postHarvests: [],
      trainings: [],
      lots: [],
    );
    expect(GapLabels.summary(GapCategory.inputs, p), '2 รายการ');
    expect(GapLabels.summary(GapCategory.harvest, p), 'ยังไม่มีบันทึก');
  });
}
