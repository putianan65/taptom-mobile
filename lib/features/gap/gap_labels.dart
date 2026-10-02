import '../../core/utils/thai_date.dart';
import 'gap_categories.dart';

/// A GAP record rendered for reading: a headline, a one-line summary and the
/// labelled fields that have values.
class GapEntry {
  const GapEntry({required this.title, this.subtitle, required this.fields});

  final String title;
  final String? subtitle;
  final List<(String, String)> fields;
}

/// Thai labels for the API's enum values and record fields, shared by the
/// farmer summary, the staff inspection and the PDF report.
abstract final class GapLabels {
  static const _values = <String, Map<String, String>>{
    'farmingSystem': {
      'ORGANIC': 'เกษตรอินทรีย์',
      'GAP': 'GAP',
      'CHEMICAL': 'ใช้สารเคมี',
      'SAFE': 'ปลอดภัย',
      'TRANSITION': 'ระยะปรับเปลี่ยน',
      'NON_ORGANIC': 'ทั่วไป',
    },
    'activityType': {
      'SOIL_PREP': 'เตรียมดิน',
      'PLANTING': 'ปลูก',
      'CARE': 'ดูแลรักษา',
      'FERTILIZING': 'ใส่ปุ๋ย',
      'WATERING': 'ให้น้ำ',
      'PEST_CONTROL': 'ป้องกันกำจัดศัตรูพืช',
      'WEEDING': 'กำจัดวัชพืช',
      'PRUNING': 'ตัดแต่งกิ่ง',
      'HARVEST': 'เก็บเกี่ยว',
      'POST_HARVEST': 'จัดการหลังเก็บเกี่ยว',
    },
    'landOwnership': {
      'OWNED': 'เป็นเจ้าของ',
      'RENTED': 'เช่า',
      'PUBLIC': 'ที่สาธารณะ',
      'ROYAL': 'ที่ราชพัสดุ',
    },
    'soilType': {
      'CLAY': 'ดินเหนียว',
      'LOAM': 'ดินร่วน',
      'SAND': 'ดินทราย',
      'SILT': 'ดินตะกอน',
    },
    'waterSource': {
      'IRRIGATION': 'ชลประทาน',
      'RIVER': 'แม่น้ำ ลำคลอง',
      'GROUNDWATER': 'น้ำบาดาล',
      'RAINWATER': 'น้ำฝน',
      'POND': 'สระน้ำ',
    },
    'irrigationSystem': {
      'SPRINKLER': 'สปริงเกอร์',
      'DRIP': 'น้ำหยด',
      'FLOOD': 'ปล่อยท่วม',
      'MANUAL': 'รดด้วยมือ',
    },
    'type': {
      'SEED': 'เมล็ดหรือกิ่งพันธุ์',
      'FERTILIZER': 'ปุ๋ย',
      'PESTICIDE': 'สารป้องกันกำจัดศัตรูพืช',
      'HERBICIDE': 'สารกำจัดวัชพืช',
      'HORMONE': 'ฮอร์โมนพืช',
      'BIO': 'ชีวภัณฑ์',
      'OTHER': 'อื่น ๆ',
    },
  };

  static const _common = {
    'KRATOM': 'กระท่อม',
    'KG': 'กก.',
    'LITER': 'ลิตร',
    'RAI': 'ไร่',
    'BOTTLE': 'ขวด',
    'BAG': 'ถุง',
    'TRUE': 'ใช่',
    'FALSE': 'ไม่ใช่',
  };

  static const fieldLabels = {
    'plotName': 'ชื่อแปลง',
    'farmerName': 'ชื่อเกษตรกร',
    'address': 'ที่อยู่',
    'subDistrict': 'ตำบล',
    'district': 'อำเภอ',
    'province': 'จังหวัด',
    'zipcode': 'รหัสไปรษณีย์',
    'farmingSystem': 'ระบบการผลิต',
    'cropType': 'พืชที่ปลูก',
    'cropVariety': 'สายพันธุ์',
    'landOwnership': 'กรรมสิทธิ์ที่ดิน',
    'area': 'พื้นที่ (ไร่)',
    'waterSource': 'แหล่งน้ำ',
    'irrigationSystem': 'ระบบให้น้ำ',
    'soilType': 'ชนิดดิน',
    'registerDate': 'วันที่ขึ้นทะเบียน',
    'expireDate': 'วันหมดอายุ',
  };

  /// Translates one value. Lists are joined, ISO timestamps become Thai
  /// dates, unknown codes pass through unchanged.
  static String value(String key, Object? raw) {
    if (raw == null) return '-';
    if (raw is List) {
      final parts = raw.map((v) => value(key, v)).where((s) => s != '-').toList();
      return parts.isEmpty ? '-' : parts.join(', ');
    }
    if (raw is bool) return raw ? 'ใช่' : 'ไม่ใช่';
    final s = raw.toString().trim();
    if (s.isEmpty || s == 'null') return '-';
    if (s.contains('T') && s.length >= 10) {
      final date = DateTime.tryParse(s);
      if (date != null) return ThaiDate.short(date.toLocal());
    }
    final upper = s.toUpperCase();
    return _values[key]?[upper] ?? _common[upper] ?? s;
  }

  static bool _has(String v) => v != '-' && v.isNotEmpty;

  /// General information as label and value pairs, skipping empty fields.
  static List<(String, String)> general(Map<String, dynamic> data, {String? plotName}) => [
        for (final key in fieldLabels.keys)
          if (_has(value(key, key == 'plotName' ? (data[key] ?? plotName) : data[key])))
            (fieldLabels[key]!, value(key, key == 'plotName' ? (data[key] ?? plotName) : data[key])),
      ];

