import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/env.dart';
import '../../../../core/services/plot_service.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../core/services/certificate_pdf_service.dart';
import '../../../../data/models/plot_model.dart';
import '../../auth/auth_provider.dart';
import '../../gap/screens/gap_main_screen.dart';
import '../../certificate/screens/certificate_list_screen.dart';
import '../../certificate/screens/certificate_viewer_screen.dart';
import '../../gap/screens/forms/gap_traceability_form.dart';
import '../../gap/screens/forms/gap_inputs_form.dart';
import 'dart:math' as math;

/// Production-Level Plot Detail Screen
/// Features: Map header, comprehensive stats, GAP progress ring, activity timeline
class PlotDetailScreen extends StatefulWidget {
  final PlotModel plot;

  const PlotDetailScreen({super.key, required this.plot});

  @override
  State<PlotDetailScreen> createState() => _PlotDetailScreenState();
}

class _PlotDetailScreenState extends State<PlotDetailScreen> {
  MaplibreMapController? _mapController;

  static String get _styleUrl =>
      'https://api.maptiler.com/maps/hybrid/style.json?key=${Env.mapTilerApiKey}';

  // GAP Progress loaded from API (starts at all false)
  Map<String, bool> _gapProgress = {
    'general': false,
    'inputs': false,
    'management': false,
    'harvest': false,
    'post_harvest': false,
    'safety': false,
    'traceability': false,
  };
  bool _loadingGapProgress = true;

  int get _gapCompleted => _gapProgress.values.where((v) => v).length;
  int get _gapTotal => _gapProgress.length;
  double get _gapPercent => _gapCompleted / _gapTotal;

