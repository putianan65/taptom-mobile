import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/user_model.dart';
import '../auth_provider.dart';
import '../widgets/pin_layout.dart';

/// First sign-in for a new staff account: choose a PIN, then confirm it.
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String _pin = '';
  String _confirm = '';
  bool _confirming = false;
  bool _busy = false;
  bool _error = false;
  int _errorTick = 0;
  String? _message;
  late final bool _isSuperAdmin;

  int get _length => _isSuperAdmin ? 8 : 6;

  @override
  void initState() {
    super.initState();
    _isSuperAdmin =
        context.read<AuthProvider>().pendingRole == UserRole.superAdmin;
  }

  static String? weakPinReason(String pin) => PinRules.weak(pin);


  void _fail(String message) {
    HapticFeedback.heavyImpact();
    setState(() {
      _error = true;
      _errorTick++;
      _message = message;
    });
  }

  void _digit(String d) {
    if (_busy) return;
    setState(() {
      _error = false;
      _message = null;
    });
    if (!_confirming) {
      if (_pin.length >= _length) return;
      setState(() => _pin += d);
      if (_pin.length == _length) {
        final weak = weakPinReason(_pin);
        if (weak != null) {
          setState(() => _pin = '');
          _fail(weak);
          return;
        }
        setState(() => _confirming = true);
      }
    } else {
      if (_confirm.length >= _length) return;
      setState(() => _confirm += d);
      if (_confirm.length == _length) _submit();
    }
  }

  void _backspace() {
    if (_busy) return;
    setState(() {
      if (_confirming) {
        if (_confirm.isEmpty) {
          _confirming = false;
          _pin = '';
        } else {
          _confirm = _confirm.substring(0, _confirm.length - 1);
        }
      } else if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _submit() async {
    if (_pin != _confirm) {
      setState(() => _confirm = '');
      _fail('รหัสทั้งสองครั้งไม่ตรงกัน ลองยืนยันอีกครั้ง');
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().setPin(_pin);
      HapticFeedback.mediumImpact();
      if (mounted) AppToast.success(context, 'ตั้งรหัส PIN เรียบร้อยแล้ว');
      // Router guard redirects to the role's home.
    } on AuthException catch (e) {
      setState(() {
        _pin = '';
        _confirm = '';
        _confirming = false;
      });
      _fail(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _cancel() {
    context.read<AuthProvider>().cancelPinStep();
    context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final current = _confirming ? _confirm : _pin;

    final Widget status;
    if (_busy) {
      status = SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: p.brand),
      );
    } else if (_error && _message != null) {
      status = Text(
        _message!,
        textAlign: TextAlign.center,
        style: context.text.bodyMedium?.copyWith(color: p.danger),
      );
    } else {
      status = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Step(label: 'ตั้งรหัส', active: !_confirming, done: _confirming),
          Container(width: 24, height: 1, color: p.lineStrong),
          _Step(label: 'ยืนยัน', active: _confirming, done: false),
        ],
      );
    }

    return PinLayout(
      icon: AppIcons.lock,
      eyebrow: _isSuperAdmin ? 'ผู้ดูแลระบบ · เข้าใช้ครั้งแรก' : 'เจ้าหน้าที่ · เข้าใช้ครั้งแรก',
      title: _confirming ? 'ยืนยันรหัส PIN' : 'ตั้งรหัส PIN',
      subtitle: _confirming
          ? 'กรอกรหัสเดิมอีกครั้งเพื่อยืนยัน'
          : 'เลือกตัวเลข $_length หลักที่จำได้ แต่เดายาก',
      onBack: _cancel,
      dots: PinDots(
        length: _length,
        filled: current.length,
        error: _error,
        errorTick: _errorTick,
      ),
      status: status,
      pad: PinPad(enabled: !_busy, onDigit: _digit, onBackspace: _backspace),
    );
  }
}

/// PIN strength rules, kept separate so they can be unit tested.
abstract final class PinRules {
  /// Returns a reason when [pin] is trivial to guess, otherwise null.
  static String? weak(String pin) {
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) {
      return 'ห้ามใช้ตัวเลขซ้ำกันทั้งหมด';
    }
    var ascending = true;
    var descending = true;
    for (var i = 1; i < pin.length; i++) {
      final diff = pin.codeUnitAt(i) - pin.codeUnitAt(i - 1);
      if (diff != 1) ascending = false;
      if (diff != -1) descending = false;
    }
    if (ascending || descending) return 'ห้ามใช้ตัวเลขเรียงกัน';
    return null;
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.active, required this.done});

  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = active || done ? p.brand : p.inkSubtle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? AppIcons.checkCircleFill : AppIcons.checkCircle,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
