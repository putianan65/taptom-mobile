import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/super_admin_service.dart';
import '../../auth/widgets/location_selector.dart';

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
    return Stack(
      children: [
        // Dark gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LuxuryTheme.backgroundGradient,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              // Glass AppBar
              SliverAppBar(
                pinned: true,
                backgroundColor: LuxuryTheme.midnightBlue.withValues(alpha: 0.8),
                title: Text(
                  'สร้าง Admin ใหม่',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                centerTitle: true,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: LuxuryTheme.glassSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: LuxuryTheme.glassBorder),
                  ),
                  child: IconButton(
                    icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: FormBuilder(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info card (glass)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: LuxuryTheme.cyanNeon.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: LuxuryTheme.cyanNeon.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    PhosphorIconsRegular.info,
                                    color: LuxuryTheme.cyanNeon),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'สร้าง Admin ใหม่สำหรับระบบ\nPIN จะถูกตั้งค่าให้อัตโนมัติ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: LuxuryTheme.cyanNeon,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Phone
                        FormBuilderTextField(
                          name: 'phone',
                          decoration: _inputDecoration('เบอร์โทรศัพท์', PhosphorIconsRegular.phone),
                          keyboardType: TextInputType.phone,
                          cursorColor: LuxuryTheme.cyanNeon,
                          style: TextStyle(color: Colors.white, fontSize: 16),
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
                          decoration: _inputDecoration('ชื่อ', PhosphorIconsRegular.user),
                          cursorColor: LuxuryTheme.cyanNeon,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          validator: FormBuilderValidators.required(
                            errorText: 'กรุณากรอกชื่อ',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Last Name
                        FormBuilderTextField(
                          name: 'lastName',
                          decoration: _inputDecoration('นามสกุล', PhosphorIconsRegular.user),
                          cursorColor: LuxuryTheme.cyanNeon,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          validator: FormBuilderValidators.required(
                            errorText: 'กรุณากรอกนามสกุล',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Job
                        FormBuilderTextField(
                          name: 'job',
                          decoration: _inputDecoration('ตำแหน่งงาน', PhosphorIconsRegular.briefcase),
                          cursorColor: LuxuryTheme.cyanNeon,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          validator: FormBuilderValidators.required(
                            errorText: 'กรุณากรอกตำแหน่งงาน',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Location Section
                        Text(
                          'พื้นที่ที่รับผิดชอบ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Admin จะเห็นเฉพาะ Users ในพื้นที่ที่เลือก',
                          style: TextStyle(
                            fontSize: 12,
                            color: LuxuryTheme.textSecondary,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                            'PIN (4-8 หลัก)',
                            PhosphorIconsRegular.lockKey,
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          obscureText: true,
                          cursorColor: LuxuryTheme.cyanNeon,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: 'กรุณากรอก PIN'),
                            FormBuilderValidators.match(
                              r'^[0-9]{4,8}$',
                              errorText: 'PIN ต้องเป็นตัวเลข 4-8 หลัก',
                            ),
                          ]),
                        ),
                        const SizedBox(height: 32),

                        // Submit Button (Neon style)
                        SizedBox(
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: LuxuryTheme.neonShadow(LuxuryTheme.purpleNeon),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: LuxuryTheme.purpleNeon,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(PhosphorIconsRegular.plus, size: 20),
                              label: Text(
                                _isLoading ? 'กำลังสร้าง...' : 'สร้าง Admin',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
          style: TextStyle(
            fontSize: 12,
            color: LuxuryTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          cursorColor: LuxuryTheme.cyanNeon,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: LuxuryTheme.textDisabled),
            filled: true,
            fillColor: const Color(0xFF1E2A4A),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: LuxuryTheme.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: LuxuryTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: LuxuryTheme.cyanNeon, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: LuxuryTheme.textSecondary),
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: LuxuryTheme.cyanNeon),
      ),
      filled: true,
      fillColor: const Color(0xFF1E2A4A),
      counterStyle: TextStyle(color: LuxuryTheme.textDisabled),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: LuxuryTheme.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: LuxuryTheme.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: LuxuryTheme.cyanNeon, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      errorStyle: TextStyle(color: AppColors.error, fontSize: 12),
    );
  }

  String _formatToBackendDate(String day, String month, String year) {
    int d = int.tryParse(day) ?? 1;
    int m = int.tryParse(month) ?? 1;
    int y = int.tryParse(year) ?? 1990;

    if (y > 2400) {
      y -= 543;
    }

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
          content: Text('กรุณากรอกวันเกิดให้ครบ', style: const TextStyle()),
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

      // Use SuperAdminService
      final service = context.read<SuperAdminService>();
      await service.createAdmin(
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
          content: Text('สร้าง Admin สำเร็จ', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.success,
        ),
      );

      navigator.pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
