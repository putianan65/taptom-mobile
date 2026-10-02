import 'package:flutter/widgets.dart';

import '../../core/design/app_icons.dart';

/// The seven GAP record categories, in the order of the official form.
enum GapCategory {
  general('1.1', 'ข้อมูลทั่วไป', 'ผู้ปลูก พันธุ์ แหล่งน้ำ ระบบการปลูก', AppIcons.document),
  inputs('1.2', 'ปัจจัยการผลิต', 'ปุ๋ย สารเคมี และวัสดุที่ใช้', AppIcons.inputs),
  management('1.3', 'การจัดการแปลง', 'กิจกรรมในแปลงตลอดรอบปลูก', AppIcons.fieldWork),
  harvest('1.4', 'การเก็บเกี่ยว', 'วันที่ ปริมาณ และคุณภาพผลผลิต', AppIcons.harvest),
  postHarvest('1.5', 'หลังการเก็บเกี่ยว', 'คัดแยก ทำแห้ง บรรจุ และเก็บรักษา', AppIcons.postHarvest),
  safety('1.6', 'สุขอนามัยและความปลอดภัย', 'การอบรมและอุปกรณ์ป้องกันของแรงงาน', AppIcons.safety),
  traceability('1.7', 'การตรวจสอบย้อนกลับ', 'ออกเลขล็อตและ QR สำหรับผู้ซื้อ', AppIcons.qr);

  const GapCategory(this.code, this.title, this.description, this.icon);

  final String code;
  final String title;
  final String description;
  final IconData icon;
}

/// Snapshot of what a plot has recorded so far.
class GapProgress {
  const GapProgress({
    required this.general,
    required this.inputs,
    required this.activities,
    required this.harvests,
    required this.postHarvests,
    required this.trainings,
    required this.lots,
  });

  final Map<String, dynamic>? general;
  final List<dynamic> inputs;
  final List<dynamic> activities;
  final List<dynamic> harvests;
  final List<dynamic> postHarvests;
  final List<dynamic> trainings;
  final List<dynamic> lots;

  static const empty = GapProgress(
    general: null,
    inputs: [],
    activities: [],
    harvests: [],
    postHarvests: [],
    trainings: [],
    lots: [],
  );

  bool isDone(GapCategory c) => switch (c) {
        GapCategory.general => general != null && general!.isNotEmpty,
        GapCategory.inputs => inputs.isNotEmpty,
        GapCategory.management => activities.isNotEmpty,
        GapCategory.harvest => harvests.isNotEmpty,
        GapCategory.postHarvest => postHarvests.isNotEmpty,
        GapCategory.safety => trainings.isNotEmpty,
        GapCategory.traceability => lots.isNotEmpty || harvests.any(_hasLot),
      };

  static bool _hasLot(dynamic h) =>
      h is Map && (h['lotNumber'] ?? h['lot'] ?? '').toString().isNotEmpty;

  int count(GapCategory c) => switch (c) {
        GapCategory.general => isDone(c) ? 1 : 0,
        GapCategory.inputs => inputs.length,
        GapCategory.management => activities.length,
        GapCategory.harvest => harvests.length,
        GapCategory.postHarvest => postHarvests.length,
        GapCategory.safety => trainings.length,
        GapCategory.traceability => lots.isNotEmpty ? lots.length : harvests.where(_hasLot).length,
      };

  int get completed => GapCategory.values.where(isDone).length;
  double get ratio => completed / GapCategory.values.length;
  bool get isComplete => completed == GapCategory.values.length;

  /// First category still missing, the natural next step.
  GapCategory? get next {
    for (final c in GapCategory.values) {
      if (!isDone(c)) return c;
    }
    return null;
  }

  /// Most recent update across all records.
  DateTime? get lastUpdated {
    DateTime? latest;
    void consider(dynamic v) {
      if (v is! Map) return;
      final raw = v['updatedAt'] ?? v['createdAt'];
      final d = raw == null ? null : DateTime.tryParse(raw.toString());
      if (d != null && (latest == null || d.isAfter(latest!))) latest = d;
    }

    consider(general);
    for (final list in [inputs, activities, harvests, postHarvests, trainings, lots]) {
      list.forEach(consider);
    }
    return latest;
  }

  /// The records behind a list category. Traceability prefers issued lots
  /// and falls back to harvests that carry a lot number.
  List<dynamic> items(GapCategory c) => switch (c) {
        GapCategory.general => general == null ? const [] : [general],
        GapCategory.inputs => inputs,
        GapCategory.management => activities,
        GapCategory.harvest => harvests,
        GapCategory.postHarvest => postHarvests,
        GapCategory.safety => trainings,
        GapCategory.traceability => lots.isNotEmpty ? lots : harvests.where(_hasLot).toList(),
      };

  /// The shape the PDF report expects: one entry per category key with the
  /// raw records under 'data', or null when the category is empty.
  Map<String, dynamic> reportSummary() => {
        for (final c in GapCategory.values)
          c.name: isDone(c)
              ? {
                  'completed': true,
                  'count': count(c),
                  'data': c == GapCategory.general ? general : items(c),
                }
              : null,
      };
}
