enum UserRole { farmer, admin, superAdmin }

/// User membership status in a community enterprise
enum MembershipStatus {
  pending, // รอการอนุมัติ
  approved, // ได้รับการอนุมัติ
  rejected, // ถูกปฏิเสธ
  none, // ไม่ได้สังกัด
}

class UserModel {
  final String id;
  final String phone;
  final String firstName;
  final String lastName;
  final UserRole role;
  final DateTime? birthDate;

  // Location fields
  final String? region;
  final String? province;
  final String? district;
  final String? subdistrict;

  // Community enterprise fields
  final String? communityEnterpriseId;
  final String? communityEnterpriseName;
  final MembershipStatus membershipStatus;

  // Additional profile fields
  final String? job;
  final DateTime? pdpaConsentAt;
  final bool hasPin;
  final String? photoUrl;
  final DateTime? deletedAt; // ✅ NEW

  UserModel({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.birthDate,
    this.region,
    this.province,
    this.district,
    this.subdistrict,
    this.communityEnterpriseId,
    this.communityEnterpriseName,
    this.membershipStatus = MembershipStatus.none,
    this.job,
    this.pdpaConsentAt,
    this.hasPin = false,
    this.photoUrl,
    this.deletedAt,
  });

  String get fullName => '$firstName $lastName';
  bool get isDeleted => deletedAt != null; // Helper getter

  String get locationDisplay {
    final parts = <String>[];
    if (subdistrict != null) parts.add('ต.$subdistrict');
    if (district != null) parts.add('อ.$district');
    if (province != null) parts.add('จ.$province');
    return parts.isEmpty ? (region ?? 'ไม่ระบุ') : parts.join(' ');
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole stringToRole(String role) {
      switch (role.toUpperCase()) {
        case 'ADMIN':
          return UserRole.admin;
        case 'SUPER_ADMIN':
          return UserRole.superAdmin;
        case 'USER':
        default:
          return UserRole.farmer;
      }
    }

    MembershipStatus stringToMembershipStatus(String? status) {
      switch (status?.toUpperCase()) {
        case 'PENDING':
          return MembershipStatus.pending;
        case 'APPROVED':
          return MembershipStatus.approved;
        case 'REJECTED':
          return MembershipStatus.rejected;
        default:
          return MembershipStatus.none;
      }
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      phone: json['phone'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: stringToRole(json['role'] ?? 'USER'),
      birthDate: json['birthday'] != null
          ? DateTime.parse(json['birthday'])
          : null,
      region: json['region'],
      province: json['province'],
      district: json['district'],
      subdistrict: json['subDistrict'] ?? json['subdistrict'],
      communityEnterpriseId: json['communityEnterpriseId'],
      communityEnterpriseName: json['communityEnterpriseName'],
      membershipStatus: stringToMembershipStatus(json['membershipStatus']),
      job: json['job'],
      pdpaConsentAt: json['pdpaConsentAt'] != null
          ? DateTime.parse(json['pdpaConsentAt'])
          : null,
      hasPin: json['hasPin'] ?? false,
      photoUrl: json['photoUrl'],
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.name.toUpperCase(),
      // 'birthday': birthDate?.toIso8601String(), // Backend rejects 'birthday'
      'region': region,
      'province': province,
      'district': district,
      'subDistrict': subdistrict,
      'communityEnterpriseId': communityEnterpriseId,
      'membershipStatus': membershipStatus.name.toUpperCase(),
      'job': job,
      'pdpaConsentAt': pdpaConsentAt?.toIso8601String(),
      'hasPin': hasPin,
      'photoUrl': photoUrl,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// Copy with modified fields
  UserModel copyWith({
    String? id,
    String? phone,
    String? firstName,
    String? lastName,
    UserRole? role,
    DateTime? birthDate,
    String? region,
    String? province,
    String? district,
    String? subdistrict,
    String? communityEnterpriseId,
    String? communityEnterpriseName,
    MembershipStatus? membershipStatus,
    String? job,
    DateTime? pdpaConsentAt,
    bool? hasPin,
    String? photoUrl,
    DateTime? deletedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      birthDate: birthDate ?? this.birthDate,
      region: region ?? this.region,
      province: province ?? this.province,
      district: district ?? this.district,
      subdistrict: subdistrict ?? this.subdistrict,
      communityEnterpriseId:
          communityEnterpriseId ?? this.communityEnterpriseId,
      communityEnterpriseName:
          communityEnterpriseName ?? this.communityEnterpriseName,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      job: job ?? this.job,
      pdpaConsentAt: pdpaConsentAt ?? this.pdpaConsentAt,
      hasPin: hasPin ?? this.hasPin,
      photoUrl: photoUrl ?? this.photoUrl,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
