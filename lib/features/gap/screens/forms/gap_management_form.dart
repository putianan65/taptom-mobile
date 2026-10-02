import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/services/database_helper.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/gap_enum_helpers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../gap_categories.dart';
import '../../widgets/gap_form_wrapper.dart';

/// 1.3 One field activity, matching the backend FieldManagement model.
/// Fields shown depend on the activity type.
class GapManagementForm extends StatefulWidget {
  const GapManagementForm({
    super.key,
    required this.plotId,
    this.existingId,
    this.existingData,
    this.isReadOnly = false,
  });

  final String plotId;
  final String? existingId;
  final Map<String, dynamic>? existingData;
  final bool isReadOnly;

  @override
  State<GapManagementForm> createState() => _GapManagementFormState();
}

class _GapManagementFormState extends State<GapManagementForm> {
  static const _types = [
    ('SOIL_PREP', 'เตรียมดิน', 'ไถพรวน ปรับหน้าดิน ใส่ปุ๋ยรองพื้น', AppIcons.plant),
    ('WATER_QUALITY', 'ตรวจคุณภาพน้ำ', 'ค่า pH ความใส กลิ่น', AppIcons.water),
    ('WEED_CONTROL', 'กำจัดวัชพืช', 'ถอนหรือตัดหญ้ารอบต้น', AppIcons.leaf),
    ('IPM_PEST_CONTROL', 'จัดการศัตรูพืช', 'สำรวจโรคและแมลง ป้องกันแบบผสมผสาน', AppIcons.safety),
    ('RISK_EVENT', 'เหตุการณ์เสี่ยง', 'น้ำท่วม ภัยแล้ง โรคระบาด', AppIcons.warning),
  ];
  static const _machines = ['รถไถเดินตาม', 'เครื่องตัดหญ้า', 'จอบ เสียม', 'กรรไกรตัดกิ่ง', 'ระบบน้ำหยด', 'เครื่องพ่นหมอก'];
  static const _materials = ['น้ำหมักชีวภาพ', 'เชื้อราไตรโคเดอร์มา', 'เชื้อบิวเวอเรีย', 'สารสะเดา', 'ปุ๋ยคอก', 'ปุ๋ยหมัก'];
  static const _water = ['ใส ไม่มีกลิ่น', 'ขุ่นเล็กน้อย', 'มีตะกอน', 'pH 5.5 ถึง 6.5', 'pH ต่ำกว่า 5'];
  static const _risks = ['น้ำท่วมขัง', 'ฝนทิ้งช่วง', 'โรคใบจุด', 'หนอนกินใบ', 'เพลี้ยไฟ ไรแดง', 'พายุลมแรง'];
  static const _impacts = ['ใบเหลืองร่วง', 'ต้นแคระแกร็น', 'รากเน่า', 'ผลผลิตลดลง', 'กิ่งหัก'];
  static const _mitigations = ['ขุดร่องระบายน้ำ', 'ให้น้ำสม่ำเสมอ', 'ตัดแต่งกิ่งที่เป็นโรค', 'พ่นเชื้อราไตรโคเดอร์มา', 'ทำไม้ค้ำยัน'];

  final _gap = GapService();
  final _description = TextEditingController();
  final _worker = TextEditingController();
  String _type = 'SOIL_PREP';
  DateTime? _date;
  String _machine = '';
  String _material = '';
  String _waterQuality = '';
  String _riskType = '';
  RiskLevel? _riskLevel;
  String _impact = '';
  String _mitigation = '';

  bool _saving = false;
  bool _dirty = false;

  bool get _editing => widget.existingId != null;
  String get _draftKey => 'management_${widget.plotId}';

  @override
  void initState() {
    super.initState();
    _description.addListener(_touch);
    _worker.addListener(_touch);
    _load();
  }

