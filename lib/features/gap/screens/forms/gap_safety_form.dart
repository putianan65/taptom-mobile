import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/checkbox_option_card.dart';
import '../../widgets/gap_form_wrapper.dart';

/// หมวด 6: ความปลอดภัย - ตรงกับ Backend WorkerTraining model
class GapSafetyForm extends StatefulWidget {
  final String plotId;
  final String? existingId;
  final Map<String, dynamic>? existingData;

  const GapSafetyForm({
    super.key,
    required this.plotId,
    this.existingId,
    this.existingData,
  });

  @override
  State<GapSafetyForm> createState() => _GapSafetyFormState();
}

class _GapSafetyFormState extends State<GapSafetyForm> {
  final _gapService = GapService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool get _isEditMode => widget.existingId != null;

  // Backend WorkerTraining fields
  DateTime? _trainingDate;
  String _status = 'COMPLETED'; // Enum: PLANNED, COMPLETED, CANCELLED

  final _topicController = TextEditingController();
  final _trainerController = TextEditingController();
  final _attendeesController = TextEditingController();
  final _proofDocumentController = TextEditingController();

  // Hygiene & Safety Checks (Stored in JSON or notes)
  bool _hasFirstAid = true;
  bool _hasProtectiveGear = true;
  bool _hasToilet = true;
  bool _hasWashingStation = true;

