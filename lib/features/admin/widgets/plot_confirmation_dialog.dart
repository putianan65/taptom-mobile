import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Dialogs for admin plot confirmation actions
class PlotConfirmationDialog {
  /// Show dialog to confirm plot approval
  static Future<bool?> showApproval(
    BuildContext context, {
    required String plotName,
    required String ownerName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ยืนยันการอนุมัติแปลง',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คุณต้องการอนุมัติแปลงนี้?',
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
                    'ชื่อแปลง: $plotName',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'เจ้าของ: $ownerName',
                    style: TextStyle(fontSize: 12),
                  ),
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

  /// Show dialog to confirm plot rejection with reason
  static Future<String?> showRejection(
    BuildContext context, {
    required String plotName,
    required String ownerName,
  }) {
    final TextEditingController reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ปฏิเสธแปลง',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ชื่อแปลง: $plotName',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              'เจ้าของ: $ownerName',
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
                hintText: 'เช่น ข้อมูลไม่ครบถ้วน, พื้นที่ไม่เหมาะสม',
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
}
