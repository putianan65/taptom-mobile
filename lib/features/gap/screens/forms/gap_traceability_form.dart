import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/gap_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/thai_date.dart';
import '../../../../core/widgets/widgets.dart';
import '../../gap_categories.dart';
import '../../widgets/gap_form_wrapper.dart';

/// 1.7 Lots and their QR codes. Buyers scan the code on the package to see
/// where and how the leaves were grown.
class GapTraceabilityForm extends StatefulWidget {
  const GapTraceabilityForm({super.key, required this.plotId, this.isReadOnly = false});

  final String plotId;
  final bool isReadOnly;

  /// Public link encoded in every lot's QR code.
  static String publicLink(String lotNumber) => 'https://taptom.app/traceability/$lotNumber';

  @override
  State<GapTraceabilityForm> createState() => _GapTraceabilityFormState();
}

class _GapTraceabilityFormState extends State<GapTraceabilityForm> {
  final _gap = GapService();
  List<Map<String, dynamic>> _lots = [];
  bool _hasHarvest = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _gap.getTraceabilityLots(widget.plotId),
        _gap.getHarvests(widget.plotId),
      ]);
      if (!mounted) return;
      setState(() {
        _lots = [
          for (final l in results[0])
            if (l is Map && (l['lotNumber'] ?? '').toString().isNotEmpty) Map<String, dynamic>.from(l),
        ];
        _hasHarvest = results[1].isNotEmpty;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorUtils.getReadableError(e);
      });
    }
  }

  Future<void> _create() async {
    final data = await showAppSheet<Map<String, dynamic>>(
      context,
      title: 'ออกเลขล็อตใหม่',
      subtitle: 'ผูกกับการเก็บเกี่ยวครั้งล่าสุด',
      child: const _LotSheet(),
    );
    if (data == null || !mounted) return;
    try {
      final lot = await _gap.createLot(widget.plotId, data);
      await _load();
      if (!mounted) return;
      final number = '${lot['lotNumber'] ?? ''}';
      if (number.isNotEmpty) _showQr(number);
    } on Object catch (e) {
      if (mounted) AppToast.error(context, ErrorUtils.getReadableError(e));
    }
  }

  void _showQr(String lotNumber) {
    final link = GapTraceabilityForm.publicLink(lotNumber);
    showAppSheet<void>(
      context,
      title: 'QR ล็อต $lotNumber',
      subtitle: 'พิมพ์ติดบรรจุภัณฑ์ให้ผู้ซื้อสแกน',
      child: Padding(
        padding: EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl + MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(Space.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: Radii.card,
                border: Border.all(color: context.palette.line),
              ),
              child: QrImageView(
                data: link,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1B4427)),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF161D18),
                ),
              ),
            ),
            const SizedBox(height: Space.md),
            Text(lotNumber, style: context.text.titleLarge?.mono),
            const SizedBox(height: Space.xl),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'คัดลอกลิงก์',
                    icon: AppIcons.copy,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      AppToast.info(context, 'คัดลอกลิงก์แล้ว');
                    },
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: AppButton(
                    label: 'แชร์',
                    icon: AppIcons.share,
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: 'ตรวจสอบที่มาของผลผลิตล็อต $lotNumber\n$link'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ro = widget.isReadOnly;
    return GapFormWrapper(
      category: GapCategory.traceability,
      hasUnsavedChanges: false,
      readOnly: ro,
      saveLabel: 'เสร็จสิ้น',
      onSave: () => Navigator.of(context).pop(true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!ro)
            const FormInfoCard(
              title: 'หนึ่งล็อตต่อการส่งขายหนึ่งครั้ง',
              message: 'ออกเลขล็อตหลังบันทึกการเก็บเกี่ยว แล้วพิมพ์ QR ติดบรรจุภัณฑ์',
            ),
          if (!ro && !_loading) ...[
            if (_hasHarvest)
              GapAddButton(label: 'ออกเลขล็อตใหม่', icon: AppIcons.qr, onPressed: _create)
            else
              const InlineBanner(
                tone: Tone.warning,
                title: 'ยังไม่มีบันทึกการเก็บเกี่ยว',
                message: 'บันทึกหมวด 1.4 ก่อน จึงจะออกเลขล็อตได้',
              ),
            const SizedBox(height: Space.lg),
          ],
          if (_loading)
            const SkeletonList(count: 2, thumbnail: false)
          else if (_error != null)
            ErrorState(message: _error, onRetry: _load, compact: true)
          else if (_lots.isEmpty)
            const EmptyState(
              title: 'ยังไม่มีล็อต',
              message: 'ล็อตที่ออกแล้วจะแสดงที่นี่พร้อม QR สำหรับพิมพ์',
              compact: true,
            )
          else
            for (final lot in _lots)
              Builder(builder: (context) {
                final number = '${lot['lotNumber']}';
                final date = DateTime.tryParse('${lot['harvestDate'] ?? lot['productionDate'] ?? lot['createdAt'] ?? ''}');
                final qty = lot['quantity'] ?? lot['batchSize'] ?? lot['yieldAmount'];
                final unit = lot['unit'] ?? lot['batchUnit'] ?? lot['yieldUnit'] ?? 'กก.';
                return GapRecordTile(
                  icon: AppIcons.qr,
                  title: number,
                  subtitle: [
                    if (date != null) ThaiDate.short(date.toLocal()),
                    if (qty != null) '$qty $unit',
                    if ((lot['destination'] ?? '').toString().isNotEmpty) 'ส่ง ${lot['destination']}',
                  ].join(' · '),
                  meta: lot['isExported'] == true ? 'ส่งออกแล้ว' : null,
                  onTap: () => _showQr(number),
                  trailing: Icon(AppIcons.chevronRight, size: 18, color: context.palette.inkSubtle),
                );
              }),
        ],
      ),
    );
  }
}

