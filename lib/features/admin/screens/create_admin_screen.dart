import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_service.dart';
import '../../auth/widgets/location_selector.dart';

/// Create Admin Screen (SUPER_ADMIN Only)
class CreateAdminScreen extends StatefulWidget {
  const CreateAdminScreen({super.key});

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;

  // Location state
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSubDistrict;

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'สร้าง Admin ใหม่',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const HeroIcon(
                      HeroIcons.informationCircle,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'สร้าง Admin ใหม่สำหรับระบบ\nPIN จะถูกตั้งค่าให้อัตโนมัติ',
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Phone
              FormBuilderTextField(
                name: 'phone',
                decoration: _inputDecoration('เบอร์โทรศัพท์', HeroIcons.phone),
                keyboardType: TextInputType.phone,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: 'กรุณากรอกเบอร์โทรศัพท์',
                  ),
                  FormBuilderValidators.match(
                    r'^0[0-9]{9}$',
                    errorText: 'เบอร์โทรศัพท์ต้องขึ้นต้นด้วย 0 และมี 10 หลัก',
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // First Name
              FormBuilderTextField(
                name: 'firstName',
                decoration: _inputDecoration('ชื่อ', HeroIcons.user),
                validator: FormBuilderValidators.required(
                  errorText: 'กรุณากรอกชื่อ',
                ),
              ),
              const SizedBox(height: 16),

              // Last Name
              FormBuilderTextField(
                name: 'lastName',
                decoration: _inputDecoration('นามสกุล', HeroIcons.user),
                validator: FormBuilderValidators.required(
                  errorText: 'กรุณากรอกนามสกุล',
                ),
              ),
              const SizedBox(height: 16),

              // Job
              FormBuilderTextField(
                name: 'job',
                decoration: _inputDecoration('ตำแหน่งงาน', HeroIcons.briefcase),
                validator: FormBuilderValidators.required(
                  errorText: 'กรุณากรอกตำแหน่งงาน',
                ),
              ),
              const SizedBox(height: 24),

              // Location Section (Region + Province + District + SubDistrict)
              Text(
                'พื้นที่ที่รับผิดชอบ',
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Admin จะเห็นเฉพาะ Users ในพื้นที่ที่เลือก',
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              LocationSelector(
                onChanged: (region, province, district, subDistrict) {
                  setState(() {
                    _selectedRegion = region;
                    _selectedProvince = province;
                    _selectedDistrict = district;
                    _selectedSubDistrict = subDistrict;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Birthday Section
              Text(
                'วันเกิด (ใช้เป็นรหัสผ่าน)',
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildDateInputSection(),
              const SizedBox(height: 24),

              // PIN
              FormBuilderTextField(
                name: 'pin',
                controller: _pinController,
                decoration: _inputDecoration(
                  'PIN (6 หลัก)',
                  HeroIcons.lockClosed,
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: 'กรุณากรอก PIN'),
                  FormBuilderValidators.match(
                    r'^[0-9]{6}$',
                    errorText: 'PIN ต้องเป็นตัวเลข 6 หลัก',
                  ),
                ]),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.textLight,
                            strokeWidth: 2,
                          ),
                        )
                      : const HeroIcon(HeroIcons.plus, size: 20),
                  label: Text(
                    _isLoading ? 'กำลังสร้าง...' : 'สร้าง Admin',
                    style: GoogleFonts.prompt(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  Widget _buildDateInputSection() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildDateBox(_dayController, 'วัน', '15')),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _buildDateBox(_monthController, 'เดือน', '01'),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _buildDateBox(_yearController, 'ปี (พ.ศ.)', '2540'),
        ),
      ],
    );
  }

  Widget _buildDateBox(
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

  InputDecoration _inputDecoration(String label, HeroIcons icon) {
    return InputDecoration(
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
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }

  String _formatToBackendDate(String day, String month, String year) {
    int d = int.tryParse(day) ?? 1;
    int m = int.tryParse(month) ?? 1;
    int y = int.tryParse(year) ?? 1990;

    // Convert BE to AD if > 2400
    if (y > 2400) {
      y -= 543;
    }

    // Format DD/MM/YYYY for backend
    return '${d.toString().padLeft(2, '0')}/${m.toString().padLeft(2, '0')}/$y';
  }

  Future<void> _handleSubmit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = GoRouter.of(context);

    if (!_formKey.currentState!.saveAndValidate()) {
      return;
    }

    final day = _dayController.text.trim();
    final month = _monthController.text.trim();
    final year = _yearController.text.trim();

    if (day.isEmpty || month.isEmpty || year.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('กรุณากรอกวันเกิดให้ครบ', style: GoogleFonts.prompt()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final values = _formKey.currentState!.value;
      final birthday = _formatToBackendDate(day, month, year);

      final adminService = context.read<AdminService>();
      await adminService.createAdmin(
        phone: values['phone'] as String,
        firstName: values['firstName'] as String,
        lastName: values['lastName'] as String,
        job: values['job'] as String,
        region: _selectedRegion ?? '',
        province: _selectedProvince,
        district: _selectedDistrict,
        subDistrict: _selectedSubDistrict,
        birthday: birthday,
        pin: values['pin'] as String,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('สร้าง Admin สำเร็จ', style: GoogleFonts.prompt()),
          backgroundColor: AppColors.success,
        ),
      );

      navigator.pop(); // Go back to Admin List
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
