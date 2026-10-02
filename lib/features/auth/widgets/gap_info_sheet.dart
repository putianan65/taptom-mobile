import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// Explains GAP and why it matters for controlled kratom cultivation.
Future<void> showGapInfoSheet(BuildContext context) {
  return showAppSheet<void>(
    context,
    title: 'มาตรฐาน GAP คืออะไร',
    subtitle: 'Good Agricultural Practices',
    child: const _GapInfo(),
  );
}

class _GapInfo extends StatelessWidget {
  const _GapInfo();

  static const _pillars = [
    (AppIcons.shield, 'ผู้บริโภคปลอดภัย', 'ไม่มีสารตกค้างเกินมาตรฐาน'),
    (AppIcons.safety, 'เกษตรกรปลอดภัย', 'ใช้สารเคมีอย่างถูกวิธีและมีอุปกรณ์ป้องกัน'),
    (AppIcons.leaf, 'เป็นมิตรต่อสิ่งแวดล้อม', 'ดูแลดินและแหล่งน้ำอย่างยั่งยืน'),
    (AppIcons.qr, 'ตรวจสอบย้อนกลับได้', 'ทุกล็อตบอกได้ว่ามาจากแปลงไหน'),
  ];

  static const _kratom = [
    ('ข้อกำหนดทางกฎหมาย', 'ผู้ปลูกกระท่อมต้องมีบันทึกตามมาตรฐานเพื่อประกอบการขออนุญาต'),
    ('ควบคุมคุณภาพ', 'ติดตามสารสำคัญ (Mitragynine) และป้องกันการปนเปื้อนโลหะหนัก'),
    ('ป้องกันการใช้ผิดวัตถุประสงค์', 'มีบันทึกการผลิตและเส้นทางผลผลิตที่ชัดเจน'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.sm, Space.xl, Space.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'มาตรฐานการปฏิบัติทางการเกษตรที่ดี เป็นระบบการผลิตที่ได้ผลผลิตปลอดภัยและมีคุณภาพ โดยคำนึงถึง 4 ด้าน',
            style: context.text.bodyMedium?.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Space.lg),
          AdaptiveGrid(
            minTileWidth: 150,
            children: [
              for (final pillar in _pillars)
                AppCard(
                  padding: const EdgeInsets.all(Space.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconTile(icon: pillar.$1, size: 36),
                      const SizedBox(height: Space.sm),
                      Text(pillar.$2, style: context.text.titleSmall),
                      Text(pillar.$3, style: context.text.bodySmall),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.xxl),
          Text('สำคัญอย่างไรกับการปลูกกระท่อม', style: context.text.headlineSmall),
          const SizedBox(height: Space.md),
          for (var i = 0; i < _kratom.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.brandSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: context.text.labelMedium?.copyWith(
                        color: p.brandStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_kratom[i].$1, style: context.text.titleSmall),
                        Text(_kratom[i].$2, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
