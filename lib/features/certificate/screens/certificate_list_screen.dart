import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/services/plot_service.dart';
import '../../../../core/config/env.dart';
import '../../../../data/models/plot_model.dart';

class CertificateListScreen extends StatefulWidget {
  const CertificateListScreen({super.key});

  @override
  State<CertificateListScreen> createState() => _CertificateListScreenState();
}

class _CertificateListScreenState extends State<CertificateListScreen> {
  Future<void> _downloadCertificate(String plotId) async {
    // Assuming backend endpoint: /api/v1/reports/plots/{id}/gap.pdf
    // And assuming we just open it in browser for now (simplest download)
    // Note: If using authentication, opening in browser might 401.
    // Ideally we use a service to download via Dio with token, then open file.
    // For this MVP, we'll assume a public signature URL or just try direct access.

    // Actually, report logic usually needs token.
    // Let's just create a Mock Toast for now since report generation is complex backend.
    // Or if Env.apiBaseUrl is localhost, we construct the link.

    final url = Uri.parse('${Env.apiBaseUrl}/reports/plots/$plotId/gap.pdf');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กำลังดาวน์โหลด... (Mock Mode)',
            style: GoogleFonts.prompt(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ใบรับรอง GAP',
          style: GoogleFonts.prompt(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: HeroIcon(
            HeroIcons.arrowLeft,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<PlotModel>>(
        future: context.read<PlotService>().getMyPlots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SkeletonListTile(count: 5, height: 120),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          final allPlots = snapshot.data ?? [];
          // Filter only APPROVED plots (or those suitable for certificate)
          final approvedPlots = allPlots
              .where((p) => p.status == 'APPROVED')
              .toList();

          if (approvedPlots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: const HeroIcon(
                      HeroIcons.documentText,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ไม่พบใบรับรอง',
                    style: GoogleFonts.prompt(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'คุณยังไม่มีแปลงที่ผ่านการรับรอง GAP',
                    style: GoogleFonts.prompt(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: approvedPlots.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final plot = approvedPlots[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const HeroIcon(
                        HeroIcons.checkBadge,
                        color: AppColors.success,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plot.name,
                            style: GoogleFonts.prompt(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'พืช: ${plot.species ?? "-"}',
                            style: GoogleFonts.prompt(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'ออกเมื่อ: ${DateTime.now().year + 543}', // Mock date
                            style: GoogleFonts.prompt(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const HeroIcon(
                        HeroIcons.arrowDownTray,
                        color: AppColors.primary,
                      ),
                      onPressed: () => _downloadCertificate(plot.id ?? ''),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
