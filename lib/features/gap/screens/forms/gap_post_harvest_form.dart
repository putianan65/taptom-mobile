import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/database_helper.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/thai_date.dart';
import '../../../../core/widgets/widgets.dart';
import '../../gap_categories.dart';
import '../../widgets/gap_form_wrapper.dart';

/// 1.5 What happened to one harvest after picking: sorting, drying,
/// packing and storage. Post-harvest records belong to a harvest, so one
/// must exist first.
class GapPostHarvestForm extends StatefulWidget {
  const GapPostHarvestForm({
    super.key,
    required this.plotId,
    this.harvestId,
    this.existingId,
    this.existingData,
    this.isReadOnly = false,
  });

  final String plotId;
  final String? harvestId;
  final String? existingId;
  final Map<String, dynamic>? existingData;
  final bool isReadOnly;

  @override
  State<GapPostHarvestForm> createState() => _GapPostHarvestFormState();
}

class _GapPostHarvestFormState extends State<GapPostHarvestForm> {
  static const _processes = ['ตากแดดธรรมชาติ', 'อบแห้งด้วยลมร้อน', 'จำหน่ายใบสด', 'บดเป็นผง', 'หมัก'];
  static const _packaging = ['ถุงพลาสติกใส 5 กก.', 'ถุงทึบแสง 10 กก.', 'ลังกระดาษ', 'ถุงสุญญากาศ', 'มัดกำ (ใบสด)'];
  static const _storage = ['โรงเรือนอากาศถ่ายเท', 'ห้องเย็น', 'โกดังเก็บสินค้า', 'ชั้นวางยกสูง'];

  final _gap = GapService();
  final _temp = TextEditingController();
  final _humidity = TextEditingController();
  List<Map<String, dynamic>> _harvests = [];
  String? _harvestId;
  DateTime? _date;
  bool _sorted = true;
  bool _washed = false;
  String _process = '';
  String _pack = '';
  String _store = '';

  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;

  bool get _editing => widget.existingId != null;
  String get _draftKey => 'post_harvest_${widget.plotId}';

  @override
  void initState() {
    super.initState();
    _temp.addListener(_touch);
    _humidity.addListener(_touch);
    _load();
  }

  @override
  void dispose() {
    _temp.dispose();
    _humidity.dispose();
    super.dispose();
  }

  void _touch() {
    if (!_loading && !_dirty) setState(() => _dirty = true);
  }

  void _set(VoidCallback fn) => setState(() {
        fn();
        _dirty = true;
      });

