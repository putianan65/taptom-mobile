import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../data/models/gap_draft_model.dart';
import '../../../../core/widgets/nature_background.dart';
import 'forms/gap_general_form.dart';
import 'forms/gap_inputs_form.dart';
import 'forms/gap_harvest_form.dart';
import 'forms/gap_management_form.dart';
import 'forms/gap_post_harvest_form.dart';
import 'forms/gap_safety_form.dart';
import 'forms/gap_traceability_form.dart';
import 'gap_summary_screen.dart';
import 'plot_gallery_screen.dart';

class GapMainScreen extends StatefulWidget {
  final String plotId;
  final String? plotName;
  final bool isReadOnly;

  const GapMainScreen({
    super.key,
    required this.plotId,
    this.plotName,
    this.isReadOnly = false,
  });

  @override
  State<GapMainScreen> createState() => _GapMainScreenState();
}

class _GapMainScreenState extends State<GapMainScreen> {
  final GapService _gapService = GapService();
  List<GapDraftModel> _drafts = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Form completion status
  Map<String, bool> _formCompleted = {
    'general': false,
    'inputs': false,
    'management': false,
    'harvest': false,
    'postHarvest': false,
    'safety': false,
    'traceability': false,
  };

  // Existing data for edit mode
  Map<String, Map<String, dynamic>?> _existingData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load Drafts
      final drafts = await DatabaseHelper.instance.getAllDrafts();

      // ── Staggered API calls to avoid backend ThrottlerException (429) ──
      final managements = await _gapService.getFieldManagements(widget.plotId);
      final harvests = await _gapService.getHarvests(widget.plotId);
      await Future.delayed(const Duration(milliseconds: 200));
      final postHarvests = await _gapService.getPostHarvestsForPlot(
        widget.plotId,
      );
      await Future.delayed(const Duration(milliseconds: 200));
      final trainings = await _gapService.getTrainings(widget.plotId);
      final inputs = await _gapService.getInputs(widget.plotId);

      // Get GAP Record for General Info update status
      Map<String, dynamic>? gapRecord;
      try {
        gapRecord = await _gapService.getGapData(widget.plotId);
      } catch (e) {
        // Silent failure - GAP data will be null
      }

