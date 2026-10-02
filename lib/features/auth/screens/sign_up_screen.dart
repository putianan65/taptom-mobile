import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/auth_layout.dart';
import '../widgets/location_selector.dart';
import '../widgets/pdpa_consent_dialog.dart';

/// Farmer registration in three short steps: who you are, where you farm,
/// and consent. Each step validates before moving on.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const _steps = ['ข้อมูลผู้สมัคร', 'ที่ตั้ง', 'ยืนยัน'];
  static const _occupations = [
    'เกษตรกร',
    'บุคคลทั่วไป',
    'เจ้าหน้าที่ส่งเสริมการเกษตร',
    'ผู้ตรวจประเมิน GAP',
    'อื่น ๆ',
  ];

  final _personalKey = GlobalKey<FormState>();
  final _locationKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _day = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  final _otherJob = TextEditingController();

  int _step = 0;
  String _occupation = _occupations.first;
  String? _dateError;
  String? _region;
  String? _province;
  String? _district;
  String? _subdistrict;
  bool _consent = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _phone, _day, _month, _year, _otherJob]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime? get _birthday => ThaiDate.parseParts(_day.text, _month.text, _year.text);

  String get _job => _occupation == 'อื่น ๆ' ? _otherJob.text.trim() : _occupation;

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      final ok = _personalKey.currentState?.validate() ?? false;
      final birthday = _birthday;
      setState(() {
        _dateError = birthday == null ? 'กรอกวัน เดือน ปีเกิดให้ถูกต้อง' : null;
      });
      if (!ok || birthday == null) return;
    } else if (_step == 1) {
      final ok = _locationKey.currentState?.validate() ?? false;
      if (!ok || _region == null || _province == null) {
        AppToast.error(context, 'กรุณาเลือกภูมิภาคและจังหวัด');
        return;
      }
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _askConsent() async {
    final accepted = await PdpaConsentDialog.show(context);
    if (mounted) setState(() => _consent = accepted);
  }

  Future<void> _submit() async {
    if (!_consent) {
      await _askConsent();
      if (!_consent) return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().signUp({
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'phone': _phone.text.trim(),
        'job': _job,
        'region': _region,
        'province': _province,
        'district': _district,
        'subDistrict': _subdistrict,
        'birthday': ThaiDate.toIso(_birthday!),
        'pdpaConsentAt': DateTime.now().toUtc().toIso8601String(),
      });
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      await AppDialogs.message(
        context,
        title: 'ลงทะเบียนเรียบร้อย',
        message:
            'เข้าสู่ระบบด้วยเบอร์ ${_phone.text.trim()} และวันเกิดของคุณได้เลย เจ้าหน้าที่ในพื้นที่จะตรวจสอบและยืนยันการเป็นสมาชิก',
        tone: Tone.success,
        mood: MascotMood.joy,
        buttonLabel: 'ไปหน้าเข้าสู่ระบบ',
      );
      if (mounted) context.pop();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AuthLayout(
        title: 'ลงทะเบียนเกษตรกร',
        subtitle: 'ขั้นตอนที่ ${_step + 1} จาก ${_steps.length} · ${_steps[_step]}',
        compactHero: true,
        onBack: _back,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepBar(count: _steps.length, current: _step),
            const SizedBox(height: Space.xxl),
            AnimatedSwitcher(
              duration: Motion.base,
              switchInCurve: Motion.emphasized,
              switchOutCurve: Motion.exit,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0.04, 0), end: Offset.zero)
                      .animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: switch (_step) {
                  0 => _personal(context),
                  1 => _location(context),
                  _ => _review(context),
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: Space.xl),
              InlineBanner(tone: Tone.danger, title: 'ลงทะเบียนไม่สำเร็จ', message: _error!),
            ],
            const SizedBox(height: Space.xxl),
            Row(
              children: [
                if (_step > 0) ...[
                  Expanded(
                    child: AppButton.secondary(label: 'ย้อนกลับ', onPressed: _back),
                  ),
                  const SizedBox(width: Space.md),
                ],
                Expanded(
                  flex: 2,
                  child: _step < _steps.length - 1
                      ? AppButton(
                          label: 'ถัดไป',
                          trailingIcon: AppIcons.forward,
                          onPressed: _next,
                        )
                      : AppButton(
                          label: 'ยืนยันการลงทะเบียน',
                          onPressed: _submit,
                          loading: _submitting,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _personal(BuildContext context) {
    final p = context.palette;
    String? required(String? v, String label) =>
        (v ?? '').trim().isEmpty ? 'กรุณากรอก$label' : null;
    return Form(
      key: _personalKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'ชื่อ',
                  required: true,
                  controller: _firstName,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  validator: (v) => required(v, 'ชื่อ'),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: AppTextField(
                  label: 'นามสกุล',
                  required: true,
                  controller: _lastName,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                  validator: (v) => required(v, 'นามสกุล'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          AppTextField(
            label: 'เบอร์โทรศัพท์',
            required: true,
            controller: _phone,
            hint: '08X XXX XXXX',
            icon: AppIcons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            helper: 'ใช้เป็นชื่อผู้ใช้ในการเข้าสู่ระบบ',
            validator: (v) => RegExp(r'^0\d{9}$').hasMatch((v ?? '').trim())
                ? null
                : 'เบอร์โทรศัพท์ต้องเป็นตัวเลข 10 หลัก ขึ้นต้นด้วย 0',
          ),
          const SizedBox(height: Space.xl),
          const FieldLabel('วันเกิด (ใช้แทนรหัสผ่าน)', required: true),
          ThaiDateFields(day: _day, month: _month, year: _year),
          if (_dateError != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm, left: 4),
              child: Text(
                _dateError!,
                style: context.text.bodySmall?.copyWith(color: p.danger),
              ),
            ),
          const SizedBox(height: Space.xl),
          const FieldLabel('อาชีพ'),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final job in _occupations)
                ChoiceChip(
                  label: Text(job),
                  selected: _occupation == job,
                  onSelected: (_) => setState(() => _occupation = job),
                ),
            ],
          ),
          AnimatedSize(
            duration: Motion.base,
            child: _occupation != 'อื่น ๆ'
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Space.lg),
                    child: AppTextField(
                      controller: _otherJob,
                      hint: 'ระบุอาชีพ',
                      validator: (v) => required(v, 'อาชีพ'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _location(BuildContext context) {
    return Form(
      key: _locationKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InlineBanner(
            tone: Tone.info,
            message:
                'ระบุที่ตั้งของคุณเพื่อให้เจ้าหน้าที่ในพื้นที่เป็นผู้ดูแลและอนุมัติการเป็นสมาชิก',
          ),
          const SizedBox(height: Space.xl),
          LocationSelector(
            initialRegion: _region,
            initialProvince: _province,
            initialDistrict: _district,
            initialSubdistrict: _subdistrict,
            requireFullAddress: false,
            onChanged: (region, province, district, subdistrict) {
              setState(() {
                _region = region;
                _province = province;
                _district = district;
                _subdistrict = subdistrict;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _review(BuildContext context) {
    final p = context.palette;
    final location = [
      if (_subdistrict != null) 'ต.$_subdistrict',
      if (_district != null) 'อ.$_district',
      if (_province != null) 'จ.$_province',
    ].join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            children: [
              KeyValueRow(label: 'ชื่อ-นามสกุล', value: '${_firstName.text} ${_lastName.text}'),
              KeyValueRow(label: 'เบอร์โทรศัพท์', value: _phone.text, mono: true),
              KeyValueRow(label: 'วันเกิด', value: ThaiDate.long(_birthday)),
              KeyValueRow(label: 'อาชีพ', value: _job),
              KeyValueRow(label: 'ที่ตั้ง', value: location.isEmpty ? (_region ?? '-') : location),
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        AppCard(
          onTap: _askConsent,
          color: _consent ? p.brandSoft : p.surface,
          borderColor: _consent ? p.brand.withValues(alpha: 0.4) : null,
          child: Row(
            children: [
              Icon(
                _consent ? AppIcons.checkCircleFill : AppIcons.privacy,
                color: _consent ? p.brand : p.inkSubtle,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _consent ? 'ยินยอมตาม PDPA แล้ว' : 'อ่านและยินยอมนโยบาย PDPA',
                      style: context.text.titleSmall,
                    ),
                    Text(
                      'การคุ้มครองข้อมูลส่วนบุคคลของคุณ',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(AppIcons.chevronRight, size: 18, color: p.inkSubtle),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: Motion.base,
              curve: Motion.emphasized,
              height: 4,
              decoration: BoxDecoration(
                color: i <= current ? p.brand : p.line,
                borderRadius: Radii.chip,
              ),
            ),
          ),
          if (i < count - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
