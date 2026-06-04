import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../data/models/notification_model.dart';

/// In-app Notification Banner Widget
/// แสดง banner popup เมื่อมี notification ใหม่เข้ามา
class NotificationBanner extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const NotificationBanner({
    super.key,
    required this.notification,
    required this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRejection = notification.isRejection;
    final primaryColor = isRejection
        ? const Color(0xFFF44336) // Red for rejections
        : const Color(0xFF2196F3); // Blue for others

    return Dismissible(
      key: Key('banner_${notification.id}'),
      direction: DismissDirection.up,
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.15),
                          primaryColor.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: HeroIcon(
                      _getIcon(),
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: GoogleFonts.prompt(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.grey[900],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (notification.message != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            notification.message!,
                            style: GoogleFonts.prompt(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Dismiss
                  GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: HeroIcon(
                        HeroIcons.xMark,
                        color: Colors.grey[400],
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              // Rejection reason box
              if (isRejection && notification.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF44336).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HeroIcon(
                        HeroIcons.exclamationTriangle,
                        color: Color(0xFFF44336),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'เหตุผล: ${notification.rejectionReason}',
                          style: GoogleFonts.prompt(
                            fontSize: 11,
                            color: const Color(0xFFD32F2F),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  HeroIcons _getIcon() {
    switch (notification.notificationType) {
      case NotificationType.plotApproved:
      case NotificationType.gapApproved:
      case NotificationType.userApproved:
        return HeroIcons.checkCircle;
      case NotificationType.plotRejected:
      case NotificationType.gapRejected:
      case NotificationType.userRejected:
        return HeroIcons.xCircle;
      case NotificationType.plotCreated:
      case NotificationType.gapSubmitted:
        return HeroIcons.documentPlus;
      case NotificationType.recordEdited:
        return HeroIcons.pencilSquare;
      case NotificationType.systemAnnouncement:
        return HeroIcons.megaphone;
      default:
        return HeroIcons.bellAlert;
    }
  }
}
