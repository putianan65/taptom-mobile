import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/legal_content.dart';
import '../../../core/constants/pdpa_content.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/widgets/widgets.dart';
import '../settings_provider.dart';
import 'content_display_screen.dart';

/// Device preferences: appearance, text size, notifications and storage,
/// plus the legal pages and app information.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _clearing = false;

  Future<void> _clearCache() async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'ล้างไฟล์ชั่วคราว?',
      message: 'รูปและแผนที่ที่เก็บไว้จะถูกโหลดใหม่เมื่อเปิดดู ข้อมูลที่บันทึกไว้จะไม่หายไป',
      confirmLabel: 'ล้าง',
      icon: AppIcons.broom,
    );
    if (!ok || !mounted) return;
    setState(() => _clearing = true);
    try {
      await CacheService().clearAllCache();
      if (mounted) AppToast.success(context, 'ล้างไฟล์ชั่วคราวแล้ว');
    } on Object catch (_) {
      if (mounted) AppToast.error(context, 'ล้างไฟล์ไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _rate(String version) async {
    final result = await showAppSheet<(int, String)>(
      context,
      title: 'ให้คะแนน TAPTOM',
      subtitle: 'ความเห็นของคุณช่วยให้เราปรับปรุงแอป',
      child: const _RatingSheet(),
    );
    if (result == null || !mounted) return;
    try {
      await FeedbackService().submitRating(
        rating: result.$1,
        feedback: result.$2,
        appVersion: version,
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      );
      if (mounted) AppToast.success(context, 'ขอบคุณสำหรับคะแนน');
    } on Object catch (_) {
      if (mounted) AppToast.error(context, 'ส่งคะแนนไม่สำเร็จ ลองใหม่ภายหลัง');
    }
  }

  void _read(String title, String body) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ContentDisplayScreen(title: title, content: body)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();

    return PageScaffold(
      title: 'ตั้งค่า',
      slivers: [
        SliverToBoxAdapter(
          child: ContentWidth(
            maxWidth: Breakpoints.maxForm + 80,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(title: 'การแสดงผล'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FieldLabel('ธีม'),
                      SegmentedTabs<ThemeMode>(
                        value: s.themeMode,
                        onChanged: s.setThemeMode,
                        segments: const [
                          (ThemeMode.system, 'ตามเครื่อง'),
                          (ThemeMode.light, 'สว่าง'),
                          (ThemeMode.dark, 'มืด'),
                        ],
                      ),
                      const SizedBox(height: Space.xl),
                      const FieldLabel('ขนาดตัวอักษร'),
                      SegmentedTabs<double>(
                        value: SettingsProvider.textScales
                            .map((e) => e.$1)
                            .reduce((a, b) => (a - s.textScale).abs() < (b - s.textScale).abs() ? a : b),
                        onChanged: s.setTextScale,
                        segments: SettingsProvider.textScales,
                      ),
                      const SizedBox(height: Space.md),
                      Text(
                        'ตัวอย่าง: บันทึกการเก็บเกี่ยวใบกระท่อม 12 กิโลกรัม',
                        style: context.text.bodyMedium,
                      ),
                    ],
                  ),
                ).entrance(context),
                const SizedBox(height: Space.xxl),
                const SectionHeader(title: 'ทั่วไป'),
                ListGroup(
                  children: [
                    ListRow(
                      icon: AppIcons.bell,
                      title: 'การแจ้งเตือน',
                      subtitle: 'ผลการตรวจ การอนุมัติ และข่าวจากเจ้าหน้าที่',
                      showChevron: false,
                      trailing: Switch(
                        value: s.notificationsEnabled,
                        onChanged: (v) async {
                          final ok = await s.toggleNotifications(v);
                          if (!ok && context.mounted) {
                            AppToast.error(context, 'เปิดสิทธิ์การแจ้งเตือนในการตั้งค่าเครื่องก่อน');
                          }
                        },
                      ),
                    ),
                    ListRow(
                      icon: AppIcons.broom,
                      title: 'ล้างไฟล์ชั่วคราว',
                      subtitle: 'คืนพื้นที่เก็บข้อมูลในเครื่อง',
                      trailing: _clearing
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : null,
                      onTap: _clearing ? null : _clearCache,
                    ),
                  ],
                ).entrance(context, index: 1),
                const SizedBox(height: Space.xxl),
                const SectionHeader(title: 'ข้อกำหนด'),
                ListGroup(
                  children: [
                    ListRow(
                      icon: AppIcons.terms,
                      title: 'ข้อกำหนดการใช้งาน',
                      onTap: () => _read(TermsContent.title, TermsContent.body),
                    ),
                    ListRow(
                      icon: AppIcons.privacy,
                      title: 'นโยบายคุ้มครองข้อมูลส่วนบุคคล',
                      onTap: () => _read(PdpaContent.title, '${PdpaContent.fullContent}\n\n${PdpaContent.references}'),
                    ),
                  ],
                ).entrance(context, index: 2),
                const SizedBox(height: Space.xxl),
                const SectionHeader(title: 'เกี่ยวกับ'),
                ListGroup(
                  children: [
                    KeyValueRow(label: 'แอป', value: 'TAPTOM'),
                    KeyValueRow(label: 'เวอร์ชัน', value: s.version.isEmpty ? '-' : s.version, mono: true),
                    ListRow(icon: AppIcons.star, title: 'ให้คะแนนแอป', onTap: () => _rate(s.version)),
                  ],
                ).entrance(context, index: 3),
                const SizedBox(height: Space.xxl),
                Center(
                  child: Column(
                    children: [
                      const LogoMark(size: 36),
                      const SizedBox(height: Space.sm),
                      Text(
                        'ระบบบันทึกข้อมูล GAP กระท่อม',
                        style: context.text.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet();

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _stars = 0;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.xl,
        0,
        Space.xl,
        Space.xl + MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 36,
                  tooltip: '$i ดาว',
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(
                    i <= _stars ? AppIcons.starFill : AppIcons.star,
                    color: i <= _stars ? p.accent : p.lineStrong,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          AppTextField(controller: _note, hint: 'อยากให้ปรับปรุงอะไร (ไม่บังคับ)', maxLines: 4, minLines: 2),
          const SizedBox(height: Space.xl),
          AppButton(
            label: 'ส่งคะแนน',
            expand: true,
            onPressed: _stars == 0 ? null : () => Navigator.of(context).pop((_stars, _note.text.trim())),
          ),
        ],
      ),
    );
  }
}
