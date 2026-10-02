import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/plot_service.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/plot_model.dart';
import '../../auth/auth_provider.dart';
import 'certificate_viewer_screen.dart';

/// Certificates for the member's approved plots.
class CertificateListScreen extends StatefulWidget {
  const CertificateListScreen({super.key});

  @override
  State<CertificateListScreen> createState() => _CertificateListScreenState();
}

class _CertificateListScreenState extends State<CertificateListScreen> {
  List<PlotModel>? _plots;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final plots = await context.read<PlotService>().getMyPlots();
      if (mounted) setState(() => _plots = plots.where((p) => p.status == 'APPROVED').toList());
    } on Object catch (_) {
      if (mounted) setState(() => _error = 'โหลดรายการแปลงไม่สำเร็จ');
    }
  }

  void _open(PlotModel plot) {
    final owner = plot.ownerName ?? context.read<AuthProvider>().currentUser?.fullName ?? 'เกษตรกร';
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CertificateViewerScreen(plot: plot, ownerName: owner)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plots = _plots;
    return PageScaffold(
      title: 'ใบรับรอง GAP',
      subtitle: 'แปลงที่ผ่านการตรวจแล้ว',
      onRefresh: _load,
      slivers: [
        if (_error != null)
          SliverToBoxAdapter(child: AppCard(child: ErrorState(message: _error, onRetry: _load)))
        else if (plots == null)
          const SliverToBoxAdapter(child: SkeletonList(count: 3))
        else if (plots.isEmpty)
          const SliverToBoxAdapter(
            child: AppCard(
              child: EmptyState(
                title: 'ยังไม่มีใบรับรอง',
                message: 'เมื่อเจ้าหน้าที่อนุมัติแปลงของคุณ ใบรับรองจะพร้อมดาวน์โหลดที่นี่',
                mood: MascotMood.think,
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: plots.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
            itemBuilder: (context, i) {
              final plot = plots[i];
              return AppCard(
                onTap: () => _open(plot),
                child: Row(
                  children: [
                    const IconTile(icon: AppIcons.certificate, tone: Tone.success, size: 48),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plot.name, style: context.text.titleSmall),
                          Text(
                            [
                              '${plot.areaRai?.toStringAsFixed(2) ?? '-'} ไร่',
                              if (plot.updatedAt != null) 'อนุมัติ ${ThaiDate.short(plot.updatedAt)}',
                            ].join(' · '),
                            style: context.text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(AppIcons.chevronRight, size: 18),
                  ],
                ),
              ).entrance(context, index: i);
            },
          ),
      ],
    );
  }
}
