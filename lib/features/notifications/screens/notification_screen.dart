import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/notification_banner.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';

/// Notification centre: grouped by day, unread filter, swipe to delete.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().refresh();
    });
  }

  String _groupOf(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'วันนี้';
    if (diff == 1) return 'เมื่อวาน';
    if (diff < 7) return 'สัปดาห์นี้';
    return 'ก่อนหน้านี้';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final all = provider.notifications;
    final items = _unreadOnly ? all.where((n) => !n.isRead).toList() : all;

    final groups = <String, List<NotificationModel>>{};
    for (final n in items) {
      groups.putIfAbsent(_groupOf(n.createdAt.toLocal()), () => []).add(n);
    }

    return PageScaffold(
      title: 'การแจ้งเตือน',
      subtitle: provider.unreadCount > 0 ? 'ยังไม่ได้อ่าน ${provider.unreadCount} รายการ' : null,
      onRefresh: provider.refresh,
      actions: [
        if (provider.unreadCount > 0)
          TextButton(
            onPressed: provider.markAllAsRead,
            child: const Text('อ่านทั้งหมด'),
          ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: Space.lg),
            child: FilterChips<bool>(
              value: _unreadOnly,
              onChanged: (v) => setState(() => _unreadOnly = v),
              options: [
                (false, 'ทั้งหมด', all.length),
                (true, 'ยังไม่อ่าน', provider.unreadCount),
              ],
            ),
          ),
        ),
        if (provider.isLoading && all.isEmpty)
          const SliverToBoxAdapter(child: SkeletonList(count: 4, thumbnail: false))
        else if (items.isEmpty)
          SliverToBoxAdapter(
            child: AppCard(
              child: EmptyState(
                title: _unreadOnly ? 'อ่านครบทุกรายการแล้ว' : 'ยังไม่มีการแจ้งเตือน',
                message: 'ผลการตรวจแปลง การอนุมัติ และข่าวจากเจ้าหน้าที่จะแสดงที่นี่',
                mood: _unreadOnly ? MascotMood.joy : MascotMood.happy,
              ),
            ),
          )
        else
          for (final entry in groups.entries) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: Space.sm, bottom: Space.sm, left: 4),
                child: Text(entry.key, style: context.text.labelMedium),
              ),
            ),
            SliverList.separated(
              itemCount: entry.value.length,
              separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
              itemBuilder: (context, i) {
                final n = entry.value[i];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => provider.deleteNotification(n.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: Space.xl),
                    decoration: BoxDecoration(
                      color: context.palette.dangerSoft,
                      borderRadius: Radii.card,
                    ),
                    child: Icon(AppIcons.delete, color: context.palette.danger),
                  ),
                  child: _NotificationTile(
                    notification: n,
                    onTap: () => provider.markAsRead(n.id),
                  ).entrance(context, index: i),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: Space.lg)),
          ],
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = notification;
    final (icon, tone) = NotificationBanner.visual(n);
    final reason = n.isRejection ? n.rejectionReason : null;

    return AppCard(
      onTap: onTap,
      color: n.isRead ? p.surface : p.surfaceMuted,
      padding: const EdgeInsets.all(Space.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, tone: tone, size: 40),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(ThaiDate.relative(n.createdAt), style: context.text.labelSmall),
                  ],
                ),
                if ((n.message ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(n.message!, style: context.text.bodySmall),
                ],
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: Space.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Space.sm + 2),
                    decoration: BoxDecoration(
                      color: p.dangerSoft,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Text(
                      'เหตุผล: $reason',
                      style: context.text.bodySmall?.copyWith(color: p.ink),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!n.isRead) ...[
            const SizedBox(width: Space.sm),
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: p.brand, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}
