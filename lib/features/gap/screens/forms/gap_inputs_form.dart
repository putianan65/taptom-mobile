import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/gap_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../gap_categories.dart';
import '../../widgets/gap_form_wrapper.dart';

/// 1.2 Production inputs: planting material, fertiliser and crop
/// protection, each saved as its own record.
class GapInputsForm extends StatefulWidget {
  const GapInputsForm({
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
  State<GapInputsForm> createState() => _GapInputsFormState();
}

class _InputKind {
  const _InputKind(this.type, this.label, this.icon, this.examples);

  final String type;
  final String label;
  final IconData icon;
  final (String name, String source, String unit) examples;
}

class _GapInputsFormState extends State<GapInputsForm> {
  static const _kinds = [
    _InputKind('SEED', 'กิ่งและต้นพันธุ์', AppIcons.plant, ('กิ่งพันธุ์ก้านแดง', 'แปลงพันธุ์บ้านหนองปลิง', 'ต้น')),
    _InputKind('FERTILIZER', 'ปุ๋ยและสารบำรุง', AppIcons.inputs, ('ปุ๋ยอินทรีย์มูลไก่', 'สหกรณ์การเกษตรวังทอง', 'กก.')),
    _InputKind('PESTICIDE', 'สารป้องกันศัตรูพืช', AppIcons.safety, ('สารสกัดสะเดา', 'ร้านเกษตรท่าเรือ', 'ลิตร')),
  ];

  final _gap = GapService();
  List<Map<String, dynamic>> _inputs = [];
  bool _loading = true;
  String _type = 'SEED';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _gap.getInputs(widget.plotId);
      if (!mounted) return;
      setState(() {
        _inputs = [for (final i in data) if (i is Map) Map<String, dynamic>.from(i)];
        _loading = false;
      });
    } on Object catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(_InputKind kind) async {
    final data = await showAppSheet<Map<String, dynamic>>(
      context,
      title: 'เพิ่ม${kind.label}',
      child: _InputSheet(kind: kind),
    );
    if (data == null || !mounted) return;
    try {
      // The API rejects a 'date' property on inputs; the server stamps it.
      await _gap.addInput(widget.plotId, {'type': kind.type, ...data});
      GapService.invalidate(widget.plotId);
      await _load();
      if (mounted) AppToast.success(context, 'เพิ่ม${data['name']}แล้ว');
    } on Object catch (e) {
      if (mounted) AppToast.error(context, ErrorUtils.getReadableError(e));
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'ลบ ${item['name'] ?? 'รายการนี้'}?',
      confirmLabel: 'ลบ',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await _gap.deleteInput(widget.plotId, '${item['id']}');
      GapService.invalidate(widget.plotId);
      await _load();
    } on Object catch (e) {
      if (mounted) AppToast.error(context, ErrorUtils.getReadableError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kinds.firstWhere((k) => k.type == _type);
    final items = _inputs.where((i) => i['type'] == _type).toList();

    return GapFormWrapper(
      category: GapCategory.inputs,
      hasUnsavedChanges: false,
      readOnly: widget.isReadOnly,
      saveLabel: 'เสร็จสิ้น',
      onSave: () => Navigator.of(context).pop(true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormInfoCard(
            message: 'ทุกรายการบันทึกทันทีที่กดเพิ่ม ไม่ต้องกดบันทึกซ้ำ',
            title: 'บันทึกทุกครั้งที่ซื้อหรือใช้ปัจจัยการผลิต',
          ),
          SegmentedTabs<String>(
            value: _type,
            onChanged: (v) => setState(() => _type = v),
            segments: [
              for (final k in _kinds)
                (k.type, '${k.label.split('และ').first} ${_inputs.where((i) => i['type'] == k.type).length}'),
            ],
          ),
          const SizedBox(height: Space.lg),
          if (_type == 'PESTICIDE')
            const Padding(
              padding: EdgeInsets.only(bottom: Space.lg),
              child: InlineBanner(
                tone: Tone.warning,
                title: 'เว้นระยะก่อนเก็บเกี่ยว',
                message: 'หยุดใช้สารอย่างน้อย 7 ถึง 15 วันก่อนเก็บใบ ตามฉลากของแต่ละผลิตภัณฑ์',
              ),
            ),
          if (!widget.isReadOnly) ...[
            GapAddButton(label: 'เพิ่ม${kind.label}', onPressed: () => _add(kind)),
            const SizedBox(height: Space.lg),
          ],
          if (_loading)
            const SkeletonList(count: 2, thumbnail: false)
          else if (items.isEmpty)
            EmptyState(
              title: 'ยังไม่มี${kind.label}',
              message: 'ตัวอย่าง: ${kind.examples.$1} จาก ${kind.examples.$2}',
              compact: true,
            )
          else
            for (final item in items)
              GapRecordTile(
                icon: kind.icon,
                title: '${item['name'] ?? '-'}',
                subtitle: '${item['amount'] ?? item['quantity'] ?? '-'} ${item['unit'] ?? ''}'
                    '${(item['source'] ?? item['brand']) != null ? ' · ${item['source'] ?? item['brand']}' : ''}',
                onDelete: widget.isReadOnly ? null : () => _delete(item),
              ),
        ],
      ),
    );
  }
}

class _InputSheet extends StatefulWidget {
  const _InputSheet({required this.kind});

  final _InputKind kind;

  @override
  State<_InputSheet> createState() => _InputSheetState();
}

class _InputSheetState extends State<_InputSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _source = TextEditingController();
  final _amount = TextEditingController();
  late final _unit = TextEditingController(text: widget.kind.examples.$3);

  @override
  void dispose() {
    for (final c in [_name, _source, _amount, _unit]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop({
      'name': _name.text.trim(),
      'source': _source.text.trim(),
      'amount': double.parse(_amount.text.trim()),
      'unit': _unit.text.trim(),
    });
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'กรอกข้อมูลช่องนี้' : null;

  @override
  Widget build(BuildContext context) {
    final ex = widget.kind.examples;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.xl,
        0,
        Space.xl,
        Space.xl + MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(label: 'ชื่อหรือชนิด', controller: _name, hint: 'เช่น ${ex.$1}', validator: _required),
            const SizedBox(height: Space.lg),
            AppTextField(label: 'แหล่งที่มา', controller: _source, hint: 'เช่น ${ex.$2}', validator: _required),
            const SizedBox(height: Space.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    label: 'ปริมาณ',
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: (v) {
                      final n = double.tryParse((v ?? '').trim());
                      return n == null || n <= 0 ? 'ใส่จำนวนมากกว่า 0' : null;
                    },
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(flex: 2, child: AppTextField(label: 'หน่วย', controller: _unit, validator: _required)),
              ],
            ),
            const SizedBox(height: Space.xl),
            AppButton(label: 'เพิ่มรายการ', icon: AppIcons.add, expand: true, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
