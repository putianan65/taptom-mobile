import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/checkbox_option_card.dart';
import '../../widgets/gap_form_wrapper.dart';

/// หมวด 5: การจัดการหลังการเก็บเกี่ยว - ตรงกับ Backend PostHarvest model
/// ต้องมี harvestId ก่อนเพราะ PostHarvest เป็น child ของ Harvest
class GapPostHarvestForm extends StatefulWidget {
  final String plotId;
  final String? harvestId; // Optional: if null, show harvest selector
  final String? existingId; // For edit mode
  final Map<String, dynamic>? existingData; // Pre-loaded data for edit

  const GapPostHarvestForm({
    super.key,
    required this.plotId,
    this.harvestId,
    this.existingId,
    this.existingData,
  });

  @override
  State<GapPostHarvestForm> createState() => _GapPostHarvestFormState();
}

class _GapPostHarvestFormState extends State<GapPostHarvestForm> {
  final _gapService = GapService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool get _isEditMode => widget.existingId != null;

  // Harvest selection
  List<Map<String, dynamic>> _harvests = [];
  String? _selectedHarvestId;

  // Backend PostHarvest fields
  DateTime? _processDate;

  // Cleaning & Selection
  bool _sortingDone = true;
  bool _washingDone =
      false; // Kratom leaves usually not washed if drying immediately to prevent mold, unless specified

  // Process & Packaging
  final _processTypeController = TextEditingController();
  final _packagingController = TextEditingController();
  final _packingLabelController = TextEditingController();

  // Storage
  final _storageLocationController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _pestControlController = TextEditingController();

  // Dropdown Options
  final List<String> _processOptions = [
    'ตากแห้งธรรมชาติ (Sun Drying)',
    'อบแห้งตู้อบลมร้อน (Hot Air)',
    'จำหน่ายใบสด (Fresh)',
    'บดผง (Grinding)',
    'หมัก (Fermentation)',
  ];
  final List<String> _packagingOptions = [
    'ถุงพลาสติกใส 5 กก.',
    'ถุงดำ 10 กก.',
    'ลังกระดาษ',
    'ถุงสุญญากาศ',
    'มัดกำ (ใบสด)',
  ];
  final List<String> _storageOptions = [
    'โรงเรือนอากาศถ่ายเท',
    'ห้องเย็น (Cold Storage)',
    'โกดังเก็บสินค้า',
    'ชั้นวางยกสูง',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Listen for changes
    _processTypeController.addListener(_onFieldChanged);
    _packagingController.addListener(_onFieldChanged);
    _storageLocationController.addListener(_onFieldChanged);
    _temperatureController.addListener(_onFieldChanged);
    _humidityController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    _processTypeController.dispose();
    _packagingController.dispose();
    // _packingLabelController (unused but defined at top, should verify if used? Removed in dispose to be safe if it was used)
    _packingLabelController.dispose();
    _storageLocationController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _pestControlController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load harvests for this plot first
      final harvestsData = await _gapService.getHarvests(widget.plotId);
      _harvests = harvestsData
          .map((h) => Map<String, dynamic>.from(h as Map))
          .toList();

      // Use provided harvestId or select first available
      _selectedHarvestId =
          widget.harvestId ??
          (_harvests.isNotEmpty ? _harvests.first['id']?.toString() : null);

      // If we have existing data (edit mode), use it
      if (widget.existingData != null) {
        final data = widget.existingData!;
        // In edit mode, use the harvestId from existing data
        _selectedHarvestId =
            data['harvestId']?.toString() ?? _selectedHarvestId;
        setState(() {
          // Try to recover state from description if booleans are false (Legacy data support)
          final description = data['description']?.toString() ?? '';
          _sortingDone = data['sortingDone'] ?? description.contains('คัดแยก');
          _washingDone = data['washingDone'] ?? description.contains('ล้าง');

          _processTypeController.text = data['processType']?.toString() ?? '';
          _packagingController.text =
              data['packagingType']?.toString() ??
              data['packaging']?.toString() ??
              '';
          _storageLocationController.text =
              data['storageLocation']?.toString() ?? '';
          _temperatureController.text = data['storageTemp']?.toString() ?? '';
          _humidityController.text = data['storageHumidity']?.toString() ?? '';

          if (data['processDate'] != null) {
            _processDate = DateTime.tryParse(data['processDate'].toString());
          }
          _hasUnsavedChanges = false; // Reset after load
        });
      } else {
        // New form - try to load draft
        final draft = await DatabaseHelper.instance.getDraft(
          'post_harvest_${widget.plotId}',
        );
        if (draft != null) {
          final data = jsonDecode(draft.jsonData);
          setState(() {
            _sortingDone = data['sortingDone'] ?? true;
            _washingDone = data['washingDone'] ?? false;
            _processTypeController.text = data['processType']?.toString() ?? '';
            _packagingController.text = data['packagingType']?.toString() ?? '';
            _storageLocationController.text =
                data['storageLocation']?.toString() ?? '';
            _temperatureController.text = data['storageTemp']?.toString() ?? '';
            _humidityController.text =
                data['storageHumidity']?.toString() ?? '';
            if (data['processDate'] != null) {
              _processDate = DateTime.tryParse(data['processDate'].toString());
            }
            _hasUnsavedChanges = false; // Reset after load
          });
        }
      }
    } catch (e) {
      // Silent failure - data loading is not critical
    }

