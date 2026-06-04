import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import 'package:taptom/core/constants/app_colors.dart';
import 'package:taptom/core/widgets/nature_background.dart';
import 'package:taptom/core/services/auth_service.dart';
import 'package:taptom/core/widgets/custom_popup.dart';
import 'package:taptom/features/auth/auth_provider.dart';
import 'package:taptom/data/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _phoneController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Check if keyboard is visible to adjust layout on mobile
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildWebLayout(context);
          } else {
            return _buildMobileLayout(context, isKeyboardVisible);
          }
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WEB LAYOUT: Floating Split Card
  // ═══════════════════════════════════════════════════════════
  Widget _buildWebLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 800),
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // LEFT: Brand Section (Green)
              Expanded(
                flex: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          'ยินดีต้อนรับสู่\nTAPTOM',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.prompt(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ระบบรับรองมาตรฐาน GAP\nเพื่อเกษตรกรไทย',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.prompt(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // RIGHT: Form Section (White)
              Expanded(
                flex: 5,
                child: Container(
                  color: Colors.white,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 64,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'เข้าสู่ระบบ',
                            style: GoogleFonts.prompt(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'กรอกเบอร์โทรศัพท์และวันเกิดเพื่อใช้งาน',
                            style: GoogleFonts.prompt(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),

                          // Form Logic (Reusing existing components logic)
                          _buildLoginFormContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MOBILE LAYOUT: Green Header + Curved Body
  // ═══════════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context, bool isKeyboardVisible) {
    // 💡 Performance: Cache measurements prevents recalculation during build
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 1. Green Header Background (Fixed)
        Container(
          height: size.height * 0.50, // 💡 Layout Fix: 50% Green Background
          width: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),

        // 2. Logo Content
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height:
              size.height *
              0.25, // 💡 Layout Fix: Adjusted to 25% to fit above 75% card
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width:
                              80, // 💡 UI Fix: Slightly larger (80px) for better presence
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20), // 💡 UI Fix: More breathing room
                    // Text + GAP Button Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TAPTOM',
                          style: GoogleFonts.prompt(
                            fontSize: 36, // 💡 UI Fix: Larger Title
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ), // 💡 UI Fix: Don't be too close (8px)
                        // GAP Button
                        GestureDetector(
                          onTap: _showGapInfoDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'มาตรฐาน GAP',
                                  style: GoogleFonts.prompt(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3. White Card (Bottom Sheet)
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            // Dynamic height: 75% requested
            height: isKeyboardVisible
                ? size.height * 0.95
                : size.height * 0.75, // 💡 Layout Fix: 75% Split
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets
                  .zero, // 💡 Layout Fix: Zero padding to allow full-width footer
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
                    child: Text(
                      'เข้าสู่ระบบ',
                      style: GoogleFonts.prompt(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: _buildLoginFormContent(),
                  ),

                  const SizedBox(height: 48), // Spacer before footer
                  // 💡 UI Design: Curved Footer covering Gistnu (Option 1)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: 32,
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(
                        0.06,
                      ), // Subtle brand tint
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(60), // The "Curve" effect
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Powered by',
                          style: GoogleFonts.prompt(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: 0.9,
                          child: Image.asset(
                            'assets/images/Gistnu_new_logo.webp',
                            height: 32,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Internal Form Content to be reused
  Widget _buildLoginFormContent() {
    return FormBuilder(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormBuilderTextField(
            name: 'phone',
            controller: _phoneController,
            style: GoogleFonts.prompt(
              color: AppColors.textPrimary,
              fontSize: 16, // 💡 UI Fix: Balanced (18 -> 16)
            ),
            decoration: _inputDecoration('เบอร์โทรศัพท์', HeroIcons.phone),
            keyboardType: TextInputType.phone,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: 'กรุณากรอกเบอร์โทรศัพท์',
              ),
              FormBuilderValidators.numeric(errorText: 'กรอกเฉพาะตัวเลข'),
              FormBuilderValidators.equalLength(
                10,
                errorText: 'เบอร์โทรต้องมี 10 หลัก',
              ),
            ]),
          ),
          const SizedBox(height: 24),

          _buildDateInputSection(),
          const SizedBox(height: 32),

          SizedBox(
            height: 52, // Slightly smaller height
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'เข้าสู่ระบบ',
                      style: GoogleFonts.prompt(
                        fontSize: 18, // 💡 UI Fix: Balanced (20 -> 18)
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: GestureDetector(
              onTap: () => context.push('/register'),
              child: RichText(
                text: TextSpan(
                  text: 'ยังไม่มีบัญชี? ',
                  style: GoogleFonts.prompt(
                    color: AppColors.textSecondary,
                    fontSize: 16, // 💡 UI Fix: Increased from 15
                  ),
                  children: [
                    TextSpan(
                      text: 'ลงทะเบียน',
                      style: GoogleFonts.prompt(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Note: Footer moved to parent widget for full-width design
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, HeroIcons icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.prompt(
        color: AppColors.textSecondary,
        fontSize: 16, // 💡 UI Fix: Increased from 14
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: HeroIcon(
          icon,
          style: HeroIconStyle.outline,
          color: AppColors.primary,
          size: 24, // 💡 UI Fix: Increased from 20
        ),
      ),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Widget _buildDateInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HeroIcon(
                HeroIcons.calendar,
                size: 24, // 💡 UI Fix: Increased
                color: AppColors.primary,
                style: HeroIconStyle.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'วันเดือนปีเกิด (รหัสผ่าน)',
                  style: GoogleFonts.prompt(
                    fontSize: 16, // 💡 UI Fix: Increased
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                child: HeroIcon(
                  _isPasswordVisible ? HeroIcons.eye : HeroIcons.eyeSlash,
                  size: 24, // 💡 UI Fix: Increased
                  color: AppColors.textSecondary,
                  style: HeroIconStyle.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildSingleDateBox(_dayController, 'วัน', '15'),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _buildSingleDateBox(_monthController, 'เดือน', '01'),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _buildSingleDateBox(
                  _yearController,
                  'ปี (พ.ศ.)',
                  '2540',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleDateBox(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.prompt(
            fontSize: 14, // 💡 UI Fix: Increased
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          obscureText: !_isPasswordVisible,
          obscuringCharacter: '•',
          style: GoogleFonts.prompt(
            fontSize: 18, // 💡 UI Fix: Increased
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.prompt(color: AppColors.textTertiary),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _handleLogin() async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = GoRouter.of(context);

    if (!_formKey.currentState!.validate()) return;
    if (!_formKey.currentState!.saveAndValidate()) return;

    final day = _dayController.text.trim();
    final month = _monthController.text.trim();
    final year = _yearController.text.trim();

    if (day.isEmpty || month.isEmpty || year.isEmpty) {
      if (!mounted) return;
      CustomPopup.showError(
        context,
        title: 'ข้อมูลไม่ครบถ้วน',
        message: 'กรุณากรอกวันเดือนปีเกิดให้ครบ',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!mounted) return;
      final values = _formKey.currentState!.value;
      final phone = values['phone'] as String;

      String formattedDate = _formatToBackendDate(day, month, year);

      final auth = context.read<AuthProvider>();
      await auth.signIn(phone, formattedDate);

      if (!mounted) return;
      final user = auth.user;
      if (user != null) {
        Future.microtask(() {
          if (!mounted) return;
          setState(() => _isLoading = false);

          if (user.role == UserRole.admin || user.role == UserRole.superAdmin) {
            final isSuperAdmin = user.role == UserRole.superAdmin;
            navigator.push('/pin', extra: {'isAdmin': true, 'isSuperAdmin': isSuperAdmin});
          } else {
            navigator.go('/dashboard');
          }
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (e is PinNotSetException) {
        if (!mounted) return;
        
        await CustomPopup.showInfo(
          context,
          title: 'แจ้งเตือน',
          message: 'กรุณาตั้งรหัส PIN เพื่อความปลอดภัยก่อนใช้งาน',
        );
        if (!mounted) return;
        // Pass isSuperAdmin based on user info from exception if available
        final isSuperAdmin = e.user?.role == UserRole.superAdmin;
        navigator.push('/set-pin', extra: {'isSuperAdmin': isSuperAdmin});
        return;
      }

      // ✅ ADDED: Handle PinRequiredException for Admin/SuperAdmin
      if (e is PinRequiredException) {
        if (!mounted) return;
        
        // Extract role from exception to determine PIN length
        final role = e.userRole?.toUpperCase();
        final isSuperAdmin = role == 'SUPER_ADMIN';
        
        navigator.push('/pin', extra: {'isAdmin': true, 'isSuperAdmin': isSuperAdmin});
        return;
      }

      final errorMessage = e.toString().replaceAll("Exception: ", "");
      await CustomPopup.showError(context, message: errorMessage);
    }
  }

  String _formatToBackendDate(String day, String month, String year) {
    int d = int.tryParse(day) ?? 1;
    int m = int.tryParse(month) ?? 1;
    int y = int.tryParse(year) ?? 1990;

    if (y > 2400) {
      y -= 543;
    }

    return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  // 💡 Feature: GAP Information Dialog
  void _showGapInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'มาตรฐาน GAP คืออะไร?',
                      style: GoogleFonts.prompt(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GAP (Good Agricultural Practices)',
                      style: GoogleFonts.prompt(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'หมายถึง มาตรฐานการปฏิบัติทางการเกษตรที่ดี เป็นระบบการผลิตพืชที่ปลอดภัย โดยคำนึงถึง 4 ด้านหลัก:',
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoBullet('ความปลอดภัยของผู้บริโภค (ไร้สารตกค้าง)'),
                    _buildInfoBullet('ความปลอดภัยของเกษตรกร'),
                    _buildInfoBullet('ความปลอดภัยต่อสิ่งแวดล้อม'),
                    _buildInfoBullet('การตรวจสอบย้อนกลับได้'),

                    const Divider(height: 32),

                    Text(
                      'ความสำคัญกับพืชเสพติด (กระท่อม)',
                      style: GoogleFonts.prompt(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'สำหรับกระท่อมภายใต้การควบคุม มาตรฐาน GAP มีความสำคัญดังนี้:',
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStepItem(
                      '1',
                      'ข้อกำหนดทางกฎหมาย',
                      'ผู้ปลูกต้องปฏิบัติตามเพื่อขอใบอนุญาต',
                    ),
                    _buildStepItem(
                      '2',
                      'ควบคุมคุณภาพ',
                      'ควบคุมสารสำคัญ (Mitragynine, 7-Hydroxymitragynine) และป้องกันโลหะหนัก',
                    ),
                    _buildStepItem(
                      '3',
                      'ป้องกันการนำไปใช้ผิด',
                      'มีระบบบันทึกและการติดตามที่ชัดเจน',
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'เข้าใจแล้ว',
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.prompt(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: GoogleFonts.prompt(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.prompt(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
