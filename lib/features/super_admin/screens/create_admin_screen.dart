import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/services/super_admin_service.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/widgets/location_selector.dart';

/// Adds a field officer and the territory they will look after.
class CreateAdminScreen extends StatefulWidget {
  const CreateAdminScreen({super.key});

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _job = TextEditingController(text: 'นักวิชาการส่งเสริมการเกษตร');
  final _pin = TextEditingController();
  final _day = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();

  String? _region;
  String? _province;
  String? _district;
  String? _subDistrict;
  bool _saving = false;
  String? _birthdayError;
  String? _areaError;

  @override
  void dispose() {
    for (final c in [_phone, _first, _last, _job, _pin, _day, _month, _year]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final birthday = ThaiDate.parseParts(_day.text, _month.text, _year.text);
    setState(() {
      _birthdayError = birthday == null ? 'กรอกวันเกิดให้ครบและถูกต้อง' : null;
      _areaError = (_region ?? '').isEmpty ? 'เลือกพื้นที่ที่รับผิดชอบอย่างน้อยระดับภูมิภาค' : null;
    });
    final valid = _form.currentState!.validate();
    if (!valid || birthday == null || _areaError != null) return;

    setState(() => _saving = true);
    try {
      await context.read<SuperAdminService>().createAdmin(
            phone: _phone.text.trim(),
            firstName: _first.text.trim(),
            lastName: _last.text.trim(),
            job: _job.text.trim(),
            region: _region!,
            province: _province,
            district: _district,
            subDistrict: _subDistrict,
            birthday: '${birthday.day.toString().padLeft(2, '0')}/'
                '${birthday.month.toString().padLeft(2, '0')}/${birthday.year}',
            pin: _pin.text,
          );
      if (!mounted) return;
      AppToast.success(context, 'เพิ่ม ${_first.text.trim()} เป็นเจ้าหน้าที่แล้ว');
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v, String label) =>
      (v ?? '').trim().isEmpty ? 'กรอก$label' : null;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PageScaffold(
      title: 'เพิ่มเจ้าหน้าที่',
      subtitle: 'บัญชีสำหรับเจ้าหน้าที่ภาคสนาม',
      bottomBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.md),
          child: AppButton(
            label: 'สร้างบัญชี',
            icon: AppIcons.userAdd,
            expand: true,
            loading: _saving,
            onPressed: _submit,
          ),
        ),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: ContentWidth(
            maxWidth: Breakpoints.maxForm,
            padding: EdgeInsets.zero,
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(title: 'ข้อมูลเจ้าหน้าที่'),
                  AppTextField(
                    label: 'เบอร์โทรศัพท์',
                    controller: _phone,
                    icon: AppIcons.phone,
                    hint: '08X XXX XXXX',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (v) => RegExp(r'^0\d{9}$').hasMatch(v ?? '')
                        ? null
                        : 'เบอร์โทรขึ้นต้นด้วย 0 และมี 10 หลัก',
                  ),
                  const SizedBox(height: Space.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'ชื่อ',
                          controller: _first,
                          validator: (v) => _required(v, 'ชื่อ'),
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: AppTextField(
                          label: 'นามสกุล',
                          controller: _last,
                          validator: (v) => _required(v, 'นามสกุล'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  AppTextField(
                    label: 'ตำแหน่ง',
                    controller: _job,
                    icon: AppIcons.officer,
                    validator: (v) => _required(v, 'ตำแหน่ง'),
                  ),
                  const SizedBox(height: Space.lg),
                  const FieldLabel('วันเกิด'),
                  ThaiDateFields(day: _day, month: _month, year: _year),
                  if (_birthdayError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        _birthdayError!,
                        style: context.text.bodySmall?.copyWith(color: p.danger),
                      ),
                    ),
                  const SizedBox(height: Space.xxl),
                  const SectionHeader(
                    title: 'พื้นที่รับผิดชอบ',
                    subtitle: 'เลือกละเอียดถึงระดับที่เจ้าหน้าที่ดูแลจริง',
                  ),
                  LocationSelector(
                    onChanged: (region, province, district, sub) => setState(() {
                      _region = region;
                      _province = province;
                      _district = district;
                      _subDistrict = sub;
                      _areaError = null;
                    }),
                  ),
                  if (_areaError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        _areaError!,
                        style: context.text.bodySmall?.copyWith(color: p.danger),
                      ),
                    ),
                  const SizedBox(height: Space.xxl),
                  const SectionHeader(title: 'การเข้าใช้งาน'),
                  AppTextField(
                    label: 'PIN เริ่มต้น',
                    controller: _pin,
                    icon: AppIcons.lock,
                    obscure: true,
                    helper: 'ตัวเลข 4 ถึง 8 หลัก แจ้งเจ้าหน้าที่ผ่านช่องทางที่ปลอดภัย',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    validator: (v) =>
                        RegExp(r'^\d{4,8}$').hasMatch(v ?? '') ? null : 'PIN เป็นตัวเลข 4 ถึง 8 หลัก',
                  ),
                  const SizedBox(height: Space.lg),
                  const InlineBanner(
                    tone: Tone.info,
                    title: 'เจ้าหน้าที่เข้าสู่ระบบด้วยเบอร์โทรและวันเกิด',
                    message: 'จากนั้นยืนยันตัวตนด้วย PIN ทุกครั้ง',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
