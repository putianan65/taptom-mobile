import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/admin_service.dart';
import '../../../data/models/notification_model.dart';
import '../../admin/widgets/user_detail_sheet.dart';

/// Notification List Screen
/// แสดงรายการแจ้งเตือนทั้งหมดของผู้ใช้
class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถโหลดการแจ้งเตือนได้',
              style: GoogleFonts.prompt(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      // Update local state
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      // Silent fail - user can retry
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      // Update local state
      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อ่านทั้งหมดแล้ว', style: GoogleFonts.prompt()),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถอ่านได้', style: GoogleFonts.prompt()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ลบการแจ้งเตือน',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณต้องการลบการแจ้งเตือนนี้?',
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: GoogleFonts.prompt()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('ลบ', style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _notificationService.deleteNotification(notificationId);
      // Update local state
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบสำเร็จ', style: GoogleFonts.prompt()),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถลบได้', style: GoogleFonts.prompt()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const HeroIcon(HeroIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'การแจ้งเตือน',
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount ยังไม่ได้อ่าน',
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const HeroIcon(
                HeroIcons.checkCircle,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                'อ่านทั้งหมด',
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const HeroIcon(HeroIcons.bell, size: 48, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีการแจ้งเตือน',
            style: GoogleFonts.prompt(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'คุณจะได้รับการแจ้งเตือนเมื่อมี\nข้อมูลสำคัญ',
            textAlign: TextAlign.center,
            style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final icon = _getNotificationIcon(notification.notificationType);
    final color = _getNotificationColor(notification.notificationType);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey[200]!
                : color.withOpacity(0.3),
          ),
        ),
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              _markAsRead(notification.id);
            }
            // Navigate based on notification type
            _handleNotificationTap(notification);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: HeroIcon(icon, color: color)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message ?? '',
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  HeroIcons _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.plotApproved:
      case NotificationType.userApproved:
        return HeroIcons.checkCircle;
      case NotificationType.plotRejected:
      case NotificationType.userRejected:
        return HeroIcons.xCircle;
      case NotificationType.gapApproved:
        return HeroIcons.documentCheck;
      case NotificationType.gapRejected:
        return HeroIcons.documentMinus;
      case NotificationType.system:
        return HeroIcons.informationCircle;
      default:
        return HeroIcons.bell;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.plotApproved:
      case NotificationType.userApproved:
      case NotificationType.gapApproved:
        return AppColors.success;
      case NotificationType.plotRejected:
      case NotificationType.userRejected:
      case NotificationType.gapRejected:
        return AppColors.error;
      case NotificationType.system:
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays} วันที่แล้ว';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ชั่วโมงที่แล้ว';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Navigate based on notification type
    switch (notification.notificationType) {
      case NotificationType.plotApproved:
      case NotificationType.plotRejected:
        // Navigate to plot detail
        if (notification.data?['plotId'] != null) {
          // context.push('/plots/${notification.data!['plotId']}');
        }
        break;
      case NotificationType.userApproved:
      case NotificationType.userRejected:
        // Show User Details Popup
        if (notification.data?['userId'] != null) {
          _showUserDetailFromNotification(notification.data!['userId']);
        }
        break;
      case NotificationType.gapApproved:
      case NotificationType.gapRejected:
        // Navigate to GAP detail
        break;
      default:
        break;
    }
  }

  Future<void> _showUserDetailFromNotification(String userId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final adminService = AdminService();
      final user = await adminService.getUserDetails(userId);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      UserDetailSheet.show(
        context,
        user: user,
        showActions: false, // Read-only view from notification
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถโหลดข้อมูลผู้ใช้ได้: $e', style: GoogleFonts.prompt()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