class _LotSheet extends StatefulWidget {
  const _LotSheet();

  @override
  State<_LotSheet> createState() => _LotSheetState();
}

class _LotSheetState extends State<_LotSheet> {
  final _form = GlobalKey<FormState>();
  final _size = TextEditingController();
  final _unit = TextEditingController(text: 'กก.');
  final _destination = TextEditingController();
  DateTime _produced = DateTime.now();
  DateTime _expires = DateTime.now().add(const Duration(days: 180));
  bool _export = false;

  @override
  void dispose() {
    _size.dispose();
    _unit.dispose();
    _destination.dispose();
    super.dispose();
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop({
      'productionDate': _ymd(_produced),
      'expiryDate': _ymd(_expires),
      'batchSize': double.parse(_size.text.trim()),
      'batchUnit': _unit.text.trim(),
      if (_destination.text.trim().isNotEmpty) 'destination': _destination.text.trim(),
      'isExported': _export,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.xl,
        0,
        Space.xl,
        Space.xl + MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DatePickerField(
                      label: 'วันผลิต',
                      value: _produced,
                      onChanged: (d) => setState(() => _produced = d),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: DatePickerField(
                      label: 'ควรใช้ก่อน',
                      value: _expires,
                      firstDate: _produced,
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                      onChanged: (d) => setState(() => _expires = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      label: 'ขนาดล็อต',
                      controller: _size,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      validator: (v) => (double.tryParse((v ?? '').trim()) ?? 0) <= 0 ? 'ใส่จำนวน' : null,
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(flex: 2, child: AppTextField(label: 'หน่วย', controller: _unit)),
                ],
              ),
              const SizedBox(height: Space.lg),
              AppTextField(label: 'ปลายทาง', controller: _destination, hint: 'เช่น ตลาดไท หรือ โรงงานสกัด'),
              const SizedBox(height: Space.md),
              ChoiceTile(
                title: 'ส่งออกต่างประเทศ',
                selected: _export,
                onTap: () => setState(() => _export = !_export),
              ),
              const SizedBox(height: Space.xl),
              AppButton(label: 'ออกเลขล็อต', icon: AppIcons.qr, expand: true, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
