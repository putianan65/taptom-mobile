import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _oldPinController;
  late TextEditingController _newPinController;
  late TextEditingController _confirmPinController;
  
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _oldPinController = TextEditingController();
    _newPinController = TextEditingController();
    _confirmPinController = TextEditingController();
  }

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  String? _validateOldPin(String? value) {
    if (value == null || value.isEmpty) return 'กรุณากรอก PIN เดิม';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'PIN ต้องเป็นตัวเลขเท่านั้น';
    return null;
  }

  String? _validateNewPin(String? value) {
    if (value == null || value.isEmpty) return 'กรุณากรอก PIN ใหม่';
    if (value.length != 6) return 'PIN ต้องมี 6 หลัก';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'PIN ต้องเป็นตัวเลขเท่านั้น';
    if (value == _oldPinController.text) return 'PIN ใหม่ต้องไม่ซ้ำกับ PIN เดิม';

    // ✅ Weak PIN Check: Repeated digits (e.g. 111111)
    if (RegExp(r'^(\d)\1{5}$').hasMatch(value)) {
      return 'PIN ต้องไม่เป็นตัวเลขซ้ำกัน (เช่น 111111)';
    }

    // ✅ Weak PIN Check: Sequential digits
    const sequences = [
      '012345', '123456', '234567', '345678', '456789', '567890',
      '098765', '987654', '876543', '765432', '654321', '543210'
    ];
    if (sequences.contains(value)) {
      return 'PIN ต้องไม่เป็นตัวเลขเรียงกันง่ายเกินไป';
    }

    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'กรุณายืนยัน PIN ใหม่';
    if (value != _newPinController.text) return 'PIN ไม่ตรงกัน';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthService>().changePin(
        _oldPinController.text,
        _newPinController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ เปลี่ยน PIN สำเร็จ'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPinField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      maxLength: 6,
      validator: validator,
      style: TextStyle(fontSize: 18, letterSpacing: 2),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        counterText: "",
        prefixIcon: const Icon(PhosphorIconsRegular.lockKey),
        suffixIcon: IconButton(
          icon: Icon(obscure ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เปลี่ยนรหัส PIN', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildPinField(
                label: 'PIN เดิม',
                controller: _oldPinController,
                obscure: _obscureOld,
                onToggle: () => setState(() => _obscureOld = !_obscureOld),
                validator: _validateOldPin,
              ),
              const SizedBox(height: 20),
              _buildPinField(
                label: 'PIN ใหม่ (6 หลัก)',
                controller: _newPinController,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: _validateNewPin,
              ),
              const SizedBox(height: 20),
              _buildPinField(
                label: 'ยืนยัน PIN ใหม่',
                controller: _confirmPinController,
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: _validateConfirm,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                        )
                      : Text(
                          'บันทึก',
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
