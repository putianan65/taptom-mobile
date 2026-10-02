import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../utils/date_formatter.dart';
import '../config/env.dart';
import 'pdf_assets.dart';

// ==================== EXCEPTIONS ====================

class PdfGenerationException implements Exception {
  final String message;
  final dynamic originalError;
  
  PdfGenerationException(this.message, [this.originalError]);
  
  @override
  String toString() => 'PdfGenerationException: $message';
}

// ==================== CONFIG ====================

class PdfConfig {
  // ⚠️ PRODUCTION: ย้ายไปใช้ Environment Variable
  static String get mapApiKey {
    const key = String.fromEnvironment('MAPTILER_API_KEY', defaultValue: '');
    if (key.isEmpty) {
      // Read from dotenv at runtime
      return _getRuntimeMapKey();
    }
    return key;
  }

  static String _getRuntimeMapKey() {
    try {
      // Import handled via top-level import
      return Env.mapTilerApiKey;
    } catch (_) {
      return '';
    }
  }
  
  static const Duration networkTimeout = Duration(seconds: 15);
  static const int maxPhotos = 8; // เพิ่มจาก 4 เป็น 8 รูป
  static const int maxConcurrentFetch = 3;
  
  // Colors
  static const PdfColor primary = PdfColors.green800;
  static const PdfColor secondary = PdfColors.green50;
  static const PdfColor border = PdfColors.green200;
  static const PdfColor tableHeader = PdfColors.green100;
  static const PdfColor textDark = PdfColors.grey900;
  static const PdfColor textLight = PdfColors.grey700;
}

// ==================== PROGRESS CALLBACK ====================

typedef PdfProgress = void Function(String stage, double progress);

// ==================== MAIN SERVICE ====================

class PdfGeneratorService {
  // Font Cache
  static pw.Font? _fontCache;
  static pw.Font? _fontBoldCache;
  