  Future<void> _load() async {
    try {
      final list = await _gap.getHarvests(widget.plotId);
      _harvests = [for (final h in list) if (h is Map) Map<String, dynamic>.from(h)];
    } on Object catch (_) {}

    var data = widget.existingData;
    if (data == null && !widget.isReadOnly) {
      try {
        final draft = await DatabaseHelper.instance.getDraft(_draftKey);
        if (draft != null) data = Map<String, dynamic>.from(jsonDecode(draft.jsonData) as Map);
      } on Object catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _harvestId = widget.harvestId ?? (_harvests.isNotEmpty ? '${_harvests.first['id']}' : null);
      final d = data;
      if (d != null) {
        _harvestId = d['harvestId']?.toString() ?? _harvestId;
        final description = '${d['description'] ?? ''}';
        _sorted = d['sortingDone'] as bool? ?? description.contains('คัดแยก');
        _washed = d['washingDone'] as bool? ?? description.contains('ล้าง');
        _process = '${d['processType'] ?? ''}';
        _pack = '${d['packagingType'] ?? d['packaging'] ?? ''}';
        _store = '${d['storageLocation'] ?? ''}';
        _temp.text = d['storageTemp'] == null ? '' : '${d['storageTemp']}';
        _humidity.text = d['storageHumidity'] == null ? '' : '${d['storageHumidity']}';
        _date = DateTime.tryParse('${d['processDate'] ?? ''}')?.toLocal();
      }
      _loading = false;
      _dirty = false;
    });
  }

  Map<String, dynamic> _data() {
    final temp = double.tryParse(_temp.text.trim());
    final hum = double.tryParse(_humidity.text.trim());
    final description = [if (_sorted) 'คัดแยกแล้ว', if (_washed) 'ล้างแล้ว'].join(', ');
    return {
      'processDate': (_date ?? DateTime.now()).toIso8601String(),
      if (_process.isNotEmpty) 'processType': _process,
      if (_pack.isNotEmpty) 'packagingType': _pack,
      if (_store.isNotEmpty) 'storageLocation': _store,
      if (description.isNotEmpty) 'description': description,
      'sortingDone': _sorted,
      'washingDone': _washed,
      if (temp != null && temp >= -50 && temp <= 100) 'storageTemp': temp,
      if (hum != null && hum >= 0 && hum <= 100) 'storageHumidity': hum,
    };
  }

  Future<void> _saveDraft() async {
    await DatabaseHelper.instance.saveDraft(_draftKey, jsonEncode(_data()));
    if (!mounted) return;
    setState(() => _dirty = false);
    AppToast.info(context, 'บันทึกร่างไว้ในเครื่องแล้ว');
  }

  Future<void> _save() async {
    if (_harvestId == null) {
      AppToast.error(context, 'เลือกรอบการเก็บเกี่ยวก่อน');
      return;
    }
    if (_date == null) {
      AppToast.error(context, 'เลือกวันที่ดำเนินการ');
      return;
    }
    final missing = [
      if (_process.isEmpty) 'วิธีแปรรูป',
      if (_pack.isEmpty) 'บรรจุภัณฑ์',
      if (_store.isEmpty) 'สถานที่เก็บ',
    ];
    if (missing.isNotEmpty &&
        !await showIncompleteFieldsDialog(context, formTitle: 'หลังการเก็บเกี่ยว', incompleteFields: missing)) {
      return;
    }
    if (!mounted) return;

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      if (_editing) {
        await _gap.updatePostHarvest(_harvestId!, widget.existingId!, _data());
        await _gap.notifyAdminOnEdit(
          plotId: widget.plotId,
          formType: 'การจัดการหลังเก็บเกี่ยว',
          recordId: widget.existingId!,
        );
      } else {
        await _gap.addPostHarvest(_harvestId!, _data());
      }
      GapService.invalidate(widget.plotId);
      await DatabaseHelper.instance.deleteDraft(_draftKey);
      if (!mounted) return;
      setState(() => _dirty = false);
      await showGapSuccessDialog(
        context,
        formTitle: _editing ? 'แก้ไขข้อมูลแล้ว' : 'บันทึกหลังการเก็บเกี่ยวแล้ว',
        formSubtitle: 'ข้อมูลนี้จะแสดงในรายงานตรวจสอบย้อนกลับของล็อต',
      );
      navigator.pop(true);
    } on Object catch (e) {
      if (mounted) AppToast.error(context, ErrorUtils.getReadableError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _harvestLabel(Map<String, dynamic> h) {
    final date = DateTime.tryParse('${h['harvestDate'] ?? ''}');
    return [
      if (date != null) ThaiDate.short(date.toLocal()),
      '${h['yieldAmount'] ?? '-'} ${h['yieldUnit'] ?? 'กก.'}',
      if ((h['lotNumber'] ?? '').toString().isNotEmpty) '${h['lotNumber']}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final ro = widget.isReadOnly;
    if (!_loading && _harvests.isEmpty && !_editing) {
      return const GapFormWrapper(
        category: GapCategory.postHarvest,
        hasUnsavedChanges: false,
        child: AppCard(
          child: EmptyState(
            title: 'ต้องมีการเก็บเกี่ยวก่อน',
            message: 'บันทึกหมวด 1.4 การเก็บเกี่ยวอย่างน้อยหนึ่งครั้ง แล้วจึงบันทึกการจัดการหลังเก็บเกี่ยว',
            mood: MascotMood.think,
          ),
        ),
      );
    }

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

    Widget number(String label, TextEditingController c, String suffix) => Expanded(
          child: AppTextField(
            label: label,
            controller: c,
            hint: suffix,
            enabled: !ro,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
          ),
        );

    return GapFormWrapper(
      category: GapCategory.postHarvest,
      subtitle: _editing ? 'แก้ไขการจัดการหลังเก็บเกี่ยว' : null,
      onSave: _save,
      onSaveDraft: _editing ? null : _saveDraft,
      isSaving: _saving,
      hasUnsavedChanges: _dirty,
      readOnly: ro,
      child: _loading
          ? const SkeletonList(count: 3, thumbnail: false)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormSectionCard(
                  title: 'รอบการเก็บเกี่ยว',
                  icon: AppIcons.harvest,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _harvests.any((h) => '${h['id']}' == _harvestId) ? _harvestId : null,
                        isExpanded: true,
                        hint: const Text('เลือกรอบที่เก็บ'),
                        items: [
                          for (final h in _harvests)
                            DropdownMenuItem(
                              value: '${h['id']}',
                              child: Text(_harvestLabel(h), overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: ro || _editing ? null : (v) => _set(() => _harvestId = v),
                      ),
                      const SizedBox(height: Space.lg),
                      DatePickerField(
                        label: 'วันที่ดำเนินการ',
                        value: _date,
                        enabled: !ro,
                        onChanged: (d) => _set(() => _date = d),
                      ),
                    ],
                  ),
                ),
                FormSectionCard(
                  title: 'คัดแยกและทำความสะอาด',
                  icon: AppIcons.checklist,
                  child: Column(
                    children: [
                      ChoiceTile(
                        title: 'คัดแยกใบเสียออกแล้ว',
                        subtitle: 'แยกใบเหลือง ใบเป็นโรค และสิ่งปนเปื้อน',
                        selected: _sorted,
                        onTap: ro ? null : () => _set(() => _sorted = !_sorted),
                      ),
                      const SizedBox(height: Space.sm),
                      ChoiceTile(
                        title: 'ล้างด้วยน้ำสะอาดแล้ว',
                        subtitle: 'ไม่จำเป็นถ้าตากแห้งทันที เพื่อลดเชื้อรา',
                        selected: _washed,
                        onTap: ro ? null : () => _set(() => _washed = !_washed),
                      ),
                    ],
                  ),
                ),
                FormSectionCard(
                  title: 'แปรรูปและบรรจุ',
                  icon: AppIcons.postHarvest,
                  child: Column(
                    children: [
                      pick('วิธีแปรรูป', 'เลือกวิธี', _processes, _process, (v) => _process = v),
                      pick('บรรจุภัณฑ์', 'เลือกบรรจุภัณฑ์', _packaging, _pack, (v) => _pack = v),
                    ],
                  ),
                ),
                FormSectionCard(
                  title: 'การเก็บรักษา',
                  icon: AppIcons.thermometer,
                  child: Column(
                    children: [
                      pick('สถานที่เก็บ', 'เลือกสถานที่', _storage, _store, (v) => _store = v),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          number('อุณหภูมิ (°C)', _temp, 'เช่น 28'),
                          const SizedBox(width: Space.md),
                          number('ความชื้น (%)', _humidity, 'เช่น 60'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
