import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/config/env.dart';
import '../../../core/network/demo/demo_accounts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/thai_date.dart';
import '../../../core/widgets/widgets.dart';
import '../auth_provider.dart';
import '../widgets/gap_info_sheet.dart';
import '../widgets/auth_layout.dart';

/// Phone number + birthday sign-in. Staff accounts continue to the PIN step.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _day = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();

  bool _showBirthday = false;
  bool _loading = false;
  String? _error;
  String? _dateError;

  @override
  void dispose() {
    _phone.dispose();
    _day.dispose();
    _month.dispose();
    _year.dispose();
    super.dispose();
  }

  void _fillDemo(DemoAccount account) {
    setState(() {
      _phone.text = account.phone;
      _day.text = account.day;
      _month.text = account.month;
      _year.text = account.yearBE;
      _error = null;
      _dateError = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final phoneOk = _formKey.currentState?.validate() ?? false;
    final birthday = ThaiDate.parseParts(_day.text, _month.text, _year.text);
    setState(() {
      _error = null;
      _dateError = birthday == null ? 'กรอกวัน เดือน ปีเกิดให้ถูกต้อง' : null;
    });
    if (!phoneOk || birthday == null) return;

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final router = GoRouter.of(context);
    try {
      await auth.signIn(_phone.text.trim(), ThaiDate.toIso(birthday));
      // Router guard sends the signed-in user to their home.
    } on PinRequiredException {
      if (mounted) router.push(Routes.pin);
    } on PinNotSetException {
      if (mounted) router.push(Routes.setPin);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AuthLayout(
      title: 'เข้าสู่ระบบ',
      subtitle: 'ใช้เบอร์โทรศัพท์และวันเกิดที่ลงทะเบียนไว้',
      topAction: TextButton.icon(
        onPressed: () => showGapInfoSheet(context),
        icon: const Icon(AppIcons.gap, size: 18),
        label: const Text('GAP คืออะไร'),
        style: TextButton.styleFrom(
          backgroundColor: p.surface.withValues(alpha: 0.8),
          foregroundColor: p.brandStrong,
        ),
      ),
      footer: _footer(context),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (Env.demoMode) ...[
                _DemoAccounts(onPick: _fillDemo),
                const SizedBox(height: Space.xl),
              ],
              AppTextField(
                label: 'เบอร์โทรศัพท์',
                controller: _phone,
                hint: '08X XXX XXXX',
                icon: AppIcons.phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
                  if (!RegExp(r'^0\d{9}$').hasMatch(value)) {
                    return 'เบอร์โทรศัพท์ต้องเป็นตัวเลข 10 หลัก ขึ้นต้นด้วย 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Space.xl),
              FieldLabel(
                'วันเกิด (ใช้แทนรหัสผ่าน)',
                trailing: IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: _showBirthday ? 'ซ่อน' : 'แสดง',
                  onPressed: () => setState(() => _showBirthday = !_showBirthday),
                  icon: Icon(
                    _showBirthday ? AppIcons.eyeOff : AppIcons.eye,
                    size: 20,
                    color: p.inkSubtle,
                  ),
                ),
              ),
              ThaiDateFields(
                day: _day,
                month: _month,
                year: _year,
                obscure: !_showBirthday,
                onCompleted: _submit,
              ),
              AnimatedSize(
                duration: Motion.quick,
                child: _dateError == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: Space.sm, left: 4),
                        child: Text(
                          _dateError!,
                          style: context.text.bodySmall?.copyWith(color: p.danger),
                        ),
                      ),
              ),
              AnimatedSize(
                duration: Motion.base,
                curve: Motion.standard,
                child: _error == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: Space.xl),
                        child: InlineBanner(
                          tone: Tone.danger,
                          title: 'เข้าสู่ระบบไม่สำเร็จ',
                          message: _error!,
                        ),
                      ),
              ),
              const SizedBox(height: Space.xxl),
              AppButton(
                label: 'เข้าสู่ระบบ',
                onPressed: _submit,
                loading: _loading,
                expand: true,
              ),
              const SizedBox(height: Space.md),
              AppButton.secondary(
                label: 'ลงทะเบียนเกษตรกรใหม่',
                onPressed: () => context.push(Routes.register),
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        const LabeledDivider(label: 'สำหรับผู้ซื้อและผู้บริโภค'),
        const SizedBox(height: Space.lg),
        AppCard(
          onTap: () => context.push(Routes.traceabilityScan),
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              const IconTile(icon: AppIcons.scan),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('สแกนตรวจสอบย้อนกลับ', style: context.text.titleSmall),
                    Text(
                      'ดูที่มาของผลผลิตจาก QR บนบรรจุภัณฑ์ ไม่ต้องเข้าสู่ระบบ',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(AppIcons.chevronRight, size: 18, color: p.inkSubtle),
            ],
          ),
        ),
        const SizedBox(height: Space.x3),
        Text('พัฒนาโดย', style: context.text.labelMedium),
        const SizedBox(height: Space.sm),
        Opacity(
          opacity: context.isDark ? 0.85 : 1,
          child: Image.asset('assets/images/partners/gistnu.webp', height: 28),
        ),
      ],
    );
  }
}

class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.onPick});

  final ValueChanged<DemoAccount> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.control,
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('โหมดสาธิต เลือกบัญชีตัวอย่าง', style: context.text.labelLarge?.copyWith(color: p.ink)),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'PIN เจ้าหน้าที่ '),
                TextSpan(text: DemoAccounts.pin, style: context.text.labelMedium?.mono),
                const TextSpan(text: '   ผู้ดูแลระบบ '),
                TextSpan(text: DemoAccounts.superPin, style: context.text.labelMedium?.mono),
              ],
            ),
            style: context.text.labelMedium?.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final a in DemoAccounts.all)
                ActionChip(
                  label: Text(a.label),
                  onPressed: () => onPick(a),
                  backgroundColor: p.surface,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