  // Real activities loaded from API
  List<Map<String, dynamic>> _recentActivities = [];
  bool _loadingActivities = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _loadGapProgress();
  }

  Future<void> _loadGapProgress() async {
    if (widget.plot.id == null) {
      setState(() => _loadingGapProgress = false);
      return;
    }

    try {
      final gapService = GapService();

      // ✅ Optimized: Use Future.wait to parallelize API calls
      final results = await Future.wait([
        gapService.getGapData(widget.plot.id!),
        gapService.getInputs(widget.plot.id!),
        gapService.getHarvests(widget.plot.id!),
        gapService.getTrainings(widget.plot.id!),
        gapService.getActivities(widget.plot.id!),
        gapService.getPostHarvestsForPlot(widget.plot.id!),
      ]);

      final gapData = results[0] as Map<String, dynamic>?;
      final inputs = results[1] as List;
      final harvests = results[2] as List;
      final trainings = results[3] as List;
      final activities = results[4] as List;
      final postHarvests = results[5] as List;

      if (mounted) {
        setState(() {
          _gapProgress = {
            // GapRecord exists if farmerName is set (flat response)
            'general': gapData != null && gapData['farmerName'] != null,
            'inputs': inputs.isNotEmpty,
            'management': activities.isNotEmpty,
            'harvest': harvests.isNotEmpty,
            'post_harvest': postHarvests.isNotEmpty,
            'safety': trainings.isNotEmpty,
            'traceability': harvests.isNotEmpty, // Based on harvest data
          };
          _loadingGapProgress = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingGapProgress = false);
    }
  }

  Future<void> _loadActivities() async {
    if (widget.plot.id == null) {
      setState(() => _loadingActivities = false);
      return;
    }

    try {
      final gapService = GapService();
      final activities = await gapService.getActivities(widget.plot.id!);
      if (mounted) {
        setState(() {
          _recentActivities = activities.map((a) {
            final type = a['type']?.toString() ?? 'general';
            return {
              'action': a['action']?.toString() ?? _getActionName(type),
              'date': _formatActivityDate(a['created_at'] ?? a['date']),
              'icon': _getActivityIcon(type),
              'color': _getActivityColor(type),
            };
          }).toList();
          _loadingActivities = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingActivities = false);
    }
  }

  String _getActionName(String type) {
    switch (type) {
      case 'general':
        return 'บันทึกข้อมูลทั่วไป';
      case 'input':
        return 'เพิ่มปัจจัยการผลิต';
      case 'management':
        return 'จัดการแปลง';
      case 'harvest':
        return 'เก็บเกี่ยว';
      case 'post_harvest':
        return 'หลังเก็บเกี่ยว';
      case 'safety':
        return 'ความปลอดภัย';
      case 'training':
        return 'เข้าร่วมอบรม';
      case 'plot_created':
        return 'สร้างแปลงใหม่';
      default:
        return 'กิจกรรม';
    }
  }

  String _formatActivityDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      final months = [
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
      return '${dt.day} ${months[dt.month - 1]} ${dt.year + 543}';
    } catch (e) {
      return date.toString();
    }
  }

  HeroIcons _getActivityIcon(String type) {
    switch (type) {
      case 'general':
        return HeroIcons.informationCircle;
      case 'input':
        return HeroIcons.beaker;
      case 'management':
        return HeroIcons.cog6Tooth;
      case 'harvest':
        return HeroIcons.scissors;
      case 'post_harvest':
        return HeroIcons.archiveBox;
      case 'safety':
        return HeroIcons.shieldCheck;
      case 'training':
        return HeroIcons.academicCap;
      case 'plot_created':
        return HeroIcons.mapPin;
      default:
        return HeroIcons.clipboardDocumentList;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'general':
        return Colors.blue;
      case 'input':
        return Colors.purple;
      case 'management':
        return Colors.indigo;
      case 'harvest':
        return Colors.orange;
      case 'post_harvest':
        return Colors.teal;
      case 'safety':
        return Colors.red;
      case 'training':
        return Colors.cyan;
      case 'plot_created':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() async {
    if (_mapController == null) return;

    // Add Plot Polygon with better styling
    if (widget.plot.boundary.isNotEmpty) {
      await _mapController!.addFill(
        FillOptions(
          geometry: [widget.plot.boundary],
          fillColor: AppColors.primary.toHexStringRGB(),
          fillOpacity: 0.35,
          fillOutlineColor: '#FFFFFF',
        ),
      );

      // Add outline
      await _mapController!.addLine(
        LineOptions(
          geometry: widget.plot.boundary,
          lineColor: '#FFFFFF',
          lineWidth: 2.5,
          lineOpacity: 0.9,
        ),
      );

      // Calculate center of polygon
      double sumLat = 0, sumLng = 0;
      for (final point in widget.plot.boundary) {
        sumLat += point.latitude;
        sumLng += point.longitude;
      }
      final centerLat = sumLat / widget.plot.boundary.length;
      final centerLng = sumLng / widget.plot.boundary.length;
      final center = LatLng(centerLat, centerLng);

      // Add red center marker circle
      await _mapController!.addCircle(
        CircleOptions(
          geometry: center,
          circleRadius: 12,
          circleColor: '#FF0000',
          circleStrokeWidth: 3,
          circleStrokeColor: '#FFFFFF',
          circleOpacity: 0.9,
        ),
      );

      // Add plot name as a symbol annotation (workaround: add small circle for inner dot)
      await _mapController!.addCircle(
        CircleOptions(
          geometry: center,
          circleRadius: 5,
          circleColor: '#FFFFFF',
          circleOpacity: 1,
        ),
      );

      // Center camera on polygon
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: 16.0),
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'ลบแปลง',
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คุณต้องการลบแปลง "${widget.plot.name}" หรือไม่?',
              style: GoogleFonts.prompt(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'การดำเนินการนี้ไม่สามารถย้อนกลับได้',
                      style: GoogleFonts.prompt(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.prompt(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePlot();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('ลบแปลง', style: GoogleFonts.prompt()),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlot() async {
    if (widget.plot.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่พบ ID ของแปลง', style: GoogleFonts.prompt()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final plotService = context.read<PlotService>();
      await plotService.deletePlot(widget.plot.id!);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const HeroIcon(
                HeroIcons.checkCircle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'ลบแปลง "${widget.plot.name}" สำเร็จ',
                style: GoogleFonts.prompt(),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
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

  /// Show dialog to edit plot name and species
  void _showEditPlotDialog() {
    final nameController = TextEditingController(text: widget.plot.name);
    final speciesController = TextEditingController(
      text: widget.plot.species ?? '',
    );
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const HeroIcon(
                  HeroIcons.pencilSquare,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'แก้ไขข้อมูลแปลง',
                style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อแปลง',
                    hintText: 'เช่น แปลงกระท่อม บ้านสวน',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.edit_outlined),
                  ),
                  style: GoogleFonts.prompt(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: speciesController,
                  decoration: InputDecoration(
                    labelText: 'ชนิดพืช',
                    hintText: 'เช่น ข้าว, ข้าวโพด, มันสำปะหลัง',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.eco_outlined),
                  ),
                  style: GoogleFonts.prompt(),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.prompt(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'กรุณากรอกชื่อแปลง',
                              style: GoogleFonts.prompt(),
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final plotService = context.read<PlotService>();
                        final updateData = <String, dynamic>{
                          'name': nameController.text,
                        };

                        // Only include species if it's not empty
                        if (speciesController.text.isNotEmpty) {
                          updateData['species'] = speciesController.text;
                        }

                        // Store messenger before async call to be safe (though dialog context works if open)
                        // But since we pop dialog first, we should use parent context's messenger if possible
                        // or ensuring usage before pop?
                        // Actually, standard pattern: Await -> Check Mounted -> Action
                        
                        await plotService.updatePlot(
                          widget.plot.id!,
                          updateData,
                        );

                        if (context.mounted) {
                           // Close Dialog first
                           Navigator.of(dialogContext).pop(); 
                           
                           // Show success on parent screen
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const HeroIcon(
                                    HeroIcons.checkCircle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'แก้ไขข้อมูลแปลงสำเร็จ',
                                    style: GoogleFonts.prompt(),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          // Return to previous screen with refresh flag
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                         if (dialogContext.mounted) {
                            setDialogState(() => isLoading = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('$e', style: GoogleFonts.prompt()),
                                backgroundColor: Colors.red,
                              ),
                            );
                         }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('บันทึก', style: GoogleFonts.prompt()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // 1. Enhanced Map Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Map
                  MaplibreMap(
                    styleString: _styleUrl,
                    onMapCreated: _onMapCreated,
                    onStyleLoadedCallback: _onStyleLoaded,
                    initialCameraPosition: CameraPosition(
                      target: widget.plot.boundary.isNotEmpty
                          ? widget.plot.boundary.first
                          : const LatLng(13.7, 100.5),
                      zoom: 15,
                    ),
                    myLocationEnabled: false,
                    attributionButtonPosition:
                        AttributionButtonPosition.topLeft,
                  ),
                  // Gradient Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Plot Name Overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.plot.name,
                                style: GoogleFonts.prompt(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    const Shadow(
                                      color: Colors.black38,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  const HeroIcon(
                                    HeroIcons.mapPin,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.plot.areaRai?.toStringAsFixed(2) ?? "-"} ไร่',
                                    style: GoogleFonts.prompt(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const HeroIcon(
                                    HeroIcons.sparkles,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.plot.species ?? 'ไม่ระบุพืช',
                                    style: GoogleFonts.prompt(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ปกติ',
                                style: GoogleFonts.prompt(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: HeroIcon(
                      HeroIcons.arrowLeft,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    // Share or more options
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const HeroIcon(
                      HeroIcons.ellipsisHorizontal,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. Content
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats Row
                      _buildQuickStats(),
                      const SizedBox(height: 24),

                      // แยก UI ตามสถานะ: APPROVED แสดง Certificate + GAP Read-Only
                      if (widget.plot.status == 'APPROVED') ...[
                        // Certificate Section สำหรับแปลงที่อนุมัติแล้ว
                        _buildCertificateSection(),
                        const SizedBox(height: 16),

                        // ✅ QR Code / Traceability Access
                        _buildModernActionTile(
                          title: 'QR Code ตรวจสอบย้อนกลับ',
                          subtitle: 'หมวด 7 (ดูข้อมูลและ QR Code ล็อตผลผลิต)',
                          icon: HeroIcons.qrCode,
                          color: AppColors.gapTraceability,
                          badge: '1/1',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GapTraceabilityForm(
                                  plotId: widget.plot.id ?? '',
                                  isReadOnly: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        // GAP Progress Section
                        _buildGapProgressSection(),
                        const SizedBox(height: 24),

                        // GAP Actions
                        Text(
                          'การจัดการ GAP',
                          style: GoogleFonts.prompt(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildModernActionTile(
                          title: 'บันทึก GAP',
                          subtitle: 'ข้อมูลการปลูก ดูแล เก็บเกี่ยว',
                          icon: HeroIcons.clipboardDocumentList,
                          color: AppColors.primary,
                          badge: '${_gapCompleted}/${_gapTotal}',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GapMainScreen(
                                  plotId: widget.plot.id ?? '',
                                  plotName: widget.plot.name,
                                ),
                              ),
                            );
                            // Refresh data after returning from GAP forms
                            _loadGapProgress();
                          },
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Danger Zone - ซ่อนเมื่อแปลง APPROVED แล้ว
                      Text(
                        'ตั้งค่าแปลง',
                        style: GoogleFonts.prompt(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // ถ้าแปลง APPROVED แล้ว แสดงข้อความแจ้งเตือน
                      if (widget.plot.status == 'APPROVED')
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const HeroIcon(
                                HeroIcons.checkBadge,
                                color: AppColors.success,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'แปลงได้รับการรับรองแล้ว',
                                      style: GoogleFonts.prompt(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    Text(
                                      'ไม่สามารถแก้ไขหรือลบแปลงที่รับรองแล้วได้',
                                      style: GoogleFonts.prompt(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        _buildModernActionTile(
                          title: 'แก้ไขข้อมูลแปลง',
                          subtitle: 'ชื่อ ประเภทพืช',
                          icon: HeroIcons.pencilSquare,
                          color: Colors.blue,
                          onTap: _showEditPlotDialog,
                        ),

                        _buildModernActionTile(
                          title: 'ลบแปลงนี้',
                          subtitle: 'ลบแปลงและข้อมูลทั้งหมด',
                          icon: HeroIcons.trash,
                          color: Colors.red,
                          isDanger: true,
                          onTap: _showDeleteConfirmation,
                        ),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    // Calculate plot age from createdAt
    final plotAge = widget.plot.ageInDays;
    final ageDisplay = plotAge > 0 ? plotAge.toString() : '-';

    // Use yieldEstimate from API if available, otherwise show '-'
    final yieldDisplay = widget.plot.yieldEstimate != null
        ? widget.plot.yieldEstimate!.toStringAsFixed(0)
        : '-';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'ขนาดพื้นที่',
            '${widget.plot.areaRai?.toStringAsFixed(1) ?? "-"}',
            'ไร่',
            HeroIcons.squares2x2,
            Colors.blue,
            tooltip: 'พื้นที่ของแปลงที่วาดไว้',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'ผลผลิตคาด',
            yieldDisplay,
            'กก.',
            HeroIcons.chartBar,
            Colors.orange,
            tooltip: 'ผลผลิตคาดการณ์ (กก./ไร่)',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'อายุแปลง',
            ageDisplay,
            'วัน',
            HeroIcons.calendar,
            Colors.purple,
            tooltip: 'จำนวนวันนับตั้งแต่สร้างแปลง',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String unit,
    HeroIcons icon,
    Color color, {
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? label,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: HeroIcon(icon, color: color, size: 18),
                ),
                if (tooltip != null)
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.prompt(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            Text(
              label,
              style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGapProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Progress Ring
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _gapPercent,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_gapPercent * 100).toInt()}%',
                      style: GoogleFonts.prompt(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ความคืบหน้า GAP',
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'บันทึกแล้ว $_gapCompleted จาก $_gapTotal หัวข้อ',
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _gapProgress.entries
                      .take(4)
                      .map(
                        (e) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: e.value
                                ? Colors.white.withOpacity(0.2)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: e.value
                                ? Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                e.value
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 12,
                                color: e.value ? Colors.white : Colors.white54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getGapLabel(e.key),
                                style: GoogleFonts.prompt(
                                  fontSize: 10,
                                  color: e.value
                                      ? Colors.white
                                      : Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGapLabel(String key) {
    switch (key) {
      case 'general':
        return 'ทั่วไป';
      case 'inputs':
        return 'ปัจจัย';
      case 'management':
        return 'จัดการ';
      case 'harvest':
        return 'เก็บเกี่ยว';
      case 'post_harvest':
        return 'หลังเกี่ยว';
      case 'safety':
        return 'ปลอดภัย';
      case 'traceability':
        return 'ตรวจสอบ';
      default:
        return key;
    }
  }

  /// Certificate Section สำหรับแปลงที่อนุมัติแล้ว
  Widget _buildCertificateSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success,
            AppColors.success.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with checkmark
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const HeroIcon(
                  HeroIcons.checkBadge,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ผ่านมาตรฐาน GAP',
                      style: GoogleFonts.prompt(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'แปลงได้รับการรับรองเรียบร้อยแล้ว',
                      style: GoogleFonts.prompt(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Logos row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Image.asset(
                  'assets/images/GAPLOGO.png',
                  height: 50,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 50, width: 50),
                ),
                Image.asset(
                  'assets/images/logo_ปปส.png',
                  height: 50,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 50, width: 50),
                ),
                Image.asset(
                  'assets/images/Gistnu_new_logo.webp',
                  height: 50,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 50, width: 50),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _viewCertificate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const HeroIcon(HeroIcons.eye, size: 20),
                  label: Text(
                    'ดูใบรับรอง',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloadCertificate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const HeroIcon(HeroIcons.arrowDownTray, size: 20),
                  label: Text(
                    'ดาวน์โหลด',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _viewCertificate() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdfService = context.read<CertificatePdfService>();
      final authProvider = context.read<AuthProvider>();
      
      // Use plot.ownerName if available (Admin view), else use current user name (Owner view)
      final ownerName = widget.plot.ownerName ?? authProvider.user?.fullName ?? 'เกษตรกร';
      
      final file = await pdfService.generateCertificate(widget.plot, ownerName: ownerName);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      // Open PDF viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CertificateViewerScreen(pdfPath: file.path),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadCertificate() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdfService = context.read<CertificatePdfService>();
      final authProvider = context.read<AuthProvider>();
      
      // Use plot.ownerName if available (Admin view), else use current user name (Owner view)
      final ownerName = widget.plot.ownerName ?? authProvider.user?.fullName ?? 'เกษตรกร';
      
      final file = await pdfService.generateCertificate(widget.plot, ownerName: ownerName);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const HeroIcon(HeroIcons.checkCircle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'บันทึกใบรับรองแล้ว: ${file.path.split('/').last}',
                  style: GoogleFonts.prompt(),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'เปิด',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CertificateViewerScreen(pdfPath: file.path),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Widget _buildModernActionTile({
    required String title,
    required String subtitle,
    required HeroIcons icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
    bool isDanger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isDanger
            ? Border.all(color: Colors.red.withOpacity(0.2))
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: HeroIcon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const HeroIcon(
              HeroIcons.chevronRight,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'กิจกรรมล่าสุด',
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // GAP-FIX-003: Removed dead button - "ดูทั้งหมด" had no functionality
            // Future: Navigate to activity history page when implemented
            // TextButton(
            //   onPressed: () {
            //     // TODO: Navigate to full activity history
            //   },
            //   child: Text(
            //     'ดูทั้งหมด',
            //     style: GoogleFonts.prompt(color: AppColors.primary),
            //   ),
            // ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _loadingActivities
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _recentActivities.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      HeroIcon(
                        HeroIcons.clipboardDocumentList,
                        color: Colors.grey.withOpacity(0.3),
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ยังไม่มีกิจกรรม',
                        style: GoogleFonts.prompt(color: Colors.grey),
                      ),
                      Text(
                        'เริ่มบันทึกข้อมูล GAP เพื่อดูกิจกรรมที่นี่',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: _recentActivities.asMap().entries.map((entry) {
                    final index = entry.key;
                    final activity = entry.value;
                    final isLast = index == _recentActivities.length - 1;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (activity['color'] as Color).withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: HeroIcon(
                                activity['icon'] as HeroIcons,
                                color: activity['color'] as Color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity['action'] as String,
                                    style: GoogleFonts.prompt(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    activity['date'] as String,
                                    style: GoogleFonts.prompt(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 18,
                              top: 8,
                              bottom: 8,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 2,
                                  height: 20,
                                  color: Colors.grey[200],
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
