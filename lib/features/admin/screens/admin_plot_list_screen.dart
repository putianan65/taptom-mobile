import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/admin_service.dart';
import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/plot_model.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import '../../gap/screens/plot_gallery_screen.dart';
import '../../map/screens/map_drawing_screen.dart';
import 'admin_gap_inspection_screen.dart';
import 'admin_plots_map_screen.dart' show canManagePlot;

/// Plot list for staff, optionally limited to one member or one status.
/// Tapping a plot opens its GAP inspection.
class AdminPlotListScreen extends StatefulWidget {
  const AdminPlotListScreen({
    super.key,
    this.userId,
    this.userName,
    this.initialStatusFilter,
  });

  final String? userId;
  final String? userName;

  /// PENDING, APPROVED or REJECTED.
  final String? initialStatusFilter;

  @override
  State<AdminPlotListScreen> createState() => _AdminPlotListScreenState();
}

class _AdminPlotListScreenState extends State<AdminPlotListScreen> {
  List<Map<String, dynamic>> _plots = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  late String? _status = widget.initialStatusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await context.read<AdminService>().getAdminPlots(userId: widget.userId);
      var plots = [for (final p in raw) if (p is Map) Map<String, dynamic>.from(p)];
      // The list endpoint may ignore userId; filter again on the client.
      if (widget.userId != null) {
        plots = plots.where((p) {
          final owner = p['owner'];
          final id = p['userId'] ?? p['ownerId'] ?? (owner is Map ? owner['id'] : null);
          return '$id' == widget.userId;
        }).toList();
      }
      if (!mounted) return;
      setState(() {
        _plots = plots;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Map<String, dynamic>> get _visible {
    final q = _query.trim().toLowerCase();
    return _plots.where((p) {
      if (_status != null && p['status'] != _status) return false;
      if (q.isEmpty) return true;
      return '${p['name']} ${p['species']} ${p['district']}'.toLowerCase().contains(q);
    }).toList();
  }

  int _count(String s) => _plots.where((p) => p['status'] == s).length;

  void _inspect(Map<String, dynamic> plot) {
    UserModel? owner;
    final o = plot['owner'];
    if (o is Map && o.isNotEmpty) {
      try {
        owner = UserModel.fromJson(Map<String, dynamic>.from(o));
      } on Object catch (_) {}
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AdminGapInspectionScreen(
              plotId: '${plot['id']}',
              plotName: '${plot['name'] ?? 'ไม่ระบุชื่อ'}',
              owner: owner,
            ),
          ),
        )
        .then((_) => _load());
  }

  void _gallery(Map<String, dynamic> plot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlotGalleryScreen(
          plotId: '${plot['id']}',
          plotName: '${plot['name'] ?? 'ไม่ระบุชื่อ'}',
          isReadOnly: true,
        ),
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> plot) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapDrawingScreen(plotToEdit: PlotModel.fromJson(plot), isAdmin: true),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final plots = _visible;
    final title = widget.userName != null ? 'แปลงของ ${widget.userName}' : 'แปลงในความดูแล';

    return PageScaffold(
      title: title,
      subtitle: _loading ? null : '${_plots.length} แปลง',
      onRefresh: _load,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchField(
                hint: 'ชื่อแปลง สายพันธุ์ หรืออำเภอ',
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: Space.md),
              FilterChips<String?>(
                value: _status,
                onChanged: (v) => setState(() => _status = v),
                options: [
                  (null, 'ทั้งหมด', _plots.length),
                  ('PENDING', 'รอตรวจ', _count('PENDING')),
                  ('APPROVED', 'อนุมัติแล้ว', _count('APPROVED')),
                  ('REJECTED', 'ไม่ผ่าน', _count('REJECTED')),
                ],
              ),
              const SizedBox(height: Space.lg),
            ],
          ),
        ),
        if (_loading)
          const SliverToBoxAdapter(child: SkeletonList(count: 4))
        else if (_error != null)
          SliverToBoxAdapter(child: AppCard(child: ErrorState(message: _error, onRetry: _load)))
        else if (plots.isEmpty)
          SliverToBoxAdapter(
            child: AppCard(
              child: EmptyState(
                title: _status == 'PENDING' ? 'ไม่มีแปลงรอตรวจ' : 'ไม่พบแปลง',
                message: _status == 'PENDING' ? 'แปลงที่ส่งตรวจใหม่จะแสดงที่นี่' : null,
                mood: _status == 'PENDING' ? MascotMood.joy : MascotMood.think,
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: plots.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
            itemBuilder: (context, i) {
              final plot = plots[i];
              final canEdit = plot['status'] != 'APPROVED' && canManagePlot(me, plot);
              return _PlotTile(
                plot: plot,
                showOwner: widget.userId == null,
                onTap: () => _inspect(plot),
                onGallery: () => _gallery(plot),
                onEdit: canEdit ? () => _edit(plot) : null,
              ).entrance(context, index: i);
            },
          ),
      ],
    );
  }
}

class _PlotTile extends StatelessWidget {
  const _PlotTile({
    required this.plot,
    required this.showOwner,
    required this.onTap,
    required this.onGallery,
    this.onEdit,
  });

  final Map<String, dynamic> plot;
  final bool showOwner;
  final VoidCallback onTap;
  final VoidCallback onGallery;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, tone) = StatusLabels.plot(plot['status'] as String?);
    final model = PlotModel.fromJson({...plot, 'name': '${plot['name'] ?? ''}'});
    final area = (plot['areaRai'] as num?)?.toDouble() ?? 0;
    final owner = plot['owner'];
    final ownerName = owner is Map ? '${owner['firstName'] ?? ''} ${owner['lastName'] ?? ''}'.trim() : '';
    final meta = [
      '${area.toStringAsFixed(area >= 10 ? 1 : 2)} ไร่',
      if ((plot['species'] ?? '').toString().isNotEmpty) '${plot['species']}',
      if (showOwner && ownerName.isNotEmpty) ownerName,
    ].join(' · ');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.xs, Space.md),
      child: Row(
        children: [
          PlotShape(points: model.boundary, size: 52),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.name.isEmpty ? 'ไม่ระบุชื่อ' : model.name,
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(meta, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: Space.sm),
                StatusBadge(label: label, tone: tone),
              ],
            ),
          ),
          IconButton(
            tooltip: 'รูปถ่ายแปลง',
            onPressed: onGallery,
            icon: Icon(AppIcons.gallery, color: p.inkMuted),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: 'แก้ไขขอบเขต',
              onPressed: onEdit,
              icon: Icon(AppIcons.edit, color: p.inkMuted),
            ),
        ],
      ),
    );
  }
}
