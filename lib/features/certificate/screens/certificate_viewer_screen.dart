import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/services/certificate_pdf_service.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/plot_model.dart';

/// Previews a plot's GAP certificate with print and share built in.
class CertificateViewerScreen extends StatelessWidget {
  const CertificateViewerScreen({super.key, required this.plot, required this.ownerName});

  final PlotModel plot;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final service = context.read<CertificatePdfService>();
    final fileName = 'GAP-${plot.name.replaceAll(' ', '_')}.pdf';
    return Scaffold(
      backgroundColor: p.surfaceSunken,
      appBar: AppBar(
        title: Text('ใบรับรอง GAP', style: context.text.titleMedium),
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: p.line)),
      ),
      body: PdfPreview(
        build: (_) => service.buildCertificate(plot, ownerName: ownerName),
        pdfFileName: fileName,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        loadingWidget: const CircularProgressIndicator(),
        onError: (context, error) => const ErrorState(
          title: 'สร้างใบรับรองไม่สำเร็จ',
          message: 'ลองใหม่อีกครั้ง หากยังไม่ได้ ติดต่อเจ้าหน้าที่',
        ),
        pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: p.shadow, blurRadius: 16, offset: const Offset(0, 6))],
        ),
        scrollViewDecoration: BoxDecoration(color: p.surfaceSunken),
      ),
    );
  }
}
