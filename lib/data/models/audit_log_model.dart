/// One entry in the staff audit trail.
class AuditLog {
  const AuditLog({
    required this.id,
    required this.action,
    required this.details,
    this.resourceType,
    this.resourceId,
    this.createdAt,
    this.ipAddress,
    this.userId,
    this.actorName,
    this.actorRole,
  });

  final String id;

  /// Machine code such as APPROVE_PLOT or CREATE_ADMIN.
  final String action;
  final String details;

  /// PLOT, USER, GAP, TRACEABILITY ...
  final String? resourceType;
  final String? resourceId;
  final DateTime? createdAt;
  final String? ipAddress;
  final String? userId;
  final String? actorName;
  final String? actorRole;

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    final actor = json['user'] ?? json['admin'] ?? json['actor'];
    String? name;
    String? role;
    if (actor is Map) {
      name = '${actor['firstName'] ?? ''} ${actor['lastName'] ?? ''}'.trim();
      if (name.isEmpty) name = null;
      role = actor['role']?.toString();
    }
    final details = json['details'];
    return AuditLog(
      id: '${json['id'] ?? ''}',
      action: json['action']?.toString() ?? 'UNKNOWN',
      details: details == null ? '' : (details is String ? details : details.toString()),
      resourceType: (json['resourceType'] ?? json['entityType'])?.toString(),
      resourceId: (json['resourceId'] ?? json['entityId'])?.toString(),
      createdAt: DateTime.tryParse('${json['createdAt'] ?? json['timestamp'] ?? ''}')?.toLocal(),
      ipAddress: json['ipAddress']?.toString(),
      userId: (json['userId'] ?? json['adminId'])?.toString(),
      actorName: name,
      actorRole: role,
    );
  }
}
