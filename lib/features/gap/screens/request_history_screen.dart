import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/plot_service.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/plot_model.dart';
import '../../map/screens/plot_detail_screen.dart';

/// Where each submitted plot stands in review, newest first.
class RequestHistoryScreen extends StatefulWidget {
  const RequestHistoryScreen({super.key});

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen> {
  List<PlotModel>? _plots;
  String? _error;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final plots = await context.read<PlotService>().getMyPlots();
      DateTime when(PlotModel p) => p.submittedDate ?? p.updatedAt ?? p.createdAt ?? DateTime(2000);
      plots.sort((a, b) => when(b).compareTo(when(a)));
      if (mounted) setState(() => _plots = plots.where((p) => p.status != null).toList());
    } on Object catch (_) {
      if (mounted) setState(() => _error = 'โหลดประวัติไม่สำเร็จ');
    }
  }

  Future<void> _open(PlotModel plot) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PlotDetailScreen(plot: plot)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final all = _plots;
    final plots = all == null ? null : (_status == null ? all : all.where((p) => p.status == _status).toList());
    int count(String s) => all?.where((p) => p.status == s).length ?? 0;

    return PageScaffold(
      title: 'ประวัติการยื่นตรวจ',
      subtitle: 'สถานะการตรวจของแต่ละแปลง',
      onRefresh: _load,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: Space.lg),
            child: FilterChips<String?>(
              value: _status,
              onChanged: (v) => setState(() => _status = v),
              options: [
                (null, 'ทั้งหมด', all?.length),
                ('PENDING', 'รอตรวจ', count('PENDING')),
                ('APPROVED', 'อนุมัติ', count('APPROVED')),
                ('REJECTED', 'ไม่ผ่าน', count('REJECTED')),
              ],
            ),
          ),
        ),
        if (_error != null)
          SliverToBoxAdapter(child: AppCard(child: ErrorState(message: _error, onRetry: _load)))
        else if (plots == null)
          const SliverToBoxAdapter(child: SkeletonList(count: 4))
        else if (plots.isEmpty)
          const SliverToBoxAdapter(
            child: AppCard(
              child: EmptyState(
                title: 'ยังไม่มีคำขอ',
                message: 'เมื่อวาดแปลงและส่งตรวจ สถานะจะแสดงที่นี่',
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: plots.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
            itemBuilder: (context, i) {
              final plot = plots[i];
              final (label, tone) = StatusLabels.plot(plot.status);
              final when = plot.submittedDate ?? plot.createdAt;
              final step = switch (plot.status) {
                'APPROVED' => 'เจ้าหน้าที่ตรวจแล้ว ดาวน์โหลดใบรับรองได้',
                'REJECTED' => 'แก้ไขตามคำแนะนำในการแจ้งเตือน แล้วส่งตรวจอีกครั้ง',
                _ => 'รอเจ้าหน้าที่ในพื้นที่ตรวจข้อมูล',
              };
              return AppCard(
                onTap: () => _open(plot),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlotShape(points: plot.boundary, size: 52),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(plot.name, style: context.text.titleSmall)),
                              StatusBadge(label: label, tone: tone),
                            ],
                          ),
                          if (when != null)
                            Text('ส่งเมื่อ ${ThaiDate.long(when.toLocal())}', style: context.text.bodySmall),
                          const SizedBox(height: Space.sm),
                          Text(step, style: context.text.bodySmall?.copyWith(color: context.palette.inkMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).entrance(context, index: i);
            },
          ),
      ],
    );
  }
}
