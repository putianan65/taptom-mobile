import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/services/database_helper.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../gap_categories.dart';
import '../../widgets/gap_form_wrapper.dart';

/// 1.1 General information about the grower, crop and water.
///
/// Drafts are kept on the device and refreshed quietly every 30 seconds
/// while there are unsaved edits, so a dropped connection never loses work.
class GapGeneralForm extends StatefulWidget {
  const GapGeneralForm({super.key, required this.plotId, this.isReadOnly = false});

  final String plotId;
  final bool isReadOnly;

  @override
  State<GapGeneralForm> createState() => _GapGeneralFormState();
}

class _GapGeneralFormState extends State<GapGeneralForm> {
  static const _autoSaveEvery = Duration(seconds: 30);
  static const _waterSources = ['บ่อบาดาล', 'สระเก็บน้ำ', 'คลองชลประทาน', 'แม่น้ำ ลำธาร', 'น้ำประปา'];
  static const _irrigation = ['รดน้ำด้วยมือ', 'มินิสปริงเกอร์', 'น้ำหยด', 'สูบน้ำราด', 'น้ำฝนตามธรรมชาติ'];
  static const _systems = [
    ('NON_ORGANIC', 'เกษตรทั่วไป', 'ใช้ปุ๋ยและสารเคมีได้ตามมาตรฐาน', AppIcons.inputs),
    ('ORGANIC', 'เกษตรอินทรีย์', 'ไม่ใช้สารเคมีสังเคราะห์', AppIcons.leaf),
    ('TRANSITION', 'ระยะปรับเปลี่ยน', 'กำลังปรับเข้าสู่เกษตรอินทรีย์', AppIcons.refresh),
  ];

  final _gap = GapService();
  final _form = GlobalKey<FormState>();
  final _farmer = TextEditingController();
  final _season = TextEditingController();
  final _variety = TextEditingController();
  final _waterNote = TextEditingController();
  String _waterSource = '';
  String _irrigationSystem = '';
  String _cropType = 'KRATOM';
  String _farmingSystem = 'NON_ORGANIC';
  DateTime? _startDate;

  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  DateTime? _draftSavedAt;
  Timer? _autoSave;

  String get _draftKey => 'general_${widget.plotId}';

  @override
  void initState() {
    super.initState();
    for (final c in [_farmer, _season, _variety, _waterNote]) {
      c.addListener(_touch);
    }
    _load();
    if (!widget.isReadOnly) {
      _autoSave = Timer.periodic(_autoSaveEvery, (_) {
        if (_dirty) _saveDraft(quiet: true);
      });
    }
  }

  @override
  void dispose() {
    _autoSave?.cancel();
    for (final c in [_farmer, _season, _variety, _waterNote]) {
      c.dispose();
    }
    super.dispose();
  }

  void _touch() {
    if (!_loading && !_dirty) setState(() => _dirty = true);
  }

  void _apply(Map<String, dynamic> d) {
    _farmer.text = '${d['farmerName'] ?? ''}';
    _season.text = '${d['seasonLabel'] ?? ''}';
    _variety.text = '${d['cropVariety'] ?? ''}';
    _waterNote.text = '${d['waterQualityNote'] ?? ''}';
    _waterSource = '${d['waterSource'] ?? ''}';
    _irrigationSystem = '${d['irrigationSystem'] ?? ''}';
    _cropType = '${d['cropType'] ?? 'KRATOM'}';
    _farmingSystem = '${d['farmingSystem'] ?? 'NON_ORGANIC'}';
    _startDate = DateTime.tryParse('${d['startDate'] ?? ''}')?.toLocal();
  }

  Future<void> _load() async {
    Map<String, dynamic>? data;
    try {
      data = await _gap.getGapData(widget.plotId);
    } on Object catch (_) {}
    // A local draft is newer than anything on the server.
    try {
      final draft = await DatabaseHelper.instance.getDraft(_draftKey);
      if (draft != null && !widget.isReadOnly) {
        data = {...?data, ...Map<String, dynamic>.from(jsonDecode(draft.jsonData) as Map)};
        _draftSavedAt = DateTime.tryParse(draft.lastUpdated)?.toLocal();
      }
    } on Object catch (_) {}
    if (!mounted) return;
    setState(() {
      if (data != null) _apply(data);
      _loading = false;
      _dirty = false;
    });
  }

  Map<String, dynamic> _data() => {
        'farmerName': _farmer.text.trim(),
        'seasonLabel': _season.text.trim(),
        'cropType': _cropType,
        'cropVariety': _variety.text.trim(),
        'irrigationSystem': _irrigationSystem.trim(),
        'waterSource': _waterSource.trim(),
        'waterQualityNote': _waterNote.text.trim(),
        'farmingSystem': _farmingSystem,
        'startDate': (_startDate ?? DateTime.now()).toIso8601String(),
      };

