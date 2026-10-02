import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/nature_background.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/services/plot_service.dart';
import '../../../data/models/plot_model.dart';
import '../../map/screens/plot_detail_screen.dart';

class RequestHistoryScreen extends StatefulWidget {
  const RequestHistoryScreen({super.key});

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen> {
  late Future<List<PlotModel>> _plotsFuture;

  @override
  void initState() {
    super.initState();
    _loadPlots();
  }

  void _loadPlots() {
    _plotsFuture = context.read<PlotService>().getMyPlots();
  }

  Future<void> _refreshPlots() async {
    setState(() {
      _loadPlots();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'ไม่ระบุวันที่';
    final thaiMonths = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    return NatureBackground.header(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'ประวัติการยื่นขอ',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white),
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: FutureBuilder<List<PlotModel>>(
            future: _plotsFuture,
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: SkeletonListTile(count: 4, height: 100),
                );
              }

              // Error state
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.warning,
                          size: 48,
                          color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'เกิดข้อผิดพลาด',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'ไม่สามารถโหลดข้อมูลได้',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _refreshPlots,
                        icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 20),
                        label: Text('ลองอีกครั้ง', style: const TextStyle()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Success state
              final plots = snapshot.data ?? [];
              final submittedPlots = plots
                  .where(
                    (p) =>
                        p.status == 'PENDING' ||
                        p.status == 'APPROVED' ||
                        p.status == 'REJECTED',
                  )
                  .toList();

              if (submittedPlots.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.clipboardText,
                          size: 48,
                          color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'ไม่มีประวัติการยื่นขอ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'เมื่อคุณส่งแบบฟอร์ม GAP\nรายการจะปรากฏที่นี่',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshPlots,
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: submittedPlots.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final plot = submittedPlots[index];
                    return _buildHistoryCard(plot);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(PlotModel plot) {
    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    switch (plot.status) {
      case 'APPROVED':
        statusColor = const Color(0xFF00D9A5);
        statusText = 'อนุมัติแล้ว';
        statusIcon = PhosphorIconsRegular.sealCheck;
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFFF6B6B);
        statusText = 'ไม่อนุมัติ';
        statusIcon = PhosphorIconsRegular.xCircle;
        break;
      case 'PENDING':
      default:
        statusColor = const Color(0xFFFF9F43);
        statusText = 'รอตรวจสอบ';
        statusIcon = PhosphorIconsRegular.clock;
        break;
    }

    // Use submittedDate if available, fallback to createdAt, then updatedAt
    final displayDate = plot.submittedDate ?? plot.createdAt ?? plot.updatedAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  PhosphorIconsRegular.fileText,
                  color: AppColors.primary,
                  size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยื่นขอรับรอง GAP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'แปลง: ${plot.name}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'ส่งเมื่อ: ${_formatDate(displayDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  if (!mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlotDetailScreen(plot: plot),
                    ),
                  );
                  if (mounted) _refreshPlots();
                },
                child: Text(
                  'ดูรายละเอียด >',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
