import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../auth_provider.dart';

/// Set PIN Screen for Admin/Super Admin who don't have PIN yet
class SetPinScreen extends StatefulWidget {
  final bool isSuperAdmin;
  
  const SetPinScreen({super.key, this.isSuperAdmin = false});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  bool _isLoading = false;
  String _errorMessage = '';
  
  late int _pinLength;
  late Color _accentColor;
  late String _roleTitle;
  
  @override
  void initState() {
    super.initState();
    // Super Admin: 8 digits for higher security, Admin: 6 digits
    _pinLength = widget.isSuperAdmin ? 8 : 6;
    _accentColor = widget.isSuperAdmin ? AppColors.superAdminPrimary : AppColors.primary;
    _roleTitle = widget.isSuperAdmin ? 'Super Admin' : 'Admin';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'ตั้งค่า PIN',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(),
              const SizedBox(height: 32),
              _buildTitle(),
              const SizedBox(height: 16),
              _buildSubtitle(),
              const SizedBox(height: 48),
              _buildPinDots(),
              const SizedBox(height: 24),
              if (_errorMessage.isNotEmpty) _buildErrorMessage(),
              const Spacer(),
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
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const HeroIcon(
        HeroIcons.lockClosed,
        size: 50,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      _isConfirmStep ? 'ยืนยัน PIN' : 'ตั้งค่า PIN',
      style: GoogleFonts.prompt(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      _isConfirmStep
          ? 'กรุณากรอก PIN อีกครั้งเพื่อยืนยัน'
          : 'กรุณาตั้งค่า PIN $_pinLength หลัก\nสำหรับเข้าใช้งานระบบ $_roleTitle',
      style: GoogleFonts.prompt(
        fontSize: 16,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPinDots() {
    final currentPin = _isConfirmStep ? _confirmPin : _pin;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        final isFilled = index < currentPin.length;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? _accentColor : Colors.transparent,
            border: Border.all(
              color: isFilled ? _accentColor : AppColors.textSecondary,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const HeroIcon(
            HeroIcons.exclamationCircle,
            size: 20,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: GoogleFonts.prompt(fontSize: 14, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        // Row 1-3
        _buildNumberRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildNumberRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildNumberRow(['7', '8', '9']),
        const SizedBox(height: 16),
        // Row 0 with actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: HeroIcons.arrowLeft,
              onPressed: _isConfirmStep ? _handleBack : null,
            ),
            _buildNumberButton('0'),
            _buildActionButton(
              icon: HeroIcons.backspace,
              onPressed: _handleBackspace,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildNumberButton(number)).toList(),
    );
  }

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: _isLoading ? null : () => _handleNumberPress(number),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            number,
            style: GoogleFonts.prompt(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
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
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onPressed != null ? AppColors.surface : Colors.transparent,
        ),
        child: Center(
          child: HeroIcon(
            icon,
            size: 28,
            color: onPressed != null
                ? AppColors.textPrimary
                : Colors.transparent,
          ),
        ),
      ),
    );
  }

  void _handleNumberPress(String number) {
    if (_isLoading) return;

    setState(() {
      _errorMessage = '';
      if (_isConfirmStep) {
        if (_confirmPin.length < _pinLength) {
          _confirmPin += number;
          if (_confirmPin.length == _pinLength) {
            _handleSubmit();
          }
        }
      } else {
        if (_pin.length < _pinLength) {
          _pin += number;
          if (_pin.length == _pinLength) {
            // Move to confirm step
            _isConfirmStep = true;
          }
        }
      }
    });
  }

  void _handleBackspace() {
    if (_isLoading) return;

    setState(() {
      _errorMessage = '';
      if (_isConfirmStep) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  void _handleBack() {
    if (_isLoading) return;

    setState(() {
      _isConfirmStep = false;
      _confirmPin = '';
      _errorMessage = '';
    });
  }

  Future<void> _handleSubmit() async {
    if (_pin != _confirmPin) {
      setState(() {
        _errorMessage = 'PIN ไม่ตรงกัน กรุณาลองใหม่อีกครั้ง';
        _confirmPin = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Use AuthProvider.setPin to handle state update correctly
      await authProvider.setPin(_pin);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ตั้งค่า PIN เรียบร้อยแล้ว'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate to admin dashboard
      // Add a small delay to ensure state propagation
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      
      context.go('/admin/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _pin = '';
        _confirmPin = '';
        _isConfirmStep = false;
        _isLoading = false;
      });
    }
  }
}
