import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import '../../auth/screens/set_pin_screen.dart' show PinRules;
import '../../auth/widgets/pin_layout.dart';

enum _Step { current, next, confirm }

/// Staff PIN change on the same keypad used at sign-in: current PIN, new
/// PIN, then the new PIN again. Super admins use eight digits.
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  _Step _step = _Step.current;
  String _current = '';
  String _next = '';
  String _entry = '';
  bool _busy = false;
  bool _error = false;
  int _errorTick = 0;
  String? _message;
  late final int _length;

  @override
  void initState() {
    super.initState();
    _length = context.read<AuthProvider>().currentUser?.role == UserRole.superAdmin ? 8 : 6;
  }

  void _fail(String message) {
    HapticFeedback.heavyImpact();
    setState(() {
      _entry = '';
      _error = true;
      _errorTick++;
      _message = message;
    });
  }

  void _digit(String d) {
    if (_busy || _entry.length >= _length) return;
    setState(() {
      _entry += d;
      _error = false;
      _message = null;
    });
    if (_entry.length == _length) _advance();
  }

  void _backspace() {
    if (_busy || _entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _advance() async {
    switch (_step) {
      case _Step.current:
        setState(() {
          _current = _entry;
          _entry = '';
          _step = _Step.next;
        });
      case _Step.next:
        final weak = PinRules.weak(_entry);
        if (weak != null) return _fail(weak);
        if (_entry == _current) return _fail('PIN ใหม่ต้องไม่ซ้ำกับ PIN เดิม');
        setState(() {
          _next = _entry;
          _entry = '';
          _step = _Step.confirm;
        });
      case _Step.confirm:
        if (_entry != _next) return _fail('รหัสทั้งสองครั้งไม่ตรงกัน');
        await _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await context.read<AuthService>().changePin(_current, _next);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      AppToast.success(context, 'เปลี่ยน PIN แล้ว');
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = e.code == 'INVALID_PIN' ? _Step.current : _Step.next;
        _current = e.code == 'INVALID_PIN' ? '' : _current;
        _next = '';
      });
      _fail(e.message);
    } on Object catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _fail('เปลี่ยน PIN ไม่สำเร็จ ลองใหม่อีกครั้ง');
    }
  }

  void _back() {
    if (_step == _Step.current || _busy) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _entry = '';
      _error = false;
      _message = null;
      _step = _step == _Step.confirm ? _Step.next : _Step.current;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (title, subtitle) = switch (_step) {
      _Step.current => ('PIN ปัจจุบัน', 'ยืนยันตัวตนด้วย PIN ที่ใช้อยู่'),
      _Step.next => ('PIN ใหม่', 'เลือกตัวเลข $_length หลักที่จำได้ แต่เดายาก'),
      _Step.confirm => ('ยืนยัน PIN ใหม่', 'กรอก PIN ใหม่อีกครั้ง'),
    };

    final Widget status;
    if (_busy) {
      status = SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: p.brand),
      );
    } else if (_message != null) {
      status = Text(
        _message!,
        textAlign: TextAlign.center,
        style: context.text.bodyMedium?.copyWith(color: p.danger),
      );
    } else {
      status = Text('ขั้นตอน ${_step.index + 1} จาก 3', style: context.text.labelMedium);
    }

    return PinLayout(
      icon: AppIcons.lock,
      eyebrow: 'เปลี่ยนรหัส PIN',
      title: title,
      subtitle: subtitle,
      onBack: _back,
      dots: PinDots(length: _length, filled: _entry.length, error: _error, errorTick: _errorTick),
      status: status,
      pad: PinPad(enabled: !_busy, onDigit: _digit, onBackspace: _backspace),
    );
  }
}
