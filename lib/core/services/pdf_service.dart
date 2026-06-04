import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  Future<void> generateGapCertificate(
    String plotId,
    String farmerName,
    String crop,
  ) async {
    final doc = pw.Document();

    // Load Thai Font (downloads on fly, might fail if offline, fallback to standard)
    // In production, bundle the .ttf asset
    final font = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 100,
                  height: 100,
                  decoration: const pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: PdfColors.green,
                  ),
                ), // Logo Placeholder

                pw.SizedBox(height: 20),

                pw.Text(
                  'ใบรับรองแหล่งผลิต GAP',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 30,
                    color: PdfColors.green800,
                  ),
                ),
                pw.Text(
                  'Certificate of Good Agricultural Practices',
                  style: const pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.grey700,
                  ),
                ),

                pw.SizedBox(height: 40),

                pw.Text(
                  'มอบให้แก่ (Awarded to):',
                  style: pw.TextStyle(font: font, fontSize: 16),
                ),
                pw.Text(
                  farmerName,
                  style: pw.TextStyle(font: fontBold, fontSize: 24),
                ),

                pw.SizedBox(height: 20),

                pw.Text(
                  'สำหรับแปลง (For Plot):',
                  style: pw.TextStyle(font: font, fontSize: 16),
                ),
                pw.Text(
                  plotId,
                  style: pw.TextStyle(font: fontBold, fontSize: 24),
                ),

                pw.SizedBox(height: 20),

                pw.Text(
                  'ชนิดพืช (Crop):',
                  style: pw.TextStyle(font: font, fontSize: 16),
                ),
                pw.Text(
                  crop,
                  style: pw.TextStyle(font: fontBold, fontSize: 24),
                ),

                pw.SizedBox(height: 50),

                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Date: ${DateTime.now().toString().split(' ')[0]}',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Signature: _________________',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'GAP-CERT-$plotId',
                  width: 80,
                  height: 80,
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'GAP-Certificate-$plotId',
    );
  }
}
