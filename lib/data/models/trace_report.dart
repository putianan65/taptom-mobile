/// The public report for one lot, read from `GET /traceability/:lotNumber`.
///
/// The API answers with four blocks: `lotInformation` (the harvest or lot,
/// with its plot), `sourceOrigin` (where it was grown), `productionHistory`
/// (inputs and harvests) and `certification`. Missing blocks read as empty so
/// a partial report still renders.
class TraceReport {
  const TraceReport({
    required this.lotNumber,
    this.quantity,
    this.unit,
    this.harvestDate,
    this.grade,
    this.plotName,
    this.subDistrict,
    this.district,
    this.province,
    this.address,
    this.areaSqm,
    this.species,
    this.farmerName,
    this.geometry,
    this.plotStatus,
    this.gapStatus,
    this.season,
    this.gapUpdatedAt,
    this.inputs = const [],
    this.harvests = const [],
  });

  final String lotNumber;
  final num? quantity;
  final String? unit;
  final DateTime? harvestDate;
  final String? grade;

  final String? plotName;
  final String? subDistrict;
  final String? district;
  final String? province;

  /// Comma-separated address from the API, used when the parts are missing.
  final String? address;
  final double? areaSqm;
  final String? species;
  final String? farmerName;
  final Map<String, dynamic>? geometry;

  final String? plotStatus;
  final String? gapStatus;
  final String? season;
  final DateTime? gapUpdatedAt;

  final List<Map<String, dynamic>> inputs;
  final List<Map<String, dynamic>> harvests;

  /// The plot passed inspection. Plot approval is the certification step;
  /// the GAP traffic light is only a fallback when the plot is not included.
  bool get certified => plotStatus != null ? plotStatus == 'APPROVED' : gapStatus == 'GREEN';

  double? get areaRai => areaSqm == null ? null : areaSqm! / 1600;

  /// "ต.ชัยนาม อ.วังทอง จ.พิษณุโลก", or the API's address string.
  String get place {
    final parts = [
      if ((subDistrict ?? '').isNotEmpty) 'ต.$subDistrict',
      if ((district ?? '').isNotEmpty) 'อ.$district',
      if ((province ?? '').isNotEmpty) 'จ.$province',
    ];
    return parts.isNotEmpty ? parts.join(' ') : (address ?? '');
  }

  factory TraceReport.fromJson(Map<String, dynamic> json, {required String lotNumber}) {
    Map<String, dynamic> map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
    List<Map<String, dynamic>> list(Object? v) =>
        v is List ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)] : const [];
    String? str(Object? v) => v == null || '$v'.isEmpty ? null : '$v';
    DateTime? date(Object? v) => v == null ? null : DateTime.tryParse('$v');

    final lot = map(json['lotInformation']);
    final plot = map(lot['plot']);
    final origin = map(json['sourceOrigin']);
    final history = map(json['productionHistory']);
    final cert = map(json['certification']);
    final harvests = list(history['harvestHistory']);
    // A harvest lot carries its own numbers; a lot issued by an officer has
    // batch fields instead.
    final quantity = lot['yieldAmount'] ?? lot['batchSize'];
    final geometry = origin['location'] ?? plot['geometry'];

    return TraceReport(
      lotNumber: str(lot['lotNumber']) ?? lotNumber,
      quantity: quantity is num ? quantity : num.tryParse('${quantity ?? ''}'),
      unit: str(lot['yieldUnit'] ?? lot['batchUnit']),
      harvestDate: date(lot['harvestDate'] ?? lot['productionDate'] ?? harvests.firstOrNull?['harvestDate']),
      grade: str(lot['qualityGrade']),
      plotName: str(origin['plotName'] ?? plot['name']),
      subDistrict: str(plot['subDistrict']),
      district: str(plot['district']),
      province: str(plot['province']),
      address: str(origin['address']),
      areaSqm: (plot['area'] as num?)?.toDouble(),
      species: str(plot['species']),
      farmerName: str(origin['farmer'] ?? plot['ownerName']),
      geometry: geometry is Map ? Map<String, dynamic>.from(geometry) : null,
      plotStatus: str(plot['status']),
      gapStatus: str(cert['gapStatus'] ?? origin['gapStatus']),
      season: str(origin['gapSeason']),
      gapUpdatedAt: date(origin['gapUpdatedAt']),
      inputs: list(history['inputsUsed']),
      harvests: harvests,
    );
  }
}
