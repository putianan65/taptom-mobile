import 'dart:math' as math;

/// Seed data for demo mode: one district in Phitsanulok with a farmer, an
/// officer, a super admin and enough plots and records to exercise every
/// screen. Shapes follow the backend's JSON responses.
abstract final class DemoSeed {
  static const farmerId = 'u-farmer-01';
  static const adminId = 'u-admin-01';
  static const superId = 'u-super-01';

  static DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) =>
      DateTime.now().subtract(Duration(days: days, hours: hours, minutes: minutes));

  static String iso(DateTime d) => d.toUtc().toIso8601String();

  static Map<String, dynamic> _user({
    required String id,
    required String first,
    required String last,
    required String phone,
    required String role,
    required String birthday,
    String status = 'APPROVED',
    String province = 'พิษณุโลก',
    String district = 'วังทอง',
    String subDistrict = 'ชัยนาม',
    String region = 'ภาคเหนือ',
    String job = 'เกษตรกร',
    int createdDaysAgo = 120,
    String? adminId,
    bool hasPin = false,
  }) =>
      {
        'id': id,
        'firstName': first,
        'lastName': last,
        'phone': phone,
        'role': role,
        'birthday': birthday,
        'membershipStatus': status,
        'region': region,
        'province': province,
        'district': district,
        'subDistrict': subDistrict,
        'job': job,
        'hasPin': hasPin,
        'pdpaConsentAt': iso(_ago(days: createdDaysAgo)),
        'createdAt': iso(_ago(days: createdDaysAgo)),
        'updatedAt': iso(_ago(days: math.max(0, createdDaysAgo - 3))),
        if (adminId != null) 'adminId': adminId,
        'plotCount': 0,
      };

  static List<Map<String, dynamic>> users() => [
        _user(
          id: farmerId,
          first: 'สมชาย',
          last: 'ใจดี',
          phone: '0812345678',
          role: 'USER',
          birthday: '1975-01-15',
          adminId: adminId,
          createdDaysAgo: 210,
        ),
        _user(
          id: adminId,
          first: 'ประเสริฐ',
          last: 'วงศ์ไทย',
          phone: '0898765432',
          role: 'ADMIN',
          birthday: '1985-05-20',
          job: 'นักวิชาการส่งเสริมการเกษตร',
          subDistrict: '',
          hasPin: true,
          createdDaysAgo: 400,
        ),
        _user(
          id: superId,
          first: 'วิภาวดี',
          last: 'ศรีสุข',
          phone: '0800000001',
          role: 'SUPER_ADMIN',
          birthday: '1982-01-01',
          job: 'ผู้ดูแลระบบ',
          province: '',
          district: '',
          subDistrict: '',
          region: '',
          hasPin: true,
          createdDaysAgo: 500,
        ),
        // Other farmers in the district.
        for (final (i, f) in _farmers.indexed)
          _user(
            id: 'u-farmer-${(i + 2).toString().padLeft(2, '0')}',
            first: f.$1,
            last: f.$2,
            phone: '08${(31000000 + i * 734117).toString().padLeft(8, '0')}',
            role: 'USER',
            birthday: '19${60 + i * 2}-0${1 + i % 9}-1${i % 9}',
            status: f.$3,
            subDistrict: f.$4,
            adminId: adminId,
            createdDaysAgo: f.$5,
          ),
        // Officers in other provinces.
        for (final (i, a) in _officers.indexed)
          _user(
            id: 'u-admin-${(i + 2).toString().padLeft(2, '0')}',
            first: a.$1,
            last: a.$2,
            phone: '09${(12000000 + i * 811231).toString().padLeft(8, '0')}',
            role: 'ADMIN',
            birthday: '198${i + 1}-0${i + 2}-1${i + 1}',
            region: a.$3,
            province: a.$4,
            district: a.$5,
            subDistrict: '',
            job: 'นักวิชาการส่งเสริมการเกษตร',
            hasPin: true,
            createdDaysAgo: 300 - i * 40,
          ),
      ];

  static const _farmers = [
    ('มานพ', 'ทองดี', 'APPROVED', 'ชัยนาม', 190),
    ('บุญเรือน', 'แก้วมณี', 'APPROVED', 'บ้านกลาง', 160),
    ('สุนทร', 'พรหมมา', 'PENDING', 'วังทอง', 2),
    ('อำไพ', 'ศรีวงศ์', 'PENDING', 'ชัยนาม', 1),
    ('ทองใบ', 'คำแสน', 'PENDING', 'บ้านกลาง', 0),
    ('ประยูร', 'จันทร์หอม', 'APPROVED', 'วังทอง', 95),
    ('ลำดวน', 'บุญมา', 'APPROVED', 'แม่ระกา', 70),
    ('สมพงษ์', 'อินทร์แก้ว', 'REJECTED', 'แม่ระกา', 12),
    ('จันทร์เพ็ญ', 'ใจงาม', 'APPROVED', 'ชัยนาม', 44),
    ('วีระ', 'สุขเกษม', 'APPROVED', 'วังทอง', 31),
    ('ถนอม', 'ศักดิ์ดี', 'APPROVED', 'บ้านกลาง', 18),
    ('พิมพ์ใจ', 'เพชรรัตน์', 'APPROVED', 'แม่ระกา', 6),
  ];

  static const _officers = [
    ('ชยพล', 'มีสุข', 'ภาคใต้', 'นครศรีธรรมราช', 'ทุ่งสง'),
    ('นภัสสร', 'ชูเชิด', 'ภาคใต้', 'สุราษฎร์ธานี', 'ท่าชนะ'),
    ('ธีรวัฒน์', 'คงสม', 'ภาคเหนือ', 'เชียงใหม่', ''),
    ('กมลชนก', 'ศรีสวัสดิ์', 'ภาคตะวันออกเฉียงเหนือ', 'ขอนแก่น', ''),
  ];

  /// Irregular polygon around a centre, roughly [rai] in area.
  static Map<String, dynamic> _polygon(
    double lat,
    double lng,
    double rai,
    int seed, {
    int sides = 5,
  }) {
    final rnd = math.Random(seed);
    // One rai is 1,600 m2. Radius of a circle with that area, in metres.
    final r = math.sqrt(rai * 1600 / math.pi);
    final coords = <List<double>>[];
    for (var i = 0; i < sides; i++) {
      final a = i / sides * math.pi * 2 + rnd.nextDouble() * 0.5;
      final d = r * (0.8 + rnd.nextDouble() * 0.4);
      final dLat = d * math.cos(a) / 111320;
      final dLng = d * math.sin(a) / (111320 * math.cos(lat * math.pi / 180));
      coords.add([lng + dLng, lat + dLat]);
    }
    coords.add(coords.first);
    return {
      'type': 'Polygon',
      'coordinates': [coords],
    };
  }

  static Map<String, dynamic> _plot({
    required String id,
    required String owner,
    required String ownerFirst,
    required String ownerLast,
    required String name,
    required String status,
    required double rai,
    required double lat,
    required double lng,
    required int seed,
    String species = 'กระท่อมพันธุ์ก้านแดง',
    String subDistrict = 'ชัยนาม',
    int trees = 400,
    int createdDaysAgo = 60,
    String? rejectReason,
    int sides = 5,
  }) =>
      {
        'id': id,
        'userId': owner,
        'name': name,
        'description': 'ปลูกแบบผสมผสานใต้ร่มไม้ใหญ่ ใช้น้ำจากบ่อในแปลง',
        'species': species,
        'status': status,
        'areaRai': rai,
        'treeCount': trees,
        'region': 'ภาคเหนือ',
        'province': 'พิษณุโลก',
        'district': 'วังทอง',
        'subDistrict': subDistrict,
        'cropMonth': 'มิถุนายน',
        'cropYear': 2024,
        'yieldEstimate': (rai * 180).roundToDouble(),
        'geometry': _polygon(lat, lng, rai, seed, sides: sides),
        'imageUrls': <String>[],
        'createdAt': iso(_ago(days: createdDaysAgo)),
        'updatedAt': iso(_ago(days: math.max(0, createdDaysAgo - 5))),
        'owner': {'id': owner, 'firstName': ownerFirst, 'lastName': ownerLast},
        if (rejectReason != null) 'rejectReason': rejectReason,
      };

  static List<Map<String, dynamic>> plots() => [
        _plot(
          id: 'p-001',
          owner: farmerId,
          ownerFirst: 'สมชาย',
          ownerLast: 'ใจดี',
          name: 'สวนกระท่อมหนองปลิง',
          status: 'APPROVED',
          rai: 6.4,
          lat: 16.8402,
          lng: 100.4335,
          seed: 7,
          trees: 820,
          createdDaysAgo: 190,
          sides: 6,
        ),
        _plot(
          id: 'p-002',
          owner: farmerId,
          ownerFirst: 'สมชาย',
          ownerLast: 'ใจดี',
          name: 'แปลงริมคลองวังทอง',
          status: 'PENDING',
          rai: 4.2,
          lat: 16.8369,
          lng: 100.4391,
          seed: 11,
          species: 'กระท่อมพันธุ์ก้านเขียว',
          trees: 510,
          createdDaysAgo: 34,
        ),
        _plot(
          id: 'p-003',
          owner: farmerId,
          ownerFirst: 'สมชาย',
          ownerLast: 'ใจดี',
          name: 'แปลงเนินมะค่า',
          status: 'REJECTED',
          rai: 2.8,
          lat: 16.8431,
          lng: 100.4398,
          seed: 23,
          trees: 300,
          createdDaysAgo: 21,
          rejectReason: 'ขอบเขตแปลงทับซ้อนพื้นที่สาธารณะ กรุณาวาดขอบเขตใหม่',
          sides: 4,
        ),
        _plot(
          id: 'p-004',
          owner: farmerId,
          ownerFirst: 'สมชาย',
          ownerLast: 'ใจดี',
          name: 'แปลงทดลองหลังบ้าน',
          status: 'PENDING',
          rai: 1.6,
          lat: 16.8352,
          lng: 100.4342,
          seed: 31,
          species: 'กระท่อมพันธุ์แตงกวา',
          trees: 160,
          createdDaysAgo: 6,
        ),
        // Neighbouring farmers, for the officer map.
        for (final (i, n) in _neighbours.indexed)
          _plot(
            id: 'p-${(i + 10).toString().padLeft(3, '0')}',
            owner: 'u-farmer-${(n.$6 + 2).toString().padLeft(2, '0')}',
            ownerFirst: _farmers[n.$6].$1,
            ownerLast: _farmers[n.$6].$2,
            name: n.$1,
            status: n.$2,
            rai: n.$3,
            lat: n.$4,
            lng: n.$5,
            seed: 100 + i,
            subDistrict: _farmers[n.$6].$4,
            trees: (n.$3 * 120).round(),
            createdDaysAgo: 20 + i * 9,
          ),
      ];

  static const _neighbours = [
    ('สวนบ้านโคกสลุด', 'APPROVED', 5.1, 16.8448, 100.4302, 0),
    ('แปลงหนองตะเคียน', 'APPROVED', 3.6, 16.8331, 100.4428, 1),
    ('แปลงริมถนนสาย 12', 'PENDING', 2.4, 16.8478, 100.4366, 5),
    ('สวนลุงประยูร', 'APPROVED', 7.8, 16.8297, 100.4351, 5),
    ('แปลงท้ายหมู่บ้าน', 'PENDING', 1.9, 16.8415, 100.4455, 6),
    ('สวนป่ากระท่อมแม่ระกา', 'APPROVED', 9.2, 16.8506, 100.4419, 6),
    ('แปลงหัวไร่', 'REJECTED', 2.2, 16.8318, 100.4293, 7),
    ('แปลงใหม่ชัยนาม', 'PENDING', 3.1, 16.8385, 100.4274, 8),
    ('สวนสองพี่น้อง', 'APPROVED', 4.7, 16.8462, 100.4482, 9),
    ('แปลงทุ่งนาเก่า', 'APPROVED', 6.0, 16.8278, 100.4405, 10),
  ];

  /// GAP records per plot: plot 1 complete, plot 2 partly done, plot 4 just
  /// started, plot 3 empty.
  static Map<String, Map<String, dynamic>> gapRecords() => {
        'p-001': _general('p-001', 'รอบปลูก 2567/1', days: 150),
        'p-002': _general('p-002', 'รอบปลูก 2568/1', days: 30),
        'p-004': _general('p-004', 'รอบปลูก 2568/1', days: 5),
        'p-010': _general('p-010', 'รอบปลูก 2567/2', days: 90),
        'p-011': _general('p-011', 'รอบปลูก 2567/2', days: 80),
        'p-013': _general('p-013', 'รอบปลูก 2567/1', days: 120),
      };

  static Map<String, dynamic> _general(String plotId, String season, {required int days}) => {
        'id': 'g-$plotId',
        'plotId': plotId,
        'farmerName': 'นายสมชาย ใจดี',
        'cropType': 'พืชกระท่อม',
        'cropVariety': 'ก้านแดง',
        'irrigationSystem': 'น้ำหยด',
        'waterSource': 'บ่อน้ำตื้นในแปลง',
        'waterQualityNote': 'น้ำใส ไม่มีกลิ่น ผลตรวจ pH 7.1',
        'farmingSystem': 'NON_ORGANIC',
        'seasonLabel': season,
        'startDate': iso(_ago(days: days + 30)),
        'gapStatus': 'GREEN',
        'createdAt': iso(_ago(days: days)),
        'updatedAt': iso(_ago(days: math.max(0, days - 2))),
      };

  static Map<String, List<Map<String, dynamic>>> inputs() => {
        'p-001': [
          {
            'id': 'in-1',
            'type': 'FERTILIZER',
            'name': 'ปุ๋ยอินทรีย์มูลไก่',
            'brand': 'สหกรณ์วังทอง',
            'amount': 120,
            'unit': 'กก.',
            'appliedDate': iso(_ago(days: 120)),
            'createdAt': iso(_ago(days: 120)),
          },
          {
            'id': 'in-2',
            'type': 'PESTICIDE',
            'name': 'สารสกัดสะเดา',
            'activeIngredient': 'Azadirachtin 0.1%',
            'amount': 2,
            'unit': 'ลิตร',
            'appliedDate': iso(_ago(days: 64)),
            'phiDays': 7,
            'createdAt': iso(_ago(days: 64)),
          },
        ],
        'p-002': [
          {
            'id': 'in-3',
            'type': 'FERTILIZER',
            'name': 'ปุ๋ยหมักชีวภาพ',
            'amount': 80,
            'unit': 'กก.',
            'appliedDate': iso(_ago(days: 20)),
            'createdAt': iso(_ago(days: 20)),
          },
        ],
      };

  static Map<String, List<Map<String, dynamic>>> activities() => {
        'p-001': [
          for (final (i, a) in const [
            ('ตัดแต่งกิ่ง', 140),
            ('กำจัดวัชพืชรอบโคนต้น', 96),
            ('ให้น้ำและตรวจระบบน้ำหยด', 30),
          ].indexed)
            {
              'id': 'act-${i + 1}',
              'activityType': a.$1,
              'activityDate': iso(_ago(days: a.$2)),
              'note': 'บันทึกโดยเกษตรกร',
              'createdAt': iso(_ago(days: a.$2)),
            },
        ],
        'p-002': [
          {
            'id': 'act-9',
            'activityType': 'เตรียมดินและปลูกซ่อม',
            'activityDate': iso(_ago(days: 25)),
            'createdAt': iso(_ago(days: 25)),
          },
        ],
      };

  static Map<String, List<Map<String, dynamic>>> harvests() => {
        'p-001': [
          {
            'id': 'h-1',
            'plotId': 'p-001',
            'harvestDate': iso(_ago(days: 45)),
            'yieldAmount': 310,
            'yieldUnit': 'กก.',
            'qualityGrade': 'A',
            'lotNumber': 'TPT-2568-0042',
            'createdAt': iso(_ago(days: 45)),
            'postHarvests': [
              {
                'id': 'ph-1',
                'processType': 'ตากแห้งในโรงเรือน',
                'processDate': iso(_ago(days: 43)),
                'packaging': 'ถุงผ้าดิบ 5 กก.',
                'storageLocation': 'โรงเก็บหมู่ 4',
                'createdAt': iso(_ago(days: 43)),
              },
            ],
          },
          {
            'id': 'h-2',
            'plotId': 'p-001',
            'harvestDate': iso(_ago(days: 12)),
            'yieldAmount': 285,
            'yieldUnit': 'กก.',
            'qualityGrade': 'A',
            'lotNumber': 'TPT-2568-0057',
            'createdAt': iso(_ago(days: 12)),
            'postHarvests': <Map<String, dynamic>>[],
          },
        ],
      };

  static Map<String, List<Map<String, dynamic>>> trainings() => {
        'p-001': [
          {
            'id': 't-1',
            'topic': 'การใช้สารเคมีอย่างปลอดภัยและอุปกรณ์ป้องกัน',
            'trainingDate': iso(_ago(days: 100)),
            'trainer': 'สำนักงานเกษตรอำเภอวังทอง',
            'participants': 3,
            'createdAt': iso(_ago(days: 100)),
          },
        ],
        'p-002': [
          {
            'id': 't-2',
            'topic': 'สุขอนามัยในการเก็บเกี่ยว',
            'trainingDate': iso(_ago(days: 18)),
            'trainer': 'สำนักงานเกษตรอำเภอวังทอง',
            'participants': 2,
            'createdAt': iso(_ago(days: 18)),
          },
        ],
      };

  static List<Map<String, dynamic>> notifications(String userId) {
    if (userId == farmerId) {
      return [
        {
          'id': 'n-1',
          'userId': userId,
          'title': 'แปลงสวนกระท่อมหนองปลิงผ่านการตรวจ',
          'message': 'เจ้าหน้าที่อนุมัติแปลงแล้ว ดาวน์โหลดใบรับรองได้ที่เมนูใบรับรอง',
          'type': 'PLOT_APPROVED',
          'isRead': false,
          'createdAt': iso(_ago(hours: 2)),
        },
        {
          'id': 'n-2',
          'userId': userId,
          'title': 'แปลงเนินมะค่าไม่ผ่านการตรวจ',
          'message': 'โปรดแก้ไขข้อมูลและส่งตรวจอีกครั้ง',
          'type': 'PLOT_REJECTED',
          'data': {'reason': 'ขอบเขตแปลงทับซ้อนพื้นที่สาธารณะ กรุณาวาดขอบเขตใหม่'},
          'isRead': false,
          'createdAt': iso(_ago(days: 1, hours: 3)),
        },
        {
          'id': 'n-3',
          'userId': userId,
          'title': 'เตือนบันทึกการเก็บเกี่ยว',
          'message': 'แปลงริมคลองวังทองยังไม่มีบันทึกหมวด 1.4 การเก็บเกี่ยว',
          'type': 'INFO',
          'isRead': true,
          'createdAt': iso(_ago(days: 3)),
        },
        {
          'id': 'n-4',
          'userId': userId,
          'title': 'อบรมการปลูกกระท่อมตามมาตรฐาน GAP',
          'message': 'สำนักงานเกษตรอำเภอวังทองจัดอบรม วันเสาร์นี้ 09:00 น. ที่ศาลาประชาคม',
          'type': 'SYSTEM_ANNOUNCEMENT',
          'isRead': true,
          'createdAt': iso(_ago(days: 6)),
        },
      ];
    }
    return [
      {
        'id': 'n-a1',
        'userId': userId,
        'title': 'คำขอเป็นสมาชิกใหม่ 3 ราย',
        'message': 'มีเกษตรกรในพื้นที่ส่งคำขอเข้ากลุ่ม รอการพิจารณา',
        'type': 'PLOT_CREATED',
        'isRead': false,
        'createdAt': iso(_ago(minutes: 40)),
      },
      {
        'id': 'n-a2',
        'userId': userId,
        'title': 'แปลงใหม่รอตรวจ: แปลงทดลองหลังบ้าน',
        'message': 'นายสมชาย ใจดี ส่งแปลงขนาด 1.6 ไร่',
        'type': 'GAP_SUBMITTED',
        'isRead': false,
        'createdAt': iso(_ago(days: 1)),
      },
      {
        'id': 'n-a3',
        'userId': userId,
        'title': 'มีการแก้ไขบันทึกการเก็บเกี่ยว',
        'message': 'สวนกระท่อมหนองปลิง แก้ไขรายการเก็บเกี่ยวครั้งที่ 2',
        'type': 'RECORD_EDITED',
        'isRead': true,
        'createdAt': iso(_ago(days: 4)),
      },
    ];
  }

  static List<Map<String, dynamic>> trends(String period) {
    final days = period == '30d' ? 30 : 7;
    final rnd = math.Random(days);
    return [
      for (var i = days - 1; i >= 0; i--)
        {
          'date': DateTime.now().subtract(Duration(days: i)).toIso8601String().substring(0, 10),
          'count': 2 + rnd.nextInt(6) + (days - i) ~/ 4,
        },
    ];
  }

  static List<Map<String, dynamic>> auditLogs() => [
        for (final (i, l) in const [
          ('APPROVE_PLOT', 'PLOT', 'อนุมัติแปลง สวนกระท่อมหนองปลิง', 1),
          ('APPROVE_USER', 'USER', 'อนุมัติสมาชิก นายมานพ ทองดี', 3),
          ('REJECT_PLOT', 'PLOT', 'ไม่อนุมัติแปลง แปลงเนินมะค่า: ขอบเขตทับซ้อนพื้นที่สาธารณะ', 26),
          ('UPDATE_PLOT', 'PLOT', 'ปรับแก้พิกัดแปลง แปลงริมคลองวังทอง', 30),
          ('CREATE_ADMIN', 'USER', 'เพิ่มเจ้าหน้าที่ นายชยพล มีสุข จ.นครศรีธรรมราช', 49),
          ('GAP_FEEDBACK', 'GAP', 'ให้คำแนะนำหมวด 1.2 การบันทึกสารสกัดสะเดา', 70),
          ('REJECT_USER', 'USER', 'ไม่อนุมัติสมาชิก นายสมพงษ์ อินทร์แก้ว: ที่ตั้งอยู่นอกพื้นที่', 96),
          ('UPDATE_TRACEABILITY', 'TRACEABILITY', 'แก้ไขล็อต TPT-2568-0042 สถานะส่งออก', 140),
        ].indexed)
          {
            'id': 'log-${i + 1}',
            'action': l.$1,
            'resourceType': l.$2,
            'resourceId': 'r-$i',
            'details': l.$3,
            'userId': i == 4 ? superId : adminId,
            'user': i == 4
                ? {'firstName': 'วิภาวดี', 'lastName': 'ศรีสุข', 'role': 'SUPER_ADMIN'}
                : {'firstName': 'ประเสริฐ', 'lastName': 'วงศ์ไทย', 'role': 'ADMIN'},
            'createdAt': iso(_ago(hours: l.$4 * 5)),
          },
      ];
}
