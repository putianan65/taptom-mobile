import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:math' show sin, pi;
import '../../../core/constants/app_colors.dart';
import '../../../core/services/gap_service.dart';
import '../../../core/services/plot_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/plot_model.dart';
import '../../gap/screens/gap_main_screen.dart';

class GapRecordsScreen extends StatefulWidget {
  const GapRecordsScreen({super.key});

  @override
  State<GapRecordsScreen> createState() => _GapRecordsScreenState();
}

class _GapRecordsScreenState extends State<GapRecordsScreen> {
  String _searchQuery = '';
  String _sortBy = 'name';  // name, progress, date

  @override
  Widget build(BuildContext context) {
    final plotService = context.read<PlotService>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // Title Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const HeroIcon(
                          HeroIcons.clipboardDocumentCheck,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'บันทึก GAP',
                              style: GoogleFonts.prompt(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'เลือกแปลงเพื่อบันทึกข้อมูลมาตรฐาน',
                              style: GoogleFonts.prompt(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // ✅ NEW: Search Bar
                  const SizedBox(height: 16),
                  TextField(
                    style: GoogleFonts.prompt(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาชื่อแปลง...',
                      hintStyle: GoogleFonts.prompt(color: Colors.white60),
                      prefixIcon: const HeroIcon(HeroIcons.magnifyingGlass, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ],
              ),
            ),

            // Plot List
            Expanded(
              child: FutureBuilder<List<PlotModel>>(
                future: plotService.getMyPlots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      child: _buildSkeletonCards(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }

                  var plots = snapshot.data ?? [];

                  // ✅ Filter
                  if (_searchQuery.isNotEmpty) {
                    plots = plots.where((plot) {
                      return plot.name.toLowerCase().contains(_searchQuery.toLowerCase());
                    }).toList();
                  }

                  // ✅ Sort
                  switch (_sortBy) {
                    case 'name':
                      plots.sort((a, b) => a.name.compareTo(b.name));
                      break;
                    case 'date':
                      // Sort by updatedAt if available
                      break;
                  }

                  if (plots.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      itemCount: plots.length,
                      itemBuilder: (context, index) {
                        return _GapPlotCard(
                          plot: plots[index],
                          index: index,  // ✅ Pass index for staggered loading
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Better Skeleton
  Widget _buildSkeletonCards() {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const HeroIcon(
              HeroIcons.exclamationTriangle,
              size: 40,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'เกิดข้อผิดพลาด',
            style: GoogleFonts.prompt(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ไม่สามารถโหลดข้อมูลแปลงได้',
            style: GoogleFonts.prompt(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: Text(
              'ลองใหม่',
              style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const HeroIcon(
                  HeroIcons.mapPin,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ยังไม่มีแปลงที่ลงทะเบียน',
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'สร้างแปลงใหม่จากหน้าแผนที่เพื่อเริ่มบันทึก GAP',
              style: GoogleFonts.prompt(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const HeroIcon(HeroIcons.map, size: 18, color: Colors.white),
              label: Text('ไปที่แผนที่', style: GoogleFonts.prompt(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Card with improvements
class _GapPlotCard extends StatefulWidget {
  final PlotModel plot;
  final int index;

  const _GapPlotCard({required this.plot, required this.index});

  @override
  State<_GapPlotCard> createState() => _GapPlotCardState();
}

class _GapPlotCardState extends State<_GapPlotCard> {
  // ✅ Use Provider instead of creating new instance
  late final GapService _gapService;

  Map<String, bool> _gapProgress = {
    'general': false,
    'inputs': false,
    'management': false,
    'harvest': false,
    'post_harvest': false,
    'safety': false,
    'traceability': false,
  };

  bool _loading = true;
  bool _hasError = false;
  int _daysSinceLastRecord = 0;
  DateTime? _lastActivityDate;

  @override
  void initState() {
    super.initState();
    _gapService = context.read<GapService>();
    
    // ✅ Stagger loading to avoid rate limiting
    final delay = Duration(milliseconds: widget.index * 300);
    Future.delayed(delay, _loadGapProgress);
  }

  Future<void> _loadGapProgress() async {
    if (widget.plot.id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final results = await Future.wait([
        _gapService.getGapData(widget.plot.id!),
        _gapService.getInputs(widget.plot.id!),
        _gapService.getHarvests(widget.plot.id!),
        _gapService.getTrainings(widget.plot.id!),
        _gapService.getActivities(widget.plot.id!),
        _gapService.getPostHarvestsForPlot(widget.plot.id!),
      ]);

      final gapData = results[0] as Map<String, dynamic>?;
      final inputs = results[1] as List;
      final harvests = results[2] as List;
      final trainings = results[3] as List;
      final activities = results[4] as List;
      final postHarvests = results[5] as List;

      // Calculate last activity date
      final allDates = <DateTime>[];
      if (gapData?['updatedAt'] != null) {
        allDates.add(DateTime.tryParse(gapData!['updatedAt'].toString()) ?? DateTime.now());
      }

      DateTime? lastDate;
      if (allDates.isNotEmpty) {
        allDates.sort((a, b) => b.compareTo(a));
        lastDate = allDates.first;
      }

      if (mounted) {
        setState(() {
          _gapProgress = {
            'general': gapData != null && gapData['farmerName'] != null,
            'inputs': inputs.isNotEmpty,
            'management': activities.isNotEmpty,
            'harvest': harvests.isNotEmpty,
            'post_harvest': postHarvests.isNotEmpty,
            'safety': trainings.isNotEmpty,
            'traceability': harvests.isNotEmpty,
          };

          if (lastDate != null) {
            _lastActivityDate = lastDate;
            _daysSinceLastRecord = DateTime.now().difference(lastDate).inDays;
          }

          _loading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });

        // ✅ Show error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถโหลดข้อมูล GAP ของแปลง ${widget.plot.name} ได้',
              style: GoogleFonts.prompt(),
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'ลองใหม่',
              textColor: Colors.white,
              onPressed: _loadGapProgress,
            ),
          ),
        );
      }
    }
  }

  int get _completedCount => _gapProgress.values.where((v) => v).length;
  int get _totalCount => _gapProgress.length;
  double get _progressPercent => _completedCount / _totalCount;

  @override
  Widget build(BuildContext context) {
    final isApproved = widget.plot.status == 'APPROVED';
    final needsAttention = !isApproved && _daysSinceLastRecord >= 7 && _completedCount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isApproved
            ? Border.all(color: Colors.green, width: 2)
            : needsAttention
                ? Border.all(color: Colors.orange.withOpacity(0.6), width: 2)
                : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _handleTap(isApproved),
        child: Column(
          children: [
            // Warning Banner
            if (needsAttention) _buildWarningBanner(),
            
            // Approved Banner
            if (isApproved) _buildApprovedBanner(),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ MapLibre Map Preview
                  _buildMapPreview(),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plot.name,
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const HeroIcon(HeroIcons.mapPin, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.plot.areaRai?.toStringAsFixed(1) ?? "-"} ไร่',
                              style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildProgressSection(isApproved),
                      ],
                    ),
                  ),

                  // Icon
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: HeroIcon(
                      isApproved ? HeroIcons.lockClosed : HeroIcons.chevronRight,
                      size: 20,
                      color: isApproved ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Missing Items
            if (!_loading && _completedCount < _totalCount && !isApproved)
              _buildMissingItems(),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(bool isApproved) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GapMainScreen(
          plotId: widget.plot.id ?? '',
          plotName: widget.plot.name,
          isReadOnly: isApproved,
        ),
      ),
    );

    _loadGapProgress();
  }

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF3E0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: sin(value * pi * 4) * 0.1,
                child: child,
              );
            },
            child: const HeroIcon(
              HeroIcons.exclamationTriangle,
              color: Colors.orange,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'คุณยังไม่ได้บันทึกแปลงนี้มา $_daysSinceLastRecord วันแล้ว',
              style: GoogleFonts.prompt(
                fontSize: 12,
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          const HeroIcon(HeroIcons.checkBadge, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'แปลงนี้ได้รับการรับรอง GAP เรียบร้อยแล้ว',
              style: GoogleFonts.prompt(
                fontSize: 12,
                color: Colors.green[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 85,
        height: 85,
        child: _GapMiniMap(plot: widget.plot),
      ),
    );
  }

  Widget _buildProgressSection(bool isApproved) {
    if (_loading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Certified / ผ่านการรับรอง',
          style: GoogleFonts.prompt(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ความคืบหน้า GAP',
              style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey[600]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _progressPercent == 1.0
                    ? Colors.green.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$_completedCount/$_totalCount',
                style: GoogleFonts.prompt(
                  fontSize: 11,
                  color: _progressPercent == 1.0 ? Colors.green : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // ✅ Animated Progress Bar
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: _progressPercent),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _progressPercent == 1.0 ? Colors.green : AppColors.primary,
                ),
                minHeight: 6,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMissingItems() {
    final missing = _getMissingItems().take(3).toList();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: missing.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HeroIcon(HeroIcons.xCircle, size: 12, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  item,
                  style: GoogleFonts.prompt(fontSize: 10, color: Colors.red[700]),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<String> _getMissingItems() {
    final missing = <String>[];
    _gapProgress.forEach((key, value) {
      if (!value) {
        switch (key) {
          case 'general':
            missing.add('ข้อมูลทั่วไป');
          case 'inputs':
            missing.add('ปัจจัยการผลิต');
          case 'management':
            missing.add('การจัดการ');
          case 'harvest':
            missing.add('การเก็บเกี่ยว');
          case 'post_harvest':
            missing.add('หลังเก็บเกี่ยว');
          case 'safety':
            missing.add('ความปลอดภัย');
          case 'traceability':
            missing.add('ตรวจติดตาม');
        }
      }
    });
    return missing;
  }
}

/// Mini Map Widget for GAP Plot Card
class _GapMiniMap extends StatefulWidget {
  final PlotModel plot;
  const _GapMiniMap({required this.plot});

  @override
  State<_GapMiniMap> createState() => _GapMiniMapState();
}

class _GapMiniMapState extends State<_GapMiniMap> {
  MaplibreMapController? _controller;
  bool _isStyleLoaded = false;
  static const String _styleUrl =
      'https://api.maptiler.com/maps/hybrid/style.json?key=Fb4cbU6chnBsGVsZ5v96';

  @override
  Widget build(BuildContext context) {
    final boundary = widget.plot.boundary;
    
    // ✅ Show fallback icon if no boundary
    if (boundary.isEmpty) {
      return Container(
        color: AppColors.primary.withOpacity(0.1),
        child: const Center(
          child: HeroIcon(HeroIcons.map, color: AppColors.primary, size: 28),
        ),
      );
    }

    // Calculate center of polygon
    double sumLat = 0, sumLng = 0;
    for (final point in boundary) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    final centerLat = sumLat / boundary.length;
    final centerLng = sumLng / boundary.length;

    return MaplibreMap(
      styleString: _styleUrl,
      initialCameraPosition: CameraPosition(
        target: LatLng(centerLat, centerLng),
        zoom: 15,
      ),
      compassEnabled: false,
      rotateGesturesEnabled: false,
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      tiltGesturesEnabled: false,
      myLocationEnabled: false,
      attributionButtonPosition: AttributionButtonPosition.bottomLeft,
      onMapCreated: (controller) {
        _controller = controller;
      },
      onStyleLoadedCallback: () {
        _isStyleLoaded = true;
        _addPolygon();
      },
    );
  }

  Future<void> _addPolygon() async {
    if (_controller == null || !_isStyleLoaded) return;

    final boundary = widget.plot.boundary;
    if (boundary.isEmpty) return;

    final points = boundary
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    
    if (points.length > 2) {
      points.add(points.first); // Close polygon
    }

    try {
      // ✅ Add filled polygon
      await _controller!.addFill(
        FillOptions(
          geometry: [points],
          fillColor: AppColors.primary.toHexStringRGB(),
          fillOpacity: 0.4,
          fillOutlineColor: '#FFFFFF',
        ),
      );

      // ✅ Add border line
      await _controller!.addLine(
        LineOptions(
          geometry: points,
          lineColor: '#FFFFFF',
          lineWidth: 2,
          lineOpacity: 0.9,
        ),
      );
    } catch (e) {
      debugPrint('Mini map polygon error (ignored): $e');
    }
  }
}