import 'user_model.dart';

class PdpaLog {
  final String id;
  final String userId;
  final String version;
  final DateTime acceptedAt;
  final String? ipAddress;
  final UserModel? user; // Optional, assuming backend joins it

  PdpaLog({
    required this.id,
    required this.userId,
    required this.version,
    required this.acceptedAt,
    this.ipAddress,
    this.user,
  });

  factory PdpaLog.fromJson(Map<String, dynamic> json) {
    return PdpaLog(
      id: json['id'] as String,
      userId: json['userId'] as String,
      version: json['version'] as String,
      acceptedAt: DateTime.parse(json['acceptedAt'] as String),
      ipAddress: json['ipAddress'] as String?,
      user: json['user'] != null 
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>) 
          : null,
    );
  }
}
