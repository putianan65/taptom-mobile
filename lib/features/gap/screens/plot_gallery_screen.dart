import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/admin_service.dart';
import '../../../core/services/plot_service.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/widgets.dart';

/// Field photos used as evidence during inspection.
class PlotGalleryScreen extends StatefulWidget {
  const PlotGalleryScreen({super.key, required this.plotId, this.plotName, this.isReadOnly = false});

  final String plotId;
  final String? plotName;
  final bool isReadOnly;

  @override
  State<PlotGalleryScreen> createState() => _PlotGalleryScreenState();
}

class _PlotGalleryScreenState extends State<PlotGalleryScreen> {
  List<String> _urls = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plots = context.read<PlotService>();
    final admin = context.read<AdminService>();
    List<String> urls = const [];
    try {
      urls = (await plots.getPlot(widget.plotId)).imageUrls;
    } on Object catch (_) {
      // Staff viewing a member's plot read it through the admin endpoint.
      try {
        final detail = await admin.getPlotDetail(widget.plotId);
        urls = [for (final u in (detail['imageUrls'] as List? ?? const [])) '$u'];
      } on Object catch (_) {}
    }
    if (mounted) {
      setState(() {
        _urls = List.of(urls);
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final source = await showAppSheet<ImageSource>(
      context,
      title: 'เพิ่มรูปแปลง',
      child: Padding(
        padding: EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl + MediaQuery.paddingOf(context).bottom),
        child: ListGroup(
          children: [
            ListRow(icon: AppIcons.camera, title: 'ถ่ายรูป', onTap: () => Navigator.of(context).pop(ImageSource.camera)),
            ListRow(icon: AppIcons.image, title: 'เลือกจากคลังภาพ', onTap: () => Navigator.of(context).pop(ImageSource.gallery)),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1920, imageQuality: 82);
    if (picked == null || !mounted) return;

    final service = context.read<PlotService>();
    setState(() => _uploading = true);
    try {
      final url = await service.uploadPlotImage(File(picked.path));
      final next = [..._urls, url];
      await service.updatePlot(widget.plotId, {'imageUrls': next});
      if (mounted) setState(() => _urls = next);
    } on Object catch (e) {
      if (mounted) AppToast.error(context, ErrorUtils.getReadableError(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _remove(int index) async {
    final ok = await AppDialogs.confirm(context, title: 'ลบรูปนี้?', confirmLabel: 'ลบ', destructive: true);
    if (!ok || !mounted) return;
    final next = [..._urls]..removeAt(index);
    try {
      await context.read<PlotService>().updatePlot(widget.plotId, {'imageUrls': next});
      if (!mounted) return;
      setState(() => _urls = next);
      Navigator.of(context).maybePop();
    } on Object catch (e) {
      if (mounted) AppToast.error(context, ErrorUtils.getReadableError(e));
    }
  }

  void _view(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _Viewer(
          urls: _urls,
          initial: index,
          onDelete: widget.isReadOnly ? null : _remove,
        ),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = !widget.isReadOnly && !kIsWeb;
    return PageScaffold(
      title: 'รูปถ่ายแปลง',
      subtitle: widget.plotName,
      onRefresh: _load,
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _uploading ? null : _add,
              icon: _uploading
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(AppIcons.camera),
              label: Text(_uploading ? 'กำลังอัปโหลด' : 'เพิ่มรูป'),
            )
          : null,
      slivers: [
        if (_loading)
          SliverToBoxAdapter(
            child: Shimmer(
              child: AdaptiveGrid(
                minTileWidth: 150,
                spacing: Space.sm,
                children: [for (var i = 0; i < 4; i++) const SkeletonBox(height: 150, radius: Radii.md)],
              ),
            ),
          )
        else if (_urls.isEmpty)
          SliverToBoxAdapter(
            child: AppCard(
              child: EmptyState(
                title: 'ยังไม่มีรูปแปลง',
                message: widget.isReadOnly
                    ? 'เจ้าของแปลงยังไม่ได้เพิ่มรูป'
                    : 'ถ่ายรูปต้น ใบ และป้ายแปลง เพื่อใช้ประกอบการตรวจ',
                mood: MascotMood.think,
              ),
            ),
          )
        else
          SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: Space.sm,
              crossAxisSpacing: Space.sm,
            ),
            itemCount: _urls.length,
            itemBuilder: (context, i) => Pressable(
              onTap: () => _view(i),
              child: Hero(
                tag: _urls[i],
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: CachedNetworkImage(
                    imageUrl: _urls[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => ColoredBox(color: context.palette.surfaceSunken),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: context.palette.surfaceSunken,
                      child: Icon(AppIcons.image, color: context.palette.inkSubtle),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Viewer extends StatefulWidget {
  const _Viewer({required this.urls, required this.initial, this.onDelete});

  final List<String> urls;
  final int initial;
  final ValueChanged<int>? onDelete;

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  late final _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.urls.length}', style: const TextStyle(color: Colors.white)),
        actions: [
          if (widget.onDelete != null)
            IconButton(
              tooltip: 'ลบรูป',
              onPressed: () => widget.onDelete!(_index),
              icon: const Icon(AppIcons.delete),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: Hero(
              tag: widget.urls[i],
              child: CachedNetworkImage(imageUrl: widget.urls[i], fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
