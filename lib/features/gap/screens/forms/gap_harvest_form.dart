// ============================================
// GAP HARVEST FORM (แก้ไขแล้ว)
// ============================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/error_utils.dart';
import '../../widgets/gap_form_wrapper.dart';

class GapHarvestForm extends StatefulWidget {
  final String plotId;
  final String? existingId;
  final Map<String, dynamic>? existingData;

  const GapHarvestForm({
    super.key,
    required this.plotId,
    this.existingId,
    this.existingData,
  });

  @override
  State<GapHarvestForm> createState() => _GapHarvestFormState();
}

class _GapHarvestFormState extends State<GapHarvestForm> {
  final _gapService = GapService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool get _isEditMode => widget.existingId != null;

  // GAP-FIX-002: Track unsaved changes and original data
  bool _hasUnsavedChanges = false;
  String _originalDataHash = '';

  DateTime? _harvestDate;

  final _harvestedByController = TextEditingController();
  final _yieldAmountController = TextEditingController();
  final _yieldUnitController = TextEditingController();
  final _equipmentUsedController = TextEditingController();
  final _qualityGradeController = TextEditingController();
  final _notesController = TextEditingController();
  final _lotNumberController = TextEditingController();

  final List<String> _equipmentOptions = [
    'กรรไกรตัดกิ่ง',
    'มีด',
    'เก็บด้วยมือ',
    'ตะกร้าเก็บใบ',
    'เครื่องตัด',
  ];
  final List<String> _gradeOptions = [
    'เกรด A (สมบูรณ์ 100%)',
    'เกรด B (มีตำหนิเล็กน้อย)',
    'เกรดรวม (คละไซส์)',
    'เกรดโรงงาน (สำหรับสกัด)',
  ];
  final List<String> _unitOptions = ['กิโลกรัม', 'ตัน', 'ขีด'];

  @override
  void initState() {
    super.initState();
    _loadData();
    if (_lotNumberController.text.isEmpty) {
      _generateLotNumber();
    }

    // GAP-FIX-002: Add listeners to track changes
    _harvestedByController.addListener(_onFieldChanged);
    _yieldAmountController.addListener(_onFieldChanged);
    _yieldUnitController.addListener(_onFieldChanged);
    _equipmentUsedController.addListener(_onFieldChanged);
    _qualityGradeController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
    _lotNumberController.addListener(_onFieldChanged);
  }

  // GAP-FIX-002: Track when fields change
  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  // GAP-FIX-002: Mark as saved (no unsaved changes)
  void _markAsSaved() {
    setState(() => _hasUnsavedChanges = false);
  }

  // GAP-FIX-002: Check if data has actually changed from original
  String _computeDataHash() {
    final data = _buildFormData();
    return '${data['harvestedBy']}|${data['yieldAmount']}|${data['yieldUnit']}|${data['equipmentUsed']}|${data['qualityGrade']}|${data['notes']}|${_harvestDate?.toIso8601String()}';
  }

  void _generateLotNumber() {
    final date = DateTime.now();
    final dateStr =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final random = date.microsecond.toString().padLeft(4, '0').substring(0, 4);
    _lotNumberController.text = 'L$dateStr-$random';
  }

