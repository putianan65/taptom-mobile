# PDF Generator Service - Production Ready

## คุณสมบัติหลัก

### การปรับปรุงจากเวอร์ชันเดิม

| Feature | เวอร์ชันเก่า | เวอร์ชันใหม่ |
|---------|------------|-------------|
| **แสดงข้อมูล** | แสดงแค่ 10 รายการ | แสดงทั้งหมด ไม่จำกัด |
| **รูปแบบ** | Bullet points | ตารางมีโครงสร้าง |
| **รูปแปลง** | แสดงแค่จุดเดียว | แสดง polygon ทั้งหมด |
| **รูปภาพ** | สูงสุด 4 รูป | สูงสุด 8 รูป |
| **Error Handling** | ไม่มี | ครบถ้วน + Custom Exceptions |
| **Progress Tracking** | ไม่มี | มี Callback |
| **Security** | API Key hardcoded | Support Environment Variables |

---

## การใช้งาน

### Basic Usage

```dart
import 'package:your_app/services/pdf_generator_service.dart';

final pdfService = PdfGeneratorService();

try {
  final pdfBytes = await pdfService.generateGapReport(
    plot: plotData,
    owner: ownerData,
    summaryData: gapSummaryData,
  );
  
  // แสดง print dialog
  await Printing.layoutPdf(
    onLayout: (format) => pdfBytes,
    name: 'รายงาน_GAP_${plotData['name']}.pdf',
  );
  
} on PdfGenerationException catch (e) {
  // จัดการ error ที่เกิดขึ้น
  print('Error: ${e.message}');
}
```

### With Progress Tracking

```dart
final pdfBytes = await pdfService.generateGapReport(
  plot: plotData,
  owner: ownerData,
  summaryData: gapSummaryData,
  onProgress: (stage, progress) {
    setState(() {
      _progressMessage = stage;
      _progressValue = progress;
    });
    print('[$stage] ${(progress * 100).toInt()}%');
  },
);
```

---

## โครงสร้างข้อมูลที่รองรับ

### 1. Plot Data

```dart
{
  'id': 'plot_123',
  'name': 'แปลงมะม่วง A1',
  'species': 'มะม่วงน้ำดอกไม้',
  'areaRai': 5.5,
  'status': 'APPROVED', // PENDING, REJECTED, DRAFT
  'province': 'เชียงใหม่',
  'district': 'สันทราย',
  'subDistrict': 'หนองจ๊อม',
  'geometry': {
    'type': 'Polygon',
    'coordinates': [
      [
        [98.12345, 18.98765],  // [lng, lat]
        [98.12346, 18.98766],
        [98.12347, 18.98765],
        [98.12345, 18.98765],  // ปิดรูป polygon
      ]
    ]
  },
  'imageUrls': [
    'https://example.com/photo1.jpg',
    'https://example.com/photo2.jpg',
    // ... สูงสุด 8 รูป
  ],
  'owner': {
    'fullName': 'นายสมชาย ใจดี',
    'phone': '081-234-5678',
  }
}
```

### 2. Owner Data (Optional)

```dart
{
  'fullName': 'นายสมชาย ใจดี',
  'firstName': 'สมชาย',
  'lastName': 'ใจดี',
  'phone': '081-234-5678',
  'tel': '081-234-5678',  // fallback
  'phoneNumber': '081-234-5678',  // fallback
}
```

### 3. Summary Data (GAP)