  /// A one-line summary of a category for list rows.
  static String summary(GapCategory c, GapProgress p) {
    final n = p.count(c);
    if (n == 0) return 'ยังไม่มีบันทึก';
    return switch (c) {
      GapCategory.general => [
          if (p.general?['farmingSystem'] != null) value('farmingSystem', p.general!['farmingSystem']),
          if (p.general?['waterSource'] != null) value('waterSource', p.general!['waterSource']),
        ].where(_has).join(' · ').ifEmpty('บันทึกแล้ว'),
      GapCategory.inputs => '$n รายการ',
      GapCategory.management => '$n กิจกรรม',
      GapCategory.harvest => '$n ครั้ง',
      GapCategory.postHarvest => '$n รายการ',
      GapCategory.safety => '$n หัวข้ออบรม',
      GapCategory.traceability => '$n ล็อต',
    };
  }

  /// A list record (input, activity, harvest ...) ready for display.
  static GapEntry entry(GapCategory c, Map<dynamic, dynamic> item, int index) {
    String v(String key, [Object? raw]) => value(key, raw ?? item[key]);
    List<(String, String)> rows(List<(String, String)> all) =>
        all.where((r) => _has(r.$2)).toList();

    switch (c) {
      case GapCategory.inputs:
        final qty = v('quantity');
        final type = v('type');
        return GapEntry(
          title: v('name', item['name'] ?? item['inputName']).ifDash('ปัจจัยการผลิต'),
          subtitle: _has(qty) && qty != '0' ? '$qty ${v('unit')} · $type' : type,
          fields: rows([
            ('ประเภท', type),
            ('แหล่งที่ซื้อ', v('source')),
            ('วันที่ซื้อ', v('purchaseDate')),
            ('เลขทะเบียน', v('registrationNo')),
            ('วิธีใช้', v('usageMethod')),
            ('อัตราการใช้', v('usageRate')),
            ('ผู้บันทึก', v('recorder')),
          ]),
        );
      case GapCategory.management:
        final activity = v('activityType', item['activityType'] ?? item['activity']);
        final description = v('description');
        final material = v('material', item['material'] ?? item['chemicalUsed'] ?? item['machineUsed']);
        return GapEntry(
          title: _has(activity) ? activity : description.ifDash('กิจกรรมในแปลง'),
          subtitle: v('date', item['activityDate'] ?? item['date']),
          fields: rows([
            ('รายละเอียด', description),
            ('วัสดุหรือสารที่ใช้', material),
            ('ผู้ปฏิบัติงาน', v('operator', item['workerName'] ?? item['operator'])),
          ]),
        );
      case GapCategory.harvest || GapCategory.traceability:
        final amount = '${v('yieldAmount')} ${v('yieldUnit', item['yieldUnit'] ?? 'KG')}';
        final lot = v('lot', item['lotNumber'] ?? item['lotNo']);
        return GapEntry(
          title: c == GapCategory.traceability && _has(lot) ? lot : 'เก็บเกี่ยว $amount',
          subtitle: [v('date', item['harvestDate']), if (_has(v('qualityGrade'))) 'เกรด ${v('qualityGrade')}']
              .where(_has)
              .join(' · '),
          fields: rows([
            ('เลขล็อต', lot),
            ('ปริมาณ', amount),
            ('ผู้เก็บเกี่ยว', v('harvestedBy')),
            ('วิธีหรืออุปกรณ์', v('method', item['harvestMethod'] ?? item['equipmentUsed'])),
            ('ภาชนะบรรจุ', v('container')),
            ('การขนย้าย', v('transport')),
            ('หมายเหตุ', v('note', item['notes'] ?? item['note'])),
          ]),
        );
      case GapCategory.postHarvest:
        final temp = item['storageTemperature'] ?? item['storageTemp'];
        final humidity = item['humidity'] ?? item['storageHumidity'];
        return GapEntry(
          title: v('activity', item['activity'] ?? item['processType']).ifDash('หลังการเก็บเกี่ยว'),
          subtitle: v('date', item['date'] ?? item['processDate']),
          fields: rows([
            ('วิธีแปรรูป', v('method', item['method'] ?? item['processType'])),
            ('บรรจุภัณฑ์', v('packaging', item['packagingType'] ?? item['packaging'])),
            ('สถานที่เก็บ', v('storageLocation')),
            ('อุณหภูมิ', temp == null ? '-' : '$temp °C'),
            ('ความชื้น', humidity == null ? '-' : '$humidity %'),
            ('ขั้นตอน', v('description', item['description'] ?? item['cleaning'])),
          ]),
        );
      case GapCategory.safety:
        return GapEntry(
          title: v('topic', item['topic'] ?? item['trainingTopic']).ifDash('การอบรม'),
          subtitle: v('trainingDate'),
          fields: rows([
            ('วิทยากรหรือผู้จัด', v('trainer')),
            ('สถานที่', v('location')),
            ('ระยะเวลา', item['durationHours'] == null ? '-' : '${item['durationHours']} ชั่วโมง'),
            ('ผู้เข้าร่วม', item['attendees'] == null ? '-' : '${item['attendees']} คน'),
            ('สุขลักษณะ', v('hygiene', item['hygieneNotes'] ?? item['hygieneFlags'])),
            ('ผลการประเมิน', v('result')),
          ]),
        );
      case GapCategory.general:
        return GapEntry(title: 'รายการที่ ${index + 1}', fields: const []);
    }
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
  String ifDash(String fallback) => this == '-' || isEmpty ? fallback : this;
}