  Future<Uint8List> generateGapReport({
    required Map<String, dynamic> plot,
    required Map<String, dynamic>? owner,
    required Map<String, dynamic> summaryData,
    PdfProgress? onProgress,
  }) async {
    try {
      onProgress?.call('กำลังตรวจสอบข้อมูล...', 0.05);
      _validateInputs(plot);
      
      onProgress?.call('กำลังโหลดฟอนต์...', 0.1);
      final font = await _loadFont();
      final fontBold = await _loadFontBold();
      
      onProgress?.call('กำลังประมวลผลข้อมูล...', 0.2);
      final ownerInfo = _getOwnerInfo(plot, owner);
      
      onProgress?.call('กำลังดาวน์โหลดแผนที่...', 0.3);
      final mapBytes = await _loadMapImage(plot);
      
      onProgress?.call('กำลังดาวน์โหลดรูปภาพ...', 0.5);
      final photoBytes = await _loadPlotPhotos(plot);
      
      onProgress?.call('กำลังสร้างเอกสาร...', 0.7);
      
      final pdf = pw.Document();
      final theme = pw.ThemeData.withFont(base: font, bold: fontBold);

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
          ),
          header: (ctx) => _header(ctx, fontBold),
          footer: (ctx) => _footer(ctx),
          build: (ctx) => [
            _reportTitle(fontBold),
            pw.SizedBox(height: 16),
            _infoBox(plot, ownerInfo, fontBold),
            pw.SizedBox(height: 16),
            
            // แผนที่ + ข้อมูลพิกัด
            if (mapBytes != null) ...[
              _sectionHeader('ตำแหน่งที่ตั้งแปลง', fontBold),
              pw.SizedBox(height: 8),
              _mapImage(mapBytes),
              pw.SizedBox(height: 4),
              _coordinateInfo(plot),
              pw.SizedBox(height: 16),
            ],
            
            // รายละเอียด GAP แบบตาราง
            _sectionHeader('รายละเอียดข้อมูล GAP', fontBold),
            pw.SizedBox(height: 8),
            ..._gapDetailsTables(summaryData, fontBold),
            
            // รูปภาพ
            if (photoBytes.isNotEmpty) ...[
              pw.NewPage(),
              _sectionHeader('รูปถ่ายสภาพแปลง (${photoBytes.length} รูป)', fontBold),
              pw.SizedBox(height: 8),
              _photoGrid(photoBytes),
            ],
            
            // ลายเซ็น
            pw.SizedBox(height: 32),
            _signatureArea(fontBold),
          ],
        ),
      );
      
      onProgress?.call('กำลังบันทึกไฟล์...', 0.95);
      final bytes = await pdf.save();
      
      onProgress?.call('เสร็จสิ้น', 1.0);
      return bytes;
      
    } on PdfGenerationException {
      rethrow;
    } catch (e, stack) {
      print('❌ PDF Generation Error: $e\n$stack');
      throw PdfGenerationException('ไม่สามารถสร้าง PDF ได้', e);
    }
  }

  // ==================== VALIDATION ====================
  
  void _validateInputs(Map<String, dynamic> plot) {
    if (plot.isEmpty) {
      throw PdfGenerationException('ข้อมูลแปลงว่างเปล่า');
    }
    if (_safe(plot['name']) == '-') {
      throw PdfGenerationException('ไม่พบชื่อแปลง');
    }
  }

  // ==================== FONT LOADING ====================
  
  Future<pw.Font> _loadFont() async {
    if (_fontCache != null) return _fontCache!;
    try {
      _fontCache = await PdfAssets.regular();
      return _fontCache!;
    } catch (e) {
      throw PdfGenerationException('ไม่สามารถโหลดฟอนต์ได้', e);
    }
  }
  
  Future<pw.Font> _loadFontBold() async {
    if (_fontBoldCache != null) return _fontBoldCache!;
    try {
      _fontBoldCache = await PdfAssets.bold();
      return _fontBoldCache!;
    } catch (e) {
      throw PdfGenerationException('ไม่สามารถโหลดฟอนต์ตัวหนาได้', e);
    }
  }

  // ==================== HEADER / FOOTER ====================

  pw.Widget _header(pw.Context ctx, pw.Font fontBold) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Text('TapTom', 
                style: pw.TextStyle(
                  font: fontBold, 
                  fontSize: 14, 
                  color: PdfConfig.primary
                )
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfConfig.primary),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  'GAP Report',
                  style: const pw.TextStyle(fontSize: 8, color: PdfConfig.primary),
                ),
              ),
            ],
          ),
          pw.Text(
            'รายงานตรวจประเมินมาตรฐาน GAP', 
            style: const pw.TextStyle(fontSize: 10, color: PdfConfig.textLight)
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'พิมพ์โดย: TapTom System • ${DateFormatter.formatThaiDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'หน้า ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  // ==================== TITLE ====================

  pw.Widget _reportTitle(pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'รายงานผลการตรวจประเมินแปลงเกษตร',
              style: pw.TextStyle(
                font: fontBold, 
                fontSize: 20, 
                color: PdfConfig.primary
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                'ฉบับสมบูรณ์',
                style: pw.TextStyle(
                  fontSize: 10, 
                  color: PdfColors.blue900,
                  font: fontBold,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'วันที่พิมพ์: ${DateFormatter.formatThaiDateTime(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfConfig.textLight),
        ),
        pw.Divider(color: PdfConfig.primary, thickness: 2),
      ],
    );
  }

  // ==================== INFO BOX ====================

  pw.Widget _infoBox(
    Map<String, dynamic> plot, 
    Map<String, String> ownerInfo, 
    pw.Font fontBold
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfConfig.secondary,
        border: pw.Border.all(color: PdfConfig.border),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          // Row 1: Plot Info
          pw.Row(
            children: [
              pw.Expanded(
                child: _infoItem('ชื่อแปลง', _safe(plot['name']), fontBold),
              ),
              pw.Expanded(
                child: _infoItem('พืชที่ปลูก', _safe(plot['species']), fontBold),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          
          // Row 2: Area & Status
          pw.Row(
            children: [
              pw.Expanded(
                child: _infoItem('พื้นที่', '${_num(plot['areaRai'])} ไร่', fontBold),
              ),
              pw.Expanded(
                child: _infoItem('สถานะ', _translateStatus(plot['status']), fontBold),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          
          // Row 3: Owner Info
          pw.Row(
            children: [
              pw.Expanded(
                child: _infoItem('ชื่อเกษตรกร', ownerInfo['name'] ?? '-', fontBold),
              ),
              pw.Expanded(
                child: _infoItem('โทรศัพท์', ownerInfo['phone'] ?? '-', fontBold),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          
          // Row 4: Address
          _infoItem('ที่ตั้งแปลง', _getAddress(plot), fontBold),
        ],
      ),
    );
  }

  pw.Widget _infoItem(String label, String value, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label, 
          style: pw.TextStyle(
            font: fontBold, 
            fontSize: 10, 
            color: PdfConfig.textLight
          )
        ),
        pw.SizedBox(height: 2),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  // ==================== SECTION HEADER ====================

  pw.Widget _sectionHeader(String title, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: const pw.BoxDecoration(
        color: PdfConfig.tableHeader,
        border: pw.Border(
          left: pw.BorderSide(color: PdfConfig.primary, width: 4),
        ),
      ),
      child: pw.Text(
        title, 
        style: pw.TextStyle(font: fontBold, fontSize: 12)
      ),
    );
  }

  // ==================== MAP ====================

  pw.Widget _mapImage(Uint8List bytes) {
    return pw.Container(
      height: 200,
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 4,
        verticalRadius: 4,
        child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
      ),
    );
  }
  
  pw.Widget _coordinateInfo(Map<String, dynamic> plot) {
    final coords = _getPolygonCoordinates(plot);
    if (coords.isEmpty) return pw.SizedBox();
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'จุดพิกัดขอบเขตแปลง (${coords.length} จุด)',
            style: const pw.TextStyle(fontSize: 9, color: PdfConfig.textLight),
          ),
          pw.SizedBox(height: 4),
          pw.Wrap(
            spacing: 12,
            runSpacing: 2,
            children: coords.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final coord = entry.value;
              return pw.Text(
                'จุดที่ $idx: ${coord['lat']}, ${coord['lng']}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== GAP DETAILS WITH TABLES ====================

  List<pw.Widget> _gapDetailsTables(Map<String, dynamic> summary, pw.Font fontBold) {
    final widgets = <pw.Widget>[];
    
    final categories = [
      {'key': 'general', 'label': '1. ข้อมูลทั่วไป', 'hasTable': false},
      {'key': 'inputs', 'label': '2. วัสดุและปัจจัยการผลิต', 'hasTable': true},
      {'key': 'management', 'label': '3. การดูแลรักษาแปลง', 'hasTable': true},
      {'key': 'harvest', 'label': '4. การเก็บเกี่ยว', 'hasTable': true},
      {'key': 'postHarvest', 'label': '5. หลังการเก็บเกี่ยว', 'hasTable': true},
      {'key': 'safety', 'label': '6. สุขลักษณะและความปลอดภัย', 'hasTable': true},
      {'key': 'traceability', 'label': '7. การตรวจสอบย้อนกลับ', 'hasTable': true},
    ];

    for (final cat in categories) {
      final key = cat['key']!;
      final catData = summary[key] as Map<String, dynamic>?;
      final hasData = catData != null && catData['data'] != null;
      
      // Category Header
      widgets.add(pw.SizedBox(height: 12));
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfConfig.border),
            color: hasData ? PdfColors.white : PdfColors.grey50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                cat['label']! as String, 
                style: pw.TextStyle(font: fontBold, fontSize: 11)
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: hasData ? PdfColors.green100 : PdfColors.grey200,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Text(
                  hasData ? 'มีข้อมูล' : 'ไม่มีข้อมูล',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: hasData ? PdfColors.green900 : PdfColors.grey600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      
      // Data Content
      if (hasData) {
        final rawData = catData!['data'];
        
        if (cat['hasTable'] == true && rawData is List && rawData.isNotEmpty) {
          // แสดงเป็นตาราง - ไม่จำกัดจำนวน
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(_buildDataTable(key as String, rawData, fontBold));
        } else if (rawData is Map && rawData.isNotEmpty) {
          // แสดงเป็น key-value (สำหรับ general)
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(_buildKeyValueData(rawData, fontBold));
        }
      }
    }
    
    return widgets;
  }

  // ==================== DATA TABLE BUILDERS ====================

  pw.Widget _buildDataTable(String category, List<dynamic> data, pw.Font fontBold) {
    switch (category) {
      case 'inputs':
        return _inputsTable(data, fontBold);
      case 'management':
        return _managementTable(data, fontBold);
      case 'harvest':
        return _harvestTable(data, fontBold);
      case 'postHarvest':
        return _postHarvestTable(data, fontBold);
      case 'safety':
        return _safetyTable(data, fontBold);
      case 'traceability':
        return _traceabilityTable(data, fontBold);
      default:
        return pw.SizedBox();
    }
  }

  pw.Widget _inputsTable(List<dynamic> data, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(60),  // วันที่
        1: const pw.FixedColumnWidth(70),  // ประเภท
        2: const pw.FlexColumnWidth(2),    // ชื่อ/ชนิด
        3: const pw.FlexColumnWidth(1.5),  // แหล่งที่มา
        4: const pw.FixedColumnWidth(50),  // ปริมาณ
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfConfig.tableHeader),
          children: [
            _tableHeader('วันที่', fontBold),
            _tableHeader('ประเภท', fontBold),
            _tableHeader('ชื่อ/ชนิด', fontBold),
            _tableHeader('แหล่งที่มา', fontBold),
            _tableHeader('ปริมาณ', fontBold),
          ],
        ),
        // Data Rows
        ...data.map((item) {
          if (item is! Map) return _emptyTableRow(5);
          return pw.TableRow(
            children: [
              _tableCell(_date(item['date'])),
              _tableCell(_safe(item['type'])),
              _tableCell(_safe(item['name'])),
              _tableCell(_safe(item['source'])),
              _tableCell('${_safe(item['amount'])} ${_safe(item['unit'])}'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _managementTable(List<dynamic> data, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(60),  // วันที่
        1: const pw.FlexColumnWidth(1.5),  // กิจกรรม
        2: const pw.FlexColumnWidth(2),    // หมายเหตุ
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfConfig.tableHeader),
          children: [
            _tableHeader('วันที่', fontBold),
            _tableHeader('กิจกรรม', fontBold),
            _tableHeader('หมายเหตุ', fontBold),
          ],
        ),
        ...data.map((item) {
          if (item is! Map) return _emptyTableRow(3);
          return pw.TableRow(
            children: [
              _tableCell(_date(item['date'] ?? item['activityDate'])),
              _tableCell(_safe(item['activity'] ?? item['activityType'])),
              _tableCell(_safe(item['note'] ?? item['description'])),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _harvestTable(List<dynamic> data, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(60),  // วันที่
        1: const pw.FixedColumnWidth(45),  // รุ่นที่
        2: const pw.FlexColumnWidth(1.5),  // วิธีการ
        3: const pw.FixedColumnWidth(60),  // ปริมาณ (กก.)
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfConfig.tableHeader),
          children: [
            _tableHeader('วันที่', fontBold),
            _tableHeader('รุ่นที่', fontBold),
            _tableHeader('วิธีการ', fontBold),
            _tableHeader('ปริมาณ (กก.)', fontBold),
          ],
        ),
        ...data.map((item) {
          if (item is! Map) return _emptyTableRow(4);
          return pw.TableRow(
            children: [
              _tableCell(_date(item['harvestDate'])),
              _tableCell(_safe(item['batchNumber'])),
              _tableCell(_safe(item['harvestMethod'])),
              _tableCell(_num(item['weightKg'])),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _postHarvestTable(List<dynamic> data, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(60),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfConfig.tableHeader),
          children: [
            _tableHeader('วันที่', fontBold),
            _tableHeader('กิจกรรม', fontBold),
            _tableHeader('สถานที่', fontBold),
          ],
        ),
        ...data.map((item) {
          if (item is! Map) return _emptyTableRow(3);
          return pw.TableRow(
            children: [
              _tableCell(_date(item['date'] ?? item['processDate'])),
              _tableCell(_safe(item['activity'] ?? item['processType'])),
              _tableCell(_safe(item['location'] ?? item['storageLocation'])),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _safetyTable(List<dynamic> data, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(60),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FixedColumnWidth(80),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfConfig.tableHeader),
          children: [
            _tableHeader('วันที่', fontBold),
            _tableHeader('หัวข้อการอบรม', fontBold),
            _tableHeader('ผู้เข้าร่วม', fontBold),
          ],
        ),
        ...data.map((item) {
          if (item is! Map) return _emptyTableRow(3);
          return pw.TableRow(
            children: [
              _tableCell(_date(item['date'] ?? item['trainingDate'])),
              _tableCell(_safe(item['topic'] ?? item['trainingTopic'])),
              _tableCell(
                  '${_safe(item['attendees'] ?? item['attendeesCount'])} คน'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _traceabilityTable(List<dynamic> data, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(60),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfConfig.tableHeader),
          children: [
            _tableHeader('วันที่', fontBold),
            _tableHeader('Lot Number', fontBold),
            _tableHeader('รายละเอียด', fontBold),
          ],
        ),
        ...data.map((item) {
          if (item is! Map) return _emptyTableRow(3);
          return pw.TableRow(
            children: [
              _tableCell(_date(item['date'] ?? item['harvestDate'])),
              _tableCell(_safe(item['lotNumber'] ?? item['batchNumber'] ?? item['id'])),
              _tableCell(_safe(item['details'] ?? item['harvestMethod'])),
            ],
          );
        }),
      ],
    );
  }

  // ==================== TABLE HELPERS ====================

  pw.Widget _tableHeader(String text, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: fontBold, fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        _clean(text),
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  pw.TableRow _emptyTableRow(int columns) {
    return pw.TableRow(
      children: List.generate(
        columns, 
        (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('-', style: const pw.TextStyle(fontSize: 9)),
        ),
      ),
    );
  }

  // ==================== KEY-VALUE DATA ====================

  pw.Widget _buildKeyValueData(Map<dynamic, dynamic> data, pw.Font fontBold) {
    final displayKeys = {
      'waterSource': 'แหล่งน้ำ',
      'soilType': 'ประเภทดิน',
      'plantingDate': 'วันที่ปลูก',
      'certificationGoal': 'เป้าหมายรับรอง',
      'farmType': 'ประเภทฟาร์ม',
      'irrigationSystem': 'ระบบน้ำ',
      'previousCrop': 'พืชรุ่นก่อน',
    };

    final entries = <pw.Widget>[];
    displayKeys.forEach((key, label) {
      // Check for multiple possible keys
      dynamic value = data[key];
      
      // key mappings
      if (key == 'plantingDate') value = data['plantingDate'] ?? data['startDate'];
      if (key == 'farmType') value = data['farmType'] ?? data['farmingSystem'];
      
      if (value != null) {
        String displayValue = _safe(value);
        if (key == 'plantingDate') displayValue = _date(value);
        
        entries.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 120,
                  child: pw.Text(
                    '$label:',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfConfig.textLight,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    displayValue,
                    style: pw.TextStyle(font: fontBold, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    if (entries.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          '- ไม่มีรายละเอียด -',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: entries,
      ),
    );
  }

  // ==================== PHOTOS ====================

  pw.Widget _photoGrid(List<Uint8List> photos) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: photos.map((p) {
        return pw.Container(
          width: 130,
          height: 100,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 4,
            verticalRadius: 4,
            child: pw.Image(pw.MemoryImage(p), fit: pw.BoxFit.cover),
          ),
        );
      }).toList(),
    );
  }

  // ==================== SIGNATURE ====================

  pw.Widget _signatureArea(pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: PdfColors.grey50,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _signBlock('ผู้จัดทำรายงาน', fontBold),
          _signBlock('ผู้ตรวจสอบ/รับรอง', fontBold),
        ],
      ),
    );
  }

  pw.Widget _signBlock(String title, pw.Font fontBold) {
    return pw.Column(
      children: [
        pw.Container(
          width: 160,
          height: 50,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(
          '(          /          /          )',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    );
  }

  // ==================== HELPER FUNCTIONS ====================

  Map<String, String> _getOwnerInfo(
    Map<String, dynamic> plot, 
    Map<String, dynamic>? owner
  ) {
    final src = owner ?? plot['owner'] ?? plot['user'] ?? {};
    String name = src['fullName'] ?? '';
    if (name.isEmpty) {
      name = '${src['firstName'] ?? ''} ${src['lastName'] ?? ''}'.trim();
    }
    if (name.isEmpty) name = '-';
    
    return {
      'name': name,
      'phone': src['phone'] ?? src['tel'] ?? src['phoneNumber'] ?? '-',
    };
  }

  String _getAddress(Map<String, dynamic> plot) {
    final parts = <String>[];
    if (plot['subDistrict'] != null && plot['subDistrict'].toString().isNotEmpty) {
      parts.add('ต.${plot['subDistrict']}');
    }
    if (plot['district'] != null && plot['district'].toString().isNotEmpty) {
      parts.add('อ.${plot['district']}');
    }
    if (plot['province'] != null && plot['province'].toString().isNotEmpty) {
      parts.add('จ.${plot['province']}');
    }
    
    if (parts.isNotEmpty) return parts.join(' ');

    // Fallback: GPS coordinates
    final lat = _getCoord(plot, 1);
    final lng = _getCoord(plot, 0);
    if (lat != 0 && lng != 0) {
      return 'พิกัด GPS: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    }
    
    return '-';
  }

  double _getCoord(Map<String, dynamic> plot, int idx) {
    try {
      return (plot['geometry']['coordinates'][0][0][idx] as num).toDouble();
    } catch (_) {
      return 0;
    }
  }
  
  List<Map<String, String>> _getPolygonCoordinates(Map<String, dynamic> plot) {
    try {
      final coords = plot['geometry']?['coordinates']?[0] as List?;
      if (coords == null || coords.isEmpty) return [];
      
      return coords.map((point) {
        final lat = (point[1] as num).toDouble();
        final lng = (point[0] as num).toDouble();
        return {
          'lat': lat.toStringAsFixed(6),
          'lng': lng.toStringAsFixed(6),
        };
      }).toList();
    } catch (e) {
      print('⚠️ Error parsing polygon: $e');
      return [];
    }
  }

  String _translateStatus(dynamic status) {
    switch (status?.toString().toUpperCase()) {
      case 'APPROVED':
        return 'อนุมัติแล้ว';
      case 'PENDING':
        return 'รอตรวจสอบ';
      case 'REJECTED':
        return 'ถูกปฏิเสธ';
      case 'DRAFT':
        return 'ฉบับร่าง';
      default:
        return status?.toString() ?? '-';
    }
  }

  String _safe(dynamic val) {
    if (val == null) return '-';
    final s = val.toString().trim();
    return s.isEmpty || s == 'null' ? '-' : s;
  }

  String _num(dynamic val) {
    if (val == null) return '0';
    if (val is num) {
      return val % 1 == 0 
          ? val.toInt().toString() 
          : val.toStringAsFixed(2);
    }
    return val.toString();
  }

  String _date(dynamic val) {
    if (val == null) return '-';
    final dt = DateTime.tryParse(val.toString());
    return DateFormatter.formatThaiDate(dt);
  }

  String _clean(String text) {
    if (text == 'null') return '-';
    return text
        .replaceAll(RegExp(r'[\u{1F600}-\u{1FAFF}]', unicode: true), '')
        .replaceAll('null', '-')
        .trim();
  }

  // ==================== IMAGE LOADING ====================

  Future<Uint8List?> _loadMapImage(Map<String, dynamic> plot) async {
    try {
      final lat = _getCoord(plot, 1);
      final lng = _getCoord(plot, 0);
      if (lat == 0 || lng == 0) {
        print('⚠️ Invalid coordinates for map');
        return null;
      }
      
      // สร้าง URL พร้อม polygon overlay
      final polygonParam = _buildPolygonParam(plot);
      final markerParam = '$lng,$lat,red';
      
      // Encode params manually if needed, but usually Uri param handles it.
      // However, MapTiler Static API expects specific format.
      // We will use 0xRRGGBBAA format for colors which is safer.
      
      final cleanKey = PdfConfig.mapApiKey.trim();
      
      // Use explicit Uri construction to ensure encoding
      final uri = Uri.parse('https://api.maptiler.com/maps/satellite/static/$lng,$lat,16/800x400.jpg').replace(
        queryParameters: {
          'key': cleanKey,
          'markers': markerParam,
          if (polygonParam.isNotEmpty) 'path': polygonParam,
        } // Uri will encode value automatically (e.g. | becomes %7C)
      );
      
      print('📍 Fetching map: $uri');
      
      final res = await http.get(uri).timeout(PdfConfig.networkTimeout);
      
      if (res.statusCode == 200) {
        print('✅ Map loaded successfully');
        return res.bodyBytes;
      } else {
        print('⚠️ Map fetch failed: ${res.statusCode} | Body: ${res.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ Error loading map: $e');
      return null;
    }
  }
  
  String _buildPolygonParam(Map<String, dynamic> plot) {
    try {
      final coords = plot['geometry']?['coordinates']?[0] as List?;
      if (coords == null || coords.isEmpty) return '';

      // Simplify polygon: Take max 20 points
      List<dynamic> simplifiedCoords = coords;
      if (coords.length > 20) {
        final step = (coords.length / 20).ceil();
        simplifiedCoords = [];
        for (var i = 0; i < coords.length; i += step) {
          simplifiedCoords.add(coords[i]);
        }
        // Ensure closed loop
        if (simplifiedCoords.last != coords.last) {
          simplifiedCoords.add(coords.last);
        }
      }
      
      // MapTiler Static API Path Format:
      // path=fill:COLOR|stroke:COLOR|width:WIDTH|lng,lat|lng,lat|...
      // Colors should be hex (e.g. #RRGGBB or #RRGGBBAA), but encoded in URL
      // Use simpler format without 0x prefix which might be improved
      
      final points = simplifiedCoords.map((point) {
        final lng = (point[0] as num).toDouble().toStringAsFixed(5);
        final lat = (point[1] as num).toDouble().toStringAsFixed(5);
        return '$lng,$lat';
      }).join('|');
      
      // Fill: #4CAF50 (Green) with ~30% opacity -> 4CAF504D
      // Stroke: #4CAF50 (Green) -> 4CAF50
      // Note: MapTiler URL API often prefers encoded values. 
      // Safe approach: fill:rgba(76,175,80,0.3)|stroke:rgb(76,175,80)|width:2
      return 'fill:rgba(76,175,80,0.3)|stroke:rgb(76,175,80)|width:2|$points';
    } catch (e) {
      print('⚠️ Error building polygon param: $e');
      return '';
    }
  }

  Future<List<Uint8List>> _loadPlotPhotos(Map<String, dynamic> plot) async {
    final List<Uint8List> photos = [];
    final urls = plot['imageUrls'];
    
    if (urls is! List || urls.isEmpty) {
      return photos;
    }
    
    final validUrls = urls
        .whereType<String>()
        .where((url) => url.trim().isNotEmpty)
        .take(PdfConfig.maxPhotos)
        .toList();
    
    if (validUrls.isEmpty) return photos;
    
    print('📷 Loading ${validUrls.length} photos...');
    
    // โหลดทีละ batch
    for (var i = 0; i < validUrls.length; i += PdfConfig.maxConcurrentFetch) {
      final batch = validUrls
          .skip(i)
          .take(PdfConfig.maxConcurrentFetch)
          .toList();
      
      final results = await Future.wait(
        batch.map((url) => _fetchSinglePhoto(url)),
        eagerError: false,
      );
      
      photos.addAll(results.whereType<Uint8List>());
    }
    
    print('✅ Loaded ${photos.length}/${validUrls.length} photos');
    return photos;
  }

  Future<Uint8List?> _fetchSinglePhoto(String url) async {
    try {
      final res = await http.get(Uri.parse(url))
          .timeout(PdfConfig.networkTimeout);
      
      if (res.statusCode == 200) {
        return res.bodyBytes;
      }
      return null;
    } catch (e) {
      print('⚠️ Failed to load photo: $url - $e');
      return null;
    }
  }
}