```dart
{
  'general': {
    'completed': true,
    'data': {
      'waterSource': 'บ่อน้ำบาดาล',
      'soilType': 'ดินร่วน',
      'plantingDate': '2024-01-15',
      'certificationGoal': 'Q GAP',
      'farmType': 'ไร่นา',
      'irrigationSystem': 'ระบบน้ำหยด',
      'previousCrop': 'ข้าวโพด',
    }
  },
  
  'inputs': {
    'completed': true,
    'data': [
      {
        'date': '2024-02-01',
        'type': 'ปุ๋ย',
        'name': 'ยูเรีย 46%',
        'source': 'ร้านเกษตรบ้านสวน',
        'amount': '20',
        'unit': 'กก.',
      },
      {
        'date': '2024-02-15',
        'type': 'สารเคมี',
        'name': 'คาร์โบซัลแฟน 3%',
        'source': 'สหกรณ์',
        'amount': '500',
        'unit': 'มล.',
      },
      // ... ไม่จำกัดจำนวน
    ]
  },
  
  'management': {
    'completed': true,
    'data': [
      {
        'date': '2024-02-10',
        'activity': 'พรวนดิน',
        'note': 'พรวนรอบโคนต้น',
      },
      {
        'date': '2024-02-20',
        'activity': 'ตัดแต่งกิ่ง',
        'note': 'ตัดกิ่งแห้งและกิ่งที่แคบเกินไป',
      },
      // ...
    ]
  },
  
  'harvest': {
    'completed': true,
    'data': [
      {
        'harvestDate': '2024-03-01',
        'batchNumber': 'H001',
        'harvestMethod': 'เก็บด้วยมือ',
        'weightKg': 150.5,
      },
      // ...
    ]
  },
  
  'postHarvest': {
    'completed': true,
    'data': [
      {
        'date': '2024-03-01',
        'activity': 'คัดแยกขนาด',
        'location': 'โรงคัดผล',
      },
      // ...
    ]
  },
  
  'safety': {
    'completed': true,
    'data': [
      {
        'date': '2024-01-20',
        'topic': 'การใช้สารเคมีอย่างปลอดภัย',
        'attendees': 15,
      },
      // ...
    ]
  },
  
  'traceability': {
    'completed': true,
    'data': [
      {
        'date': '2024-03-01',
        'lotNumber': 'LOT-2024-001',
        'details': 'ส่งตลาดกลางพืชผล',
      },
      // ...
    ]
  }
}
```

---

## Security: API Key Configuration

### วิธีที่ 1: ใช้ --dart-define (แนะนำ)

```bash
# Development
flutter run --dart-define=MAPTILER_API_KEY=your_dev_key_here

# Build Production APK
flutter build apk --dart-define=MAPTILER_API_KEY=your_prod_key_here

# Build iOS
flutter build ios --dart-define=MAPTILER_API_KEY=your_prod_key_here
```

### วิธีที่ 2: ใช้ flutter_dotenv

1. ติดตั้ง package:

```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.0.2

flutter:
  assets:
    - .env
```

2. สร้างไฟล์ `.env`:

```env
MAPTILER_API_KEY=your_api_key_here
```

3. เพิ่มใน `.gitignore`:

```gitignore
.env
```

4. โหลดใน `main.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

5. ปรับ `PdfConfig`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PdfConfig {
  static String get mapApiKey {
    return dotenv.env['MAPTILER_API_KEY'] ?? '';
  }
}
```

---

## การแสดงผลในรายงาน PDF

### 1. หน้าแรก - ข้อมูลทั่วไป
- ชื่อรายงาน + วันที่พิมพ์
- กล่องข้อมูลแปลง (ชื่อ, พืช, พื้นที่, สถานะ)
- ข้อมูลเกษตรกร (ชื่อ, เบอร์โทร, ที่อยู่)

### 2. แผนที่
- แสดง satellite map พร้อม **polygon overlay สีเขียว**
- แสดงพิกัดทุกจุดของแปลง (ถ้ามี)
- Marker สีแดงที่จุดกลางแปลง

### 3. รายละเอียด GAP (7 หมวด)

**หมวดที่มีตาราง:**

