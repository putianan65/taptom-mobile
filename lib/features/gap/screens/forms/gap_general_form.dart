import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../widgets/gap_form_wrapper.dart';

class GapGeneralForm extends StatefulWidget {
  final String plotId;

  const GapGeneralForm({super.key, required this.plotId});

  @override
  State<GapGeneralForm> createState() => _GapGeneralFormState();
}

class _GapGeneralFormState extends State<GapGeneralForm> {
  final _gapService = GapService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  String _cropType = 'KRATOM';
  String _farmingSystem = 'NON_ORGANIC';
  DateTime? _startDate;

  final _farmerNameController = TextEditingController();
  final _seasonController = TextEditingController();
  final _cropVarietyController = TextEditingController();
  final _irrigationSystemController = TextEditingController();
  final _waterSourceController = TextEditingController();
  final _waterQualityNoteController = TextEditingController();

  // Auto-save timer
  Timer? _autoSaveTimer;
  DateTime? _lastAutoSave;
  static const Duration _autoSaveInterval = Duration(seconds: 30);

  final List<String> _irrigationOptions = [
    'รดน้ำด้วยมือ',
    'ระบบมินิสปริงเกอร์',
    'ระบบน้ำหยด',
    'สูบน้ำราด',
    'น้ำฝนตามธรรมชาติ',
  ];
  final List<String> _waterSourceOptions = [
    'บ่อบาดาล',
    'สระเก็บน้ำ',
    'คลองชลประทาน',
    'แม่น้ำ/ลำธาร',
    'น้ำประปา',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupAutoSave();
  }

