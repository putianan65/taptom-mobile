import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/database_helper.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../gap_categories.dart';
import '../../widgets/gap_form_wrapper.dart';

/// 1.4 One harvest: when, by whom, how much and of what grade. Lot numbers
/// are issued later in 1.7 so a lot can bundle several harvests.
class GapHarvestForm extends StatefulWidget {
  const GapHarvestForm({
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
  State<GapHarvestForm> createState() => _GapHarvestFormState();
}

class _GapHarvestFormState extends State<GapHarvestForm> {
  static const _equipment = ['กรรไกรตัดกิ่ง', 'มีด', 'เด็ดด้วยมือ', 'ตะกร้าเก็บใบ', 'เครื่องตัด'];
  static const _grades = [
    ('A', 'เกรด A', 'ใบสมบูรณ์ ไม่มีตำหนิ'),
    ('B', 'เกรด B', 'มีตำหนิเล็กน้อย'),
    ('MIXED', 'เกรดรวม', 'คละขนาด'),
    ('INDUSTRIAL', 'เกรดโรงงาน', 'สำหรับสกัด'),
  ];
  static const _units = ['กก.', 'ตัน', 'ขีด'];

  final _gap = GapService();
  final _form = GlobalKey<FormState>();
  final _by = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String _unit = 'กก.';
  String _equipmentUsed = '';
  String? _grade;
  DateTime? _date;

  bool _saving = false;
  bool _dirty = false;

  bool get _editing => widget.existingId != null;
  String get _draftKey => 'harvest_${widget.plotId}';

  @override
  void initState() {
    super.initState();
    for (final c in [_by, _amount, _notes]) {
      c.addListener(_touch);
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in [_by, _amount, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

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
    setState(() {
      _by.text = '${d['harvestedBy'] ?? ''}' == 'ไม่ระบุ' ? '' : '${d['harvestedBy'] ?? ''}';
      _amount.text = d['yieldAmount'] == null ? '' : '${d['yieldAmount']}';
      _notes.text = '${d['notes'] ?? ''}';
      final unit = '${d['yieldUnit'] ?? ''}';
      _unit = _units.contains(unit) ? unit : (unit == 'กิโลกรัม' || unit.toUpperCase() == 'KG' ? 'กก.' : _unit);
      _equipmentUsed = '${d['equipmentUsed'] ?? ''}';
      final g = '${d['qualityGrade'] ?? ''}';
      _grade = g.isEmpty ? null : g;
      _date = DateTime.tryParse('${d['harvestDate'] ?? ''}')?.toLocal();
      _dirty = false;
    });
  }

  Map<String, dynamic> _data() => {
        'harvestDate': (_date ?? DateTime.now()).toIso8601String(),
        'harvestedBy': _by.text.trim().isEmpty ? 'ไม่ระบุ' : _by.text.trim(),
        'yieldAmount': double.tryParse(_amount.text.trim()) ?? 0.0,
        'yieldUnit': _unit,
        if (_equipmentUsed.trim().isNotEmpty) 'equipmentUsed': _equipmentUsed.trim(),
        if (_grade != null) 'qualityGrade': _grade,
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      };

  Future<void> _saveDraft() async {
    await DatabaseHelper.instance.saveDraft(_draftKey, jsonEncode(_data()));
    if (!mounted) return;
    setState(() => _dirty = false);
    AppToast.info(context, 'บันทึกร่างไว้ในเครื่องแล้ว');
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_date == null) {
      AppToast.error(context, 'เลือกวันที่เก็บเกี่ยว');
      return;
    }
    final missing = [
      if (_by.text.trim().isEmpty) 'ผู้เก็บเกี่ยว',
      if (_equipmentUsed.isEmpty) 'อุปกรณ์',
      if (_grade == null) 'เกรด',
    ];
    if (missing.isNotEmpty &&
        !await showIncompleteFieldsDialog(context, formTitle: 'การเก็บเกี่ยว', incompleteFields: missing)) {
      return;
    }
    if (!mounted) return;

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      if (_editing) {
        await _gap.updateHarvest(widget.plotId, widget.existingId!, _data());
        await _gap.notifyAdminOnEdit(plotId: widget.plotId, formType: 'การเก็บเกี่ยว', recordId: widget.existingId!);
      } else {
        await _gap.addHarvest(widget.plotId, _data());
      }
      GapService.invalidate(widget.plotId);
      await DatabaseHelper.instance.deleteDraft(_draftKey);
      if (!mounted) return;
      setState(() => _dirty = false);
      await showGapSuccessDialog(
        context,
        formTitle: _editing ? 'แก้ไขการเก็บเกี่ยวแล้ว' : 'บันทึกการเก็บเกี่ยวแล้ว',
        formSubtitle: 'ออกเลขล็อตและ QR ได้ที่หมวด 1.7',
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
    return GapFormWrapper(
      category: GapCategory.harvest,
      subtitle: _editing ? 'แก้ไขรายการเก็บเกี่ยว' : null,
      onSave: _save,
      onSaveDraft: _editing ? null : _saveDraft,
      isSaving: _saving,
      hasUnsavedChanges: _dirty,
      readOnly: ro,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormSectionCard(
              title: 'วันที่และผู้เก็บ',
              icon: AppIcons.harvest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DatePickerField(
                    label: 'วันที่เก็บเกี่ยว',
                    value: _date,
                    enabled: !ro,
                    onChanged: (d) => setState(() {
                      _date = d;
                      _dirty = true;
                    }),
                  ),
                  const SizedBox(height: Space.lg),
                  AppTextField(
                    label: 'ผู้เก็บเกี่ยว',
                    controller: _by,
                    hint: 'เช่น นายแดง หรือ คนงานชุดที่ 1',
                    enabled: !ro,
                  ),
                ],
              ),
            ),
            FormSectionCard(
              title: 'ปริมาณผลผลิต',
              icon: AppIcons.weight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      label: 'ปริมาณ',
                      controller: _amount,
                      hint: '0',
                      enabled: !ro,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        return n == null || n <= 0 ? 'ใส่จำนวนมากกว่า 0' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const FieldLabel('หน่วย'),
                        DropdownButtonFormField<String>(
                          initialValue: _unit,
                          items: [for (final u in _units) DropdownMenuItem(value: u, child: Text(u))],
                          onChanged: ro
                              ? null
                              : (v) => setState(() {
                                    _unit = v ?? _unit;
                                    _dirty = true;
                                  }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            FormSectionCard(
              title: 'คุณภาพผลผลิต',
              icon: AppIcons.star,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (code, title, sub) in _grades) ...[
                    ChoiceTile(
                      title: title,
                      subtitle: sub,
                      selected: _grade == code,
                      onTap: ro
                          ? null
                          : () => setState(() {
                                _grade = code;
                                _dirty = true;
                              }),
                    ),
                    const SizedBox(height: Space.sm),
                  ],
                  const SizedBox(height: Space.sm),
                  FormDropdownWithOther(
                    label: 'อุปกรณ์ที่ใช้',
                    hint: 'เลือกอุปกรณ์',
                    options: _equipment,
                    value: _equipmentUsed,
                    enabled: !ro,
                    onChanged: (v) => setState(() {
                      _equipmentUsed = v;
                      _dirty = true;
                    }),
                  ),
                ],
              ),
            ),
            FormSectionCard(
              title: 'หมายเหตุ',
              icon: AppIcons.note,
              child: AppTextField(
                controller: _notes,
                hint: 'เช่น ใบใหญ่ หนา สีเขียวเข้ม เก็บช่วงเช้า',
                maxLines: 3,
                minLines: 2,
                maxLength: 300,
                enabled: !ro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