  Future<void> _saveDraft({bool quiet = false}) async {
    try {
      await DatabaseHelper.instance.saveDraft(_draftKey, jsonEncode(_data()));
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _draftSavedAt = DateTime.now();
      });
      if (!quiet) AppToast.info(context, 'บันทึกร่างไว้ในเครื่องแล้ว');
    } on Object catch (e) {
      debugPrint('Draft save failed: $e');
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_startDate == null) {
      AppToast.error(context, 'เลือกวันเริ่มปลูก');
      return;
    }
    final missing = [
      if (_variety.text.trim().isEmpty) 'สายพันธุ์',
      if (_waterSource.isEmpty) 'แหล่งน้ำ',
      if (_irrigationSystem.isEmpty) 'ระบบให้น้ำ',
    ];
    if (missing.isNotEmpty &&
        !await showIncompleteFieldsDialog(context, formTitle: 'ข้อมูลทั่วไป', incompleteFields: missing)) {
      return;
    }
    if (!mounted) return;

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      await _gap.saveGeneralInfo(widget.plotId, _data());
      GapService.invalidate(widget.plotId);
      await DatabaseHelper.instance.deleteDraft(_draftKey);
      if (!mounted) return;
      setState(() => _dirty = false);
      await showGapSuccessDialog(context, formTitle: 'บันทึกข้อมูลทั่วไปแล้ว', formSubtitle: 'ไปต่อหมวด 1.2 ปัจจัยการผลิตได้เลย');
      navigator.pop(true);
    } on Object catch (e) {
      if (mounted) AppToast.error(context, ErrorUtils.getReadableError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateName(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'กรอกชื่อเกษตรกร';
    if (s.length < 3) return 'ชื่อสั้นเกินไป';
    if (!RegExp(r'^[฀-๿a-zA-Z\s\.]+$').hasMatch(s)) return 'ใช้ได้เฉพาะตัวอักษร';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ro = widget.isReadOnly;
    final saved = _draftSavedAt;

    return GapFormWrapper(
      category: GapCategory.general,
      subtitle: saved == null
          ? null
          : 'บันทึกร่างล่าสุด ${saved.hour.toString().padLeft(2, '0')}:${saved.minute.toString().padLeft(2, '0')} น.',
      onSave: _save,
      onSaveDraft: () => _saveDraft(),
      isSaving: _saving,
      hasUnsavedChanges: _dirty,
      readOnly: ro,
      child: _loading
          ? const SkeletonList(count: 4, thumbnail: false)
          : Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!ro)
                    const FormInfoCard(
                      title: 'ข้อมูลพื้นฐานสำหรับยื่นขอรับรอง GAP',
                      message: 'ช่องที่จำเป็นคือชื่อเกษตรกรและวันเริ่มปลูก ที่เหลือกรอกภายหลังได้',
                    ),
                  FormSectionCard(
                    title: 'ผู้ปลูกและรอบการผลิต',
                    icon: AppIcons.user,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'ชื่อเกษตรกร',
                          controller: _farmer,
                          hint: 'เช่น นายสมชาย ใจดี',
                          maxLength: 100,
                          enabled: !ro,
                          validator: _validateName,
                        ),
                        const SizedBox(height: Space.lg),
                        DatePickerField(
                          label: 'วันเริ่มปลูก',
                          value: _startDate,
                          enabled: !ro,
                          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                          onChanged: (d) => setState(() {
                            _startDate = d;
                            _dirty = true;
                          }),
                        ),
                        const SizedBox(height: Space.lg),
                        AppTextField(
                          label: 'รุ่นการผลิต',
                          controller: _season,
                          hint: 'เช่น 1/2569 หรือ ฤดูฝน',
                          maxLength: 50,
                          enabled: !ro,
                        ),
                        const SizedBox(height: Space.lg),
                        AppTextField(
                          label: 'สายพันธุ์',
                          controller: _variety,
                          hint: 'เช่น ก้านแดง หางกระรอก',
                          maxLength: 100,
                          enabled: !ro,
                        ),
                      ],
                    ),
                  ),
                  FormSectionCard(
                    title: 'ระบบการผลิต',
                    icon: AppIcons.plant,
                    child: Column(
                      children: [
                        for (final (value, title, sub, icon) in _systems) ...[
                          ChoiceTile(
                            title: title,
                            subtitle: sub,
                            icon: icon,
                            selected: _farmingSystem == value,
                            onTap: ro
                                ? null
                                : () => setState(() {
                                      _farmingSystem = value;
                                      _dirty = true;
                                    }),
                          ),
                          const SizedBox(height: Space.sm),
                        ],
                      ],
                    ),
                  ),
                  FormSectionCard(
                    title: 'น้ำที่ใช้ในแปลง',
                    icon: AppIcons.water,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FormDropdownWithOther(
                          label: 'แหล่งน้ำ',
                          hint: 'เลือกแหล่งน้ำหลัก',
                          options: _waterSources,
                          value: _waterSource,
                          enabled: !ro,
                          onChanged: (v) => setState(() {
                            _waterSource = v;
                            _dirty = true;
                          }),
                        ),
                        const SizedBox(height: Space.lg),
                        FormDropdownWithOther(
                          label: 'ระบบให้น้ำ',
                          hint: 'เลือกวิธีให้น้ำ',
                          options: _irrigation,
                          value: _irrigationSystem,
                          enabled: !ro,
                          onChanged: (v) => setState(() {
                            _irrigationSystem = v;
                            _dirty = true;
                          }),
                        ),
                        const SizedBox(height: Space.lg),
                        AppTextField(
                          label: 'หมายเหตุคุณภาพน้ำ',
                          controller: _waterNote,
                          hint: 'เช่น ผลตรวจน้ำล่าสุด หรือสิ่งที่สังเกตได้',
                          maxLines: 3,
                          minLines: 2,
                          maxLength: 200,
                          enabled: !ro,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