    setState(() => _isLoading = false);
  }

  /// Build data matching Backend PostHarvest schema
  Map<String, dynamic> _buildFormData() {
    final data = <String, dynamic>{
      'processDate':
          _processDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };

    // Trim all text inputs
    final processType = _processTypeController.text.trim();
    final packaging = _packagingController.text.trim();
    final storageLocation = _storageLocationController.text.trim();
    final temperature = _temperatureController.text.trim();
    final humidity = _humidityController.text.trim();

    // Only add optional fields if they have values
    if (processType.isNotEmpty) data['processType'] = processType;
    if (packaging.isNotEmpty) data['packagingType'] = packaging;
    if (storageLocation.isNotEmpty) data['storageLocation'] = storageLocation;

    // Build description from checkboxes
    final descParts = <String>[];
    if (_sortingDone) descParts.add('คัดแยกแล้ว');
    if (_washingDone) descParts.add('ล้างแล้ว');
    if (descParts.isNotEmpty) data['description'] = descParts.join(', ');

    // Add boolean flags for direct mapping (Confirmed by User)
    data['sortingDone'] = _sortingDone;
    data['washingDone'] = _washingDone;

    // Parse and validate numeric fields
    if (temperature.isNotEmpty) {
      final temp = double.tryParse(temperature);
      if (temp != null && temp >= -50 && temp <= 100) {
        data['storageTemp'] = temp;
      }
    }

    if (humidity.isNotEmpty) {
      final hum = double.tryParse(humidity);
      if (hum != null && hum >= 0 && hum <= 100) {
        data['storageHumidity'] = hum;
      }
    }

    return data;
  }

  Future<void> _saveDraft() async {
    final messenger = ScaffoldMessenger.of(context);
    final json = jsonEncode(_buildFormData());
    await DatabaseHelper.instance.saveDraft(
      'post_harvest_${widget.plotId}',
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
  /// Only check text fields, not checkboxes (sorting/washing are truly optional)
  List<String> _getIncompleteFields() {
    final incomplete = <String>[];
    if (_processTypeController.text.trim().isEmpty)
      incomplete.add('ประเภทการดำเนินการ');
    if (_packagingController.text.trim().isEmpty) incomplete.add('การบรรจุ');
    if (_storageLocationController.text.trim().isEmpty)
      incomplete.add('สถานที่จัดเก็บ');
    if (_temperatureController.text.trim().isEmpty)
      incomplete.add('อุณหภูมิจัดเก็บ');
    if (_humidityController.text.trim().isEmpty) incomplete.add('ความชื้น');
    return incomplete;
  }

  Future<void> _saveToApi() async {
    // GAP-BUG-001: Prevent double submission
    if (_isSaving) return;

    final messenger = ScaffoldMessenger.of(context);

    // Validate harvestId
    if (_selectedHarvestId == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาเลือกข้อมูลการเก็บเกี่ยวก่อน',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate process date
    if (_processDate == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาเลือกวันที่ดำเนินการ',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate process date is not in the future
    if (_processDate!.isAfter(DateTime.now())) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'วันที่ดำเนินการไม่สามารถเป็นวันในอนาคต',
            style: GoogleFonts.prompt(),
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
    }

    // Validate process type (minimum 3 characters)
    if (_processTypeController.text.trim().isEmpty ||
        _processTypeController.text.trim().length < 3) {
      messenger.showSnackBar(
      SnackBar(
        content: Text(
          'กรุณากรอกประเภทการดำเนินการ (อย่างน้อย 3 ตัวอักษร)',
          style: GoogleFonts.prompt(),
        ),
        backgroundColor: Colors.orange,
      ),
      );
      return;
    }

    // Validate temperature if provided
    final tempText = _temperatureController.text.trim();
    if (tempText.isNotEmpty) {
      final temp = double.tryParse(tempText);
      if (temp == null) {
        messenger.showSnackBar(
        SnackBar(
          content: Text(
            'อุณหภูมิต้องเป็นตัวเลข',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
        );
        return;
      }
      if (temp < -50 || temp > 100) {
        messenger.showSnackBar(
        SnackBar(
          content: Text(
            'อุณหภูมิต้องอยู่ระหว่าง -50 ถึง 100 °C',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
        );
        return;
      }
    }

    // Validate humidity if provided
    final humidityText = _humidityController.text.trim();
    if (humidityText.isNotEmpty) {
      final humidity = double.tryParse(humidityText);
      if (humidity == null) {
        messenger.showSnackBar(
        SnackBar(
          content: Text(
            'ความชื้นต้องเป็นตัวเลข',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
        );
        return;
      }
      if (humidity < 0 || humidity > 100) {
        messenger.showSnackBar(
        SnackBar(
          content: Text(
            'ความชื้นต้องอยู่ระหว่าง 0 ถึง 100 %',
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
        formTitle: 'การจัดการหลังเก็บเกี่ยว',
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
        await _gapService.updatePostHarvest(
          _selectedHarvestId!,
          widget.existingId!,
          _buildFormData(),
        );
        await _gapService.notifyAdminOnEdit(
          plotId: widget.plotId,
          formType: 'การจัดการหลังเก็บเกี่ยว',
          recordId: widget.existingId!,
        );
      } else {
        await _gapService.addPostHarvest(_selectedHarvestId!, _buildFormData());
      }
      await DatabaseHelper.instance.deleteDraft(
        'post_harvest_${widget.plotId}',
      );

      if (!mounted) return;

      // Reset saving state BEFORE showing dialog/popping
      setState(() {
        _isSaving = false;
        _hasUnsavedChanges = false;
      });

      await showGapSuccessDialog(
        context,
        formTitle: 'การจัดการหลังเก็บเกี่ยว',
        formSubtitle: _isEditMode ? 'แก้ไขสำเร็จ' : 'บันทึกสำเร็จ',
      );

      // Use stored navigator to avoid context usage after dispose
      navigator.pop(true);
      return; // Exit immediately — widget will be disposed after pop
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        
        // Ensure both this widget and the messenger are still mounted
        if (messenger.mounted) {
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
      initialDate: _processDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Prevent future date selection
      locale: const Locale('th', 'TH'),
    );
    if (picked != null) {
      setState(() {
         _processDate = picked;
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
      title: '5. การจัดการหลังเก็บเกี่ยว',
      subtitle: 'คัดแยก บรรจุ และเก็บรักษา',
      headerIcon: HeroIcons.cube,
      headerColor: Colors.purple,
      onSave: _saveToApi,
      onSaveDraft: _saveDraft,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FormInfoCard(
            message:
                'การจัดการหลังเก็บเกี่ยวสำคัญต่อคุณภาพใบกระท่อม บันทึกวิธีการแปรรูปและเก็บรักษา',
            icon: HeroIcons.lightBulb,
            color: Colors.purple,
          ),

          // วันที่ดำเนินการ
          FormSectionCard(
            title: 'วันที่ดำเนินการ *',
            example: 'ตัวอย่าง: 16 มกราคม 2569',
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
                      _formatDate(_processDate),
                      style: GoogleFonts.prompt(
                        color: _processDate != null
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

          // การคัดแยกและทำความสะอาด
          FormSectionCard(
            title: 'การคัดแยกและทำความสะอาด',
            example: 'เลือกขั้นตอนที่ทำ (ถ้ามี)',
            icon: HeroIcons.sparkles,
            iconColor: Colors.blue,
            child: Column(
              children: [
                CheckboxOptionCard(
                  label: 'มีการคัดแยกเกรด/ขนาด (Sorting)',
                  icon: HeroIcons.funnel,
                  isSelected: _sortingDone,
                  onTap: () => setState(() {
                     _sortingDone = !_sortingDone;
                     _hasUnsavedChanges = true;
                  }),
                ),
                const SizedBox(height: 10),
                CheckboxOptionCard(
                  label: 'มีการล้างทำความสะอาด (Washing)',
                  icon: HeroIcons.beaker,
                  isSelected: _washingDone,
                  onTap: () => setState(() {
                    _washingDone = !_washingDone;
                    _hasUnsavedChanges = true;
                  }),
                ),
              ],
            ),
          ),

          // รูปแบบการแปรรูป/จัดการ
          FormSectionCard(
            title: 'วิธีการแปรรูป/จัดการ *',
            example: 'เลือกวิธีการแปรรูป',
            icon: HeroIcons.cog,
            iconColor: Colors.orange,
            child: FormDropdownWithOther(
              label: 'วิธีการ',
              hint: 'เลือกวิธีการแปรรูป',
              options: _processOptions,
              value: _processTypeController.text,
              onChanged: (val) =>
                  setState(() => _processTypeController.text = val),
              icon: HeroIcons.wrenchScrewdriver,
            ),
          ),

          // บรรจุภัณฑ์
          FormSectionCard(
            title: 'บรรจุภัณฑ์',
            example: 'เลือกชนิดบรรจุภัณฑ์',
            icon: HeroIcons.gift,
            iconColor: Colors.green,
            child: FormDropdownWithOther(
              label: 'บรรจุภัณฑ์',
              hint: 'เลือกชนิดบรรจุภัณฑ์',
              options: _packagingOptions,
              value: _packagingController.text,
              onChanged: (val) =>
                  setState(() => _packagingController.text = val),
              icon: HeroIcons.archiveBox,
            ),
          ),

          // สถานที่เก็บรักษา
          FormSectionCard(
            title: 'การเก็บรักษา',
            example: 'ระบุสถานที่เก็บรักษา',
            icon: HeroIcons.buildingStorefront,
            iconColor: Colors.brown,
            child: Column(
              children: [
                FormDropdownWithOther(
                  label: 'สถานที่เก็บ',
                  hint: 'เลือกสถานที่เก็บรักษา',
                  options: _storageOptions,
                  value: _storageLocationController.text,
                  onChanged: (val) =>
                      setState(() => _storageLocationController.text = val),
                  icon: HeroIcons.home,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _temperatureController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        maxLength: 6,
                        decoration: InputDecoration(
                          hintText: 'อุณหภูมิ (°C)',
                          hintStyle: GoogleFonts.prompt(color: Colors.grey),
                          labelText: 'อุณหภูมิ (-50 ถึง 100 °C)',
                          labelStyle: GoogleFonts.prompt(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          counterText: '',
                        ),
                        style: GoogleFonts.prompt(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _humidityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        maxLength: 5,
                        decoration: InputDecoration(
                          hintText: 'ความชื้น (%)',
                          hintStyle: GoogleFonts.prompt(color: Colors.grey),
                          labelText: 'ความชื้น (0-100 %)',
                          labelStyle: GoogleFonts.prompt(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          counterText: '',
                        ),
                        style: GoogleFonts.prompt(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
