import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/nature_background.dart';

/// Support Ticket Screen for Admin/User to contact Super Admin
class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen({super.key});

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  // Mock data for now
  final List<Map<String, dynamic>> _tickets = [
    {
      'id': 'T-001',
      'title': 'ขออนุมัติแก้ข้อมูลแปลง',
      'description': 'ต้องการแก้ไขพิกัดแปลงของนาย ก. เนื่องจากวัดผิด',
      'type': 'REQUEST',
      'status': 'OPEN',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': 'T-002',
      'title': 'App ค้างบ่อย',
      'description': 'หน้าแผนที่โหลดช้ามาก',
      'type': 'REPORT',
      'status': 'CLOSED',
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return NatureBackground.header(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('ช่วยเหลือ & แจ้งปัญหา', style: GoogleFonts.prompt()),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: HeroIcon(HeroIcons.arrowLeft, color: AppColors.textLight),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: _tickets.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) =>
                      _buildTicketCard(_tickets[index]),
                ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateTicketDialog,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add),
          label: Text('สร้างคำร้อง', style: GoogleFonts.prompt()),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: HeroIcon(
              HeroIcons.lifebuoy,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีรายการคำร้อง',
            style: GoogleFonts.prompt(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กดปุ่มด้านล่างเพื่อแจ้งปัญหาหรือขอความช่วยเหลือ',
            style: GoogleFonts.prompt(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status'];
    final isClosed = status == 'CLOSED';
    final color = isClosed ? AppColors.textSecondary : AppColors.primary;
    final type = ticket['type'] == 'REPORT' ? 'แจ้งปัญหา' : 'ขอความช่วยเหลือ';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${ticket['id']} • $type',
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Text(
                status,
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isClosed ? AppColors.textSecondary : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket['title'],
            style: GoogleFonts.prompt(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ticket['description'],
            style: GoogleFonts.prompt(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showCreateTicketDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'สร้างคำร้องใหม่',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'หัวข้อ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'ประเภท',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'REPORT',
                  child: Text('แจ้งปัญหาการใช้งาน'),
                ),
                DropdownMenuItem(
                  value: 'REQUEST',
                  child: Text('ขอความช่วยเหลือ'),
                ),
                DropdownMenuItem(value: 'OTHER', child: Text('อื่นๆ')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'รายละเอียด',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.prompt(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'ส่งคำร้องเรียบร้อยแล้ว (Demo)',
                    style: GoogleFonts.prompt(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'ส่งข้อมูล',
              style: GoogleFonts.prompt(color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }
}
