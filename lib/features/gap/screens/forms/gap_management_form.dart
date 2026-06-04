import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/gap_enum_helpers.dart';
import '../../widgets/gap_form_wrapper.dart';

/// หมวด 3: การจัดการแปลง - ตรงกับ Backend FieldManagement model
class GapManagementForm extends StatefulWidget {
  final String plotId;
  final String? existingId;
  final Map<String, dynamic>? existingData;

  const GapManagementForm({
    super.key,
    required this.plotId,
    this.existingId,
    this.existingData,
  });

  @override
  State<GapManagementForm> createState() => _GapManagementFormState();
}

class _GapManagementFormState extends State<GapManagementForm> {
  final _gapService = GapService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool get _isEditMode => widget.existingId != null;

  // Backend FieldManagement fields
  String _activityType =
      'SOIL_PREP'; // Enum: SOIL_PREP, WATER_QUALITY, WEED_CONTROL, IPM_PEST_CONTROL, RISK_EVENT
  DateTime? _activityDate;

  final _descriptionController = TextEditingController();
  final _waterQualityController = TextEditingController();
  final _riskTypeController = TextEditingController();
  final _riskLevelController = TextEditingController();
  final _riskImpactController = TextEditingController();
  final _mitigationController = TextEditingController();
  final _chemicalUsedController = TextEditingController();
  final _machineUsedController = TextEditingController();
  final _workerNameController = TextEditingController();

  // Dropdown Options
  final List<String> _machineOptions = [
    'รถไถเดินตาม',
    'เครื่องตัดหญ้า',
    'จอบ/เสียม',
    'กรรไกรตัดกิ่ง',
    'ระบบน้ำหยด',
    'เครื่องพ่นหมอก',
  ];
  final List<String> _chemicalOptions = [
    'น้ำหมักชีวภาพ',
    'เชื้อราไตรโคเดอร์มา',
    'เชื้อบิวเวอเรีย',
    'สารสะเดา',
    'ปุ๋ยคอก',
    'ปุ๋ยหมัก',
  ];
  final List<String> _waterQualityOptions = [
    'ใส ไม่มีกลิ่น',
    'ขุ่นเล็กน้อย',
    'มีตะกอน',
    'ค่า pH 5.5-6.5 (เหมาะสม)',
    'ค่า pH < 5 (เป็นกรด)',
  ];
  final List<String> _riskTypeOptions = [
    'น้ำท่วมขัง',
    'ฝนทิ้งช่วง/ภัยแล้ง',
    'โรคใบจุด',
    'หนอนกินใบ',
    'เพลี้ยไฟ/ไรแดง',
    'พายุลมแรง',
  ];
  final List<String> _riskImpactOptions = [
    'ใบเหลืองร่วง',
    'ต้นแคระแกร็น',
    'รากเน่า',
    'ผลผลิตลดลง',
    'กิ่งหักเสียหาย',
  ];
  final List<String> _mitigationOptions = [
    'ขุดร่องระบายน้ำ',
    'ให้น้ำสม่ำเสมอ',
    'ตัดแต่งกิ่งที่เป็นโรค',
    'ฉีดพ่นเชื้อราไตรโคเดอร์มา',
    'ทำไม้ค้ำยัน',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Listen for changes
    _descriptionController.addListener(_onFieldChanged);
    _waterQualityController.addListener(_onFieldChanged);
    _riskTypeController.addListener(_onFieldChanged);
    _riskLevelController.addListener(_onFieldChanged);
    _riskImpactController.addListener(_onFieldChanged);
    _mitigationController.addListener(_onFieldChanged);
    _chemicalUsedController.addListener(_onFieldChanged);
    _machineUsedController.addListener(_onFieldChanged);
    _workerNameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _waterQualityController.dispose();
    _riskTypeController.dispose();
    _riskLevelController.dispose();
    _riskImpactController.dispose();
    _mitigationController.dispose();
    _chemicalUsedController.dispose();
    _machineUsedController.dispose();
    _workerNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // If we have existing data (edit mode), use it
      if (widget.existingData != null) {
        final data = widget.existingData!;
        setState(() {
          _activityType = data['activityType']?.toString() ?? 'SOIL_PREP';
          _descriptionController.text = data['description']?.toString() ?? '';
          _waterQualityController.text = data['waterQuality']?.toString() ?? '';
          _riskTypeController.text = data['riskType']?.toString() ?? '';
          _riskTypeController.text = data['riskType']?.toString() ?? '';
          
          // GAP-FIX: Map API value to Display Text
          final riskApi = data['riskLevel']?.toString();
          _riskLevelController.text = RiskLevel.fromApi(riskApi) ?? riskApi ?? '';

          _riskImpactController.text = data['riskImpact']?.toString() ?? '';
          _riskImpactController.text = data['riskImpact']?.toString() ?? '';
          _mitigationController.text = data['mitigation']?.toString() ?? '';
          _chemicalUsedController.text = data['chemicalUsed']?.toString() ?? '';
          _machineUsedController.text = data['machineUsed']?.toString() ?? '';
          _workerNameController.text = data['workerName']?.toString() ?? '';
          if (data['activityDate'] != null) {
            _activityDate = DateTime.tryParse(data['activityDate'].toString());
          }
          _hasUnsavedChanges = false; // Reset after load
        });
      } else {
        // New form - try to load draft
        final draft = await DatabaseHelper.instance.getDraft(
          'management_${widget.plotId}',
        );
        if (draft != null) {
          final data = jsonDecode(draft.jsonData);
          setState(() {
            _activityType = data['activityType']?.toString() ?? 'SOIL_PREP';
            _descriptionController.text = data['description']?.toString() ?? '';
            _waterQualityController.text =
                data['waterQuality']?.toString() ?? '';
            _riskTypeController.text = data['riskType']?.toString() ?? '';
            _riskLevelController.text = data['riskLevel']?.toString() ?? '';
            _riskImpactController.text = data['riskImpact']?.toString() ?? '';
            _mitigationController.text = data['mitigation']?.toString() ?? '';
            _chemicalUsedController.text =
                data['chemicalUsed']?.toString() ?? '';
            _machineUsedController.text = data['machineUsed']?.toString() ?? '';
            _workerNameController.text = data['workerName']?.toString() ?? '';
            if (data['activityDate'] != null) {
              _activityDate = DateTime.tryParse(
                data['activityDate'].toString(),
              );
            }
            _hasUnsavedChanges = false; // Reset after load
          });
        }
      }
    } catch (e) {
      // Silent failure - draft loading is not critical
    }

