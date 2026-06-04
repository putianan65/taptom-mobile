import 'package:maplibre_gl/maplibre_gl.dart';
import '../../core/utils/geo_json_utils.dart';

class PlotModel {
  final String? id;
  final String name;
  final String? description;
  final String? species; // Backend: species (was cropType)
  final String? status; // PENDING, APPROVED, REJECTED
  final double? areaRai; // Calculated frontend or backend? Usually derived.
  final Map<String, dynamic> geometry; // GeoJSON
  final String? region;
  final String? province;
  final String? district;
  final String? subDistrict;
  final List<String> imageUrls;

  // New fields from API
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? cropMonth;
  final int? cropYear;
  final double? yieldEstimate; // ผลผลิตคาดการณ์
  final double? cropYield; // ผลผลิตจริง
  final int? treeCount;
  final DateTime? submittedDate;
  final String? ownerName; // New: Store owner name if available

  PlotModel({
    this.id,
    required this.name,
    this.description,
    this.species,
    this.status,
    this.areaRai,
    required this.geometry,
    this.region,
    this.province,
    this.district,
    this.subDistrict,
    this.imageUrls = const [],
    this.createdAt,
    this.updatedAt,
    this.cropMonth,
    this.cropYear,
    this.yieldEstimate,
    this.cropYield,
    this.treeCount,
    this.submittedDate,
    this.ownerName,
  });

  // Getter for Map display
  List<LatLng> get boundary => GeoJsonUtils.fromPolygon(geometry);

  // Calculate plot age in days
  int get ageInDays {
    if (createdAt == null) return 0;
    return DateTime.now().difference(createdAt!).inDays;
  }

  factory PlotModel.fromJson(Map<String, dynamic> json) {
    String? parsedOwnerName;
    if (json['owner'] != null) {
      final owner = json['owner'];
      parsedOwnerName = '${owner['firstName'] ?? ''} ${owner['lastName'] ?? ''}'.trim();
    }

    return PlotModel(
      id: json['id'],
      name: json['name'] ?? 'ไม่มีชื่อแปลง',
      description: json['description'],
      species: json['species'],
      status: json['status'],
      areaRai: (json['areaRai'] as num?)?.toDouble(),
      geometry: json['geometry'] ?? {},
      region: json['region'],
      province: json['province'],
      district: json['district'],
      subDistrict: json['subDistrict'],
      imageUrls:
          (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      cropMonth: json['cropMonth'],
      cropYear: json['cropYear'],
      yieldEstimate: (json['yieldEstimate'] as num?)?.toDouble(),
      cropYield: (json['cropYield'] as num?)?.toDouble(),
      treeCount: json['treeCount'],
      submittedDate: json['submitted_date'] != null
          ? DateTime.tryParse(json['submitted_date'])
          : null,
      ownerName: parsedOwnerName,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
      'description': description,
      'species': species,
      'geometry': geometry,
      'region': region,
      'province': province,
      'district': district,
      'subDistrict': subDistrict,
      'imageUrls': imageUrls,
      'cropMonth': cropMonth,
      'cropYear': cropYear,
      'yieldEstimate': yieldEstimate,
      'cropYield': cropYield,
      'treeCount': treeCount,
    };

    // Only include submitted_date if it has a value
    // Backend doesn't accept this field on create (it's auto-generated)
    if (submittedDate != null) {
      json['submittedDate'] = submittedDate!.toIso8601String();
    }

    // Remove null values to keep payload clean
    json.removeWhere((key, value) => value == null);

    return json;
  }

  /// Create a copy with updated fields (for edit functionality)
  PlotModel copyWith({
    String? id,
    String? name,
    String? description,
    String? species,
    String? status,
    double? areaRai,
    Map<String, dynamic>? geometry,
    String? region,
    String? province,
    String? district,
    String? subDistrict,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cropMonth,
    int? cropYear,
    double? yieldEstimate,
    double? cropYield,
    int? treeCount,
    DateTime? submittedDate,
  }) {
    return PlotModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      species: species ?? this.species,
      status: status ?? this.status,
      areaRai: areaRai ?? this.areaRai,
      geometry: geometry ?? this.geometry,
      region: region ?? this.region,
      province: province ?? this.province,
      district: district ?? this.district,
      subDistrict: subDistrict ?? this.subDistrict,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cropMonth: cropMonth ?? this.cropMonth,
      cropYear: cropYear ?? this.cropYear,
      yieldEstimate: yieldEstimate ?? this.yieldEstimate,
      cropYield: cropYield ?? this.cropYield,
      treeCount: treeCount ?? this.treeCount,
      submittedDate: submittedDate ?? this.submittedDate,
    );
  }
}
