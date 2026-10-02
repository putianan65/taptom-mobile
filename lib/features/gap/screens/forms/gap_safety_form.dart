import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/database_helper.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../gap_categories.dart';
import '../../widgets/gap_form_wrapper.dart';

/// 1.6 Worker training and on-farm hygiene, matching the backend
/// WorkerTraining model.
class GapSafetyForm extends StatefulWidget {
  const GapSafetyForm({
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
  State<GapSafetyForm> createState() => _GapSafetyFormState();
}

class _GapSafetyFormState extends State<GapSafetyForm> {
  static const _topics = [
    'การใช้ชีวภัณฑ์และสมุนไพรควบคุมศัตรูพืช',
    'สุขลักษณะส่วนบุคคลระหว่างเก็บเกี่ยว',
    'การปฐมพยาบาลเบื้องต้น',
    'การใช้เครื่องจักรอย่างปลอดภัย',
    'การจัดการขยะและของเสีย',
    'มาตรฐาน GAP พืชสมุนไพร',
  ];
  static const _trainers = ['เจ้าหน้าที่เกษตรอำเภอ', 'หมอดินอาสา', 'ผู้นำชุมชน', 'วิทยากรภายนอก', 'อบรมออนไลน์'];
  static const _statuses = [('COMPLETED', 'อบรมแล้ว'), ('PLANNED', 'วางแผนไว้'), ('CANCELLED', 'ยกเลิก')];
  static const _flags = [
    ('FIRST_AID', 'มีชุดปฐมพยาบาล', 'พร้อมใช้และไม่หมดอายุ', 'มีชุดปฐมพยาบาล'),
    ('PROTECTIVE_GEAR', 'มีอุปกรณ์ป้องกัน', 'ถุงมือ หน้ากาก รองเท้าบูท', 'มีอุปกรณ์ป้องกัน'),
    ('TOILET', 'มีห้องน้ำถูกสุขลักษณะ', 'อยู่ห่างจากแปลงและแหล่งน้ำ', 'มีห้องน้ำถูกสุขลักษณะ'),
    ('WASHING_STATION', 'มีจุดล้างมือ', 'มีน้ำสะอาดและสบู่', 'มีจุดล้างมือ'),
  ];

  final _gap = GapService();
  final _attendees = TextEditingController();
  DateTime? _date;
  String _status = 'COMPLETED';
  String _topic = '';
  String _trainer = '';
  final Set<String> _hygiene = {'FIRST_AID', 'PROTECTIVE_GEAR', 'TOILET', 'WASHING_STATION'};

  bool _saving = false;
  bool _dirty = false;

  bool get _editing => widget.existingId != null;
  String get _draftKey => 'safety_${widget.plotId}';

  @override
  void initState() {
    super.initState();
    _attendees.addListener(_touch);
    _load();
  }

  @override
  void dispose() {
    _attendees.dispose();
    super.dispose();
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _set(VoidCallback fn) => setState(() {
        fn();
        _dirty = true;
      });

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
      _topic = '${d['topic'] ?? d['trainingTopic'] ?? ''}';
      _trainer = '${d['trainer'] ?? ''}';
      _attendees.text = d['attendees'] == null ? '' : '${d['attendees']}';
      _status = '${d['status'] ?? 'COMPLETED'}';
      _date = DateTime.tryParse('${d['trainingDate'] ?? ''}')?.toLocal();
      final flags = d['hygieneFlags'];
      _hygiene.clear();
      if (flags is List && flags.isNotEmpty) {
        _hygiene.addAll(flags.map((e) => '$e'));
      } else {
        // Older records kept the checklist as text.
        final notes = '${d['hygieneNotes'] ?? ''}';
        for (final f in _flags) {
          if (notes.contains(f.$4)) _hygiene.add(f.$1);
        }
      }
      _dirty = false;
    });
  }

