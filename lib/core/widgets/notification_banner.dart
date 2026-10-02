import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/models/notification_model.dart';
import '../design/design.dart';
import '../utils/thai_date.dart';
import 'pressable.dart';

/// In-app banner for a notification that arrived while the app was open.
/// Swipe up to dismiss.
class NotificationBanner extends StatelessWidget {
  const NotificationBanner({
    super.key,
    required this.notification,
    required this.onDismiss,
    this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  static (IconData, Tone) visual(NotificationModel n) => switch (n.notificationType) {
        NotificationType.plotApproved ||
        NotificationType.userApproved ||
        NotificationType.gapApproved =>
          (AppIcons.checkCircle, Tone.success),
        NotificationType.plotRejected ||
        NotificationType.userRejected ||
        NotificationType.gapRejected =>
          (AppIcons.warningCircle, Tone.danger),
        NotificationType.plotCreated || NotificationType.gapSubmitted =>
          (AppIcons.clipboard, Tone.brand),
        NotificationType.recordEdited => (AppIcons.edit, Tone.info),
        NotificationType.systemAnnouncement || NotificationType.system =>
          (AppIcons.megaphone, Tone.warning),
        NotificationType.info => (AppIcons.bell, Tone.info),
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (icon, tone) = visual(notification);
    return Dismissible(
      key: ValueKey('banner_${notification.id}'),
      direction: DismissDirection.up,
      onDismissed: (_) => onDismiss(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Pressable(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: Radii.card,
              border: Border.all(color: p.line),
              boxShadow: [
                BoxShadow(color: p.shadow, blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.toneSoft(tone),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: p.toneColor(tone), size: 20),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall,
                      ),
                      if (notification.message != null)
                        Text(
                          notification.isRejection && notification.rejectionReason != null
                              ? 'เหตุผล: ${notification.rejectionReason}'
                              : notification.message!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.sm),
                Text(ThaiDate.relative(notification.createdAt), style: context.text.labelSmall),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: Motion.base).moveY(begin: -24, end: 0, curve: Motion.emphasized);
  }
}
