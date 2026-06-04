import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'package:taptom/core/constants/app_colors.dart';
import 'package:taptom/core/network/api_client.dart';
import 'package:taptom/core/network/api_endpoints.dart';
import 'package:taptom/core/widgets/nature_background.dart';
import 'package:taptom/core/widgets/custom_popup.dart';
import '../widgets/pdpa_consent_dialog.dart';
import '../widgets/location_selector.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  // Occupation Options
  final List<String> _occupations = [
    'บุคคลทั่วไป',
    'เกษตรกร',
    'เจ้าหน้าที่ส่งเสริมการเกษตร',
    'ผู้ตรวจประเมิน GAP',
    'อื่นๆ',
  ];

  bool _isOtherOccupation = false;

  bool _hasAcceptedPdpa = false;

  // Location state
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSubdistrict;

  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

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
  // WEB LAYOUT: Split Card
  // ═══════════════════════════════════════════════════════════
  Widget _buildWebLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 850),
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
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
                flex: 40,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'เข้าร่วมกับเรา',
                          style: GoogleFonts.prompt(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'สร้างบัญชีเพื่อเข้าถึงเครื่องมือจัดการสวน\nและระบบรับรองมาตรฐาน GAP ครบวงจร',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.prompt(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // RIGHT: Form Section (White)
              Expanded(
                flex: 60,
                child: Container(
                  color: AppColors.surface,
                  child: Column(
                    children: [
                      // Header with Back Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => context.pop(),
                            icon: const HeroIcon(
                              HeroIcons.arrowLeft,
                              color: AppColors.textSecondary,
                            ),
                            label: Text(
                              'กลับ',
                              style: GoogleFonts.prompt(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 56,
                              vertical: 24,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: _buildSignUpFormContent(isWeb: true),
                            ),
                          ),
                        ),
                      ),
                    ],
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
  // MOBILE LAYOUT: Updated (Compact Header, High Card, No GAP Btn)
  // ═══════════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context, bool isKeyboardVisible) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 1. Green Header Background
        Container(
          height: size.height * 0.30,
          width: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),

        // 2. Logo Content (Compact Brand Header)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size.height * 0.15, // 💡 Layout Fix: Very compact (15%)
          child: SafeArea(
            child: Stack(
              children: [
                // Back Button Removed (Moved to top layer)
                
                // Centered Brand Content (Horizontal & Welcoming)
                Align(
                  alignment:
                      Alignment.bottomCenter, // 💡 Layout Fix: Push to bottom
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ), // 💡 Layout Fix: Tiny gap above card
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo (Smaller for row)
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
                                  56, // 💡 UI Fix: Even smaller (56px) for tight space
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title (Welcoming Text)
                        Text(
                          'สมัครสมาชิก',
                          style: GoogleFonts.prompt(
                            fontSize: 24, // 💡 UI Fix: Slightly smaller (24px)
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. White Card Body
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: isKeyboardVisible
                ? size.height * 0.95
                : size.height * 0.85, // 💡 Layout Fix: Massive 85% height
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: _buildSignUpFormContent(isWeb: false),
            ),
          ),
        ),

        // 4. Back Button (Moved to top layer for z-index)
        Positioned(
          top: 0,
          left: 4,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const HeroIcon(
                  HeroIcons.arrowLeft,
                  color: Colors.white,
                ),
                onPressed: () => context.pop(),
                tooltip: 'กลับ',
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Internal Form Content to be reused
  Widget _buildSignUpFormContent({bool isWeb = false}) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          // 💡 UI Fix: Always show title, simpler style for Mobile inside card
          Text(
            'ลงทะเบียน', // Changed to match Login's "เข้าสู่ระบบ" style roughly
            style: GoogleFonts.prompt(
              fontSize: 26, // Matches Login Header size
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          if (isWeb) ...[
            // Keep extra spacing for web if needed, or remove since we added title above
          ],

          // Name Row
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  name: 'first_name',
                  label: 'ชื่อ',
                  icon: HeroIcons.user,
                  validator: FormBuilderValidators.required(
                    errorText: 'จำเป็น',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  name: 'last_name',
                  label: 'นามสกุล',
                  icon: HeroIcons.userCircle,
                  validator: FormBuilderValidators.required(
                    errorText: 'จำเป็น',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Phone
          _buildFormField(
            name: 'phone',
            label: 'เบอร์โทรศัพท์',
            icon: HeroIcons.phone,
            keyboardType: TextInputType.phone,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: 'กรุณากรอกเบอร์โทรศัพท์',
              ),
              FormBuilderValidators.numeric(errorText: 'ตัวเลขเท่านั้น'),
              FormBuilderValidators.equalLength(
                10,
                errorText: 'ต้องมี 10 หลัก',
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Occupation Dropdown
          _buildOccupationDropdown(),
          const SizedBox(height: 16),

          // Location Selector
          _buildLocationSection(),
          const SizedBox(height: 16),

          // Birth Date (Password)
          _buildDateInputSection(),

          const SizedBox(height: 24),

          // Password Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const HeroIcon(
                  HeroIcons.informationCircle,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'วันเดือนปีเกิดของคุณจะถูกใช้เป็นรหัสผ่าน',
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // PDPA Terms
          _buildPdpaConsent(),

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'ลงทะเบียน',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Login Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'มีบัญชีอยู่แล้ว? ',
                style: GoogleFonts.prompt(color: AppColors.textSecondary),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'เข้าสู่ระบบ',
                  style: GoogleFonts.prompt(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String name,
    required String label,
    required HeroIcons icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return FormBuilderTextField(
      name: name,
      keyboardType: keyboardType,
      style: GoogleFonts.prompt(color: AppColors.textMain),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.prompt(color: AppColors.textSecondary),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: HeroIcon(
            icon,
            style: HeroIconStyle.outline,
            color: AppColors.primary,
          ),
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: validator,
    );
  }

  Widget _buildOccupationDropdown() {
    return Column(
      children: [
        FormBuilderDropdown<String>(
          name: 'occupation',
          style: GoogleFonts.prompt(color: AppColors.textMain),
          decoration: InputDecoration(
            labelText: 'อาชีพ/ประเภทผู้ใช้งาน',
            labelStyle: GoogleFonts.prompt(color: AppColors.textSecondary),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: HeroIcon(
                HeroIcons.briefcase,
                style: HeroIconStyle.outline,
                color: AppColors.primary,
              ),
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          items: _occupations
              .map(
                (occupation) => DropdownMenuItem(
                  value: occupation,
                  child: Text(occupation, style: GoogleFonts.prompt()),
                ),
              )
              .toList(),
          validator: FormBuilderValidators.required(
            errorText: 'กรุณาเลือกอาชีพ',
          ),
          onChanged: (value) {
            setState(() {
              _isOtherOccupation = value == 'อื่นๆ';
            });
          },
        ),
        if (_isOtherOccupation) ...[
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'occupation_other',
            style: GoogleFonts.prompt(color: AppColors.textMain),
            decoration: InputDecoration(
              labelText: 'โปรดระบุอาชีพอื่นๆ',
              labelStyle: GoogleFonts.prompt(color: AppColors.textSecondary),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: HeroIcon(
                  HeroIcons.pencil,
                  style: HeroIconStyle.outline,
                  color: AppColors.textSecondary,
                ),
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: FormBuilderValidators.required(
              errorText: 'กรุณาระบุอาชีพ',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LocationSelector(
        initialRegion: _selectedRegion,
        initialProvince: _selectedProvince,
        initialDistrict: _selectedDistrict,
        initialSubdistrict: _selectedSubdistrict,
        onChanged: (region, province, district, subdistrict) {
          setState(() {
            _selectedRegion = region;
            _selectedProvince = province;
            _selectedDistrict = district;
            _selectedSubdistrict = subdistrict;
          });
        },
      ),
    );
  }

  // New 3-Box Date Input Style (Copied and adapted from LoginScreen)
  Widget _buildDateInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HeroIcon(
                HeroIcons.calendar,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'วันเดือนปีเกิด (รหัสผ่าน)',
                  style: GoogleFonts.prompt(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
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
                  size: 22,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Day
              Expanded(
                flex: 2,
                child: _buildSingleDateBox(_dayController, 'วัน', '15'),
              ),
              const SizedBox(width: 12),
              // Month
              Expanded(
                flex: 2,
                child: _buildSingleDateBox(_monthController, 'เดือน', '01'),
              ),
              const SizedBox(width: 12),
              // Year
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
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          obscureText: !_isPasswordVisible,
          obscuringCharacter: '•',
          style: GoogleFonts.prompt(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.prompt(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdpaConsent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hasAcceptedPdpa
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasAcceptedPdpa
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _hasAcceptedPdpa,
            onChanged: (value) async {
              if (value == true && !_hasAcceptedPdpa) {
                // Show PDPA dialog
                final accepted = await PdpaConsentDialog.show(context);
                if (accepted) {
                  setState(() => _hasAcceptedPdpa = true);
                }
              } else if (value == false) {
                setState(() => _hasAcceptedPdpa = false);
              }
            },
            activeColor: AppColors.success,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                // Show PDPA dialog on text tap
                final accepted = await PdpaConsentDialog.show(context);
                if (accepted) {
                  setState(() => _hasAcceptedPdpa = true);
                }
              },
              child: RichText(
                text: TextSpan(
                  text: 'ฉันได้อ่านและยอมรับ ',
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    color: AppColors.textMain,
                  ),
                  children: [
                    TextSpan(
                      text: 'ข้อตกลง PDPA',
                      style: GoogleFonts.prompt(
                        fontSize: 13,
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
          if (_hasAcceptedPdpa)
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    // Store messenger reference before async operations to prevent "deactivated widget" error
    final messenger = ScaffoldMessenger.of(context);

    // 1. Check PDPA Consent
    if (!_hasAcceptedPdpa) {
      CustomPopup.showError(
        context,
        title: 'แจ้งเตือน',
        message: 'กรุณายอมรับข้อตกลง PDPA ก่อนลงทะเบียน',
      );
      return;
    }

    // 2. Validate Manual Date Inputs
    final day = _dayController.text.trim();
    final month = _monthController.text.trim();
    final year = _yearController.text.trim();

    if (day.isEmpty || month.isEmpty || year.isEmpty) {
      CustomPopup.showError(
        context,
        message: 'กรุณากรอกวันเดือนปีเกิดให้ครบถ้วน',
      );
      return;
    }

    // 3. Validate Form Fields
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;

      try {
        final apiClient = ApiClient();

        // Construct DateTime from manual inputs
        int d = int.tryParse(day) ?? 1;
        int m = int.tryParse(month) ?? 1;
        int y = int.tryParse(year) ?? 1990;

        // Convert Thai Year (BE) to AD if > 2400
        if (y > 2400) y -= 543;

        // Create date (handle invalid dates roughly or let DateTime handle it)
        final birthDate = DateTime(y, m, d);

        final signupData = {
          'firstName': values['first_name'],
          'lastName': values['last_name'],
          'phone': values['phone'],
          'job': values['occupation'] == 'อื่นๆ'
              ? values['occupation_other']
              : values['occupation'],
          'region': _selectedRegion,
          'province': _selectedProvince,
          'district': _selectedDistrict,
          'subDistrict': _selectedSubdistrict,
          'birthday': DateFormat('yyyy-MM-dd').format(birthDate),
          'pdpaConsentAt': DateTime.now().toIso8601String(),
        };

        // Submitting signup data

        await apiClient.post(ApiEndpoints.signup, data: signupData);

        if (!mounted) return;

        await CustomPopup.showSuccess(
          context,
          title: 'ลงทะเบียนสำเร็จ!',
          message:
              'บัญชีของคุณถูกสร้างเรียบร้อยแล้ว\nกรุณาเข้าสู่ระบบเพื่อใช้งาน',
          buttonText: 'ไปหน้าเข้าสู่ระบบ',
          onConfirm: () {
            context.pop(); // Close dialog
            context.pop(); // Go back to login
          },
        );
      } catch (e) {
        await CustomPopup.showError(
          context,
          message: 'ลงทะเบียนไม่สำเร็จ: ${e.toString()}',
        );
      }
    } else {
      await CustomPopup.showError(
        context,
        title: 'ข้อมูลไม่ถูกต้อง',
        message: 'กรุณาตรวจสอบข้อมูลที่กรอกอีกครั้ง',
      );
    }
  }
}