    setState(() => _isLoading = false);
  }

  /// Build data matching Backend FieldManagement schema
  Map<String, dynamic> _buildFormData() {
    // GAP-FIX: Use Enum Helper
    final mappedRiskLevel = RiskLevel.toApi(_riskLevelController.text.trim());

    final data = <String, dynamic>{
      'activityType': _activityType, // Required Enum
      'activityDate':
          _activityDate?.toIso8601String() ??
          DateTime.now().toIso8601String(), // Required
    };

    // Trim all text inputs
    final description = _descriptionController.text.trim();
    final waterQuality = _waterQualityController.text.trim();
    final riskType = _riskTypeController.text.trim();
    final riskImpact = _riskImpactController.text.trim();
    final mitigation = _mitigationController.text.trim();
    final chemicalUsed = _chemicalUsedController.text.trim();
    final machineUsed = _machineUsedController.text.trim();
    final workerName = _workerNameController.text.trim();

    // Only add optional fields if they have values
    if (description.isNotEmpty) {
      // Combine description with water quality and risk type info since those fields aren't allowed
      String fullDescription = description;
      if (waterQuality.isNotEmpty) {
        fullDescription += '\n[คุณภาพน้ำ: $waterQuality]';
      }
      if (riskType.isNotEmpty) {
        fullDescription += '\n[ประเภทความเสี่ยง: $riskType]';
      }
      data['description'] = fullDescription;
    }

    if (mappedRiskLevel != null) data['riskLevel'] = mappedRiskLevel;
    if (riskImpact.isNotEmpty) data['riskImpact'] = riskImpact;
    if (mitigation.isNotEmpty) data['mitigation'] = mitigation;
    if (chemicalUsed.isNotEmpty) data['chemicalUsed'] = chemicalUsed;
    if (machineUsed.isNotEmpty) data['machineUsed'] = machineUsed;
    if (workerName.isNotEmpty) data['workerName'] = workerName;

    return data;
  }

  Future<void> _saveDraft() async {
    final messenger = ScaffoldMessenger.of(context);
    final json = jsonEncode(_buildFormData());
    await DatabaseHelper.instance.saveDraft(
      'management_${widget.plotId}',
      json,
    );
    
    if (!mounted) return;
    
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_done, color: Colors.white),
            const SizedBox(width: 8),
            Text('บันทึกร่างเรียบร้อย', style: GoogleFonts.prompt()),
          ],
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Get list of incomplete (empty) optional fields for soft warning
  List<String> _getIncompleteFields() {
    final incomplete = <String>[];

    // Always shown fields
    if (_descriptionController.text.trim().isEmpty)
      incomplete.add('รายละเอียดกิจกรรม');
    if (_workerNameController.text.trim().isEmpty)
      incomplete.add('ผู้ปฏิบัติงาน');
    if (_machineUsedController.text.trim().isEmpty)
      incomplete.add('เครื่องจักร/อุปกรณ์');

    // Conditional fields - only check if they are shown in UI
    if (_activityType == 'WATER_QUALITY' &&
        _waterQualityController.text.trim().isEmpty) {
      incomplete.add('คุณภาพน้ำ');
    }
    if ((_activityType == 'IPM_PEST_CONTROL' ||
            _activityType == 'WEED_CONTROL') &&
        _chemicalUsedController.text.trim().isEmpty) {
      incomplete.add('สารเคมี/ชีวภัณฑ์');
    }
    if (_activityType == 'RISK_EVENT') {
      if (_riskTypeController.text.trim().isEmpty)
        incomplete.add('ประเภทความเสี่ยง');
      if (_riskLevelController.text.trim().isEmpty)
        incomplete.add('ระดับความเสี่ยง');
      if (_riskImpactController.text.trim().isEmpty) incomplete.add('ผลกระทบ');
      if (_mitigationController.text.trim().isEmpty)
        incomplete.add('การแก้ไข/บรรเทา');
    }

    return incomplete;
  }

  Future<void> _saveToApi() async {
    // GAP-BUG-001: Prevent double submission
    if (_isSaving) return;

    // GAP-BUG-003: Store messenger reference before async operations
    final messenger = ScaffoldMessenger.of(context);

    // Validate activity date
    if (_activityDate == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาเลือกวันที่ทำกิจกรรม',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate activity date is not in the future
    if (_activityDate!.isAfter(DateTime.now())) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'วันที่ทำกิจกรรมไม่สามารถเป็นวันในอนาคต',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate minimum text length for description (at least 5 characters)
    if (_descriptionController.text.trim().isEmpty ||
        _descriptionController.text.trim().length < 5) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'รายละเอียดกิจกรรมต้องมีอย่างน้อย 5 ตัวอักษร',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate conditional required fields based on activity type
    if (_activityType == 'WATER_QUALITY' &&
        _waterQualityController.text.trim().isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาระบุผลตรวจคุณภาพน้ำ',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_activityType == 'RISK_EVENT') {
      if (_riskTypeController.text.trim().isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'กรุณาระบุประเภทความเสี่ยง',
              style: GoogleFonts.prompt(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_riskLevelController.text.trim().isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'กรุณาระบุระดับความเสี่ยง',
              style: GoogleFonts.prompt(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_riskImpactController.text.trim().isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('กรุณาระบุผลกระทบ', style: GoogleFonts.prompt()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_mitigationController.text.trim().isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'กรุณาระบุวิธีการแก้ไข/บรรเทา',
              style: GoogleFonts.prompt(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // GAP-BUG-004: Show incomplete fields warning BEFORE saving
    final incompleteFields = _getIncompleteFields();
    if (incompleteFields.isNotEmpty) {
      final shouldProceed = await showIncompleteFieldsDialog(
        context,
        formTitle: 'การจัดการแปลง',
        incompleteFields: incompleteFields,
      );
      if (!shouldProceed) return;
    }

    setState(() => _isSaving = true);

    // GAP-FIX: Store navigator before async operations to avoid
    // using context after widget is disposed (_dependents.isEmpty assertion)
    final navigator = Navigator.of(context);

    try {
      // Use PUT for edit, POST for new
      if (_isEditMode) {
        await _gapService.updateActivity(
          widget.plotId,
          widget.existingId!,
          _buildFormData(),
        );
        await _gapService.notifyAdminOnEdit(
          plotId: widget.plotId,
          formType: 'การจัดการแปลง',
          recordId: widget.existingId!,
        );
      } else {
        await _gapService.addActivity(widget.plotId, _buildFormData());
      }
      await DatabaseHelper.instance.deleteDraft('management_${widget.plotId}');

      if (!mounted) return;

      // Reset saving state BEFORE showing dialog/popping
      setState(() {
        _isSaving = false;
        _hasUnsavedChanges = false;
      });

      await showGapSuccessDialog(
        context,
        formTitle: 'การจัดการแปลง',
        formSubtitle: _isEditMode ? 'แก้ไขสำเร็จ' : 'หมวด 3 บันทึกสำเร็จ',
      );

      // Use stored navigator to avoid context usage after dispose
      navigator.pop(true);
      return; // Exit immediately — widget will be disposed after pop
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              ErrorUtils.getReadableError(e),
              style: GoogleFonts.prompt(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _activityDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Prevent future date selection
      locale: const Locale('th', 'TH'),
    );
    if (picked != null) {
      setState(() {
        _activityDate = picked;
        _hasUnsavedChanges = true;
      });
    }
  }

  String _formatDate(DateTime? date) => DateFormatter.formatThaiDate(date);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return GapFormWrapper(
      title: '3. การจัดการแปลง',
      subtitle: 'กิจกรรมดูแลแปลงกระท่อม',
      headerIcon: HeroIcons.wrenchScrewdriver,
      headerColor: Colors.teal,
      onSave: _saveToApi,
      onSaveDraft: _saveDraft,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FormInfoCard(
            message:
                'บันทึกกิจกรรมการดูแลแปลงกระท่อม เช่น เตรียมดิน กำจัดวัชพืช ตรวจคุณภาพน้ำ',
            icon: HeroIcons.lightBulb,
            color: Colors.teal,
          ),

          // ประเภทกิจกรรม (Required Enum)
          FormSectionCard(
            title: 'ประเภทกิจกรรม *',
            example: 'เลือกประเภทกิจกรรมที่ทำ',
            icon: HeroIcons.clipboardDocumentList,
            iconColor: Colors.indigo,
            child: Column(
              children: [
                _buildActivityOption(
                  'SOIL_PREP',
                  'เตรียมดิน',
                  'ไถพรวน ปรับหน้าดิน ใส่ปุ๋ยรองพื้น',
                  HeroIcons.buildingOffice,
                  Colors.brown,
                ),
                const SizedBox(height: 8),
                _buildActivityOption(
                  'WATER_QUALITY',
                  'ตรวจคุณภาพน้ำ',
                  'วัดค่า pH, EC, ความสะอาด',
                  HeroIcons.beaker,
                  Colors.cyan,
                ),
                const SizedBox(height: 8),
                _buildActivityOption(
                  'WEED_CONTROL',
                  'กำจัดวัชพืช',
                  'ถอน/ตัดหญ้ารอบต้นกระท่อม',
                  HeroIcons.sparkles,
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildActivityOption(
                  'IPM_PEST_CONTROL',
                  'จัดการศัตรูพืช IPM',
                  'ตรวจโรค แมลง การป้องกัน',
                  HeroIcons.shieldCheck,
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildActivityOption(
                  'RISK_EVENT',
                  'เหตุการณ์ความเสี่ยง',
                  'น้ำท่วม, ภัยแล้ง, โรคระบาด',
                  HeroIcons.exclamationTriangle,
                  Colors.red,
                ),
              ],
            ),
          ),

          // วันที่ทำกิจกรรม (Required)
          FormSectionCard(
            title: 'วันที่ทำกิจกรรม *',
            example: 'ตัวอย่าง: 10 มกราคม 2569',
            icon: HeroIcons.calendarDays,
            iconColor: Colors.purple,
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const HeroIcon(
                      HeroIcons.calendarDays,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatDate(_activityDate),
                      style: GoogleFonts.prompt(
                        color: _activityDate != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    const HeroIcon(
                      HeroIcons.chevronRight,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // รายละเอียดกิจกรรม
          FormSectionCard(
            title: 'รายละเอียดกิจกรรม *',
            example:
                'ตัวอย่าง: ไถพรวนดินด้วยรถไถเดินตาม ใส่ปุ๋ยหมักจากใบกระท่อมเก่า',
            icon: HeroIcons.documentText,
            iconColor: Colors.blue,
            child: TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'อธิบายรายละเอียดกิจกรรมที่ทำ (อย่างน้อย 5 ตัวอักษร)',
                hintStyle: GoogleFonts.prompt(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.prompt(),
            ),
          ),

          // ผู้ปฏิบัติงาน
          FormSectionCard(
            title: 'ผู้ปฏิบัติงาน',
            example: 'ตัวอย่าง: นายแดง อุดมทรัพย์',
            icon: HeroIcons.user,
            iconColor: Colors.grey,
            child: TextField(
              controller: _workerNameController,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: 'กรอกชื่อผู้ปฏิบัติงาน',
                hintStyle: GoogleFonts.prompt(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.prompt(),
            ),
          ),

          // เครื่องจักร/อุปกรณ์
          FormSectionCard(
            title: 'เครื่องจักร/อุปกรณ์ที่ใช้',
            example: 'เลือกหรือระบุเครื่องจักรที่ใช้',
            icon: HeroIcons.cog6Tooth,
            iconColor: Colors.orange,
            child: FormDropdownWithOther(
              label: 'เครื่องจักร/อุปกรณ์',
              hint: 'เลือกเครื่องจักร/อุปกรณ์',
              options: _machineOptions,
              value: _machineUsedController.text,
              onChanged: (val) =>
                  setState(() => _machineUsedController.text = val),
              icon: HeroIcons.truck,
            ),
          ),

          // สารเคมี (ถ้ามี)
          if (_activityType == 'IPM_PEST_CONTROL' ||
              _activityType == 'WEED_CONTROL')
            FormSectionCard(
              title: 'สารเคมี/ชีวภัณฑ์ที่ใช้ (ถ้ามี)',
              example: 'เลือกหรือระบุสารที่ใช้',
              icon: HeroIcons.beaker,
              iconColor: Colors.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const HeroIcon(
                          HeroIcons.exclamationTriangle,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'สำหรับกระท่อม ควรใช้ชีวภัณฑ์/สมุนไพรแทนสารเคมี',
                            style: GoogleFonts.prompt(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FormDropdownWithOther(
                    label: 'สารเคมี/ชีวภัณฑ์',
                    hint: 'เลือกสารที่ใช้',
                    options: _chemicalOptions,
                    value: _chemicalUsedController.text,
                    onChanged: (val) =>
                        setState(() => _chemicalUsedController.text = val),
                    icon: HeroIcons.beaker,
                  ),
                ],
              ),
            ),

          // คุณภาพน้ำ (ถ้าเลือก WATER_QUALITY)
          if (_activityType == 'WATER_QUALITY')
            FormSectionCard(
              title: 'ผลตรวจคุณภาพน้ำ *',
              example: 'เลือกผลการตรวจ',
              icon: HeroIcons.beaker,
              iconColor: Colors.cyan,
              child: FormDropdownWithOther(
                label: 'คุณภาพน้ำ',
                hint: 'เลือกผลตรวจคุณภาพน้ำ',
                options: _waterQualityOptions,
                value: _waterQualityController.text,
                onChanged: (val) =>
                    setState(() => _waterQualityController.text = val),
                icon: HeroIcons.eyeDropper,
              ),
            ),

          // ความเสี่ยง (ถ้าเลือก RISK_EVENT)
          if (_activityType == 'RISK_EVENT') ...[
            FormSectionCard(
              title: 'ประเภทความเสี่ยง *',
              example: 'เลือกเหตุการณ์ความเสี่ยง',
              icon: HeroIcons.exclamationTriangle,
              iconColor: Colors.red,
              child: FormDropdownWithOther(
                label: 'ความเสี่ยง',
                hint: 'เลือกประเภทความเสี่ยง',
                options: _riskTypeOptions,
                value: _riskTypeController.text,
                onChanged: (val) =>
                    setState(() => _riskTypeController.text = val),
                icon: HeroIcons.bugAnt,
              ),
            ),
            FormSectionCard(
              title: 'ระดับความเสี่ยง *',
              example: 'เลือกระดับความรุนแรง',
              icon: HeroIcons.signalSlash,
              iconColor: Colors.amber,
              child: FormDropdownWithOther(
                label: 'ระดับความเสี่ยง',
                hint: 'เลือกระดับความเสี่ยง',
                options: const ['ต่ำ (Low)', 'กลาง (Medium)', 'สูง (High)'],
                value: _riskLevelController.text,
                onChanged: (val) =>
                    setState(() => _riskLevelController.text = val),
                icon: HeroIcons.chartBar,
              ),
            ),
            FormSectionCard(
              title: 'ผลกระทบ *',
              example: 'ระบุผลกระทบที่เกิดขึ้น',
              icon: HeroIcons.fire,
              iconColor: Colors.orange,
              child: FormDropdownWithOther(
                label: 'ผลกระทบ',
                hint: 'เลือกผลกระทบ',
                options: _riskImpactOptions,
                value: _riskImpactController.text,
                onChanged: (val) =>
                    setState(() => _riskImpactController.text = val),
                icon: HeroIcons.chartBar,
              ),
            ),
            FormSectionCard(
              title: 'การแก้ไข/บรรเทา *',
              example: 'ระบุวิธีแก้ไข',
              icon: HeroIcons.wrench,
              iconColor: Colors.green,
              child: FormDropdownWithOther(
                label: 'การแก้ไข',
                hint: 'เลือกวิธีการแก้ไข',
                options: _mitigationOptions,
                value: _mitigationController.text,
                onChanged: (val) =>
                    setState(() => _mitigationController.text = val),
                icon: HeroIcons.lifebuoy,
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActivityOption(
    String value,
    String title,
    String subtitle,
    HeroIcons icon,
    Color color,
  ) {
    final isSelected = _activityType == value;
    return GestureDetector(
      onTap: () => setState(() => _activityType = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: HeroIcon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.prompt(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