  /// Setup auto-save timer that saves draft every 30 seconds
  void _setupAutoSave() {
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) {
      if (_hasUnsavedChanges) {
        if (!mounted) return;
        _autoSaveDraft();
      }
    });

    // Listen to text changes
    _farmerNameController.addListener(_onFieldChanged);
    _seasonController.addListener(_onFieldChanged);
    _cropVarietyController.addListener(_onFieldChanged);
    _waterQualityNoteController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _autoSaveDraft() async {
    if (_lastAutoSave != null &&
        DateTime.now().difference(_lastAutoSave!) < _autoSaveInterval) {
      return;
    }
    
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final json = jsonEncode(_buildFormData());
      await DatabaseHelper.instance.saveDraft(
        'general_${widget.plotId}',
        json,
      );
      _lastAutoSave = DateTime.now();
      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        // Show subtle auto-save indicator
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(PhosphorIconsRegular.cloudArrowUp, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('บันทึกร่างอัตโนมัติ', style: TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    } catch (e) {
      // Silent fail for auto-save
      debugPrint('Auto-save failed: $e');
    }
  }

  @override
  void dispose() {
    // Cancel auto-save timer
    _autoSaveTimer?.cancel();
    
    // Remove listeners
    _farmerNameController.removeListener(_onFieldChanged);
    _seasonController.removeListener(_onFieldChanged);
    _cropVarietyController.removeListener(_onFieldChanged);
    _waterQualityNoteController.removeListener(_onFieldChanged);
    
    _farmerNameController.dispose();
    _seasonController.dispose();
    _cropVarietyController.dispose();
    _irrigationSystemController.dispose();
    _waterSourceController.dispose();
    _waterQualityNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _gapService.getGapData(widget.plotId);
      if (mounted && data != null) {
        setState(() {
          _farmerNameController.text = data['farmerName']?.toString() ?? '';
          _seasonController.text = data['seasonLabel']?.toString() ?? '';
          _cropVarietyController.text = data['cropVariety']?.toString() ?? '';
          _irrigationSystemController.text =
              data['irrigationSystem']?.toString() ?? '';
          _waterSourceController.text = data['waterSource']?.toString() ?? '';
          _waterQualityNoteController.text =
              data['waterQualityNote']?.toString() ?? '';
          _cropType = data['cropType']?.toString() ?? 'KRATOM';
          _farmingSystem = data['farmingSystem']?.toString() ?? 'NON_ORGANIC';
          if (data['startDate'] != null) {
            _startDate = DateTime.tryParse(data['startDate'].toString());
          }
        });
      }
    } catch (e) {
      try {
        final draft = await DatabaseHelper.instance.getDraft(
          'general_${widget.plotId}',
        );
        if (mounted && draft != null) {
          final data = jsonDecode(draft.jsonData);
          setState(() {
            _farmerNameController.text = data['farmerName']?.toString() ?? '';
            _seasonController.text = data['seasonLabel']?.toString() ?? '';
            _cropType = data['cropType']?.toString() ?? 'KRATOM';
            _farmingSystem = data['farmingSystem']?.toString() ?? 'NON_ORGANIC';
            if (data['startDate'] != null) {
              _startDate = DateTime.tryParse(data['startDate'].toString());
            }
          });
        }
      } catch (e) {
        // Silent failure - will use defaults
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        // GAP-FIX: Reset dirty flag after initial data load
        _hasUnsavedChanges = false;
      });
    }
  }

  Map<String, dynamic> _buildFormData() {
    return {
      'farmerName': _farmerNameController.text.trim(),
      'seasonLabel': _seasonController.text.trim(),
      'cropType': _cropType,
      'cropVariety': _cropVarietyController.text.trim(),
      'irrigationSystem': _irrigationSystemController.text.trim(),
      'waterSource': _waterSourceController.text.trim(),
      'waterQualityNote': _waterQualityNoteController.text.trim(),
      'farmingSystem': _farmingSystem,
      'startDate':
          _startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  Future<void> _saveDraft() async {
    final messenger = ScaffoldMessenger.of(context);
    final json = jsonEncode(_buildFormData());
    await DatabaseHelper.instance.saveDraft('general_${widget.plotId}', json);
    
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
    // GAP-FIX: Reset dirty flag after saving draft
    setState(() => _hasUnsavedChanges = false);
  }

  String? _validateForm() {
    final farmerName = _farmerNameController.text.trim();
    
    if (farmerName.isEmpty) {
      return 'กรุณากรอกชื่อเกษตรกร';
    }
    
    if (farmerName.length < 3) {
      return 'ชื่อเกษตรกรต้องมีอย่างน้อย 3 ตัวอักษร';
    }
    
    // Validate Thai characters or common name patterns
    final nameRegExp = RegExp(r'^[\u0E00-\u0E7Fa-zA-Z\s\.]+$');
    if (!nameRegExp.hasMatch(farmerName)) {
      return 'ชื่อเกษตรกรต้องเป็นตัวอักษรเท่านั้น';
    }

    if (_startDate == null) {
      return 'กรุณาเลือกวันเริ่มการเพาะปลูก';
    }

    if (_startDate!.isAfter(DateTime.now())) {
      return 'วันเริ่มการเพาะปลูกไม่สามารถเป็นวันในอนาคต';
    }
    
    // Check if start date is too old (more than 5 years)
    final fiveYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 5));
    if (_startDate!.isBefore(fiveYearsAgo)) {
      return 'วันเริ่มการเพาะปลูกไม่สามารถเก่ากว่า 5 ปี';
    }
    
    // Validate water source if provided
    final waterSource = _waterSourceController.text.trim();
    if (waterSource.isNotEmpty && waterSource.length < 2) {
      return 'กรุณาระบุแหล่งน้ำให้ถูกต้อง';
    }
    
    // Validate irrigation system if provided
    final irrigation = _irrigationSystemController.text.trim();
    if (irrigation.isNotEmpty && irrigation.length < 2) {
      return 'กรุณาระบุระบบการให้น้ำให้ถูกต้อง';
    }

    return null; // Validation passed
  }

  Future<void> _saveToApi() async {
    if (_isSaving) return;

    final messenger = ScaffoldMessenger.of(context);
    
    // Run validation
    final validationError = _validateForm();
    if (validationError != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(validationError, style: const TextStyle()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // GAP-FIX: Store navigator before async operations to avoid
    // using context after widget is disposed (_dependents.isEmpty assertion)
    final navigator = Navigator.of(context);

    try {
      await _gapService.saveGeneralInfo(widget.plotId, _buildFormData());
      await DatabaseHelper.instance.deleteDraft('general_${widget.plotId}');

      if (!mounted) return;

      // Reset saving state BEFORE showing dialog/popping
      setState(() {
        _isSaving = false;
        _hasUnsavedChanges = false;
      });

      await showGapSuccessDialog(
        context,
        formTitle: 'ข้อมูลทั่วไป',
        formSubtitle: 'บันทึกสำเร็จ',
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasUnsavedChanges = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'),
    );
    if (picked != null) {
      if (!mounted) return;
      
      setState(() {
        _startDate = picked;
        _hasUnsavedChanges = true;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'เลือกวันที่';
    final thaiMonths = [
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
    return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
  }

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
      title: '1. ข้อมูลทั่วไป',
      subtitle: 'ข้อมูลพื้นฐานของแปลงและเกษตรกร',
      headerIcon: PhosphorIconsRegular.info,
      headerColor: AppColors.primary,
      onSave: _saveToApi,
      onSaveDraft: _saveDraft,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges, // GAP-FIX: Pass real state
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FormInfoCard(
              message:
                  'กรอกข้อมูลพื้นฐานเพื่อใช้ในการขอใบรับรอง GAP พืชอาหารและสมุนไพร',
              icon: PhosphorIconsRegular.lightbulb,
              color: Colors.amber,
            ),

            FormSectionCard(
              title: 'ชื่อเกษตรกร *',
              example: 'ตัวอย่าง: นายสมชาย ใจดี',
              icon: PhosphorIconsRegular.user,
              iconColor: Colors.blue,
              child: TextField(
                controller: _farmerNameController,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'กรอกชื่อ-นามสกุล',
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
              title: 'วันเริ่มการเพาะปลูก *',
              example: 'ตัวอย่าง: 1 มกราคม 2569',
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
                        _formatDate(_startDate),
                        style: TextStyle(
                          color: _startDate != null
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
              title: 'ฤดูกาล / รุ่นการผลิต',
              example: 'ตัวอย่าง: 1/2569, ฤดูฝน',
              icon: PhosphorIconsRegular.clock,
              iconColor: Colors.orange,
              child: TextField(
                controller: _seasonController,
                maxLength: 50,
                decoration: InputDecoration(
                  hintText: 'กรอกรุ่นการผลิต',
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
              title: 'สายพันธุ์ที่ปลูก',
              example: 'ตัวอย่าง: ก้านแดง, หางกระรอก',
              icon: PhosphorIconsRegular.tag,
              iconColor: Colors.green,
              child: TextField(
                controller: _cropVarietyController,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'ระบุสายพันธุ์',
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
              title: 'ระบบการผลิต',
              example: 'เลือกรูปแบบการผลิตของคุณ',
              icon: PhosphorIconsRegular.gear,
              iconColor: Colors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSystemOption(
                    'NON_ORGANIC',
                    'เกษตรเคมี (ทั่วไป)',
                    'ใช้ปุ๋ยเคมีได้ตามมาตรฐาน',
                    Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildSystemOption(
                    'ORGANIC',
                    'เกษตรอินทรีย์',
                    'ไม่ใช้สารเคมีสังเคราะห์',
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildSystemOption(
                    'TRANSITION',
                    'ระยะปรับเปลี่ยน',
                    'กำลังปรับเข้าสู่อินทรีย์',
                    Colors.orange,
                  ),
                ],
              ),
            ),

            FormSectionCard(
              title: 'แหล่งน้ำและระบบน้ำ',
              example: 'ระบุแหล่งน้ำและวิธีการให้น้ำ',
              icon: PhosphorIconsRegular.flask,
              iconColor: Colors.cyan,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormDropdownWithOther(
                    key: const Key('waterSource_dropdown'),
                    label: 'แหล่งน้ำ',
                    hint: 'เลือกแหล่งน้ำหลัก',
                    options: _waterSourceOptions,
                    value: _waterSourceController.text,
                    onChanged: (val) {
                      if (mounted) {
                        setState(() => _waterSourceController.text = val);
                      }
                    },
                    icon: PhosphorIconsRegular.flask,
                  ),
                  const SizedBox(height: 12),
                  FormDropdownWithOther(
                    key: const Key('irrigationSystem_dropdown'),
                    label: 'ระบบการให้น้ำ',
                    hint: 'เลือกวิธีการให้น้ำ',
                    options: _irrigationOptions,
                    value: _irrigationSystemController.text,
                    onChanged: (val) {
                      if (mounted) {
                        setState(() => _irrigationSystemController.text = val);
                      }
                    },
                    icon: PhosphorIconsRegular.slidersHorizontal,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _waterQualityNoteController,
                    maxLength: 200,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'หมายเหตุคุณภาพน้ำ (ถ้ามี)',
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
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOption(
    String value,
    String title,
    String subtitle,
    Color color,
  ) {
    final isSelected = _farmingSystem == value;
    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            _farmingSystem = value;
            _hasUnsavedChanges = true;
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                value == 'ORGANIC'
                    ? PhosphorIconsRegular.sparkle
                    : (value == 'TRANSITION'
                          ? PhosphorIconsRegular.arrowsClockwise
                          : PhosphorIconsRegular.flask),
                color: color,
                size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
