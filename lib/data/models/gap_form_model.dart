// GAP-BUG-012: These models are currently NOT USED in the application.
// The forms use Map<String, dynamic> directly for flexibility.
// Keeping for reference and potential future typed data layer.
// TODO: Either integrate these models into forms or remove in future cleanup.

enum GapFormStatus { pending, inProgress, completed, rejected }

/// @deprecated This model is not currently used. Forms use Map<String, dynamic>.
@Deprecated('Not in use - forms use raw Maps. See GAP-BUG-012.')
class GapReportModel {
  final String id;
  final String plotId;
  final String userId;
  final DateTime createdAt;

  // Sections
  GapGeneralInfo? generalInfo;
  // Add other sections here later (Inputs, Harvest, etc.)

  GapReportModel({
    required this.id,
    required this.plotId,
    required this.userId,
    required this.createdAt,
    this.generalInfo,
  });
}

/// @deprecated This model is not currently used. Forms use Map<String, dynamic>.
@Deprecated('Not in use - forms use raw Maps. See GAP-BUG-012.')
class GapGeneralInfo {
  final String responsiblePerson;
  final String cropType;
  final double areaSize; // in Rai
  final String waterSourceType; // Ground, Rain, Canal
  final String waterQuality; // Good, Moderate, Poor
  final bool isOrganic;

  GapGeneralInfo({
    required this.responsiblePerson,
    required this.cropType,
    required this.areaSize,
    required this.waterSourceType,
    required this.waterQuality,
    required this.isOrganic,
  });

  Map<String, dynamic> toJson() {
    return {
      'responsible_person': responsiblePerson,
      'crop_type': cropType,
      'area_size': areaSize,
      'water_source': waterSourceType,
      'water_quality': waterQuality,
      'is_organic': isOrganic,
    };
  }

  // GAP-BUG-011: Add null safety with default values
  factory GapGeneralInfo.fromJson(Map<String, dynamic> json) {
    return GapGeneralInfo(
      responsiblePerson: json['responsible_person']?.toString() ?? '',
      cropType: json['crop_type']?.toString() ?? '',
      areaSize: (json['area_size'] as num?)?.toDouble() ?? 0.0,
      waterSourceType: json['water_source']?.toString() ?? '',
      waterQuality: json['water_quality']?.toString() ?? '',
      isOrganic: json['is_organic'] as bool? ?? false,
    );
  }
}