  @override
  void dispose() {
    _description.dispose();
    _worker.dispose();
    super.dispose();
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _set(VoidCallback fn) => setState(() {
        fn();
        _dirty = true;
      });

  static String _strip(String text) =>
      text.replaceAll(RegExp(r'\n?\[(คุณภาพน้ำ|ประเภทความเสี่ยง): [^\]]*\]'), '').trim();

  static String? _tag(String text, String label) =>
      RegExp('\\[$label: ([^\\]]*)\\]').firstMatch(text)?.group(1);

  Future<void> _load() async {
    var data = widget.existingData;
    if (data == null && !widget.isReadOnly) {
      try {
        final draft = await DatabaseHelper.instance.getDraft(_draftKey);
        if (draft != null) data = Map<String, dynamic>.from(jsonDecode(draft.jsonData) as Map);
      } on Object catch (_) {}
    }
    if (data == null || !mounted) return;
    final d = data;
    final description = '${d['description'] ?? ''}';
    setState(() {
      _type = '${d['activityType'] ?? 'SOIL_PREP'}';
      _date = DateTime.tryParse('${d['activityDate'] ?? ''}')?.toLocal();
      _description.text = _strip(description);
      _worker.text = '${d['workerName'] ?? ''}';
      _machine = '${d['machineUsed'] ?? ''}';
      _material = '${d['chemicalUsed'] ?? ''}';
      _waterQuality = '${d['waterQuality'] ?? _tag(description, 'คุณภาพน้ำ') ?? ''}';
      _riskType = '${d['riskType'] ?? _tag(description, 'ประเภทความเสี่ยง') ?? ''}';
      _riskLevel = RiskLevel.values.where((r) => r.apiValue == d['riskLevel']).firstOrNull;
      _impact = '${d['riskImpact'] ?? ''}';
      _mitigation = '${d['mitigation'] ?? ''}';
      _dirty = false;
    });
  }

  /// Water quality and risk type have no columns of their own on the
  /// backend, so they travel as tagged lines inside the description.
  Map<String, dynamic> _data() {
    final description = [
      if (_description.text.trim().isNotEmpty) _description.text.trim(),
      if (_type == 'WATER_QUALITY' && _waterQuality.isNotEmpty) '[คุณภาพน้ำ: $_waterQuality]',
      if (_type == 'RISK_EVENT' && _riskType.isNotEmpty) '[ประเภทความเสี่ยง: $_riskType]',
    ].join('\n');
    final risk = _type == 'RISK_EVENT';
    final chemical = _type == 'IPM_PEST_CONTROL' || _type == 'WEED_CONTROL';
    return {
      'activityType': _type,
      'activityDate': (_date ?? DateTime.now()).toIso8601String(),
      if (description.isNotEmpty) 'description': description,
      if (_worker.text.trim().isNotEmpty) 'workerName': _worker.text.trim(),
      if (_machine.isNotEmpty) 'machineUsed': _machine,
      if (chemical && _material.isNotEmpty) 'chemicalUsed': _material,
      if (risk && _riskLevel != null) 'riskLevel': _riskLevel!.apiValue,
      if (risk && _impact.isNotEmpty) 'riskImpact': _impact,
      if (risk && _mitigation.isNotEmpty) 'mitigation': _mitigation,
    };
  }

  Future<void> _saveDraft() async {
    await DatabaseHelper.instance.saveDraft(_draftKey, jsonEncode(_data()));
    if (!mounted) return;
    setState(() => _dirty = false);
    AppToast.info(context, 'บันทึกร่างไว้ในเครื่องแล้ว');
  }

  Future<void> _save() async {
    if (_date == null) {
      AppToast.error(context, 'เลือกวันที่ทำกิจกรรม');
      return;
    }
    final missing = [
      if (_description.text.trim().isEmpty) 'รายละเอียด',
      if (_worker.text.trim().isEmpty) 'ผู้ปฏิบัติงาน',
      if (_type == 'WATER_QUALITY' && _waterQuality.isEmpty) 'คุณภาพน้ำ',
      if ((_type == 'IPM_PEST_CONTROL' || _type == 'WEED_CONTROL') && _material.isEmpty) 'สารหรือชีวภัณฑ์',
      if (_type == 'RISK_EVENT' && _riskLevel == null) 'ระดับความเสี่ยง',
    ];
    if (missing.isNotEmpty &&
        !await showIncompleteFieldsDialog(context, formTitle: 'การจัดการแปลง', incompleteFields: missing)) {
      return;
    }
    if (!mounted) return;

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      if (_editing) {
        await _gap.updateActivity(widget.plotId, widget.existingId!, _data());
        await _gap.notifyAdminOnEdit(plotId: widget.plotId, formType: 'การจัดการแปลง', recordId: widget.existingId!);
      } else {
        await _gap.addActivity(widget.plotId, _data());
      }
      GapService.invalidate(widget.plotId);
      await DatabaseHelper.instance.deleteDraft(_draftKey);
      if (!mounted) return;
      setState(() => _dirty = false);
      await showGapSuccessDialog(
        context,
        formTitle: _editing ? 'แก้ไขกิจกรรมแล้ว' : 'บันทึกกิจกรรมแล้ว',
        formSubtitle: 'บันทึกทุกครั้งที่ทำงานในแปลง เพื่อให้ประวัติครบถ้วน',
      );
      navigator.pop(true);
    } on Object catch (e) {
      if (mounted) AppToast.error(context, ErrorUtils.getReadableError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ro = widget.isReadOnly;
    final p = context.palette;
    Widget pick(String label, String hint, List<String> options, String value, ValueChanged<String> set) =>
        Padding(
          padding: const EdgeInsets.only(bottom: Space.lg),
          child: FormDropdownWithOther(
            label: label,
            hint: hint,
            options: options,
            value: value,
            enabled: !ro,
            onChanged: (v) => _set(() => set(v)),
          ),
        );

    return GapFormWrapper(
      category: GapCategory.management,
      subtitle: _editing ? 'แก้ไขกิจกรรม' : null,
      onSave: _save,
      onSaveDraft: _editing ? null : _saveDraft,
      isSaving: _saving,
      hasUnsavedChanges: _dirty,
      readOnly: ro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormSectionCard(
            title: 'ทำอะไรในแปลง',
            icon: AppIcons.fieldWork,
            child: Column(
              children: [
                for (final (value, title, sub, icon) in _types) ...[
                  ChoiceTile(
                    title: title,
                    subtitle: sub,
                    icon: icon,
                    selected: _type == value,
                    onTap: ro ? null : () => _set(() => _type = value),
                  ),
                  const SizedBox(height: Space.sm),
                ],
              ],
            ),
          ),
          FormSectionCard(
            title: 'รายละเอียด',
            icon: AppIcons.note,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DatePickerField(
                  label: 'วันที่ทำ',
                  value: _date,
                  enabled: !ro,
                  onChanged: (d) => _set(() => _date = d),
                ),
                const SizedBox(height: Space.lg),
                AppTextField(
                  label: 'สิ่งที่ทำ',
                  controller: _description,
                  hint: 'เช่น ตัดหญ้ารอบโคนต้นทั้งแปลง',
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 300,
                  enabled: !ro,
                ),
                const SizedBox(height: Space.lg),
                AppTextField(label: 'ผู้ปฏิบัติงาน', controller: _worker, hint: 'เช่น นายสมชาย', enabled: !ro),
                const SizedBox(height: Space.lg),
                pick('เครื่องมือหรืออุปกรณ์', 'เลือกอุปกรณ์', _machines, _machine, (v) => _machine = v),
                if (_type == 'IPM_PEST_CONTROL' || _type == 'WEED_CONTROL')
                  pick('สารหรือชีวภัณฑ์ที่ใช้', 'เลือกสาร', _materials, _material, (v) => _material = v),
                if (_type == 'WATER_QUALITY')
                  pick('ผลตรวจน้ำ', 'เลือกผลตรวจ', _water, _waterQuality, (v) => _waterQuality = v),
              ],
            ),
          ),
          if (_type == 'RISK_EVENT')
            FormSectionCard(
              title: 'ประเมินความเสี่ยง',
              icon: AppIcons.warning,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  pick('เหตุการณ์', 'เลือกเหตุการณ์', _risks, _riskType, (v) => _riskType = v),
                  const FieldLabel('ระดับความรุนแรง'),
                  Row(
                    children: [
                      for (final (i, level) in RiskLevel.values.indexed) ...[
                        if (i > 0) const SizedBox(width: Space.sm),
                        Expanded(
                          child: ChoiceChip(
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(
                                switch (level) {
                                  RiskLevel.low => 'ต่ำ',
                                  RiskLevel.medium => 'กลาง',
                                  RiskLevel.high => 'สูง',
                                },
                                textAlign: TextAlign.center,
                              ),
                            ),
                            selected: _riskLevel == level,
                            selectedColor: switch (level) {
                              RiskLevel.low => p.successSoft,
                              RiskLevel.medium => p.warningSoft,
                              RiskLevel.high => p.dangerSoft,
                            },
                            onSelected: ro ? null : (_) => _set(() => _riskLevel = level),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  pick('ผลกระทบ', 'เลือกผลกระทบ', _impacts, _impact, (v) => _impact = v),
                  pick('การแก้ไข', 'เลือกวิธีแก้ไข', _mitigations, _mitigation, (v) => _mitigation = v),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
