import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/gap_service.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/widgets/nature_background.dart';
import '../../../data/models/user_model.dart';
import '../widgets/plot_confirmation_dialog.dart';

import 'package:printing/printing.dart';
import '../../../core/services/pdf_generator_service.dart';
import 'traceability_sheet.dart';
import '../../gap/screens/plot_gallery_screen.dart'; // Added

/// Admin GAP Inspection Report Screen
/// แสดงสรุป GAP 8 หมวดของ User ที่ Admin กำลังตรวจสอบ (Read-Only)
class AdminGapInspectionScreen extends StatefulWidget {
  final String plotId;
  final String plotName;
  final UserModel? owner;

  const AdminGapInspectionScreen({
    super.key,
    required this.plotId,
    required this.plotName,
    this.owner,
  });

  @override
  State<AdminGapInspectionScreen> createState() =>
      _AdminGapInspectionScreenState();
}

class _AdminGapInspectionScreenState extends State<AdminGapInspectionScreen> {
  final _gapService = GapService();
  final _adminService = AdminService(); // Add AdminService
  bool _isLoading = true;
  Map<String, dynamic> _summaryData = {};
  Map<String, dynamic>? _generalData;

  /// GAP 8 หมวดตามมาตรฐานกรมวิชาการเกษตร
  final List<Map<String, dynamic>> _categories = [
    {
      'key': 'general',
      'title': '1. ข้อมูลทั่วไป',
      'subtitle': 'แหล่งน้ำ, พื้นที่',
      'icon': PhosphorIconsRegular.info,
      'color': AppColors.primary,
    },
    {
      'key': 'inputs',
      'title': '2. ปัจจัยการผลิต',
      'subtitle': 'สารเคมี, ปุ๋ย',
      'icon': PhosphorIconsRegular.flask,
      'color': AppColors.primary,
    },
    {
      'key': 'management',
      'title': '3. การจัดการแปลง',
      'subtitle': 'การดูแลพื้นที่',
      'icon': PhosphorIconsRegular.wrench,
      'color': AppColors.primary,
    },
    {
      'key': 'harvest',
      'title': '4. การเก็บเกี่ยว',
      'subtitle': 'ผลผลิต, คุณภาพ',
      'icon': PhosphorIconsRegular.archive,
      'color': AppColors.primary,
    },
    {
      'key': 'postHarvest',
      'title': '5. หลังเก็บเกี่ยว',
      'subtitle': 'การจัดเก็บ',
      'icon': PhosphorIconsRegular.cube,
      'color': AppColors.primary,
    },
    {
      'key': 'safety',
      'title': '6. ความปลอดภัย',
      'subtitle': 'การอบรมบุคลากร',
      'icon': PhosphorIconsRegular.shieldCheck,
      'color': AppColors.primary,
    },
    {
      'key': 'traceability',
      'title': '7. ตรวจติดตาม',
      'subtitle': 'ระบบติดตาม',
      'icon': PhosphorIconsRegular.magnifyingGlass,
      'color': AppColors.primary,
    },
  ];

