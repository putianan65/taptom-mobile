import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // NEW
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_service.dart'; // NEW
import '../../../core/widgets/nature_background.dart';
import '../../auth/auth_provider.dart';
import '../../auth/widgets/location_selector.dart';
import '../../../data/models/user_model.dart';

/// Production-grade Personal Info Screen
/// Improvements:
/// - Better validation with Thai phone number format
/// - Loading state management
/// - Proper error handling
/// - Keyboard management
/// - Accessibility support
/// - Form state preservation
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _jobController;

  // Location data
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSubdistrict;

  // Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _jobController = TextEditingController(text: user?.job ?? '');

    // Initialize location
    _selectedRegion = user?.region;
    _selectedProvince = user?.province;
    _selectedDistrict = user?.district;
    _selectedSubdistrict = user?.subdistrict;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  // ==================== VALIDATION ====================

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกชื่อจริง';
    }
    if (value.trim().length < 2) {
      return 'ชื่อต้องมีอย่างน้อย 2 ตัวอักษร';
    }
    // Check for Thai or English characters
    final thaiPattern = RegExp(r'^[ก-๙\s]+$');
    final englishPattern = RegExp(r'^[a-zA-Z\s]+$');
    if (!thaiPattern.hasMatch(value.trim()) &&
        !englishPattern.hasMatch(value.trim())) {
      return 'ชื่อต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกนามสกุล';
    }
    if (value.trim().length < 2) {
      return 'นามสกุลต้องมีอย่างน้อย 2 ตัวอักษร';
    }
    // Check for Thai or English characters
    final thaiPattern = RegExp(r'^[ก-๙\s]+$');
    final englishPattern = RegExp(r'^[a-zA-Z\s]+$');
    if (!thaiPattern.hasMatch(value.trim()) &&
        !englishPattern.hasMatch(value.trim())) {
      return 'นามสกุลต้องเป็นภาษาไทยหรืออังกฤษเท่านั้น';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกเบอร์โทรศัพท์';
    }

    // Remove spaces and dashes
    final cleanPhone = value.replaceAll(RegExp(r'[\s-]'), '');

    // Thai phone format: 0X-XXXX-XXXX or 0XX-XXX-XXXX
    if (cleanPhone.length != 10) {
      return 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
    }

    if (!cleanPhone.startsWith('0')) {
      return 'เบอร์โทรศัพท์ต้องขึ้นต้นด้วย 0';
    }

    // Valid Thai mobile prefixes
    final validPrefixes = ['06', '08', '09'];
    final prefix = cleanPhone.substring(0, 2);
    if (!validPrefixes.contains(prefix)) {
      return 'เบอร์โทรศัพท์ต้องขึ้นต้นด้วย 06, 08 หรือ 09';
    }

    return null;
  }

  // ==================== SAVE PROFILE ====================

  Future<void> _saveProfile() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final currentUser = auth.user;

      if (currentUser == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      final updatedUser = currentUser.copyWith(
        phone: _phoneController.text.trim(),
        firstName: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        job: _jobController.text.trim().isEmpty
            ? null
            : _jobController.text.trim(),
        region: _selectedRegion,
        province: _selectedProvince,
        district: _selectedDistrict,
        subdistrict: _selectedSubdistrict,
      );

      await auth.updateProfile(updatedUser);

      if (!mounted) return;

      // Show success and pop
      _showSuccessSnackBar('บันทึกข้อมูลสำเร็จ');

      // Delay navigation to allow snackbar to show
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _showErrorSnackBar(
        'เกิดข้อผิดพลาด: ${e.toString().replaceAll("Exception: ", "")}',
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              PhosphorIconsRegular.checkCircle,
              color: Colors.white,
              size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              PhosphorIconsRegular.warningCircle,
              color: Colors.white,
              size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== IMAGE PICKER ====================

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      // 1. Upload Photo
      final File file = File(image.path);
      final adminService = context.read<AdminService>();
      final photoUrl = await adminService.uploadProfilePhoto(file);

      // 2. Update User Profile with new photo URL
      final auth = context.read<AuthProvider>();
      final currentUser = auth.user;
      
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(photoUrl: photoUrl);
        await auth.updateProfile(updatedUser);
        
        if (!mounted) return;
        _showSuccessSnackBar('อัพโหลดรูปภาพสำเร็จ');
      }

    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('อัพโหลดรูปภาพไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return NatureBackground.header(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('ข้อมูลส่วนตัว', style: const TextStyle()),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white),
            onPressed: _isLoading ? null : () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Avatar
                    Center(child: _buildProfileAvatar()),
                    const SizedBox(height: 32),

                    // Form Fields
                    _buildLabel('ชื่อจริง', required: true),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        hint: 'กรอกชื่อจริง',
                        icon: PhosphorIconsRegular.user,
                      ),
                      style: const TextStyle(),
                      validator: _validateName,
                      enabled: !_isLoading,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('นามสกุล', required: true),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: _inputDecoration(
                        hint: 'กรอกนามสกุล',
                        icon: PhosphorIconsRegular.user,
                      ),
                      style: const TextStyle(),
                      validator: _validateLastName,
                      enabled: !_isLoading,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('เบอร์โทรศัพท์', required: true),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration(
                        hint: '0XX-XXX-XXXX',
                        icon: PhosphorIconsRegular.phone,
                      ),
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(),
                      validator: _validatePhone,
                      enabled: !_isLoading,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('อาชีพ'),
                    TextFormField(
                      controller: _jobController,
                      decoration: _inputDecoration(
                        hint: 'กรอกอาชีพ (ถ้ามี)',
                        icon: PhosphorIconsRegular.briefcase,
                      ),
                      style: const TextStyle(),
                      enabled: !_isLoading,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('ข้อมูลที่อยู่'),
                    LocationSelector(
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
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary
                              .withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: _isLoading ? 0 : 2,
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'กำลังบันทึก...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    PhosphorIconsRegular.checkCircle,
                                    color: Colors.white,
                                    size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'บันทึกข้อมูล',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                // Show photo if available
                if (auth.user?.photoUrl != null) {
                   return ClipOval(
                     child: Image.network(
                       auth.user!.photoUrl!,
                       width: 100,
                       height: 100,
                       fit: BoxFit.cover,
                       errorBuilder: (context, error, stackTrace) {
                         final initial = auth.user?.firstName.substring(0, 1) ?? 'U';
                         return Text(
                           initial,
                           style: TextStyle(
                             fontSize: 40,
                             fontWeight: FontWeight.bold,
                             color: AppColors.primary,
                           ),
                         );
                       },
                     ),
                   );
                }

                final initial = auth.user?.firstName.substring(0, 1) ?? 'U';
                return Text(
                  initial,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isLoading ? null : _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoading 
                ? const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Icon(
                    PhosphorIconsRegular.camera,
                    color: Colors.white,
                    size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          if (required) ...[
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.grey[400] : Colors.grey[500],
      ),
      filled: true,
      fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorStyle: TextStyle(fontSize: 12),
    );
  }
}
