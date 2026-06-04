import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/security/secure_storage.dart';
import '../../../../core/services/auth_service.dart';
import '../auth_provider.dart';

class PinEntryScreen extends StatefulWidget {
  final bool isAdmin; // Regular Admin (6 digits)
  final bool isSuperAdmin; // Super Admin (8 digits for higher security)

  const PinEntryScreen({
    super.key, 
    this.isAdmin = true,
    this.isSuperAdmin = false,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen>
    with SingleTickerProviderStateMixin {
  late final int _pinLength;
  late final String _title;
  late final Color _accentColor;

  String _enteredPin = '';
  int _attempts = 0;
  bool _isLocked = false;
  bool _isError = false;
  int _remainingLockMinutes = 0;

  late AnimationController _shakeController;
  final SecureStorage _secureStorage = SecureStorage();

  // ⚠️ PIN VERIFICATION:
  // - Admin PINs are verified server-side via AuthService.verifyPin()
  // - Each admin sets their own PIN during signup
  // - NO hardcoded PINs in code for security reasons
  // - See: AuthService.signInWithPin() for backend verification

  @override
  void initState() {
    super.initState();
    
    // ✅ Check for tempToken
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tempToken = context.read<AuthProvider>().tempToken;
      if (tempToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('หมดเวลาทำรายการ กรุณาเข้าสู่ระบบใหม่'),
              backgroundColor: AppColors.error,
            ),
          );
          context.go('/login');
        }
        return;
      }
    });

    _pinLength = widget.isSuperAdmin ? 8 : 6; // Super Admin: 8 digits, Admin: 6 digits
    _title = widget.isSuperAdmin ? 'Super Admin' : 'Admin';
    // Use AppColors for consistent role-based theming
    _accentColor = widget.isSuperAdmin
        ? AppColors.superAdminPrimary
        : AppColors.adminPrimary;

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Check for existing lockout on init
    _checkLockoutStatus();
  }

  /// Check if there's an active lockout from secure storage
  Future<void> _checkLockoutStatus() async {
    final isLocked = await _secureStorage.isPinLocked();
    final remainingMinutes = await _secureStorage.getRemainingLockoutMinutes();
    final attempts = await _secureStorage.getPinAttempts();

    if (mounted) {
      setState(() {
        _isLocked = isLocked;
        _remainingLockMinutes = remainingMinutes;
        _attempts = attempts;
      });
    }

    // If locked, start a timer to check when lockout expires
    if (isLocked) {
      _startLockoutTimer();
    }
  }

  /// Timer to update lockout status
  void _startLockoutTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;

      final remaining = await _secureStorage.getRemainingLockoutMinutes();
      if (mounted) {
        setState(() {
          _remainingLockMinutes = remaining;
          if (remaining == 0) {
            _isLocked = false;
            _attempts = 0;
          }
        });
      }
      return _isLocked && mounted;
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: HeroIcon(
            HeroIcons.arrowLeft,
            style: HeroIconStyle.outline,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Icon
              _buildIcon(),
              const SizedBox(height: 24),

              // Title
              _buildTitle(),
              const SizedBox(height: 40),

              // PIN Dots
              _buildPinDots(),
              const SizedBox(height: 16),

              // Error/Attempts Message
              _buildStatusMessage(),

              const Spacer(),

              // Number Pad
              _buildNumberPad(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: HeroIcon(
          widget.isSuperAdmin ? HeroIcons.shieldCheck : HeroIcons.userGroup,
          style: HeroIconStyle.solid,
          size: 40,
          color: _accentColor,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'เข้าสู่ระบบ $_title',
          style: GoogleFonts.prompt(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'กรุณากรอก PIN $_pinLength หลัก',
          style: GoogleFonts.prompt(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPinDots() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset = _shakeController.isAnimating
            ? 10 *
                  (0.5 - _shakeController.value).abs() *
                  (_shakeController.value < 0.5 ? 1 : -1)
            : 0.0;

        return Transform.translate(
          offset: Offset(offset, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinLength, (index) {
              final isFilled = index < _enteredPin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled
                      ? (_isError ? AppColors.error : _accentColor)
                      : Colors.transparent,
                  border: Border.all(
                    color: _isError ? AppColors.error : _accentColor,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildStatusMessage() {
    if (_isLocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeroIcon(
              HeroIcons.lockClosed,
              style: HeroIconStyle.solid,
              color: AppColors.error,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'ถูกล็อก $_remainingLockMinutes นาที',
              style: GoogleFonts.prompt(fontSize: 13, color: AppColors.error),
            ),
          ],
        ),
      );
    }

    if (_isError) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HeroIcon(
            HeroIcons.exclamationTriangle,
            style: HeroIconStyle.solid,
            color: AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'PIN ไม่ถูกต้อง (เหลืออีก ${3 - _attempts} ครั้ง)',
            style: GoogleFonts.prompt(fontSize: 13, color: AppColors.error),
          ),
        ],
      );
    }

    return const SizedBox(height: 20);
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('1'),
            _buildNumberButton('2'),
            _buildNumberButton('3'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('4'),
            _buildNumberButton('5'),
            _buildNumberButton('6'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('7'),
            _buildNumberButton('8'),
            _buildNumberButton('9'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: HeroIcons.fingerPrint,
              onPressed: () {
                // Biometric auth placeholder
              },
            ),
            _buildNumberButton('0'),
            _buildActionButton(
              icon: HeroIcons.backspace,
              onPressed: _isLocked ? null : _handleBackspace,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: _isLocked ? null : () => _handleNumberPress(number),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _isLocked ? AppColors.surfaceVariant : AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            number,
            style: GoogleFonts.prompt(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: _isLocked
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required HeroIcons icon,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Center(
          child: HeroIcon(
            icon,
            style: HeroIconStyle.outline,
            size: 28,
            color: onPressed == null
                ? AppColors.textSecondary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _handleNumberPress(String number) {
    if (_enteredPin.length >= _pinLength) return;

    setState(() {
      _enteredPin += number;
      _isError = false;
    });

    // Check PIN when complete
    if (_enteredPin.length == _pinLength) {
      _verifyPin();
    }
  }

  void _handleBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    // Check if locked before attempting
    if (_isLocked) {
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();

      await authProvider.verifyPin(_enteredPin);

      // Success - Reset attempts and clear lockout
      await _secureStorage.resetPinAttempts();
      await _secureStorage.clearPinLockout();

      if (mounted) {
        // Success - Router redirect will handle navigation
      }
    } catch (e) {
      if (mounted) {
        // Increment attempt count in secure storage
        await _secureStorage.incrementPinAttempts();
        final currentAttempts = await _secureStorage.getPinAttempts();

        setState(() {
          _attempts = currentAttempts;
          _isError = true;
          _enteredPin = '';

          // Lock after 3 failed attempts
          if (_attempts >= 3) {
            _isLocked = true;
            _remainingLockMinutes = 5;
            _secureStorage.setPinLockout(5); // Lock for 5 minutes
            _startLockoutTimer();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );

        _shakeController.forward().then((_) => _shakeController.reset());
      }
    }
  }
}