| หมวด | คอลัมน์ที่แสดง |
|------|---------------|
| **1. ข้อมูลทั่วไป** | Key-Value pairs |
| **2. วัสดุและปัจจัยการผลิต** | วันที่ \| ประเภท \| ชื่อ/ชนิด \| แหล่งที่มา \| ปริมาณ |
| **3. การดูแลรักษาแปลง** | วันที่ \| กิจกรรม \| หมายเหตุ |
| **4. การเก็บเกี่ยว** | วันที่ \| รุ่นที่ \| วิธีการ \| ปริมาณ (กก.) |
| **5. หลังการเก็บเกี่ยว** | วันที่ \| กิจกรรม \| สถานที่ |
| **6. สุขลักษณะและความปลอดภัย** | วันที่ \| หัวข้อ \| ผู้เข้าอบรม |
| **7. การตรวจสอบย้อนกลับ** | วันที่ \| Lot Number \| รายละเอียด |

**แสดงข้อมูลครบทั้งหมด - ไม่จำกัดจำนวน**

### 4. รูปภาพแปลง
- แสดงได้สูงสุด 8 รูป
- Layout แบบ grid 4 คอลัมน์
- Auto pagination ถ้ารูปเยอะ

### 5. ลายเซ็น
- ช่องสำหรับผู้จัดทำรายงาน
- ช่องสำหรับผู้ตรวจสอบ/รับรอง
- ช่องวันที่

---

## ตัวอย่าง UI Integration

### Widget พร้อม Progress Indicator

```dart
class ExportGapReportButton extends StatefulWidget {
  final Map<String, dynamic> plot;
  final Map<String, dynamic>? owner;
  final Map<String, dynamic> summaryData;
  
  const ExportGapReportButton({
    Key? key,
    required this.plot,
    this.owner,
    required this.summaryData,
  }) : super(key: key);

  @override
  State<ExportGapReportButton> createState() => _ExportGapReportButtonState();
}

class _ExportGapReportButtonState extends State<ExportGapReportButton> {
  final _pdfService = PdfGeneratorService();
  bool _isGenerating = false;
  String _progressMsg = '';
  double _progressValue = 0.0;

  Future<void> _handleExport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final pdfBytes = await _pdfService.generateGapReport(
        plot: widget.plot,
        owner: widget.owner,
        summaryData: widget.summaryData,
        onProgress: (stage, progress) {
          if (mounted) {
            setState(() {
              _progressMsg = stage;
              _progressValue = progress;
            });
          }
        },
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: 'GAP_${widget.plot['name']}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สร้างรายงาน PDF สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on PdfGenerationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _progressMsg = '';
          _progressValue = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : _handleExport,
          icon: _isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Icon(Icons.picture_as_pdf),
          label: Text(_isGenerating ? 'กำลังสร้าง PDF...' : 'ส่งออกรายงาน PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        
        if (_isGenerating) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 280,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _progressValue,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(Colors.green[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  _progressMsg,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${(_progressValue * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
```

---

## Testing

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PdfGeneratorService service;

  setUp(() {
    service = PdfGeneratorService();
  });

  group('PdfGeneratorService', () {
    test('should throw PdfGenerationException when plot is empty', () async {
      expect(
        () => service.generateGapReport(
          plot: {},
          owner: null,
          summaryData: {},
        ),
        throwsA(isA<PdfGenerationException>()),
      );
    });

    test('should throw PdfGenerationException when plot name is missing', () async {
      expect(
        () => service.generateGapReport(
          plot: {'id': '123'},
          owner: null,
          summaryData: {},
        ),
        throwsA(isA<PdfGenerationException>()),
      );
    });

    test('should generate PDF successfully with valid data', () async {
      final plot = {
        'id': 'plot_123',
        'name': 'แปลงทดสอบ',
        'species': 'มะม่วง',
        'areaRai': 5.0,
        'status': 'APPROVED',
      };

      final bytes = await service.generateGapReport(
        plot: plot,
        owner: null,
        summaryData: {},
      );

      expect(bytes, isNotEmpty);
      expect(bytes, isA<Uint8List>());
    });
  });
}
```

---

## Migration Guide

### จากเวอร์ชันเก่าไปใหม่

**1. เปลี่ยน import (ถ้าจำเป็น):**

```dart
// เดิม
import 'package:your_app/services/pdf_generator.dart';

