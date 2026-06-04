class Province {
  final int id;
  final String code;
  final String nameTh;
  final String? nameEn;
  final String? region;

  Province({
    required this.id,
    required this.code,
    required this.nameTh,
    this.nameEn,
    this.region,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'].toString(),
      nameTh: json['nameTh'] ?? '',
      nameEn: json['nameEn'],
      region: json['region'],
    );
  }
}

class District {
  final int id;
  final String code;
  final String nameTh;
  final String? nameEn;
  final String provinceCode;

  District({
    required this.id,
    required this.code,
    required this.nameTh,
    this.nameEn,
    required this.provinceCode,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'].toString(),
      nameTh: json['nameTh'] ?? '',
      nameEn: json['nameEn'],
      provinceCode: json['provinceCode'].toString(),
    );
  }
}

class Subdistrict {
  final int id;
  final String code;
  final String nameTh;
  final String? nameEn;
  final String districtCode;
  final String? postalCode;

  Subdistrict({
    required this.id,
    required this.code,
    required this.nameTh,
    this.nameEn,
    required this.districtCode,
    this.postalCode,
  });

  factory Subdistrict.fromJson(Map<String, dynamic> json) {
    return Subdistrict(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'].toString(),
      nameTh: json['nameTh'] ?? '',
      nameEn: json['nameEn'],
      districtCode: json['districtCode'].toString(),
      postalCode: json['postalCode']?.toString(),
    );
  }
}
