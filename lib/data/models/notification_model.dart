enum NotificationType {
  plotCreated,
  plotApproved,
  plotRejected,
  userApproved,
  userRejected,
  gapSubmitted,
  gapApproved,
  gapRejected,
  recordEdited,
  systemAnnouncement,
  system,
  info,
}

class NotificationModel {
  final String id;
  final String? userId;
  final String title;
  final String? message;
  final String type; // Raw type string from API (PLOT_APPROVED, etc.)
  final NotificationType notificationType;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final String? createdBy;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    this.message,
    this.type = 'INFO',
    this.notificationType = NotificationType.info,
    this.data,
    this.actionUrl,
    this.createdBy,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'] ?? 'การแจ้งเตือน',
      message: json['message'] ?? json['body'],
      type: json['type'] ?? 'INFO',
      notificationType: _parseNotificationType(
        json['notificationType'] ?? json['type'],
      ),
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
      actionUrl: json['actionUrl'],
      createdBy: json['createdBy'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    NotificationType? notificationType,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? createdBy,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      notificationType: notificationType ?? this.notificationType,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      createdBy: createdBy ?? this.createdBy,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  /// ตรวจว่าเป็น rejection notification หรือไม่
  bool get isRejection => const [
    NotificationType.plotRejected,
    NotificationType.userRejected,
    NotificationType.gapRejected,
  ].contains(notificationType);

  /// ดึงเหตุผลการปฏิเสธจาก data
  String? get rejectionReason => data?['reason'];

  static NotificationType _parseNotificationType(String? type) {
    switch (type?.toUpperCase()) {
      case 'PLOT_CREATED':
        return NotificationType.plotCreated;
      case 'PLOT_APPROVED':
        return NotificationType.plotApproved;
      case 'PLOT_REJECTED':
        return NotificationType.plotRejected;
      case 'USER_APPROVED':
        return NotificationType.userApproved;
      case 'USER_REJECTED':
        return NotificationType.userRejected;
      case 'GAP_SUBMITTED':
        return NotificationType.gapSubmitted;
      case 'GAP_APPROVED':
        return NotificationType.gapApproved;
      case 'GAP_REJECTED':
        return NotificationType.gapRejected;
      case 'RECORD_EDITED':
        return NotificationType.recordEdited;
      case 'SYSTEM_ANNOUNCEMENT':
        return NotificationType.systemAnnouncement;
      case 'SYSTEM':
        return NotificationType.system;
      default:
        return NotificationType.info;
    }
  }
}