// ใหม่
import 'package:your_app/services/pdf_generator_service.dart';
```

**2. เพิ่ม Error Handling:**

```dart
// เดิม
final pdf = await pdfService.generateGapReport(...);

// ใหม่
try {
  final pdf = await pdfService.generateGapReport(...);
  // success
} on PdfGenerationException catch (e) {
  // handle error
  print('PDF Error: ${e.message}');
}
```

**3. เพิ่ม Progress Tracking (ถ้าต้องการ):**

```dart
final pdf = await pdfService.generateGapReport(
  ...,
  onProgress: (stage, progress) {
    print('[$stage] ${(progress * 100).toInt()}%');
  },
);
```

**4. ตั้งค่า API Key:**

เลือกวิธีใดวิธีหนึ่ง:
- `--dart-define` สำหรับ production
- `.env` สำหรับ development

---

## Known Limitations

1. **Polygon Overlay**: MapTiler API อาจมีข้อจำกัดในการแสดง polygon ที่ซับซ้อนมาก
2. **Image Loading**: รูปภาพที่เกิน 8 รูปจะถูกตัดทิ้ง
3. **Network Timeout**: ตั้งไว้ที่ 15 วินาที - ถ้าเน็ตช้ามากอาจ timeout
4. **Font Caching**: Cache อยู่ใน memory - app restart จะต้องโหลดใหม่

---

## Troubleshooting

### ปัญหา: "ไม่สามารถโหลดฟอนต์ได้"

**สาเหตุ:** Network timeout หรือ PdfGoogleFonts service ไม่ตอบสนอง

**แก้ไข:**
1. ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
2. เพิ่ม timeout ใน `PdfConfig.fontLoadTimeout`
3. ใช้ local fonts แทน (ดูเอกสาร pdf package)

### ปัญหา: "แผนที่ไม่แสดง"

**สาเหตุ:** 
- API Key ไม่ถูกต้อง
- Coordinates ไม่ valid
- Network timeout

**แก้ไข:**
1. ตรวจสอบ API Key
2. ตรวจสอบ coordinates ว่าเป็น valid lat/lng
3. ดู console logs

### ปัญหา: "รูปภาพบางรูปไม่แสดง"

**สาเหตุ:** URL ไม่ valid หรือ image host ไม่ตอบสนอง

**แก้ไข:**
- PDF จะแสดงเฉพาะรูปที่โหลดสำเร็จ
- รูปที่ไม่สำเร็จจะถูกข้าม
- ดู console เพื่อดู warning messages

---

## Performance Tips

1. **ใช้ Font Cache**: Font จะถูก cache หลังครั้งแรก
2. **จำกัดรูปภาพ**: อย่าส่งรูปเกิน 8 รูป
3. **Optimize Images**: ใช้รูปขนาดไม่เกิน 1-2 MB
4. **Async Loading**: ระบบโหลดรูปทีละ 3 รูป (concurrent)

---

## Best Practices

1. **Always use try-catch** เมื่อเรียก generateGapReport
2. **Show loading indicator** ให้ user รู้ว่ากำลังประมวลผล
3. **Handle errors gracefully** แสดงข้อความที่เป็นมิตร
4. **Use progress callback** เพื่อ UX ที่ดีขึ้น
5. **Validate data** ก่อนส่งเข้า service
6. **Keep API keys secure** ห้าม commit ลง Git

---

## Support

ถ้ามีปัญหาหรือข้อสงสัย:
1. ดู Troubleshooting section
2. ตรวจสอบ console logs
3. ตรวจสอบ error messages
4. ติดต่อทีมพัฒนา

---

## License

MIT License - ดูไฟล์ LICENSE สำหรับรายละเอียด
