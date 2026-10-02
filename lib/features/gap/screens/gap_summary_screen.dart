import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/gap_service.dart';
import '../../../core/utils/gap_summary_builder.dart';
import '../../../core/widgets/nature_background.dart';
import 'forms/gap_general_form.dart';
import 'forms/gap_inputs_form.dart';
import 'forms/gap_management_form.dart';
import 'forms/gap_harvest_form.dart';
import 'forms/gap_post_harvest_form.dart';
import 'forms/gap_safety_form.dart';
import 'forms/gap_traceability_form.dart';

/// GAP Summary/History Screen - แสดงประวัติและสรุปการบันทึก GAP ต่อแปลง
class GapSummaryScreen extends StatefulWidget {
  final String plotId;
  final String plotName;

  const GapSummaryScreen({
    super.key,
    required this.plotId,
    required this.plotName,
  });

  @override
  State<GapSummaryScreen> createState() => _GapSummaryScreenState();
}

class _GapSummaryScreenState extends State<GapSummaryScreen> {
  final _gapService = GapService();
  bool _isLoading = true;
  Map<String, dynamic> _summaryData = {};

  // Store raw data for edit mode
  Map<String, Map<String, dynamic>?> _rawData = {};

  final List<Map<String, dynamic>> _categories = [
    {
      'key': 'general',
      'title': '1. ข้อมูลทั่วไป',
      'icon': PhosphorIconsRegular.info,
      'color': AppColors.gapGeneral,
    },
    {
      'key': 'inputs',
      'title': '2. ปัจจัยการผลิต',
      'icon': PhosphorIconsRegular.flask,
      'color': AppColors.gapInputs,
    },
    {
      'key': 'management',
      'title': '3. การจัดการแปลง',
      'icon': PhosphorIconsRegular.wrench,
      'color': AppColors.gapManagement,
    },
    {
      'key': 'harvest',
      'title': '4. การเก็บเกี่ยว',
      'icon': PhosphorIconsRegular.archive,
      'color': AppColors.gapHarvest,
    },
    {
      'key': 'postHarvest',
      'title': '5. หลังเก็บเกี่ยว',
      'icon': PhosphorIconsRegular.cube,
      'color': AppColors.gapPostHarvest,
    },
    {
      'key': 'safety',
      'title': '6. ความปลอดภัย',
      'icon': PhosphorIconsRegular.shieldCheck,
      'color': AppColors.gapSafety,
    },
    {
      'key': 'traceability',
      'title': '7. ตรวจติดตาม',
      'icon': PhosphorIconsRegular.magnifyingGlass,
      'color': AppColors.gapTraceability,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);

    try {
      final gapRecord = await _gapService.getGapData(widget.plotId);
      final inputs = await _gapService.getInputs(widget.plotId);
      final managements = await _gapService.getFieldManagements(widget.plotId);
      final harvests = await _gapService.getHarvests(widget.plotId);
      final postHarvests = await _gapService.getPostHarvestsForPlot(
        widget.plotId,
      );
      final trainings = await _gapService.getTrainings(widget.plotId);

      if (mounted) {
        setState(() {
          // Store raw data for edit mode
          _rawData = {
            'general': gapRecord,
            'inputs': inputs.isNotEmpty
                ? inputs.first as Map<String, dynamic>
                : null,
            'management': managements.isNotEmpty
                ? managements.first as Map<String, dynamic>
                : null,
            'harvest': harvests.isNotEmpty
                ? harvests.first as Map<String, dynamic>
                : null,
            'postHarvest': postHarvests.isNotEmpty
                ? postHarvests.first as Map<String, dynamic>
                : null,
            'training': trainings.isNotEmpty
                ? trainings.first as Map<String, dynamic>
                : null,
          };

          // Build summary data
          _summaryData = {
            'general': gapRecord != null
                ? {
                    'completed': true,
                    'summary': GapSummaryBuilder.buildGeneral(gapRecord),
                  }
                : null,
            'inputs': inputs.isNotEmpty
                ? {
                    'completed': true,
                    'summary': GapSummaryBuilder.buildInputs(inputs),
                  }
                : null,
            'management': managements.isNotEmpty
                ? {
                    'completed': true,
                    'summary': GapSummaryBuilder.buildManagement(
                        managements.first as Map<String, dynamic>),
                  }
                : null,
            'harvest': harvests.isNotEmpty
                ? {
                    'completed': true,
                    'summary': GapSummaryBuilder.buildHarvest(
                        harvests.first as Map<String, dynamic>),
                  }
                : null,
            'postHarvest': postHarvests.isNotEmpty
                ? {
                    'completed': true,
                    'summary': GapSummaryBuilder.buildPostHarvest(postHarvests),
                  }
                : null,
            'safety': trainings.isNotEmpty
                ? {
                    'completed': true,
                    'summary': GapSummaryBuilder.buildSafety(
                        trainings.first as Map<String, dynamic>),
                  }
                : null,
            'traceability': harvests.isNotEmpty
                ? {
                    'completed': true,
                    'summary': GapSummaryBuilder.buildTraceability(harvests),
                  }
                : null,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เกิดข้อผิดพลาดในการโหลดข้อมูล',
            style: const TextStyle(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Removed _buildGeneralSummary, _buildManagementSummary, etc. replaced by GapSummaryBuilder

  int get _completedCount => _summaryData.values.where((v) => v != null).length;

  Future<void> _navigateToForm(String key) async {
    if (!mounted) return;

    Widget? form;

    try {
      switch (key) {
        case 'general':
          form = GapGeneralForm(plotId: widget.plotId);
          break;

        case 'inputs':
          final inputsData = _rawData['inputs'];
          form = GapInputsForm(
            plotId: widget.plotId,
            existingId: inputsData?['id']?.toString(),
            existingData: inputsData,
          );
          break;

        case 'management':
          final managementData = _rawData['management'];
          form = GapManagementForm(
            plotId: widget.plotId,
            existingId: managementData?['id']?.toString(),
            existingData: managementData,
          );
          break;

        case 'harvest':
          final harvestData = _rawData['harvest'];
          form = GapHarvestForm(
            plotId: widget.plotId,
            existingId: harvestData?['id']?.toString(),
            existingData: harvestData,
          );
          break;

        case 'postHarvest':
          // Show loading while fetching harvests
          if (!mounted) return;

          final messenger = ScaffoldMessenger.of(context);

          // PostHarvest requires harvestId
          final harvests = await _gapService.getHarvests(widget.plotId);

          if (harvests.isEmpty) {
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'กรุณาบันทึกการเก็บเกี่ยวก่อน',
                    style: const TextStyle(),
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }

          final postHarvestData = _rawData['postHarvest'];
          form = GapPostHarvestForm(
            plotId: widget.plotId,
            harvestId: harvests.first['id']?.toString(),
            existingId: postHarvestData?['id']?.toString(),
            existingData: postHarvestData,
          );
          break;

        case 'safety':
          final trainingData = _rawData['training'];
          form = GapSafetyForm(
            plotId: widget.plotId,
            existingId: trainingData?['id']?.toString(),
            existingData: trainingData,
          );
          break;

        case 'traceability':
          form = GapTraceabilityForm(plotId: widget.plotId);
          break;
      }

      if (form != null) {
        if (!mounted) return;
        
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => form!),
        );

        if (result == true) {
          if (!mounted) return;
          _loadSummary(); // Reload summary after form saved
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เกิดข้อผิดพลาดในการเปิดฟอร์ม',
            style: const TextStyle(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ยืนยันการล้างข้อมูล?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คุณต้องการลบข้อมูล GAP ทั้งหมด (หมวด 1.1-1.6)\nของแปลงนี้ใช่หรือไม่?',
              style: const TextStyle(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    PhosphorIconsRegular.warning,
                    color: Colors.orange,
                    size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'การกระทำนี้ไม่สามารถย้อนกลับได้',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
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
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: const TextStyle()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'ลบข้อมูล',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _gapService.resetGapData(widget.plotId);
      
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      _loadSummary(); // Reload to show empty state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ล้างข้อมูลสำเร็จ',
            style: const TextStyle(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
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

  Future<void> _deleteCategory(String key, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ลบข้อมูล $title?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'ข้อมูลทั้งหมดในหมวดนี้จะถูกลบ\nคุณต้องการดำเนินการต่อหรือไม่?',
          style: const TextStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: const TextStyle()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'ลบข้อมูล',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Logic to delete all items in category
      switch (key) {
        case 'general':
          await _gapService.deleteGeneralInfo(widget.plotId);
          break;
        case 'inputs':
          final inputs = await _gapService.getInputs(widget.plotId);
          for (var item in inputs) {
            await _gapService.deleteInput(widget.plotId, item['id'].toString());
          }
          break;
        case 'management':
          final items = await _gapService.getFieldManagements(widget.plotId);
          for (var item in items) {
            await _gapService.deleteActivity(widget.plotId, item['id'].toString());
          }
          break;
        case 'harvest':
          final items = await _gapService.getHarvests(widget.plotId);
          for (var item in items) {
            await _gapService.deleteHarvest(widget.plotId, item['id'].toString());
          }
          break;
        case 'postHarvest':
           final harvests = await _gapService.getHarvests(widget.plotId);
           for (var h in harvests) {
             final harvestId = h['id'].toString();
             final items = await _gapService.getPostHarvest(harvestId);
             for (var item in items) {
               await _gapService.deletePostHarvest(harvestId, item['id'].toString());
             }
           }
          break;
        case 'safety':
          final items = await _gapService.getTrainings(widget.plotId);
          for (var item in items) {
            await _gapService.deleteTraining(widget.plotId, item['id'].toString());
          }
          break;
        case 'traceability':
          // Traceability usually derived from harvest, but if separate:
           // await _gapService.deleteTraceability... (Not implemented yet, skip)
          break;
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _loadSummary(); // Reload
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบข้อมูลเรียบร้อย', style: const TextStyle()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เกิดข้อผิดพลาดในการลบข้อมูล',
            style: const TextStyle(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NatureBackground.header(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      PhosphorIconsRegular.arrowLeft,
                      color: Colors.white),
                    onPressed: () {
                      if (mounted) Navigator.of(context).pop();
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ประวัติการบันทึก GAP',
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_completedCount/7',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Reset Button (Modified Style)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextButton.icon(
                  onPressed: _confirmReset,
                  icon: const Icon(
                    PhosphorIconsRegular.trash,
                    color: Colors.white,
                    size: 20),
                  label: Text(
                    'ล้างข้อมูล GAP ทั้งหมด',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F), // Darker Red
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),


            // Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSummary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) =>
                              _buildCategoryCard(_categories[index]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final key = category['key'] as String;
    final data = _summaryData[key];
    final isCompleted = data != null;
    final color = category['color'] as Color;

    return GestureDetector(
      onTap: () => _navigateToForm(key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isCompleted ? color.withValues(alpha: 0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isCompleted ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category['icon'] as IconData,
                  color: isCompleted ? color : Colors.grey,
                  size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            category['title'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? Colors.black87 : Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '✓ บันทึกแล้ว',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted
                          ? (data['summary'] ?? 'มีข้อมูล')
                          : 'ยังไม่ได้บันทึก',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted
                            ? Colors.grey.shade700
                            : Colors.grey.shade400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isCompleted) // Show delete button if completed
                InkWell(
                  onTap: () => _deleteCategory(key, category['title']),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                       PhosphorIconsRegular.trash,
                       color: Colors.red,
                       size: 20),
                  ),
                )
              else
                Icon(
                  PhosphorIconsRegular.circle,
                  color: Colors.grey.shade300,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
