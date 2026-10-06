/// Thai Location Data - Official data from government sources
/// Source: https://github.com/Dhanabhon/thailand-geodata
/// 77 จังหวัด, 928 อำเภอ, 7,435 ตำบล
library;

class ThaiLocationData {
  /// ภูมิภาค (Regions) - 6 ภาค
  static const List<String> regions = [
    'ภาคเหนือ',
    'ภาคตะวันออกเฉียงเหนือ',
    'ภาคกลาง',
    'ภาคตะวันออก',
    'ภาคตะวันตก',
    'ภาคใต้',
  ];

  /// จังหวัดทั้งหมด 77 จังหวัด (เรียงตามรหัส)
  static const List<Map<String, dynamic>> provinces = [
    {
      'id': 1,
      'code': '10',
      'nameTh': 'กรุงเทพมหานคร',
      'nameEn': 'Bangkok',
      'region': 'ภาคกลาง',
    },
    {
      'id': 2,
      'code': '11',
      'nameTh': 'สมุทรปราการ',
      'nameEn': 'Samut Prakan',
      'region': 'ภาคกลาง',
    },
    {
      'id': 3,
      'code': '12',
      'nameTh': 'นนทบุรี',
      'nameEn': 'Nonthaburi',
      'region': 'ภาคกลาง',
    },
    {
      'id': 4,
      'code': '13',
      'nameTh': 'ปทุมธานี',
      'nameEn': 'Pathum Thani',
      'region': 'ภาคกลาง',
    },
    {
      'id': 5,
      'code': '14',
      'nameTh': 'พระนครศรีอยุธยา',
      'nameEn': 'Phra Nakhon Si Ayutthaya',
      'region': 'ภาคกลาง',
    },
    {
      'id': 6,
      'code': '15',
      'nameTh': 'อ่างทอง',
      'nameEn': 'Ang Thong',
      'region': 'ภาคกลาง',
    },
    {
      'id': 7,
      'code': '16',
      'nameTh': 'ลพบุรี',
      'nameEn': 'Lop Buri',
      'region': 'ภาคกลาง',
    },
    {
      'id': 8,
      'code': '17',
      'nameTh': 'สิงห์บุรี',
      'nameEn': 'Sing Buri',
      'region': 'ภาคกลาง',
    },
    {
      'id': 9,
      'code': '18',
      'nameTh': 'ชัยนาท',
      'nameEn': 'Chai Nat',
      'region': 'ภาคกลาง',
    },
    {
      'id': 10,
      'code': '19',
      'nameTh': 'สระบุรี',
      'nameEn': 'Saraburi',
      'region': 'ภาคกลาง',
    },
    {
      'id': 11,
      'code': '20',
      'nameTh': 'ชลบุรี',
      'nameEn': 'Chon Buri',
      'region': 'ภาคตะวันออก',
    },
    {
      'id': 12,
      'code': '21',
      'nameTh': 'ระยอง',
      'nameEn': 'Rayong',
      'region': 'ภาคตะวันออก',
    },
    {
      'id': 13,
      'code': '22',
      'nameTh': 'จันทบุรี',
      'nameEn': 'Chanthaburi',
      'region': 'ภาคตะวันออก',
    },
    {
      'id': 14,
      'code': '23',
      'nameTh': 'ตราด',
      'nameEn': 'Trat',
      'region': 'ภาคตะวันออก',
    },
    {
      'id': 15,
      'code': '24',
      'nameTh': 'ฉะเชิงเทรา',
      'nameEn': 'Chachoengsao',
      'region': 'ภาคตะวันออก',
    },
    {
      'id': 16,
      'code': '25',
      'nameTh': 'ปราจีนบุรี',
      'nameEn': 'Prachin Buri',
      'region': 'ภาคตะวันออก',
    },
    {
      'id': 17,
      'code': '26',
      'nameTh': 'นครนายก',
      'nameEn': 'Nakhon Nayok',
      'region': 'ภาคกลาง',
    },
    {
      'id': 18,
      'code': '27',
      'nameTh': 'สระแก้ว',
      'nameEn': 'Sa Kaeo',
      'region': 'ภาคตะวันออก',
    },
    {
      'id': 19,
      'code': '30',
      'nameTh': 'นครราชสีมา',
      'nameEn': 'Nakhon Ratchasima',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 20,
      'code': '31',
      'nameTh': 'บุรีรัมย์',
      'nameEn': 'Buri Ram',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 21,
      'code': '32',
      'nameTh': 'สุรินทร์',
      'nameEn': 'Surin',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 22,
      'code': '33',
      'nameTh': 'ศรีสะเกษ',
      'nameEn': 'Si Sa Ket',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 23,
      'code': '34',
      'nameTh': 'อุบลราชธานี',
      'nameEn': 'Ubon Ratchathani',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 24,
      'code': '35',
      'nameTh': 'ยโสธร',
      'nameEn': 'Yasothon',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 25,
      'code': '36',
      'nameTh': 'ชัยภูมิ',
      'nameEn': 'Chaiyaphum',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 26,
      'code': '37',
      'nameTh': 'อำนาจเจริญ',
      'nameEn': 'Amnat Charoen',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 27,
      'code': '38',
      'nameTh': 'บึงกาฬ',
      'nameEn': 'Bueng Kan',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 28,
      'code': '39',
      'nameTh': 'หนองบัวลำภู',
      'nameEn': 'Nong Bua Lam Phu',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 29,
      'code': '40',
      'nameTh': 'ขอนแก่น',
      'nameEn': 'Khon Kaen',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 30,
      'code': '41',
      'nameTh': 'อุดรธานี',
      'nameEn': 'Udon Thani',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 31,
      'code': '42',
      'nameTh': 'เลย',
      'nameEn': 'Loei',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 32,
      'code': '43',
      'nameTh': 'หนองคาย',
      'nameEn': 'Nong Khai',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 33,
      'code': '44',
      'nameTh': 'มหาสารคาม',
      'nameEn': 'Maha Sarakham',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 34,
      'code': '45',
      'nameTh': 'ร้อยเอ็ด',
      'nameEn': 'Roi Et',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 35,
      'code': '46',
      'nameTh': 'กาฬสินธุ์',
      'nameEn': 'Kalasin',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 36,
      'code': '47',
      'nameTh': 'สกลนคร',
      'nameEn': 'Sakon Nakhon',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 37,
      'code': '48',
      'nameTh': 'นครพนม',
      'nameEn': 'Nakhon Phanom',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 38,
      'code': '49',
      'nameTh': 'มุกดาหาร',
      'nameEn': 'Mukdahan',
      'region': 'ภาคตะวันออกเฉียงเหนือ',
    },
    {
      'id': 39,
      'code': '50',
      'nameTh': 'เชียงใหม่',
      'nameEn': 'Chiang Mai',
      'region': 'ภาคเหนือ',
    },
    {
      'id': 40,
      'code': '51',
      'nameTh': 'ลำพูน',
      'nameEn': 'Lamphun',
      'region': 'ภาคเหนือ',
    },
    {
      'id': 41,
      'code': '52',
      'nameTh': 'ลำปาง',
      'nameEn': 'Lampang',
      'region': 'ภาคเหนือ',
    },
    {
      'id': 42,
      'code': '53',
      'nameTh': 'อุตรดิตถ์',
      'nameEn': 'Uttaradit',
      'region': 'ภาคเหนือ',
    },
    {
      'id': 43,
      'code': '54',
      'nameTh': 'แพร่',
      'nameEn': 'Phrae',
      'region': 'ภาคเหนือ',
    },
    {
      'id': 44,
      'code': '55',
      'nameTh': 'น่าน',
      'nameEn': 'Nan',
      'region': 'ภาคเหนือ',
    },
    {
      'id': 45,
      'code': '56',
      'nameTh': 'พะเยา',
      'nameEn': 'Phayao',
      'region': 'ภาคเหนือ',
    },
    {
      'id': 46,
      'code': '57',
      'nameTh': 'เชียงราย',
      'nameEn': 'Chiang Rai',
      'region': 'ภาคเหนือ',
    },
    {
      'id': 47,
      'code': '58',
      'nameTh': 'แม่ฮ่องสอน',
      'nameEn': 'Mae Hong Son',
      'region': 'ภาคเหนือ',
    },
    {
      'id': 48,
      'code': '60',
      'nameTh': 'นครสวรรค์',
      'nameEn': 'Nakhon Sawan',
      'region': 'ภาคกลาง',
    },
    {
      'id': 49,
      'code': '61',
      'nameTh': 'อุทัยธานี',
      'nameEn': 'Uthai Thani',
      'region': 'ภาคกลาง',
    },
    {
      'id': 50,
      'code': '62',
      'nameTh': 'กำแพงเพชร',
      'nameEn': 'Kamphaeng Phet',
      'region': 'ภาคกลาง',
    },
    {
      'id': 51,
      'code': '63',
      'nameTh': 'ตาก',
      'nameEn': 'Tak',
      'region': 'ภาคตะวันตก',
    },
    {
      'id': 52,
      'code': '64',
      'nameTh': 'สุโขทัย',
      'nameEn': 'Sukhothai',
      'region': 'ภาคกลาง',
    },
    {
      'id': 53,
      'code': '65',
      'nameTh': 'พิษณุโลก',
      'nameEn': 'Phitsanulok',
      'region': 'ภาคกลาง',
    },
    {
      'id': 54,
      'code': '66',
      'nameTh': 'พิจิตร',
      'nameEn': 'Phichit',
      'region': 'ภาคกลาง',
    },
    {
      'id': 55,
      'code': '67',
      'nameTh': 'เพชรบูรณ์',
      'nameEn': 'Phetchabun',
      'region': 'ภาคกลาง',
    },
    {
      'id': 56,
      'code': '70',
      'nameTh': 'ราชบุรี',
      'nameEn': 'Ratchaburi',
      'region': 'ภาคตะวันตก',
    },
    {
      'id': 57,
      'code': '71',
      'nameTh': 'กาญจนบุรี',
      'nameEn': 'Kanchanaburi',
      'region': 'ภาคตะวันตก',
    },
    {
      'id': 58,
      'code': '72',
      'nameTh': 'สุพรรณบุรี',
      'nameEn': 'Suphan Buri',
      'region': 'ภาคกลาง',
    },
    {
      'id': 59,
      'code': '73',
      'nameTh': 'นครปฐม',
      'nameEn': 'Nakhon Pathom',
      'region': 'ภาคกลาง',
    },
    {
      'id': 60,
      'code': '74',
      'nameTh': 'สมุทรสาคร',
      'nameEn': 'Samut Sakhon',
      'region': 'ภาคกลาง',
    },
    {
      'id': 61,
      'code': '75',
      'nameTh': 'สมุทรสงคราม',
      'nameEn': 'Samut Songkhram',
      'region': 'ภาคกลาง',
    },
    {
      'id': 62,
      'code': '76',
      'nameTh': 'เพชรบุรี',
      'nameEn': 'Phetchaburi',
      'region': 'ภาคตะวันตก',
    },
    {
      'id': 63,
      'code': '77',
      'nameTh': 'ประจวบคีรีขันธ์',
      'nameEn': 'Prachuap Khiri Khan',
      'region': 'ภาคตะวันตก',
    },
    {
      'id': 64,
      'code': '80',
      'nameTh': 'นครศรีธรรมราช',
      'nameEn': 'Nakhon Si Thammarat',
      'region': 'ภาคใต้',
    },
    {
      'id': 65,
      'code': '81',
      'nameTh': 'กระบี่',
      'nameEn': 'Krabi',
      'region': 'ภาคใต้',
    },
    {
      'id': 66,
      'code': '82',
      'nameTh': 'พังงา',
      'nameEn': 'Phang Nga',
      'region': 'ภาคใต้',
    },
    {
      'id': 67,
      'code': '83',
      'nameTh': 'ภูเก็ต',
      'nameEn': 'Phuket',
      'region': 'ภาคใต้',
    },
    {
      'id': 68,
      'code': '84',
      'nameTh': 'สุราษฎร์ธานี',
      'nameEn': 'Surat Thani',
      'region': 'ภาคใต้',
    },
    {
      'id': 69,
      'code': '85',
      'nameTh': 'ระนอง',
      'nameEn': 'Ranong',
      'region': 'ภาคใต้',
    },
    {
      'id': 70,
      'code': '86',
      'nameTh': 'ชุมพร',
      'nameEn': 'Chumphon',
      'region': 'ภาคใต้',
    },
    {
      'id': 71,
      'code': '90',
      'nameTh': 'สงขลา',
      'nameEn': 'Songkhla',
      'region': 'ภาคใต้',
    },
    {
      'id': 72,
      'code': '91',
      'nameTh': 'สตูล',
      'nameEn': 'Satun',
      'region': 'ภาคใต้',
    },
    {
      'id': 73,
      'code': '92',
      'nameTh': 'ตรัง',
      'nameEn': 'Trang',
      'region': 'ภาคใต้',
    },
    {
      'id': 74,
      'code': '93',
      'nameTh': 'พัทลุง',
      'nameEn': 'Phatthalung',
      'region': 'ภาคใต้',
    },
    {
      'id': 75,
      'code': '94',
      'nameTh': 'ปัตตานี',
      'nameEn': 'Pattani',
      'region': 'ภาคใต้',
    },
    {
      'id': 76,
      'code': '95',
      'nameTh': 'ยะลา',
      'nameEn': 'Yala',
      'region': 'ภาคใต้',
    },
    {
      'id': 77,
      'code': '96',
      'nameTh': 'นราธิวาส',
      'nameEn': 'Narathiwat',
      'region': 'ภาคใต้',
    },
  ];

  /// Get all provinces
  static List<String> getAllProvinces() {
    return provinces.map((p) => p['nameTh'] as String).toList();
  }

  /// Get provinces by region
  static List<String> getProvincesByRegion(String region) {
    return provinces
        .where((p) => p['region'] == region)
        .map((p) => p['nameTh'] as String)
        .toList();
  }

  /// Get province code by name
  static String? getProvinceCode(String provinceName) {
    final province = provinces.firstWhere(
      (p) => p['nameTh'] == provinceName,
      orElse: () => {},
    );
    return province['code'] as String?;
  }

  /// Get province ID by name
  static int? getProvinceId(String provinceName) {
    final province = provinces.firstWhere(
      (p) => p['nameTh'] == provinceName,
      orElse: () => {},
    );
    return province['id'] as int?;
  }

  /// Check if province exists
  static bool provinceExists(String provinceName) {
    return provinces.any((p) => p['nameTh'] == provinceName);
  }
}
