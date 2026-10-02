import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';

/// Dialogs for admin confirmation actions
class AdminConfirmationDialog {
  /// Show dialog to confirm user approval
  static Future<bool?> showApproval(
    BuildContext context, {
    required UserModel user,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ยืนยันการอนุมัติ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คุณต้องการอนุมัติสมาชิก?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ชื่อ: ${user.fullName}',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'โทรศัพท์: ${user.phone}',
                    style: TextStyle(fontSize: 12),
                  ),
                  if (user.province != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'จังหวัด: ${user.province}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: const TextStyle()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(
              'อนุมัติ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog to confirm user rejection with reason
  static Future<String?> showRejection(
    BuildContext context, {
    required UserModel user,
  }) {
    final TextEditingController reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ปฏิเสธสมาชิก',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ชื่อ: ${user.fullName}',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Text(
              'กรุณาระบุเหตุผลในการปฏิเสธ:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'เช่น ข้อมูลไม่ครบถ้วน',
                hintStyle: TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.pop(context, null);
            },
            child: Text('ยกเลิก', style: const TextStyle()),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text;
              reasonController.dispose();
              if (reason.isNotEmpty) {
                Navigator.pop(context, reason);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(
              'ปฏิเสธ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog to delete user
  static Future<bool?> showDelete(
    BuildContext context, {
    required UserModel user,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ลบสมาชิก',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ยืนยันการลบสมาชิก?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ชื่อ: ${user.fullName}',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'โทรศัพท์: ${user.phone}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'การกระทำนี้ไม่สามารถยกเลิกได้',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: const TextStyle()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Show dialog for editing user details
  static Future<Map<String, String>?> showEdit(
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
                'name': nameController.text,
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