  @override
  void initState() {
    super.initState();
    _owner = widget.owner; // Initialize local owner
    _loadSummary();
    if (widget.owner == null) {
      _fetchOwnerDetails();
    }
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    
    // Helper to safely fetch data
    Future<T?> safeFetch<T>(Future<T> Function() fetcher) async {
      try {
        return await fetcher();
      } catch (e) {
        print('⚠️ Gap Data Fetch Error: $e');
        return null;
      }
    }

    try {
      // Parallel fetching for performance, but safe independent execution
      final results = await Future.wait([
        safeFetch(() => _gapService.getGapData(widget.plotId)),      // 0
        safeFetch(() => _gapService.getInputs(widget.plotId)),       // 1
        safeFetch(() => _gapService.getFieldManagements(widget.plotId)), // 2
        safeFetch(() => _gapService.getHarvests(widget.plotId)),     // 3
        safeFetch(() => _gapService.getPostHarvestsForPlot(widget.plotId)), // 4
        safeFetch(() => _gapService.getTrainings(widget.plotId)),    // 5
      ]);

      final gapRecord = results[0] as Map<String, dynamic>?;
      final inputs = results[1] as List<dynamic>? ?? [];
      final managements = results[2] as List<dynamic>? ?? [];
      final harvests = results[3] as List<dynamic>? ?? [];
      final postHarvests = results[4] as List<dynamic>? ?? [];
      final trainings = results[5] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          _generalData = gapRecord;
          _summaryData = {
            'general': gapRecord != null
                ? {
                    'completed': true,
                    'summary': _buildGeneralSummary(gapRecord),
                    'details': gapRecord,
                    'data': gapRecord,
                  }
                : null,
            'inputs': inputs.isNotEmpty
                ? {
                    'completed': true,
                    'summary': 'บันทึก ${inputs.length} รายการ',
                    'count': inputs.length,
                    'data': inputs,
                  }
                : null,
            'management': managements.isNotEmpty
                ? {
                    'completed': true,
                    'summary': 'บันทึก ${managements.length} กิจกรรม',
                    'count': managements.length,
                    'data': managements,
                  }
                : null,
            'harvest': harvests.isNotEmpty
                ? {
                    'completed': true,
                    'summary': _buildHarvestSummary(harvests),
                    'count': harvests.length,
                    'data': harvests,
                  }
                : null,
            'postHarvest': postHarvests.isNotEmpty
                ? {
                    'completed': true,
                    'summary': 'บันทึก ${postHarvests.length} รายการ',
                    'count': postHarvests.length,
                    'data': postHarvests,
                  }
                : null,
            'safety': trainings.isNotEmpty
                ? {
                    'completed': true,
                    'summary': 'อบรม ${trainings.length} หัวข้อ',
                    'count': trainings.length,
                    'data': trainings,
                  }
                : null,
            'traceability': harvests.isNotEmpty
                ? {
                    'completed': true,
                    'summary': 'มี ${harvests.length} ล็อตผลผลิต',
                    'count': harvests.length,
                    'data': harvests,
                  }
                : null,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ ERROR LOADING GAP SUMMARY: $e'); 
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Fetch Owner if missing
  Future<void> _fetchOwnerDetails() async {
    if (widget.owner != null) return;
    try {
      final plot = await _adminService.getPlotDetail(widget.plotId);
      if (plot['owner'] != null && mounted) {
        setState(() {
           // We can't update widget.owner (final), so we store it in a local variable
           _owner = UserModel.fromJson(plot['owner']);
        });
      }
    } catch (e) {
      print('Error fetching owner: $e');
    }
  }

  UserModel? _owner; // Local owner state


  String _buildGeneralSummary(Map<String, dynamic> data) {
    final items = <String>[];
    if (data['farmerName'] != null) items.add('👤 ${data['farmerName']}');
    if (data['farmingSystem'] != null) {
      final system = data['farmingSystem'] == 'ORGANIC'
          ? 'อินทรีย์'
          : data['farmingSystem'] == 'TRANSITION'
          ? 'ปรับเปลี่ยน'
          : 'เคมี';
      items.add('🌱 $system');
    }
    if (data['waterSource'] != null) items.add('💧 ${data['waterSource']}');
    return items.isNotEmpty ? items.join(' • ') : 'มีข้อมูล';
  }

  String _buildHarvestSummary(List<dynamic> harvests) {
    if (harvests.isEmpty) return 'ไม่มีข้อมูล';
    final latest = harvests.first as Map<String, dynamic>;
    final items = <String>[];
    if (latest['yieldAmount'] != null) {
      items.add('⚖️ ${latest['yieldAmount']} ${latest['yieldUnit'] ?? 'กก.'}');
    }
    if (latest['qualityGrade'] != null)
      items.add('⭐ ${latest['qualityGrade']}');
    return items.isNotEmpty ? items.join(' • ') : 'มีข้อมูลเก็บเกี่ยว';
  }

  int get _completedCount => _summaryData.values.where((v) => v != null).length;
  int get _totalCategories => _categories.length;
  double get _completionPercentage => _completedCount / _totalCategories;

  String get _overallStatus {
    if (_completionPercentage >= 1.0) return '✅ สมบูรณ์';
    if (_completionPercentage >= 0.7) return '⚠️ เกือบครบ';
    if (_completionPercentage > 0) return '❌ ยังไม่ครบ';
    return '❌ ยังไม่กรอก';
  }

  Color get _overallStatusColor {
    if (_completionPercentage >= 1.0) return AppColors.success;
    if (_completionPercentage >= 0.7) return Colors.orange;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Professional Gradient Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: (MediaQuery.of(context).size.height * 0.3).clamp(
              180.0,
              double.infinity,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSummary,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Owner Info Card
                                  _buildOwnerInfoCard(),
                                  const SizedBox(height: 20),

                                  // Overall Progress
                                  _buildOverallProgress(),
                                  const SizedBox(height: 20),

                                  // Categories
                                  Text(
                                    'รายละเอียด GAP 7 หมวด',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._categories.map(
                                    (cat) => _buildCategoryCard(cat),
                                  ),

                                  const SizedBox(height: 20),

                                  // Export Button
                                  _buildExportButton(),

                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'รายงานตรวจสอบ GAP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.plotName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Gallery Button
          IconButton(
            icon: const Icon(PhosphorIconsRegular.image, color: Colors.white),
            tooltip: 'ดูรูปแปลง',
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlotGalleryScreen(
                    plotId: widget.plotId,
                    plotName: widget.plotName,
                    isReadOnly: true,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _overallStatusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _overallStatusColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              _overallStatus,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerInfoCard() {
    final owner = _owner; // Use local variable
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  owner?.firstName.isNotEmpty == true
                      ? owner!.firstName[0]
                      : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เจ้าของแปลง',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      owner?.fullName ??
                          _generalData?['farmerName'] ??
                          'ไม่ทราบชื่อ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (owner?.phone != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        PhosphorIconsRegular.phone,
                        size: 14,
                        color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        owner!.phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (owner?.locationDisplay != null &&
              owner!.locationDisplay.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(PhosphorIconsRegular.mapPin, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    owner.locationDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverallProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ความสมบูรณ์ GAP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_completedCount / $_totalCategories หมวด',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _overallStatusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _completionPercentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(_overallStatusColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_completionPercentage * 100).toInt()}% สมบูรณ์',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final key = category['key'] as String;
    final data = _summaryData[key];
    final isCompleted = data != null;
    final color = category['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
        boxShadow: isCompleted
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCompleted
              ? () => _showCategoryDetails(key, category['title'])
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isCompleted ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: isCompleted ? color : Colors.grey,
                    size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      Text(
                        isCompleted
                            ? (data['summary'] ?? 'มีข้อมูล')
                            : 'ยังไม่ได้บันทึก',
                        style: TextStyle(
                          fontSize: 11,
                          color: isCompleted
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Feedback Button
                if (isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _showFeedbackDialog(key, category['title']),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.chatsCircle,
                          color: Colors.orange,
                          size: 20),
                      ),
                    ),
                  ),

                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? PhosphorIconsRegular.check : PhosphorIconsRegular.x,
                    color: isCompleted
                        ? Colors.white
                        : Colors.grey.shade400,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryDetails(String key, String title) {
    // Check if separate dialog needed for Traceability
    if (key == 'traceability') {
      _showTraceabilityManagementDialog();
      return;
    }

    final data = _summaryData[key]?['data'];
    if (data == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'รายละเอียด: $title',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildDetailList(key, data, controller),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Value Translator: Convert technical enums to Thai
  String _translateValue(String key, dynamic value) {
    if (value == null) return '-';
    final String valStr = value.toString();

    // Farming System
    if (key == 'farmingSystem') {
      switch (valStr.toUpperCase()) {
        case 'ORGANIC': return 'เกษตรอินทรีย์';
        case 'GAP': return 'GAP';
        case 'CHEMICAL': return 'เคมี';
        case 'SAFE': return 'ปลอดภัย';
        case 'TRANSITION': return 'ระยะปรับเปลี่ยน';
        case 'NON_ORGANIC': return 'ทั่วไป (ไม่ใช่อินทรีย์)';
      }
    }

    // Activity Types
    if (key == 'activityType' || key == 'activity') {
      switch (valStr.toUpperCase()) {
        case 'SOIL_PREP': return 'การเตรียมดิน';
        case 'PLANTING': return 'การเพาะปลูก';
        case 'CARE': return 'การดูแลรักษา';
        case 'FERTILIZING': return 'การใส่ปุ๋ย';
        case 'WATERING': return 'การให้น้ำ';
        case 'PEST_CONTROL': return 'การป้องกันกำจัดศัตรูพืช';
        case 'HARVEST': return 'การเก็บเกี่ยว';
        case 'POST_HARVEST': return 'การจัดการหลังเก็บเกี่ยว';
      }
    }


    // Land Ownership
    if (key == 'landOwnership') {
      switch (valStr.toUpperCase()) {
        case 'OWNED': return 'โฉนดที่ดิน (ของตนเอง)';
        case 'RENTED': return 'เช่า';
        case 'PUBLIC': return 'ที่สาธารณะ';
        case 'ROYAL': return 'ที่ราชพัสดุ';
      }
    }

    // Soil Type
    if (key == 'soilType') {
      switch (valStr.toUpperCase()) {
        case 'CLAY': return 'ดินเหนียว';
        case 'LOAM': return 'ดินร่วน';
        case 'SAND': return 'ดินทราย';
        case 'SILT': return 'ดินตะกอน';
      }
    }

    // Water Source
    if (key == 'waterSource') {
      switch (valStr.toUpperCase()) {
        case 'IRRIGATION': return 'ชลประทาน';
        case 'RIVER': return 'แม่น้ำ/ลำคลอง';
        case 'GROUNDWATER': return 'น้ำบาดาล';
        case 'RAINWATER': return 'น้ำฝน';
        case 'POND': return 'สระน้ำ';
      }
    }

    // Irrigation System
    if (key == 'irrigationSystem') {
      switch (valStr.toUpperCase()) {
        case 'SPRINKLER': return 'สปริงเกอร์';
        case 'DRIP': return 'น้ำหยด';
        case 'FLOOD': return 'ปล่อยท่วม';
        case 'MANUAL': return 'รดด้วยมือ';
      }
    }

    // Input Types
    if (key == 'type' || valStr == 'SEED' || valStr == 'FERTILIZER') {
       switch (valStr.toUpperCase()) {
        case 'SEED': return 'เมล็ดพันธุ์/กิ่งพันธุ์';
        case 'FERTILIZER': return 'ปุ๋ย';
        case 'PESTICIDE': return 'สารกำจัดศัตรูพืช';
        case 'HERBICIDE': return 'สารกำจัดวัชพืช';
        case 'HORMONE': return 'ฮอร์โมนพืช';
        case 'OTHER': return 'อื่นๆ';
      }
    }

    // Common Crops (Add as needed)
    switch (valStr.toUpperCase()) {
      case 'KRATOM': return 'กระท่อม';
      case 'DURIAN': return 'ทุเรียน';
      case 'MANGOSTEEN': return 'มังคุด';
      case 'RAMBUTAN': return 'เงาะ';
      case 'LONGAN': return 'ลำไย';
      case 'MAIZE': return 'ข้าวโพด';
      case 'CASSAVA': return 'มันสำปะหลัง';
      case 'RICE': return 'ข้าว';
      case 'SUGARCANE': return 'อ้อย';
      case 'PARA_RUBBER': return 'ยางพารา';
      case 'PALM': return 'ปาล์มน้ำมัน';
      case 'KG': return 'กิโลกรัม';
      case 'LITER': return 'ลิตร';
      case 'RAI': return 'ไร่';
      case 'BOTTLE': return 'ขวด';
      case 'BAG': return 'ถุง';
      case 'TRUE': return 'ใช่/ผ่าน';
      case 'FALSE': return 'ไม่ใช่/ไม่ผ่าน';
    }

    // Handle generic English terms that might appear
    if (valStr.contains('North')) return valStr.replaceAll('North', 'เหนือ');
    if (valStr.contains('South')) return valStr.replaceAll('South', 'ใต้');
    if (valStr.contains('East')) return valStr.replaceAll('East', 'ตะวันออก');
    if (valStr.contains('West')) return valStr.replaceAll('West', 'ตะวันตก');

    return valStr;
  }

  // Helper for safe value display
  String _formatValue(String key, dynamic value) {
    if (value == null) return '-';
    
    // Handle List (e.g. hygiene flags or multi-selects)
    if (value is List) {
      if (value.isEmpty) return '-';
      return value.map((v) => _translateValue(key, v)).join(', ');
    }

    if (value is String) {
      if (value.isEmpty || value == 'null') return '-';
      // Detect ISO Date
      if (DateTime.tryParse(value) != null && value.contains('T')) {
        return _formatDate(value);
      }
    }
    // Use Translator
    return _translateValue(key, value);
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      // Simple Thai Date Format: DD/MM/YYYY
      return '${date.day}/${date.month}/${date.year + 543}';
    } catch (e) {
      return isoString;
    }
  }

  Widget _buildDetailList(String key, dynamic data, ScrollController controller) {
    if (data is Map) {
      // 1. General Info (Single Map)
      // Define ALL possible keys for General Info
      // Removed technical IDs as requested
      final displayKeys = [
        'plotName',      // Priority 1
        'farmerName',
        'address',
        'subDistrict',
        'district',
        'province',
        'zipcode',
        // 'location', // Too technical usually
        'farmingSystem', // ระบบการผลิต
        'cropType',      // พืช
        'cropVariety',   // พันธุ์
        'landOwnership', // กรรมสิทธิ์
        'area',          // พื้นที่
        'waterSource',   // แหล่งน้ำ
        'irrigationSystem', // ระบบน้ำ
        'soilType',      // ดิน
        'registerDate', // วันที่ขึ้นทะเบียน
        'expireDate', // วันที่หมดอายุ
      ];

      return ListView(
        controller: controller,
        padding: const EdgeInsets.only(bottom: 20),
        children: displayKeys.map((k) {
          
          // ✅ FIX: Force Plot Name from Widget if missing in API
          var val = data[k];
          if (k == 'plotName' && (val == null || val.toString().isEmpty || val == 'null')) {
            val = widget.plotName; // Use the name passed from Map Screen
          }

          // Show "Unspecified" for important fields even if null
          if (val == null && !['farmerName', 'plotName'].contains(k)) return const SizedBox.shrink();
          
          final info = _getFieldInfo(k);
          return _buildInfoCard(
            label: info['label'],
            value: _formatValue(k, val), // Pass key for translation
            icon: info['icon'],
          );
        }).toList(),
      );
    } else if (data is List) {
      if (data.isEmpty) return _buildEmptyState();

      return ListView.separated(
        controller: controller,
        itemCount: data.length,
        padding: const EdgeInsets.only(bottom: 20),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = data[index];
          // Determine if this is Traceability (which is just Harvests now)
          if (key == 'traceability') {
             return _buildListItemCard('harvest', item, index, isTraceability: true);
          }
          if (item is! Map) return ListTile(title: Text(item.toString()));

          return _buildListItemCard(key, item, index);
        },
      );
    }
    return Center(child: Text('รูปแบบข้อมูลไม่ถูกต้อง', style: const TextStyle()));
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItemCard(String key, Map<dynamic, dynamic> item, int index, {bool isTraceability = false}) {
    String title = 'รายการที่ ${index + 1}';
    String? subtitle;
    IconData icon = PhosphorIconsRegular.fileText;
    Color color = AppColors.primary;
    List<Widget> details = [];

    // Comprehensive Mapping Logic
    switch (key) {
      case 'inputs': // 2. ปัจจัยการผลิต
        // ✅ Smart Input Title/Subtitle
        title = _formatValue('name', item['name'] ?? item['inputName'] ?? 'ปัจจัยการผลิต');
        
        String inputType = _formatValue('type', item['type']);
        String quantity = _formatValue('amount', item['quantity']);
        String unit = _formatValue('unit', item['unit']);
        
        if (quantity != '-' && quantity != '0') {
           subtitle = '$quantity $unit ($inputType)';
        } else {
           subtitle = 'ประเภท: $inputType'; // Don't show "0 kg"
        }

        icon = PhosphorIconsRegular.flask;
        color = Colors.blue;
        details = [
          _buildDetailRow('ประเภท', inputType),
          _buildDetailRow('ชื่อสามัญ/การค้า', _formatValue('name', item['name'] ?? item['inputName'])),
          _buildDetailRow('แหล่งที่มา', _formatValue('source', item['source'])),
          _buildDetailRow('วันที่ซื้อ', _formatValue('purchaseDate', item['purchaseDate'])),
          _buildDetailRow('ทะเบียนวัตถุอันตราย', _formatValue('registrationNo', item['registrationNo'])),
          _buildDetailRow('วิธีใช้', _formatValue('usageMethod', item['usageMethod'])),
          // Only show usage rate if valid
          if (item['usageRate'] != null && item['usageRate'].toString() != '0')
             _buildDetailRow('อัตราการใช้', _formatValue('usageRate', item['usageRate'])),
          _buildDetailRow('ผู้บันทึก', _formatValue('recorder', item['recorder'])),
        ];
        break;
        
      case 'management': // 3. การจัดการแปลง
        // ✅ Corrected Keys based on user logs
        String activityKey = item.containsKey('activityType') ? 'activityType' : 'activity';
        String dateKey = item.containsKey('activityDate') ? 'activityDate' : 'date';
        
        String activity = item[activityKey]?.toString() ?? '';
        String description = item['description']?.toString() ?? '';
        
        if (activity.isEmpty || activity == 'null' || activity == '-') {
           if (description.isNotEmpty) {
             title = description.length > 30 ? '${description.substring(0, 30)}...' : description;
           } else {
             title = 'กิจกรรมแปลง';
           }
        } else {
           title = _formatValue('activityType', activity);
        }

        subtitle = _formatValue('date', item[dateKey]);
        icon = PhosphorIconsRegular.wrench;
        color = Colors.teal;
        
        // Identify material/machine/chemical used
        String material = '-';
        if (item['machineUsed'] != null) material = item['machineUsed'];
        if (item['chemicalUsed'] != null) material = item['chemicalUsed'];
        if (item['material'] != null) material = item['material'];

        details = [
          _buildDetailRow('วันที่ดำเนินการ', _formatValue('date', item[dateKey])),
          // _buildDetailRow('ช่วงเวลา', _formatValue('time', item['time'])), // Not in logs logic usually
          _buildDetailRow('กิจกรรม', _formatValue('activityType', activity)), 
          _buildDetailRow('รายละเอียด', _formatValue('description', description)),
          _buildDetailRow('วัสดุ/อุปกรณ์/สารเคมี', _formatValue('material', material)),
          _buildDetailRow('ผู้ปฏิบัติงาน', _formatValue('operator', item['workerName'] ?? item['operator'])),
          //_buildDetailRow('สภาพอากาศ', _formatValue('weather', item['weather'])),
          //_buildDetailRow('หมายเหตุ', _formatValue('note', item['note'])),
        ];
        break;
        
      case 'harvest': // 4. การเก็บเกี่ยว + 7. Traceability
        title = 'เก็บเกี่ยว ${_formatValue('amount', item['yieldAmount'])} ${_formatValue('unit', item['yieldUnit'])}';
        subtitle = 'เกรด: ${_formatValue('grade', item['qualityGrade'])}';
        icon = isTraceability ? PhosphorIconsRegular.magnifyingGlass : PhosphorIconsRegular.archive;
        color = isTraceability ? Colors.deepPurple : Colors.orange;
        details = [
          _buildDetailRow('รหัสรุ่น (Lot No)', _formatValue('lotNo', item['lotNo'] ?? item['lotNumber'])),
          _buildDetailRow('วันที่เก็บเกี่ยว', _formatValue('date', item['harvestDate'])),
          _buildDetailRow('ผู้เก็บเกี่ยว', _formatValue('harvester', item['harvestedBy'])),
          _buildDetailRow('วิธีการ/อุปกรณ์', _formatValue('method', item['harvestMethod'] ?? item['equipmentUsed'])),
          _buildDetailRow('ปริมาณที่ได้', '${_formatValue('amount', item['yieldAmount'])} ${_formatValue('unit', item['yieldUnit'])}'),
          _buildDetailRow('เกรด/คุณภาพ', _formatValue('grade', item['qualityGrade'])),
          _buildDetailRow('ภาชนะบรรจุ', _formatValue('container', item['container'])),
          _buildDetailRow('การขนย้าย', _formatValue('transport', item['transport'])),
           _buildDetailRow('หมายเหตุ', _formatValue('note', item['notes'] ?? item['note'])),
          _buildDetailRow('ผู้บันทึก', _formatValue('recorder', item['recorder'])),
        ];
        break;
        
      case 'postHarvest': // 5. หลังเก็บเกี่ยว
        title = _formatValue('activity', item['activity'] ?? item['processType'] ?? 'กิจกรรมหลังเก็บเกี่ยว');
        subtitle = _formatValue('date', item['date'] ?? item['processDate']);
        icon = PhosphorIconsRegular.cube;
        color = Colors.indigo;
        details = [
          _buildDetailRow('วันที่ดำเนินการ', _formatValue('date', item['date'] ?? item['processDate'])),
          _buildDetailRow('วิธีการแปรรูป', _formatValue('method', item['method'] ?? item['processType'])),
          _buildDetailRow('บรรจุภัณฑ์', _formatValue('packaging', item['packagingType'] ?? item['packaging'])),
          _buildDetailRow('สถานที่เก็บรักษา', _formatValue('location', item['storageLocation'])),
          _buildDetailRow('อุณหภูมิ', item['storageTemperature'] != null || item['storageTemp'] != null 
              ? '${item['storageTemperature'] ?? item['storageTemp']} °C' : '-'),
          _buildDetailRow('ความชื้น', item['humidity'] != null || item['storageHumidity'] != null 
              ? '${item['humidity'] ?? item['storageHumidity']} %' : '-'),
          _buildDetailRow('ระยะเวลาเก็บ', _formatValue('duration', item['duration'])),
           // Show description if available (e.g. "Sorting, Washing")
          _buildDetailRow('รายละเอียด/ขั้นตอน', _formatValue('description', item['description'] ?? item['cleaning'])), 
        ];
        break;
        
      case 'safety': // 6. ความปลอดภัย (อบรม/สุขลักษณะ)
        title = _formatValue('topic', item['topic'] ?? item['trainingTopic'] ?? 'หัวข้ออบรม');
        subtitle = _formatValue('date', item['trainingDate']);
        icon = PhosphorIconsRegular.graduationCap;
        color = Colors.purple;
        details = [
          _buildDetailRow('หัวข้ออบรม', _formatValue('topic', item['topic'] ?? item['trainingTopic'])),
          _buildDetailRow('วันที่อบรม', _formatValue('date', item['trainingDate'])),
          _buildDetailRow('วิทยากร/ผู้จัด', _formatValue('trainer', item['trainer'])),
          _buildDetailRow('สถานที่', _formatValue('location', item['location'])),
          _buildDetailRow('จำนวนชั่วโมง', item['durationHours'] != null ? '${item['durationHours']} ชม.' : '-'),
          _buildDetailRow('จำนวนผู้เข้าร่วม', item['attendees'] != null ? '${item['attendees']} คน' : '-'),
          _buildDetailRow('มาตรการสุขลักษณะ', _formatValue('hygiene', item['hygieneNotes'] ?? item['hygieneFlags'])),
          _buildDetailRow('ผลการประเมิน', _formatValue('result', item['result'])),
          _buildDetailRow('เอกสารแนบ', _formatValue('attachment', item['attachment'])),
        ];
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withValues(alpha: 0.03),
             blurRadius: 8,
             offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: subtitle != null 
          ? Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])) 
          : null,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          ...details.where((w) => w is! SizedBox), // Filter empty
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value == '-' || value.isEmpty || value == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Wider label for Thai text
            child: Text(
              label, 
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
            ),
          ),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(PhosphorIconsRegular.tray, size: 64, color: Colors.grey[200]),
           const SizedBox(height: 16),
           Text('ยังไม่มีข้อมูลบันทึกในหมวดนี้', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
         ],
      ),
    );
  }

  // ✅ Comprehensive Helper to map Keys to Thai Labels & Icons
  Map<String, dynamic> _getFieldInfo(String key) {
    switch (key) {
      // General Info
      case 'farmerName': return {'label': 'ชื่อเกษตรกร', 'icon': PhosphorIconsRegular.user};
      case 'plotName': return {'label': 'ชื่อแปลง', 'icon': PhosphorIconsRegular.mapTrifold};
      case 'address': return {'label': 'ที่อยู่', 'icon': PhosphorIconsRegular.mapPin};
      case 'subDistrict': return {'label': 'ตำบล', 'icon': PhosphorIconsRegular.mapTrifold};
      case 'district': return {'label': 'อำเภอ', 'icon': PhosphorIconsRegular.buildings};
      case 'province': return {'label': 'จังหวัด', 'icon': PhosphorIconsRegular.bank};
      case 'zipcode': return {'label': 'รหัสไปรษณีย์', 'icon': PhosphorIconsRegular.envelopeSimple};
      case 'location': return {'label': 'พิกัด', 'icon': PhosphorIconsRegular.globeHemisphereEast};
      case 'farmingSystem': return {'label': 'ระบบการผลิต', 'icon': PhosphorIconsRegular.cpu};
      case 'waterSource': return {'label': 'แหล่งน้ำ', 'icon': PhosphorIconsRegular.cloud};
      case 'soilType': return {'label': 'ชนิดดิน', 'icon': PhosphorIconsRegular.globe};
      case 'cropType': return {'label': 'พืชที่ปลูก', 'icon': PhosphorIconsRegular.sparkle};
      case 'cropVariety': return {'label': 'พันธุ์พืช', 'icon': PhosphorIconsRegular.tag};
      case 'area': return {'label': 'พื้นที่ (ไร่)', 'icon': PhosphorIconsRegular.copy};
      case 'landOwnership': return {'label': 'กรรมสิทธิ์', 'icon': PhosphorIconsRegular.fileText};
      case 'irrigationSystem': return {'label': 'ระบบน้ำ', 'icon': PhosphorIconsRegular.playCircle};
      case 'registerDate': return {'label': 'วันที่ขึ้นทะเบียน', 'icon': PhosphorIconsRegular.calendarBlank};
      case 'expireDate': return {'label': 'วันที่หมดอายุ', 'icon': PhosphorIconsRegular.clock};
      case 'createdById': return {'label': 'ผู้บันทึก (ID)', 'icon': PhosphorIconsRegular.userCircle};
      case 'createdAt': return {'label': 'วันที่สร้าง', 'icon': PhosphorIconsRegular.calendarDots};
      case 'updatedAt': return {'label': 'อัปเดตล่าสุด', 'icon': PhosphorIconsRegular.arrowsClockwise};

      // Inputs (ปัจจัยการผลิต)
      case 'type': return {'label': 'ประเภท', 'icon': PhosphorIconsRegular.flask};
      case 'name': return {'label': 'ชื่อสามัญ/การค้า', 'icon': PhosphorIconsRegular.tag};
      case 'source': return {'label': 'แหล่งที่มา', 'icon': PhosphorIconsRegular.shoppingBag};
      case 'purchaseDate': return {'label': 'วันที่ซื้อ', 'icon': PhosphorIconsRegular.calendarBlank};
      case 'registrationNo': return {'label': 'เลขทะเบียน', 'icon': PhosphorIconsRegular.identificationCard};
      case 'usageMethod': return {'label': 'วิธีใช้', 'icon': PhosphorIconsRegular.wrench};
      case 'usageRate': return {'label': 'อัตราการใช้', 'icon': PhosphorIconsRegular.scales};
      case 'recorder': return {'label': 'ผู้บันทึก', 'icon': PhosphorIconsRegular.pencilSimple};

      // Management (การจัดการแปลง)
      case 'activity': return {'label': 'กิจกรรม', 'icon': PhosphorIconsRegular.wrench};
      case 'date': return {'label': 'วันที่', 'icon': PhosphorIconsRegular.calendarBlank};
      case 'time': return {'label': 'เวลา', 'icon': PhosphorIconsRegular.clock};
      case 'description': return {'label': 'รายละเอียด', 'icon': PhosphorIconsRegular.fileText};
      case 'material': return {'label': 'วัสดุ/อุปกรณ์', 'icon': PhosphorIconsRegular.cube};
      case 'operator': return {'label': 'ผู้ปฏิบัติงาน', 'icon': PhosphorIconsRegular.user};
      case 'weather': return {'label': 'สภาพอากาศ', 'icon': PhosphorIconsRegular.cloud};
      case 'note': return {'label': 'หมายเหตุ', 'icon': PhosphorIconsRegular.clipboard};

      // Harvest (เก็บเกี่ยว)
      case 'harvestDate': return {'label': 'วันที่เก็บเกี่ยว', 'icon': PhosphorIconsRegular.calendarBlank};
      case 'yieldAmount': return {'label': 'ปริมาณ', 'icon': PhosphorIconsRegular.scales};
      case 'qualityGrade': return {'label': 'เกรด/คุณภาพ', 'icon': PhosphorIconsRegular.star};
      case 'container': return {'label': 'ภาชนะบรรจุ', 'icon': PhosphorIconsRegular.cube};
      case 'transport': return {'label': 'การขนย้าย', 'icon': PhosphorIconsRegular.truck};
      
      // Safety (ความปลอดภัย)
      case 'topic': return {'label': 'หัวข้ออบรม', 'icon': PhosphorIconsRegular.graduationCap};
      case 'trainingDate': return {'label': 'วันที่อบรม', 'icon': PhosphorIconsRegular.calendarBlank};
      case 'trainer': return {'label': 'วิทยากร/หน่วยงาน', 'icon': PhosphorIconsRegular.usersThree};
      case 'location': return {'label': 'สถานที่', 'icon': PhosphorIconsRegular.mapPin};
      case 'durationHours': return {'label': 'จำนวนชั่วโมง', 'icon': PhosphorIconsRegular.clock};
      case 'attendees': return {'label': 'จำนวนผู้เข้าอบรม', 'icon': PhosphorIconsRegular.users};
      case 'hygieneNotes': return {'label': 'บันทึกสุขลักษณะ', 'icon': PhosphorIconsRegular.clipboardText};
      case 'result': return {'label': 'ผลการประเมิน', 'icon': PhosphorIconsRegular.sealCheck};
      case 'attachment': return {'label': 'เอกสารแนบ', 'icon': PhosphorIconsRegular.paperclip};

      // Default fallback
      default: return {'label': key, 'icon': PhosphorIconsRegular.info};
    }
  }

  Future<void> _showTraceabilityManagementDialog() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TraceabilityManagementSheet(
        plotId: widget.plotId,
        gapService: _gapService,
        adminService: _adminService,
      ),
    );
  }

  void _showFeedbackDialog(String key, String title) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ส่ง Feedback: $title',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ระบุสิ่งที่เกษตรกรต้องแก้ไข:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'เช่น รูปภาพไม่ชัดเจน, เอกสารหมดอายุ...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final message = controller.text.trim();
              if (message.isEmpty) return;

              Navigator.pop(context); // Close dialog first

              try {
                await _adminService.submitGapFeedback(
                  plotId: widget.plotId,
                  categoryKey: key,
                  message: message,
                );

                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'ส่ง Feedback เรียบร้อย',
                      style: const TextStyle(),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceAll('Exception: ', ''),
                      style: const TextStyle(),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'ส่ง',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePreview() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             CircularProgressIndicator(color: Colors.white),
             SizedBox(height: 16),
             Text('กำลังเตรียมตัวอย่าง...', style: TextStyle(color: Colors.white))
          ],
        ),
      ),
    );

    try {
      final plotDetails = await _adminService.getPlotDetail(widget.plotId);
      final pdfService = PdfGeneratorService();
      
      final pdfData = await pdfService.generateGapReport(
        plot: plotDetails,
        owner: widget.owner?.toJson(),
        summaryData: _summaryData,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      await Printing.layoutPdf(
        onLayout: (_) => pdfData,
        name: 'GAP-Report-Preview',
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Widget _buildExportButton() {
    return Column(
      children: [
        // Approve/Reject Buttons
        if (_generalData != null && _generalData!['status'] == 'PENDING') ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleApprovePlot(),
                  icon: const Icon(
                    PhosphorIconsRegular.checkCircle,
                    size: 20,
                    color: Colors.white),
                  label: Text(
                    'อนุมัติแปลง',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleRejectPlot(),
                  icon: const Icon(
                    PhosphorIconsRegular.xCircle,
                    size: 20,
                    color: Colors.white),
                  label: Text(
                    'ปฏิเสธ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        // Export & Preview Buttons
        Row(
           children: [
             Expanded(
               child: OutlinedButton.icon(
                 onPressed: _completedCount > 0 ? _handlePreview : null,
                 icon: const Icon(PhosphorIconsRegular.eye, size: 20),
                 label: Text(
                   'ตัวอย่าง',
                   style: TextStyle(fontWeight: FontWeight.bold),
                 ),
                 style: OutlinedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(14),
                   ),
                   side: BorderSide(color: AppColors.primary),
                   foregroundColor: AppColors.primary,
                 ),
               ),
             ),
             const SizedBox(width: 12),
             Expanded(
               flex: 2,
               child: ElevatedButton.icon(
                 onPressed: _completedCount > 0 ? _handleExport : null,
                 icon: const Icon(
                   PhosphorIconsRegular.fileArrowDown,
                   size: 20,
                   color: Colors.white),
                 label: Text(
                   'ส่งรายงานผู้เชี่ยวชาญ',
                   style: TextStyle(
                     fontWeight: FontWeight.w600,
                     color: Colors.white,
                   ),
                 ),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   disabledBackgroundColor: Colors.grey.shade300,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(14),
                   ),
                 ),
               ),
             ),
           ],
        ),
      ],
    );
  }

  Future<void> _handleApprovePlot() async {
    final confirmed = await PlotConfirmationDialog.showApproval(
      context,
      plotName: widget.plotName,
      ownerName: widget.owner?.fullName ?? 'ไม่ทราบชื่อ',
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _adminService.approvePlot(
        widget.plotId,
        ownerId: widget.owner?.id,
        plotName: widget.plotName,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อนุมัติแปลงสำเร็จ', style: const TextStyle()),
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh data
      _loadSummary();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleRejectPlot() async {
    final reason = await PlotConfirmationDialog.showRejection(
      context,
      plotName: widget.plotName,
      ownerName: widget.owner?.fullName ?? 'ไม่ทราบชื่อ',
    );

    if (reason == null || reason.isEmpty) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _adminService.rejectPlot(
        widget.plotId,
        reason,
        ownerId: widget.owner?.id,
        plotName: widget.plotName,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ปฏิเสธแปลงสำเร็จ', style: const TextStyle()),
          backgroundColor: AppColors.warning,
        ),
      );

      // Refresh data
      _loadSummary();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleExport() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             CircularProgressIndicator(color: Colors.white),
             SizedBox(height: 16),
             Text('กำลังสร้างไฟล์รายงาน...', style: TextStyle(color: Colors.white))
          ],
        ),
      ),
    );

    try {
      // 1. Prepare Data
      final plotDetails = await _adminService.getPlotDetail(widget.plotId);
      final pdfService = PdfGeneratorService();
      
      // 2. Generate PDF
      final pdfData = await pdfService.generateGapReport(
        plot: plotDetails,
        owner: widget.owner?.toJson(), // Use existing if available
        summaryData: _summaryData,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // 3. Share PDF
      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'GAP-Report-${widget.plotName.replaceAll(' ', '_')}.pdf',
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สร้างไฟล์ไม่สำเร็จ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