  Map<String, dynamic> _data() {
    final attendees = int.tryParse(_attendees.text.trim());
    final flags = [for (final f in _flags) if (_hygiene.contains(f.$1)) f.$1];
    return {
      'trainingDate': (_date ?? DateTime.now()).toIso8601String(),
      'status': _status,
      if (_topic.isNotEmpty) 'topic': _topic,
      if (_trainer.isNotEmpty) 'trainer': _trainer,
      if (attendees != null && attendees > 0) 'attendees': attendees,
      if (flags.isNotEmpty) 'hygieneFlags': flags,
      if (flags.isNotEmpty)
        'hygieneNotes': [for (final f in _flags) if (_hygiene.contains(f.$1)) f.$4].join(', '),
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
      AppToast.error(context, 'เลือกวันที่อบรม');
      return;
    }
    final missing = [
      if (_topic.isEmpty) 'หัวข้ออบรม',
      if (_trainer.isEmpty) 'วิทยากร',
      if (_attendees.text.trim().isEmpty) 'จำนวนผู้เข้าร่วม',
    ];
    if (missing.isNotEmpty &&
        !await showIncompleteFieldsDialog(context, formTitle: 'ความปลอดภัย', incompleteFields: missing)) {
      return;
    }
    if (!mounted) return;

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      if (_editing) {
        await _gap.updateTraining(widget.plotId, widget.existingId!, _data());
        await _gap.notifyAdminOnEdit(plotId: widget.plotId, formType: 'ความปลอดภัย', recordId: widget.existingId!);
      } else {
        await _gap.addTraining(widget.plotId, _data());
      }
      GapService.invalidate(widget.plotId);
      await DatabaseHelper.instance.deleteDraft(_draftKey);
      if (!mounted) return;
      setState(() => _dirty = false);
      await showGapSuccessDialog(
        context,
        formTitle: _editing ? 'แก้ไขการอบรมแล้ว' : 'บันทึกการอบรมแล้ว',
        formSubtitle: 'แรงงานที่ผ่านการอบรมช่วยให้ผ่านการตรวจหมวดนี้',
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
      category: GapCategory.safety,
      subtitle: _editing ? 'แก้ไขการอบรม' : null,
      onSave: _save,
      onSaveDraft: _editing ? null : _saveDraft,
      isSaving: _saving,
      hasUnsavedChanges: _dirty,
      readOnly: ro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormSectionCard(
            title: 'การอบรมแรงงาน',
            icon: AppIcons.training,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DatePickerField(
                  label: 'วันที่อบรม',
                  value: _date,
                  enabled: !ro,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  onChanged: (d) => _set(() => _date = d),
                ),
                const SizedBox(height: Space.lg),
                const FieldLabel('สถานะ'),
                SegmentedTabs<String>(
                  value: _status,
                  segments: _statuses,
                  onChanged: (v) {
                    if (!ro) _set(() => _status = v);
                  },
                ),
                const SizedBox(height: Space.lg),
                FormDropdownWithOther(
                  label: 'หัวข้อ',
                  hint: 'เลือกหัวข้ออบรม',
                  options: _topics,
                  value: _topic,
                  enabled: !ro,
                  onChanged: (v) => _set(() => _topic = v),
                ),
                const SizedBox(height: Space.lg),
                FormDropdownWithOther(
                  label: 'วิทยากร',
                  hint: 'เลือกผู้สอน',
                  options: _trainers,
                  value: _trainer,
                  enabled: !ro,
                  onChanged: (v) => _set(() => _trainer = v),
                ),
                const SizedBox(height: Space.lg),
                AppTextField(
                  label: 'จำนวนผู้เข้าร่วม (คน)',
                  controller: _attendees,
                  hint: 'เช่น 5',
                  enabled: !ro,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                ),
              ],
            ),
          ),
          FormSectionCard(
            title: 'สุขลักษณะในแปลง',
            example: 'เลือกสิ่งที่มีพร้อมใช้งาน',
            icon: AppIcons.safety,
            child: Column(
              children: [
                for (final (code, title, sub, _) in _flags) ...[
                  ChoiceTile(
                    title: title,
                    subtitle: sub,
                    selected: _hygiene.contains(code),
                    onTap: ro ? null : () => _set(() => _hygiene.contains(code) ? _hygiene.remove(code) : _hygiene.add(code)),
                  ),
                  const SizedBox(height: Space.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