  @override
  void dispose() {
    _harvestedByController.removeListener(_onFieldChanged);
    _yieldAmountController.removeListener(_onFieldChanged);
    _yieldUnitController.removeListener(_onFieldChanged);
    _equipmentUsedController.removeListener(_onFieldChanged);
    _qualityGradeController.removeListener(_onFieldChanged);
    _notesController.removeListener(_onFieldChanged);
    _lotNumberController.removeListener(_onFieldChanged);

    _harvestedByController.dispose();
    _yieldAmountController.dispose();
    _yieldUnitController.dispose();
    _equipmentUsedController.dispose();
    _qualityGradeController.dispose();
    _notesController.dispose();
    _lotNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (widget.existingData != null) {
        final data = widget.existingData!;
        if (mounted) {
          setState(() {
            _harvestedByController.text = data['harvestedBy']?.toString() ?? '';
            _yieldAmountController.text = data['yieldAmount']?.toString() ?? '';
            _yieldUnitController.text =
                data['yieldUnit']?.toString() ?? 'กิโลกรัม';
            _equipmentUsedController.text =
                data['equipmentUsed']?.toString() ?? '';
            _qualityGradeController.text =
                data['qualityGrade']?.toString() ?? '';
            _notesController.text = data['notes']?.toString() ?? '';
            _lotNumberController.text = data['lotNumber']?.toString() ?? '';
            if (data['harvestDate'] != null) {
              _harvestDate = DateTime.tryParse(data['harvestDate'].toString());
            }

            // GAP-FIX: Map short grade to full dropdown option
            final shortGrade = data['qualityGrade']?.toString();
            if (shortGrade != null) {
              final fullGrade = _gradeOptions.firstWhere(
                (option) => option.startsWith('เกรด $shortGrade'),
                orElse: () => shortGrade,
              );
              _qualityGradeController.text = fullGrade;
            } else {
               _qualityGradeController.text = '';
            }
          });
          // GAP-FIX-002: Store original data hash after loading
          _originalDataHash = _computeDataHash();
          _hasUnsavedChanges = false;
        }
      } else {
        final draft = await DatabaseHelper.instance.getDraft(
          'harvest_${widget.plotId}',
        );
        if (mounted && draft != null) {
          final data = jsonDecode(draft.jsonData);
          setState(() {
            _harvestedByController.text = data['harvestedBy']?.toString() ?? '';
            _equipmentUsedController.text =
                data['equipmentUsed']?.toString() ?? '';
            if (data['harvestDate'] != null) {
              _harvestDate = DateTime.tryParse(data['harvestDate'].toString());
            }
          });
        }
      }
    } catch (e) {
      // Silent failure - will use defaults
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _buildFormData() {
    final data = <String, dynamic>{
      'harvestDate':
          _harvestDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'harvestedBy': _harvestedByController.text.trim().isNotEmpty
          ? _harvestedByController.text.trim()
          : 'ไม่ระบุ',
      'yieldAmount': double.tryParse(_yieldAmountController.text) ?? 0.0,
      'yieldUnit': _yieldUnitController.text.trim().isNotEmpty
          ? _yieldUnitController.text.trim()
          : 'กก.',
    };

    if (_equipmentUsedController.text.trim().isNotEmpty) {
      data['equipmentUsed'] = _equipmentUsedController.text.trim();
    }
    if (_qualityGradeController.text.trim().isNotEmpty) {
      final gradeText = _qualityGradeController.text.trim();
      // GAP-FIX: Extract grade letter only (A, B, etc.) for API consistency
      final gradeMatch = RegExp(r'เกรด\s([A-Z])').firstMatch(gradeText);
      data['qualityGrade'] = gradeMatch != null ? gradeMatch.group(1) : gradeText;
    }
    if (_notesController.text.trim().isNotEmpty) {
      data['notes'] = _notesController.text.trim();
    }

    return data;
  }

  Future<void> _saveDraft() async {
    final messenger = ScaffoldMessenger.of(context);
    final json = jsonEncode(_buildFormData());
    await DatabaseHelper.instance.saveDraft('harvest_${widget.plotId}', json);
    
    if (!mounted) return;
    
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(PhosphorIconsRegular.cloudCheck, color: Colors.white),
            const SizedBox(width: 8),
            Text('บันทึกร่างเรียบร้อย', style: const TextStyle()),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<String> _getIncompleteFields() {
    final incomplete = <String>[];
    if (_harvestedByController.text.trim().isEmpty)
      incomplete.add('ผู้เก็บเกี่ยว');
    if (_equipmentUsedController.text.trim().isEmpty)
      incomplete.add('อุปกรณ์ที่ใช้');
    if (_qualityGradeController.text.trim().isEmpty)
      incomplete.add('เกรดคุณภาพ');
    if (_notesController.text.trim().isEmpty) incomplete.add('หมายเหตุ');
    return incomplete;
  }

  Future<void> _saveToApi() async {
    if (_isSaving) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (_harvestDate == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาเลือกวันที่เก็บเกี่ยว',
            style: const TextStyle(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_harvestDate!.isAfter(DateTime.now())) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'วันที่เก็บเกี่ยวไม่สามารถเป็นวันในอนาคต',
            style: const TextStyle(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_yieldAmountController.text.trim().isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('กรุณาระบุปริมาณผลผลิต', style: const TextStyle()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final yieldAmount = double.tryParse(_yieldAmountController.text);
    if (yieldAmount == null || yieldAmount <= 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'ปริมาณผลผลิตต้องเป็นจำนวนบวก',
            style: const TextStyle(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final incompleteFields = _getIncompleteFields();
    if (incompleteFields.isNotEmpty) {
      if (!mounted) return;
      
      final shouldProceed = await showIncompleteFieldsDialog(
        context,
        formTitle: 'การเก็บเกี่ยว',
        incompleteFields: incompleteFields,
      );
      if (!shouldProceed) return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    // GAP-FIX: Store navigator before async operations to avoid
    // using context after widget is disposed (_dependents.isEmpty assertion)
    final navigator = Navigator.of(context);

    try {
      if (_isEditMode) {
        await _gapService.updateHarvest(
          widget.plotId,
          widget.existingId!,
          _buildFormData(),
        );
        await _gapService.notifyAdminOnEdit(
          plotId: widget.plotId,
          formType: 'การเก็บเกี่ยว',
          recordId: widget.existingId!,
        );
      } else {
        await _gapService.addHarvest(widget.plotId, _buildFormData());
      }
      await DatabaseHelper.instance.deleteDraft('harvest_${widget.plotId}');

      // GAP-FIX-002: Mark as saved after successful save
      _markAsSaved();
      _originalDataHash = _computeDataHash();

      if (!mounted) return;

      // Reset saving state BEFORE showing dialog/popping
      setState(() => _isSaving = false);

      await showGapSuccessDialog(
        context,
        formTitle: 'การเก็บเกี่ยว',
        formSubtitle: _isEditMode ? 'แก้ไขสำเร็จ' : 'บันทึกสำเร็จ',
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
              style: const TextStyle(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'),
    );
    if (picked != null) {
      if (!mounted) return;
      
      setState(() {
        _harvestDate = picked;
        _hasUnsavedChanges = true;
      });
    }
  }

  String _formatDate(DateTime? date) => DateFormatter.formatThaiDate(date);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return GapFormWrapper(
      title: '4. การเก็บเกี่ยว',
      subtitle: 'บันทึกผลผลิตและการจัดการ',
      headerIcon: PhosphorIconsRegular.archive,
      headerColor: Colors.orange,
      onSave: _saveToApi,
      onSaveDraft: _saveDraft,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges, // GAP-FIX-002: Pass unsaved changes state
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FormInfoCard(
              message:
                  'บันทึกข้อมูลการเก็บเกี่ยวใบกระท่อม เพื่อการตรวจสอบย้อนกลับ (Traceability)',
              icon: PhosphorIconsRegular.lightbulb,
              color: Colors.orange,
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.tag, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Lot Number: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _lotNumberController.text,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            FormSectionCard(
              title: 'วันที่เก็บเกี่ยว *',
              example: 'ตัวอย่าง: 15 มกราคม 2569',
              icon: PhosphorIconsRegular.calendarDots,
              iconColor: Colors.purple,
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        PhosphorIconsRegular.calendarDots,
                        color: Colors.grey,
                        size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(_harvestDate),
                        style: TextStyle(
                          color: _harvestDate != null
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        PhosphorIconsRegular.caretRight,
                        color: Colors.grey,
                        size: 16),
                    ],
                  ),
                ),
              ),
            ),

            FormSectionCard(
              title: 'ผู้เก็บเกี่ยว *',
              example: 'ตัวอย่าง: คนงานชุดที่ 1, นายแดง',
              icon: PhosphorIconsRegular.users,
              iconColor: Colors.blue,
              child: TextField(
                controller: _harvestedByController,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'ระบุชื่อผู้เก็บเกี่ยว หรือกลุ่มคนงาน',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                ),
                style: const TextStyle(),
              ),
            ),

            FormSectionCard(
              title: 'ปริมาณผลผลิต *',
              example: 'ระบุจำนวนที่ได้',
              icon: PhosphorIconsRegular.scales,
              iconColor: Colors.green,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _yieldAmountController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        counterText: '',
                      ),
                      style: const TextStyle(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: FormDropdownWithOther(
                      label: 'หน่วย',
                      hint: 'หน่วย',
                      options: _unitOptions,
                      value: _yieldUnitController.text,
                      onChanged: (val) {
                        if (mounted) {
                          setState(() {
                            _yieldUnitController.text = val;
                            _hasUnsavedChanges = true;
                          });
                        }
                      },
                      icon: PhosphorIconsRegular.cube,
                    ),
                  ),
                ],
              ),
            ),

            FormSectionCard(
              title: 'อุปกรณ์เก็บเกี่ยว',
              example: 'เลือกอุปกรณ์ที่ใช้',
              icon: PhosphorIconsRegular.wrench,
              iconColor: Colors.grey,
              child: FormDropdownWithOther(
                label: 'อุปกรณ์',
                hint: 'เลือกอุปกรณ์เก็บเกี่ยว',
                options: _equipmentOptions,
                value: _equipmentUsedController.text,
                onChanged: (val) {
                  if (mounted) {
                    setState(() {
                      _equipmentUsedController.text = val;
                      _hasUnsavedChanges = true;
                    });
                  }
                },
                icon: PhosphorIconsRegular.scissors,
              ),
            ),

            FormSectionCard(
              title: 'คุณภาพ/เกรด',
              example: 'ระบุเกรดของใบกระท่อม',
              icon: PhosphorIconsRegular.star,
              iconColor: Colors.amber,
              child: FormDropdownWithOther(
                label: 'เกรด',
                hint: 'เลือกเกรดผลผลิต',
                options: _gradeOptions,
                value: _qualityGradeController.text,
                onChanged: (val) {
                  if (mounted) {
                    setState(() {
                      _qualityGradeController.text = val;
                      _hasUnsavedChanges = true;
                    });
                  }
                },
                icon: PhosphorIconsRegular.tag,
              ),
            ),

            FormSectionCard(
              title: 'หมายเหตุ',
              example: 'ตัวอย่าง: ใบใหญ่หนา สีเขียวเข้ม',
              icon: PhosphorIconsRegular.chatText,
              iconColor: Colors.grey,
              child: TextField(
                controller: _notesController,
                maxLines: 2,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'บันทึกเพิ่มเติม (ถ้ามี)',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                ),
                style: const TextStyle(),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
