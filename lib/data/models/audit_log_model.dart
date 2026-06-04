class AuditLog {
  final String id;
  final String action;
  final String details;
  final String timestamp;
  final String? ipAddress;
  final String? userId;

  AuditLog({
    required this.id,
    required this.action,
    required this.details,
    required this.timestamp,
    this.ipAddress,
    this.userId,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      action: json['action'] as String? ?? 'Unknown',
      details: json['details'].toString(),
      timestamp: json['timestamp'] as String? ?? '',
      ipAddress: json['ipAddress'] as String?,
      userId: json['userId'] as String?,
    );
  }
}
