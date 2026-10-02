import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';

/// Dialog for editing user details
class EditUserDialog {
  /// Show edit user dialog
  static Future<Map<String, String>?> show(
    BuildContext context, {
    required UserModel user,
  }) {
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone);

    return showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'แก้ไขข้อมูลสมาชิก',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'ชื่อ-นามสกุล',
                labelStyle: const TextStyle(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'เบอร์โทรศัพท์',
                labelStyle: const TextStyle(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              phoneController.dispose();
              Navigator.pop(context, null);
            },
            child: Text('ยกเลิก', style: const TextStyle()),
          ),
          ElevatedButton(
            onPressed: () {
              final result = {
                'fullName': nameController.text,
                'phone': phoneController.text,
              };
              nameController.dispose();
              phoneController.dispose();
              Navigator.pop(context, result);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              'บันทึก',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