      if (mounted) {
        setState(() {
          _drafts = drafts;
          // Store existing data for edit mode
          _existingData = {
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
          // Set form completion status based on API data
          _formCompleted = {
            'general': gapRecord != null,
            'inputs': inputs.isNotEmpty,
            'management': managements.isNotEmpty,
            'harvest': harvests.isNotEmpty,
            'postHarvest': postHarvests.isNotEmpty,
            'safety': trainings.isNotEmpty,
            'traceability':
                harvests.isNotEmpty, // Uses harvest data for traceability
          };
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadData();
  }

  Future<void> _navigateToForm(Widget form) async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => form),
    );

    if (result == true) {
      if (!mounted) return;
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NatureBackground.header(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // AppBar-like Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const HeroIcon(
                          HeroIcons.arrowLeft,
                          color: Colors.white,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        widget.isReadOnly ? 'ดูข้อมูล GAP' : 'บันทึก GAP',
                        style: GoogleFonts.prompt(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            const Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Hide camera & summary buttons in read-only mode ──
                          if (!widget.isReadOnly) ...[
                            IconButton(
                              icon: const HeroIcon(
                                HeroIcons.camera,
                                color: Colors.white,
                              ),
                              tooltip: 'รูปภาพแปลง',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlotGalleryScreen(
                                      plotId: widget.plotId,
                                      plotName: widget.plotName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const HeroIcon(
                                HeroIcons.documentText,
                                color: Colors.white,
                              ),
                              tooltip: 'ดูประวัติ',
                              onPressed: () async {
                                if (!mounted) return;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GapSummaryScreen(
                                      plotId: widget.plotId,
                                      plotName:
                                          widget.plotName ??
                                          'แปลงที่ ${widget.plotId}',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Plot Selector (Now Glassmorphic on Header)
                  _buildPlotSelector(),
                ],
              ),
            ),

            // 2. Sliding Body
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ✅ Read-only banner when APPROVED
                      if (widget.isReadOnly)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock_outline, color: Colors.amber.shade700, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'แปลงนี้ผ่านการรับรองแล้ว — ดูข้อมูลได้อย่างเดียว',
                                  style: GoogleFonts.prompt(
                                    fontSize: 13,
                                    color: Colors.amber.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        'หัวข้อการบันทึก',
                        style: GoogleFonts.prompt(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryGrid(context),
                      const SizedBox(height: 24),
                      // ✅ Hide drafts in read-only mode
                      if (!widget.isReadOnly) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'รายการแบบร่าง (Drafts)',
                              style: GoogleFonts.prompt(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            if (_drafts.isNotEmpty)
                              TextButton(
                                onPressed: _isRefreshing ? null : _refreshData,
                                child: _isRefreshing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'รีเฟรช',
                                        style: GoogleFonts.prompt(
                                          color: AppColors.primary,
                                        ),
                                      ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDraftsList(),
                      ],
                      const SizedBox(height: 80), // Bottom spacer
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_drafts.isEmpty) {
      return Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const HeroIcon(
                HeroIcons.document,
                size: 48,
                color: Color(0xFFCBD5E1),
              ),
              const SizedBox(height: 16),
              Text(
                'ไม่มีรายการแบบร่าง',
                style: GoogleFonts.prompt(color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _drafts
          .map(
            (draft) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const HeroIcon(
                    HeroIcons.pencilSquare,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  _getCategoryName(draft.category),
                  style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'แก้ไขล่าสุด: ${draft.lastUpdated}',
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                trailing: IconButton(
                  icon: const HeroIcon(
                    HeroIcons.trash,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('ลบแบบร่าง?', style: GoogleFonts.prompt()),
                        content: Text(
                          'คุณต้องการลบแบบร่างนี้หรือไม่?',
                          style: GoogleFonts.prompt(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('ยกเลิก', style: GoogleFonts.prompt()),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'ลบ',
                              style: GoogleFonts.prompt(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete == true) {
                      await DatabaseHelper.instance.deleteDraft(draft.category);
                      if (mounted) _loadData();
                    }
                  },
                ),
                onTap: () async {
                  // Navigate to appropriate form based on draft category
                  Widget? formWidget;

                  if (draft.category.startsWith('general')) {
                    formWidget = GapGeneralForm(plotId: widget.plotId);
                  } else if (draft.category.startsWith('inputs')) {
                    final inputsData = _existingData['inputs'];
                    formWidget = GapInputsForm(
                      plotId: widget.plotId,
                      existingId: inputsData?['id']?.toString(),
                      existingData: inputsData,
                    );
                  } else if (draft.category.startsWith('management')) {
                    final managementData = _existingData['management'];
                    formWidget = GapManagementForm(
                      plotId: widget.plotId,
                      existingId: managementData?['id']?.toString(),
                      existingData: managementData,
                    );
                  } else if (draft.category.startsWith('harvest')) {
                    final harvestData = _existingData['harvest'];
                    formWidget = GapHarvestForm(
                      plotId: widget.plotId,
                      existingId: harvestData?['id']?.toString(),
                      existingData: harvestData,
                    );
                  } else if (draft.category.startsWith('post_harvest')) {
                    final postHarvestData = _existingData['postHarvest'];
                    formWidget = GapPostHarvestForm(
                      plotId: widget.plotId,
                      existingId: postHarvestData?['id']?.toString(),
                      existingData: postHarvestData,
                    );
                  } else if (draft.category.startsWith('safety')) {
                    final trainingData = _existingData['training'];
                    formWidget = GapSafetyForm(
                      plotId: widget.plotId,
                      existingId: trainingData?['id']?.toString(),
                      existingData: trainingData,
                    );
                  }

                  if (formWidget != null) {
                    if (!mounted) return;
                    await _navigateToForm(formWidget);
                  }
                },
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPlotSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const HeroIcon(
              HeroIcons.mapPin,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'แปลงปัจจุบัน',
                  style: GoogleFonts.prompt(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  widget.plotName ?? "ไม่ระบุชื่อแปลง",
                  style: GoogleFonts.prompt(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const HeroIcon(HeroIcons.chevronDown, color: Colors.white),
        ],
      ),
    );
  }

  void _showReadOnlyHint() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'แปลงที่รับรองแล้วไม่สามารถแก้ไขได้ ดูได้อย่างเดียว',
                style: GoogleFonts.prompt(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.amber.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final children = <Widget>[
      // 1. General Form
      GestureDetector(
        onTap: () async {
          if (widget.isReadOnly) return _showReadOnlyHint();
          await _navigateToForm(GapGeneralForm(plotId: widget.plotId));
        },
        child: _buildCardContent(
          '1. ข้อมูลทั่วไป',
          HeroIcons.informationCircle,
          AppColors.gapGeneral,
          isCompleted: _formCompleted['general'] ?? false,
          isLocked: widget.isReadOnly,
        ),
      ),

      // 2. Inputs Form
      GestureDetector(
        onTap: () async {
          if (widget.isReadOnly) return _showReadOnlyHint();
          final inputsData = _existingData['inputs'];
          await _navigateToForm(
            GapInputsForm(
              plotId: widget.plotId,
              existingId: inputsData?['id']?.toString(),
              existingData: inputsData,
            ),
          );
        },
        child: _buildCardContent(
          '2. ปัจจัยการผลิต',
          HeroIcons.beaker,
          AppColors.gapInputs,
          isCompleted: _formCompleted['inputs'] ?? false,
          isLocked: widget.isReadOnly,
        ),
      ),

      // 3. Management Form
      GestureDetector(
        onTap: () async {
          if (widget.isReadOnly) return _showReadOnlyHint();
          final managementData = _existingData['management'];
          await _navigateToForm(
            GapManagementForm(
              plotId: widget.plotId,
              existingId: managementData?['id']?.toString(),
              existingData: managementData,
            ),
          );
        },
        child: _buildCardContent(
          '3. การจัดการแปลง',
          HeroIcons.wrenchScrewdriver,
          AppColors.gapManagement,
          isCompleted: _formCompleted['management'] ?? false,
          isLocked: widget.isReadOnly,
        ),
      ),

      // 4. Harvest Form
      GestureDetector(
        onTap: () async {
          if (widget.isReadOnly) return _showReadOnlyHint();
          final harvestData = _existingData['harvest'];
          await _navigateToForm(
            GapHarvestForm(
              plotId: widget.plotId,
              existingId: harvestData?['id']?.toString(),
              existingData: harvestData,
            ),
          );
        },
        child: _buildCardContent(
          '4. การเก็บเกี่ยว',
          HeroIcons.archiveBox,
          AppColors.gapHarvest,
          isCompleted: _formCompleted['harvest'] ?? false,
          isLocked: widget.isReadOnly,
        ),
      ),

      // 5. Post Harvest Form
      GestureDetector(
        onTap: () async {
          if (widget.isReadOnly) return _showReadOnlyHint();
          final postHarvestData = _existingData['postHarvest'];
          await _navigateToForm(
            GapPostHarvestForm(
              plotId: widget.plotId,
              existingId: postHarvestData?['id']?.toString(),
              existingData: postHarvestData,
            ),
          );
        },
        child: _buildCardContent(
          '5. หลังเก็บเกี่ยว',
          HeroIcons.cube,
          AppColors.gapPostHarvest,
          isCompleted: _formCompleted['postHarvest'] ?? false,
          isLocked: widget.isReadOnly,
        ),
      ),

      // 6. Safety Form
      GestureDetector(
        onTap: () async {
          if (widget.isReadOnly) return _showReadOnlyHint();
          final trainingData = _existingData['training'];
          await _navigateToForm(
            GapSafetyForm(
              plotId: widget.plotId,
              existingId: trainingData?['id']?.toString(),
              existingData: trainingData,
            ),
          );
        },
        child: _buildCardContent(
          '6. ความปลอดภัย',
          HeroIcons.shieldCheck,
          AppColors.gapSafety,
          isCompleted: _formCompleted['safety'] ?? false,
          isLocked: widget.isReadOnly,
        ),
      ),
    ];

    // หมวด 7 (Traceability/QR) — ซ่อนเมื่อ readOnly (ย้ายไปหน้าใบรับรอง)
    if (!widget.isReadOnly) {
      children.add(
        GestureDetector(
          onTap: () async {
            await _navigateToForm(GapTraceabilityForm(plotId: widget.plotId));
          },
          child: _buildCardContent(
            '7. ตรวจติดตาม',
            HeroIcons.magnifyingGlass,
            AppColors.gapTraceability,
            isCompleted: _formCompleted['traceability'] ?? false,
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: children,
    );
  }

  Widget _buildCardContent(
    String title,
    HeroIcons icon,
    Color color, {
    bool isCompleted = false,
    bool isLocked = false,
  }) {
    final effectiveColor = isLocked ? color.withOpacity(0.4) : color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFFF1F1F1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withOpacity(isLocked ? 0.05 : 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          effectiveColor.withOpacity(0.05),
                          effectiveColor.withOpacity(isLocked ? 0.08 : 0.2),
                        ],
                      ),
                      boxShadow: isLocked ? [] : [
                        BoxShadow(
                          color: color.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                        const BoxShadow(
                          color: Colors.white,
                          blurRadius: 2,
                          offset: Offset(-1, -1),
                        ),
                      ],
                    ),
                    child: HeroIcon(icon, color: effectiveColor, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      title,
                      style: GoogleFonts.prompt(
                        color: isLocked
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF2D3748),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Lock icon overlay for read-only mode
            if (isLocked)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            // Completion check badge
            if (isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const HeroIcon(
                    HeroIcons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(String category) {
    if (category.startsWith('general')) return 'ข้อมูลทั่วไป';
    if (category.startsWith('inputs')) return 'ปัจจัยการผลิต';
    if (category.startsWith('management')) return 'การจัดการแปลง';
    if (category.startsWith('harvest')) return 'การเก็บเกี่ยว';
    if (category.startsWith('post_harvest')) return 'หลังเก็บเกี่ยว';
    if (category.startsWith('safety')) return 'ความปลอดภัย';
    if (category.startsWith('traceability')) return 'ตรวจติดตาม';
    return category;
  }
}
