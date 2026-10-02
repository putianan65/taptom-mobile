import 'dart:io';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import '../../auth/widgets/location_selector.dart'; // NEW

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _jobController;
  DateTime? _selectedDate;

  // Address State
  String? _region;
  String? _province;
  String? _district;
  String? _subdistrict;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _jobController = TextEditingController(text: user?.job ?? '');
    
    _selectedDate = user?.birthDate;
    
    // Init Address
    _region = user?.region;
    _province = user?.province;
    _district = user?.district;
    _subdistrict = user?.subdistrict;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate Address if needed (optional for now, but good to check region)
    if (_region == null || _region!.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกภูมิภาค')),
       );
       return;
    }

    setState(() => _isLoading = true);
    
    String? uploadedPhotoUrl;

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      if (currentUser == null) throw Exception('ไม่พบข้อมูลผู้ใช้งาน');
      
      // 1. Upload Photo if changed
      if (_selectedImage != null) {
        uploadedPhotoUrl = await context.read<AdminService>().uploadProfilePhoto(_selectedImage!);
      }

      // 2. Update Profile
      final updatedModel = currentUser.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        job: _jobController.text.trim(),
        birthDate: _selectedDate,
        photoUrl: uploadedPhotoUrl ?? currentUser.photoUrl,
        // Address fields
        region: _region,
        province: _province,
        district: _district,
        subdistrict: _subdistrict,
      );

      // Call Update
      await authProvider.updateProfile(updatedModel);

      if (!mounted) return; // ✅ Fix: Check mounted before using context

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ บันทึกข้อมูลเรียบร้อย'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return; // ✅ Fix: Check mounted before using context
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: Colors.grey[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Current Photo URL
    final currentPhotoUrl = context.select<AuthProvider, String?>((p) => p.currentUser?.photoUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไขข้อมูลส่วนตัว', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo Uploader
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[200]!, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            : (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty)
                                ? Image.network(
                                    currentPhotoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(PhosphorIconsRegular.user, size: 60, color: Colors.grey),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(PhosphorIconsRegular.user, size: 60, color: Colors.grey),
                                  ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        elevation: 4,
                        child: InkWell(
                          onTap: _pickImage,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(PhosphorIconsRegular.camera, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: _buildInputDecoration('ชื่อ', PhosphorIconsRegular.user),
                      validator: (v) => v!.isEmpty ? 'กรุณาระบุชื่อ' : null,
                      style: const TextStyle(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: _buildInputDecoration('นามสกุล', PhosphorIconsRegular.user),
                      validator: (v) => v!.isEmpty ? 'กรุณาระบุนามสกุล' : null,
                      style: const TextStyle(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _buildInputDecoration('เบอร์โทรศัพท์', PhosphorIconsRegular.phone).copyWith(counterText: ""),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'กรุณาระบุเบอร์โทรศัพท์';
                  if (!RegExp(r'^\d+$').hasMatch(v)) return 'เบอร์โทรศัพท์ต้องเป็นตัวเลขเท่านั้น';
                  if (v.length != 10) return 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
                  if (!v.startsWith('0')) return 'เบอร์โทรศัพท์ต้องขึ้นต้นด้วย 0';
                  return null;
                },
                style: const TextStyle(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _jobController, // Occupation
                decoration: _buildInputDecoration('อาชีพ', PhosphorIconsRegular.briefcase),
                 // check prompt: "occupation" -> mapped to job
                style: const TextStyle(),
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _buildInputDecoration('วันเกิด', PhosphorIconsRegular.calendarBlank),
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('d MMMM yyyy', 'th').format(_selectedDate!)
                        : 'เลือกวันเกิด',
                    style: TextStyle(
                      color: _selectedDate != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // Address Selector
              LocationSelector(
                initialRegion: _region,
                initialProvince: _province,
                initialDistrict: _district,
                initialSubdistrict: _subdistrict,
                requireFullAddress: false, // Optional for admin update?
                onChanged: (region, province, district, subdistrict) {
                  setState(() {
                    _region = region;
                    _province = province;
                    _district = district;
                    _subdistrict = subdistrict;
                  });
                },
              ),

              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'บันทึกการแก้ไข',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
}