  // Dropdown Options
  final List<String> _topicOptions = [
    'การใช้สารชีวภัณฑ์และสมุนไพรควบคุมศัตรูพืช',
    'สุขลักษณะส่วนบุคคลและการเก็บเกี่ยว',
    'การปฐมพยาบาลเบื้องต้น',
    'การใช้เครื่องจักรอย่างปลอดภัย',
    'การจัดการขยะและของเสีย',
    'มาตรฐาน GAP พืชอาหาร/สมุนไพร',
  ];
  final List<String> _trainerOptions = [
    'เจ้าหน้าที่เกษตรอำเภอ',
    'หมอดินอาสา',
    'ผู้นำชุมชน',
    'วิทยากรภายนอก',
    'อบรมด้วยตนเอง (ออนไลน์)',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Listen for changes
    _topicController.addListener(_onFieldChanged);
    _trainerController.addListener(_onFieldChanged);
    _attendeesController.addListener(_onFieldChanged);
    _proofDocumentController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _trainerController.dispose();
    _attendeesController.dispose();
    _proofDocumentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // If we have existing data (edit mode), use it
      if (widget.existingData != null) {
        final data = widget.existingData!;
        setState(() {
          _topicController.text = data['trainingTopic']?.toString() ??
              data['topic']?.toString() ??
              '';
          _trainerController.text = data['trainer']?.toString() ?? '';
          _attendeesController.text = data['attendees']?.toString() ?? '';
          _status = data['status']?.toString() ?? 'COMPLETED';

          // GAP-FIX: Parse hygiene flags with backward compatibility
          final flagsList = data['hygieneFlags'] as List<dynamic>?;
          if (flagsList != null && flagsList.isNotEmpty) {
              _hasFirstAid = flagsList.contains('FIRST_AID');
              _hasProtectiveGear = flagsList.contains('PROTECTIVE_GEAR');
              _hasToilet = flagsList.contains('TOILET');
              _hasWashingStation = flagsList.contains('WASHING_STATION');
          } else {
              // Fallback if flags are empty (might be legacy data stored in notes)
              final hygieneNotes = data['hygieneNotes']?.toString() ?? '';
              _hasFirstAid = hygieneNotes.contains('มีชุดปฐมพยาบาล');
              _hasProtectiveGear = hygieneNotes.contains('มีอุปกรณ์ป้องกัน');
              _hasToilet = hygieneNotes.contains('มีห้องน้ำถูกสุขลักษณะ');
              _hasWashingStation = hygieneNotes.contains('มีจุดล้างมือ');
          }

          if (data['trainingDate'] != null) {
            _trainingDate = DateTime.tryParse(data['trainingDate'].toString());
          }
          _hasUnsavedChanges = false; // Reset after load
        });
      } else {
        // New form - try to load draft
        final draft = await DatabaseHelper.instance.getDraft(
          'safety_${widget.plotId}',
        );
        if (draft != null) {
          final data = jsonDecode(draft.jsonData);
          setState(() {
            _topicController.text = data['trainingTopic']?.toString() ??
                data['topic']?.toString() ??
                '';
            _trainerController.text = data['trainer']?.toString() ?? '';
            _attendeesController.text = data['attendees']?.toString() ?? '';
            _status = data['status']?.toString() ?? 'COMPLETED';

            // GAP-FIX: Parse hygiene flags (New Format)
            final flagsList = data['hygieneFlags'] as List<dynamic>?;
            if (flagsList != null && flagsList.isNotEmpty) {
              _hasFirstAid = flagsList.contains('FIRST_AID');
              _hasProtectiveGear = flagsList.contains('PROTECTIVE_GEAR');
              _hasToilet = flagsList.contains('TOILET');
              _hasWashingStation = flagsList.contains('WASHING_STATION');
            } else {
              // Fallback to old format (hygieneNotes check)
              final hygieneNotes = data['hygieneNotes']?.toString() ?? '';
              if (hygieneNotes.isNotEmpty) {
                _hasFirstAid = hygieneNotes.contains('มีชุดปฐมพยาบาล');
                _hasProtectiveGear = hygieneNotes.contains('มีอุปกรณ์ป้องกัน');
                _hasToilet = hygieneNotes.contains('มีห้องน้ำถูกสุขลักษณะ');
                _hasWashingStation = hygieneNotes.contains('มีจุดล้างมือ');
              }
            }

            if (data['trainingDate'] != null) {
              _trainingDate = DateTime.tryParse(
                data['trainingDate'].toString(),
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

  /// Build data matching Backend WorkerTraining schema
  Map<String, dynamic> _buildFormData() {
    final data = <String, dynamic>{
      'trainingDate':
          _trainingDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'status': _status,
    };

    // Trim all text inputs
    final topic = _topicController.text.trim();
    final trainer = _trainerController.text.trim();
    final attendeesText = _attendeesController.text.trim();

    // Only add optional fields if they have values
    if (topic.isNotEmpty) data['topic'] = topic;
    if (trainer.isNotEmpty) data['trainer'] = trainer;

    // Convert attendees to integer if possible
    if (attendeesText.isNotEmpty) {
      final attendeesInt = int.tryParse(attendeesText);
      if (attendeesInt != null) {
        data['attendees'] = attendeesInt;
      }
    }

    // GAP-FIX: Store hygiene flags as JSON Array
    final hygieneFlags = <String>[];
    if (_hasFirstAid) hygieneFlags.add('FIRST_AID');
    if (_hasProtectiveGear) hygieneFlags.add('PROTECTIVE_GEAR');
    if (_hasToilet) hygieneFlags.add('TOILET');
    if (_hasWashingStation) hygieneFlags.add('WASHING_STATION');
    
    if (hygieneFlags.isNotEmpty) {
      data['hygieneFlags'] = hygieneFlags;
      
      // Keep hygieneNotes for backward compatibility / display
      final hygieneInfo = <String>[];
      if (_hasFirstAid) hygieneInfo.add('มีชุดปฐมพยาบาล');
      if (_hasProtectiveGear) hygieneInfo.add('มีอุปกรณ์ป้องกัน');
      if (_hasToilet) hygieneInfo.add('มีห้องน้ำถูกสุขลักษณะ');
      if (_hasWashingStation) hygieneInfo.add('มีจุดล้างมือ');
      data['hygieneNotes'] = hygieneInfo.join(', ');
    }

    return data;
  }

  /// Get list of incomplete (empty) optional fields for soft warning
  /// Only check text fields that are truly optional
  List<String> _getIncompleteFields() {
    final incomplete = <String>[];
    if (_trainerController.text.trim().isEmpty) incomplete.add('วิทยากร');
    if (_attendeesController.text.trim().isEmpty)
      incomplete.add('จำนวนผู้เข้าร่วม');
    return incomplete;
  }

  Future<void> _saveDraft() async {
    final messenger = ScaffoldMessenger.of(context);
    final json = jsonEncode(_buildFormData());
    await DatabaseHelper.instance.saveDraft('safety_${widget.plotId}', json);
    
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

  Future<void> _saveToApi() async {
    // GAP-BUG-001: Prevent double submission
    if (_isSaving) return;

    // GAP-BUG-003: Store messenger reference before async operations
    final messenger = ScaffoldMessenger.of(context);

    // Validate training date
    if (_trainingDate == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('กรุณาเลือกวันที่อบรม', style: GoogleFonts.prompt()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate training date is not in the future
    if (_trainingDate!.isAfter(DateTime.now())) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'วันที่อบรมไม่สามารถเป็นวันในอนาคต',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate topic (minimum 5 characters)
    if (_topicController.text.trim().isEmpty ||
        _topicController.text.trim().length < 5) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาระบุหัวข้อการอบรม (อย่างน้อย 5 ตัวอักษร)',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate trainer (minimum 3 characters)
    if (_trainerController.text.trim().isEmpty ||
        _trainerController.text.trim().length < 3) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาระบุชื่อวิทยากร (อย่างน้อย 3 ตัวอักษร)',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate attendees count is positive integer
    final attendeesText = _attendeesController.text.trim();
    if (attendeesText.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาระบุจำนวนผู้เข้าร่วม',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final attendees = int.tryParse(attendeesText);
    if (attendees == null || attendees <= 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'จำนวนผู้เข้าร่วมต้องเป็นจำนวนเต็มบวก',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (attendees > 1000) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'จำนวนผู้เข้าร่วมเกิน 1,000 คน กรุณาตรวจสอบ',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // GAP-BUG-004: Show incomplete fields warning BEFORE saving
    final incompleteFields = _getIncompleteFields();
    if (incompleteFields.isNotEmpty) {
      final shouldProceed = await showIncompleteFieldsDialog(
        context,
        formTitle: 'ความปลอดภัย',
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
      final apiData = Map<String, dynamic>.from(_buildFormData());
      
      // FIX: API expects 'trainingTopic', not 'topic'
      if (apiData.containsKey('topic')) {
        apiData['trainingTopic'] = apiData['topic'];
        apiData.remove('topic');
      }

      // GAP-FIX: Now allowed to send hygieneFlags directly
      // apiData.remove('hygieneFlags');

      if (_isEditMode) {
        await _gapService.updateTraining(
          widget.plotId,
          widget.existingId!,
          apiData,
        );
        await _gapService.notifyAdminOnEdit(
          plotId: widget.plotId,
          formType: 'ความปลอดภัย',
          recordId: widget.existingId!,
        );
      } else {
        await _gapService.addTraining(widget.plotId, apiData);
      }
      await DatabaseHelper.instance.deleteDraft('safety_${widget.plotId}');

      if (!mounted) return;

      // Reset saving state BEFORE showing dialog/popping
      setState(() {
        _isSaving = false;
        _hasUnsavedChanges = false;
      });

      await showGapSuccessDialog(
        context,
        formTitle: 'ความปลอดภัย',
        formSubtitle: _isEditMode ? 'แก้ไขสำเร็จ' : 'บันทึกการอบรมสำเร็จ',
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
      initialDate: _trainingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Prevent future date selection
      locale: const Locale('th', 'TH'),
    );
    if (picked != null) {
      setState(() {
         _trainingDate = picked;
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
      title: '6. สุขลักษณะและความปลอดภัย',
      subtitle: 'การอบรมและสวัสดิภาพผู้ปฏิบัติงาน',
      headerIcon: HeroIcons.shieldCheck,
      headerColor: Colors.pink,
      onSave: _saveToApi,
      onSaveDraft: _saveDraft,
      isSaving: _isSaving,
      hasUnsavedChanges: _hasUnsavedChanges,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FormInfoCard(
            message:
                'บันทึกประวัติการอบรม และการจัดสวัสดิการเพื่อความปลอดภัยของผู้ปฏิบัติงาน',
            icon: HeroIcons.lightBulb,
            color: Colors.pink,
          ),

          // สวัสดิการและความปลอดภัย
          FormSectionCard(
            title: 'สวัสดิการและความปลอดภัยในแปลง',
            example: 'เลือกรายการที่มี (ถ้ามี)',
            icon: HeroIcons.heart,
            iconColor: Colors.red,
            child: Column(
              children: [
                CheckboxOptionCard(
                  label: 'มีชุดปฐมพยาบาลเบื้องต้น',
                  icon: HeroIcons.plusCircle,
                  isSelected: _hasFirstAid,
                  onTap: () => setState(() {
                     _hasFirstAid = !_hasFirstAid;
                     _hasUnsavedChanges = true;
                  }),
                ),
                const SizedBox(height: 8),
                CheckboxOptionCard(
                  label: 'มีอุปกรณ์ป้องกัน (ถุงมือ/รองเท้าบูท)',
                  icon: HeroIcons.shieldCheck,
                  isSelected: _hasProtectiveGear,
                  onTap: () =>
                      setState(() {
                        _hasProtectiveGear = !_hasProtectiveGear;
                        _hasUnsavedChanges = true;
                      }),
                ),
                const SizedBox(height: 8),
                CheckboxOptionCard(
                  label: 'มีห้องน้ำถูกสุขลักษณะ',
                  icon: HeroIcons.home,
                  isSelected: _hasToilet,
                  onTap: () => setState(() {
                    _hasToilet = !_hasToilet;
                    _hasUnsavedChanges = true;
                  }),
                ),
                const SizedBox(height: 8),
                CheckboxOptionCard(
                  label: 'มีจุดล้างมือ/ชำระล้างร่างกาย',
                  icon: HeroIcons.sparkles,
                  isSelected: _hasWashingStation,
                  onTap: () =>
                      setState(() {
                        _hasWashingStation = !_hasWashingStation;
                        _hasUnsavedChanges = true;
                      }),
                ),
              ],
            ),
          ),

          // ประวัติการอบรม
          FormSectionCard(
            title: 'บันทึกการอบรม',
            example: 'บันทึกหัวข้อที่ได้รับการอบรม',
            icon: HeroIcons.academicCap,
            iconColor: Colors.blue,
            child: Column(
              children: [
                // วันที่อบรม
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
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
                          _formatDate(_trainingDate),
                          style: GoogleFonts.prompt(
                            color: _trainingDate != null
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
                // หัวข้อ
                FormDropdownWithOther(
                  label: 'หัวข้อการอบรม *',
                  hint: 'เลือกหัวข้อการอบรม',
                  options: _topicOptions,
                  value: _topicController.text,
                  onChanged: (val) =>
                      setState(() => _topicController.text = val),
                  icon: HeroIcons.bookOpen,
                ),
                const SizedBox(height: 12),
                // วิทยากร/หน่วยงาน
                FormDropdownWithOther(
                  label: 'วิทยากร/หน่วยงาน *',
                  hint: 'ระบุผู้ให้การอบรม',
                  options: _trainerOptions,
                  value: _trainerController.text,
                  onChanged: (val) =>
                      setState(() => _trainerController.text = val),
                  icon: HeroIcons.userGroup,
                ),
                const SizedBox(height: 12),
                // ผู้เข้าร่วม
                TextField(
                  controller: _attendeesController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: 'จำนวนคน (ตัวเลข)',
                    hintStyle: GoogleFonts.prompt(color: Colors.grey),
                    labelText: 'จำนวนผู้เข้าร่วมอบรม *',
                    labelStyle: GoogleFonts.prompt(color: Colors.grey[700]),
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
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
