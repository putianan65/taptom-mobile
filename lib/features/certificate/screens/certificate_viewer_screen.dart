import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';

/// หน้าจอสำหรับแสดง PDF ใบรับรอง
class CertificateViewerScreen extends StatefulWidget {
  final String pdfPath;
  
  const CertificateViewerScreen({super.key, required this.pdfPath});

  @override
  State<CertificateViewerScreen> createState() => _CertificateViewerScreenState();
}

class _CertificateViewerScreenState extends State<CertificateViewerScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'ใบรับรอง GAP',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const HeroIcon(HeroIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const HeroIcon(HeroIcons.share, color: Colors.white),
            onPressed: _sharePdf,
            tooltip: 'แชร์',
          ),
          IconButton(
            icon: const HeroIcon(HeroIcons.printer, color: Colors.white),
            onPressed: _printPdf,
            tooltip: 'พิมพ์',
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) async {
          final file = File(widget.pdfPath);
          return await file.readAsBytes();
        },
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: widget.pdfPath.split('/').last,
      ),
    );
  }
  
  Future<void> _sharePdf() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.pdfPath)],
        text: 'ใบรับรองมาตรฐาน GAP',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _printPdf() async {
    try {
      final file = File(widget.pdfPath);
      final bytes = await file.readAsBytes();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
