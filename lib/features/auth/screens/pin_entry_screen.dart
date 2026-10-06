import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/security/secure_storage.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/user_model.dart';
import '../auth_provider.dart';
import '../widgets/pin_layout.dart';

/// Second sign-in step for staff. Three wrong PINs lock entry on this device
/// for five minutes; the server enforces its own limit as well.
class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  static const _maxAttempts = 3;
  static const _lockMinutes = 5;

  final _storage = SecureStorage();
  String _pin = '';
  int _attempts = 0;
  int _errorTick = 0;
  bool _error = false;
  bool _busy = false;
  int _lockedMinutes = 0;
  String? _message;
  Timer? _lockTimer;

  late final bool _isSuperAdmin;

  int get _length => _isSuperAdmin ? 8 : 6;

  @override
  void initState() {
    super.initState();
    _isSuperAdmin =
        context.read<AuthProvider>().pendingRole == UserRole.superAdmin;
    _loadLock();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLock() async {
    final minutes = await _storage.getRemainingLockoutMinutes();
    final attempts = await _storage.getPinAttempts();
    if (!mounted) return;
    setState(() {
      _lockedMinutes = minutes;
      _attempts = attempts;
    });
    if (minutes > 0) _watchLock();
  }

  void _watchLock() {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      final minutes = await _storage.getRemainingLockoutMinutes();
      if (!mounted) return;
      setState(() {
        _lockedMinutes = minutes;
        if (minutes == 0) {
          _attempts = 0;
          _lockTimer?.cancel();
        }
      });
    });
  }

  void _digit(String d) {
    if (_busy || _lockedMinutes > 0 || _pin.length >= _length) return;
    setState(() {
      _pin += d;
      _error = false;
      _message = null;
    });
    if (_pin.length == _length) _verify();
  }

  void _backspace() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().verifyPin(_pin);
      await _storage.resetPinAttempts();
      HapticFeedback.mediumImpact();
      // The router guard moves the now signed-in user to their home.
    } on AuthException catch (e) {
      await _storage.incrementPinAttempts();
      final attempts = await _storage.getPinAttempts();
      if (attempts >= _maxAttempts) {
        await _storage.setPinLockout(_lockMinutes);
        _lockedMinutes = _lockMinutes;
        _watchLock();
      }
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      setState(() {
        _attempts = attempts;
        _error = true;
        _errorTick++;
        _pin = '';
        _message = e.code == 'INVALID_PIN' ? null : e.message;
      });
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
    final locked = _lockedMinutes > 0;

    Widget status;
    if (_busy) {
      status = SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: p.brand),
      );
    } else if (locked) {
      status = StatusBadge(
        label: 'ล็อกชั่วคราว ลองใหม่ใน $_lockedMinutes นาที',
        tone: Tone.danger,
        icon: AppIcons.lock,
      );
    } else if (_error) {
      status = Text(
        _message ??
            'รหัส PIN ไม่ถูกต้อง เหลืออีก ${(_maxAttempts - _attempts).clamp(0, _maxAttempts)} ครั้ง',
        textAlign: TextAlign.center,
        style: context.text.bodyMedium?.copyWith(color: p.danger),
      );
    } else {
      status = Text(
        'ลืม PIN? ติดต่อผู้ดูแลระบบเพื่อรีเซ็ต',
        style: context.text.bodySmall,
      );
    }

    return PinLayout(
      icon: _isSuperAdmin ? AppIcons.superAdmin : AppIcons.officer,
      eyebrow: _isSuperAdmin ? 'ผู้ดูแลระบบ' : 'เจ้าหน้าที่',
      title: 'ยืนยันรหัส PIN',
      subtitle: 'กรอกรหัส PIN $_length หลักเพื่อเข้าใช้งาน',
      onBack: _cancel,
      dots: PinDots(
        length: _length,
        filled: _pin.length,
        error: _error,
        errorTick: _errorTick,
      ),
      status: status,
      pad: PinPad(
        enabled: !_busy && !locked,
        onDigit: _digit,
        onBackspace: _backspace,
      ),
    );
  }
}
