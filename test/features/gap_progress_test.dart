import 'package:flutter_test/flutter_test.dart';
import 'package:taptom/features/gap/gap_categories.dart';

void main() {
  test('empty progress points to the first category', () {
    expect(GapProgress.empty.completed, 0);
    expect(GapProgress.empty.next, GapCategory.general);
    expect(GapProgress.empty.isComplete, isFalse);
  });

  test('counts completed categories and finds the next gap', () {
    const progress = GapProgress(
      general: {'farmerName': 'สมชาย'},
      inputs: [{'id': 'i1'}],
      activities: [],
      harvests: [{'id': 'h1', 'lotNumber': 'TPT-2569-0001'}],
      postHarvests: [],
      trainings: [],
      lots: [],
    );
    expect(progress.isDone(GapCategory.general), isTrue);
    expect(progress.isDone(GapCategory.management), isFalse);
    expect(progress.isDone(GapCategory.traceability), isTrue);
    expect(progress.completed, 4);
    expect(progress.next, GapCategory.management);
    expect(progress.ratio, closeTo(4 / 7, 1e-9));
  });

  test('latest update is taken across all record types', () {
    const progress = GapProgress(
      general: {'updatedAt': '2026-01-01T00:00:00Z'},
      inputs: [{'updatedAt': '2026-03-05T00:00:00Z'}],
      activities: [],
      harvests: [],
      postHarvests: [],
      trainings: [],
      lots: [],
    );
    expect(progress.lastUpdated, DateTime.parse('2026-03-05T00:00:00Z'));
  });
}
