import 'package:flutter_test/flutter_test.dart';
import 'package:taptom/data/models/trace_report.dart';

// Trimmed from a real GET /traceability/:lotNumber response.
const _api = {
  'lotInformation': {
    'harvestDate': '2026-08-18T00:00:00.000Z',
    'yieldAmount': 310,
    'yieldUnit': 'kg',
    'lotNumber': 'PLOT-cmuqoa24-20261002-0001',
    'qualityGrade': 'A',
    'plot': {
      'name': 'สวนกระท่อมหนองปลิง',
      'area': 8790.2,
      'status': 'APPROVED',
      'ownerName': 'สมชาย ใจดี',
      'species': 'กระท่อมพันธุ์ก้านแดง',
      'province': 'พิษณุโลก',
      'district': 'วังทอง',
      'subDistrict': 'ชัยนาม',
    },
  },
  'sourceOrigin': {
    'plotName': 'สวนกระท่อมหนองปลิง',
    'address': 'ชัยนาม, วังทอง, พิษณุโลก',
    'farmer': 'สมชาย ใจดี',
    'location': {
      'type': 'Polygon',
      'coordinates': [
        [
          [100.4335, 16.8408],
          [100.4339, 16.8404],
          [100.4334, 16.8396],
          [100.4335, 16.8408],
        ],
      ],
    },
    'gapStatus': 'GREEN',
    'gapSeason': 'รอบปลูก 2567/1',
  },
  'productionHistory': {
    'inputsUsed': [
      {'type': 'PESTICIDE', 'name': 'สารสกัดสะเดา', 'amount': 2, 'unit': 'L', 'usedDate': '2026-07-30T00:00:00.000Z'},
    ],
    'harvestHistory': [
      {'lotNumber': 'PLOT-cmuqoa24-20261002-0001', 'yieldAmount': 310},
    ],
  },
  'certification': {'gapStatus': 'GREEN'},
};

void main() {
  test('reads the API report blocks', () {
    final r = TraceReport.fromJson(_api, lotNumber: 'ignored');
    expect(r.lotNumber, 'PLOT-cmuqoa24-20261002-0001');
    expect(r.quantity, 310);
    expect(r.unit, 'kg');
    expect(r.grade, 'A');
    expect(r.plotName, 'สวนกระท่อมหนองปลิง');
    expect(r.farmerName, 'สมชาย ใจดี');
    expect(r.place, 'ต.ชัยนาม อ.วังทอง จ.พิษณุโลก');
    expect(r.areaRai, closeTo(5.49, 0.01));
    expect(r.certified, isTrue);
    expect(r.geometry?['type'], 'Polygon');
    expect(r.inputs.single['name'], 'สารสกัดสะเดา');
    expect(r.harvests, hasLength(1));
  });

  test('a plot under review is not certified even with a green GAP light', () {
    final json = {
      ..._api,
      'lotInformation': {
        ..._api['lotInformation']!,
        'plot': {'status': 'PENDING'},
      },
    };
    expect(TraceReport.fromJson(json, lotNumber: 'x').certified, isFalse);
  });

  test('an empty body still gives a usable report', () {
    final r = TraceReport.fromJson(const {}, lotNumber: 'TPT-1');
    expect(r.lotNumber, 'TPT-1');
    expect(r.place, '');
    expect(r.certified, isFalse);
    expect(r.inputs, isEmpty);
  });
}
