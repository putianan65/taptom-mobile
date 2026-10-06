import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/plot_model.dart';
import 'pdf_assets.dart';

/// Builds the GAP certificate for an approved plot as an A4 PDF.
class CertificatePdfService {
  /// The certificate as PDF bytes, ready for preview, print or share.
  Future<Uint8List> buildCertificate(PlotModel plot, {required String ownerName}) async {
    final pdf = pw.Document(title: 'GAP ${plot.name}', author: 'TAPTOM');
    final fontRegular = await PdfAssets.regular();
    final fontBold = await PdfAssets.bold();
    final gapLogo = await PdfAssets.gapMark();
    final ppsLogo = await PdfAssets.oncbSeal();
    final gistLogo = await PdfAssets.gistnu();

    // Format date
    final now = DateTime.now();
    final thaiYear = now.year + 543;
    final dateStr = '${now.day} ${_getThaiMonth(now.month)} พ.ศ. $thaiYear';
    
    // Prepare location string
    final hasLocation = (plot.subDistrict?.isNotEmpty == true) || 
                        (plot.district?.isNotEmpty == true) || 
                        (plot.province?.isNotEmpty == true);
    
    final locationStr = [
      if (plot.subDistrict?.isNotEmpty == true) 'ต.${plot.subDistrict}',
      if (plot.district?.isNotEmpty == true) 'อ.${plot.district}',
      if (plot.province?.isNotEmpty == true) 'จ.${plot.province}',
    ].join(' ');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0), // Full page for border
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#245A33'), width: 5), // Outer Border
              color: PdfColors.white,
            ),
            child: pw.Container(
              margin: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#6CA874'), width: 2), // Inner Border
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                   // --- Header Logos ---
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      if (gapLogo != null) ...[
                        pw.Image(gapLogo, height: 60),
                        pw.SizedBox(width: 30),
                      ],
                      if (ppsLogo != null) ...[
                         pw.Image(ppsLogo, height: 70),
                         pw.SizedBox(width: 30),
                      ],
                      if (gistLogo != null)
                        pw.Image(gistLogo, height: 50),
                    ],
                  ),
                  pw.SizedBox(height: 40),
                  
                  // --- Title ---
                  pw.Text(
                    'ใบรับรองมาตรฐานการปฏิบัติทางการเกษตรที่ดี',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                      color: PdfColor.fromHex('#245A33'),
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    '(Good Agricultural Practices: GAP)',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: PdfColor.fromHex('#2F7041'),
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  
                  pw.SizedBox(height: 40),
                  
                  // --- Body Content ---
                  pw.Text(
                    'หนังสือสำคัญฉบับนี้ให้ไว้เพื่อรับรองว่า',
                    style: pw.TextStyle(font: fontRegular, fontSize: 16),
                  ),
                  pw.SizedBox(height: 10),

                  // Owner Name
                  pw.Text(
                    ownerName,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 22,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  
                  // Plot Name
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: 'เกษตรกรผู้ดูแลแปลง ',
                          style: pw.TextStyle(font: fontRegular, fontSize: 16),
                        ),
                        pw.TextSpan(
                          text: '"${plot.name}"',
                          style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.black),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 30),
                  
                  // Details Table
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F1F8E9'),
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: PdfColor.fromHex('#C5E1A5')),
                    ),
                    child: pw.Column(
                      children: [
                        _buildInfoRow('ชนิดพืช', plot.species ?? '-', fontRegular, fontBold),
                        pw.SizedBox(height: 10),
                        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                        pw.SizedBox(height: 10),
                        _buildInfoRow('พื้นที่เพาะปลูก', '${plot.areaRai?.toStringAsFixed(2) ?? "-"} ไร่', fontRegular, fontBold),
                        
                        // Conditional Location Row
                        if (hasLocation) ...[
                          pw.SizedBox(height: 10),
                          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                          pw.SizedBox(height: 10),
                          _buildInfoRow('ที่ตั้งแปลง', locationStr, fontRegular, fontBold),
                        ],
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(height: 30),
                  
                  pw.Text(
                    'ได้ผ่านการตรวจประเมินตามข้อกำหนดและหลักเกณฑ์\nมาตรฐานสินค้าเกษตร (มกษ. 9001-2556)',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 16,
                      lineSpacing: 4,
                    ),
                  ),
                  
                  pw.Spacer(),
                  
                  // --- Signatures & Date ---
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'เลขที่ใบรับรอง: TAPTOM-${plot.id?.substring(0, 8).toUpperCase() ?? "UNKNOWN"}',
                            style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'ให้ไว้ ณ วันที่ $dateStr',
                            style: pw.TextStyle(font: fontRegular, fontSize: 14),
                          ),
                        ],
                      ),
                      
                      pw.Column(
                         crossAxisAlignment: pw.CrossAxisAlignment.center,
                         children: [
                           // Fake Signature Line
                           pw.Container(width: 160, height: 1, color: PdfColors.black),
                           pw.SizedBox(height: 8),
                           pw.Text('นายทะเบียน / ผู้ตรวจประเมิน', style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                           pw.Text('( ระบบ TapTom )', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey600)),
                         ],
                      )
                    ],
                  ),
                  
                  pw.SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
    
    // Save to file
    return pdf.save();
  }
  
  pw.Widget _buildInfoRow(String label, String value, pw.Font regular, pw.Font bold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: regular, fontSize: 16, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 16, color: PdfColor.fromHex('#245A33'))),
      ],
    );
  }
  
  String _getThaiMonth(int month) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
      'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
      'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return months[month - 1];
  }
}

