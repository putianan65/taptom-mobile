import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/audit_log_model.dart';
import '../../../core/services/audit_service.dart';

/// Audit log screen to display admin actions history
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<AuditLog> auditLogs = [];
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final service = AuditService();
      final logs = await service.getAuditLogs();
      setState(() {
        auditLogs = logs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่สามารถโหลด Audit Logs: $e',
            style: GoogleFonts.prompt(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'บันทึกการใช้งาน (Audit Logs)',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : auditLogs.isEmpty
          ? _buildEmptyState()
          : _buildAuditList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAuditLogs,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'ไม่มีประวัติการใช้งาน',
            style: GoogleFonts.prompt(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ยังไม่มีรายการบันทึกในขณะนี้',
            style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditList() {
    return RefreshIndicator(
      onRefresh: _loadAuditLogs,
      child: ListView.builder(
        itemCount: auditLogs.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final log = auditLogs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getActionColor(log.action).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getActionIcon(log.action),
                          color: _getActionColor(log.action),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _translateAction(log.action),
                              style: GoogleFonts.prompt(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              log.details,
                              style: GoogleFonts.prompt(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'ผู้ดำเนินการ: ${log.userId ?? "ระบบ (System)"}', 
                          style: GoogleFonts.prompt(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTh(log.timestamp),
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _translateAction(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return 'สร้างข้อมูล';
      case 'update':
        return 'แก้ไขข้อมูล';
      case 'delete':
        return 'ลบข้อมูล';
      case 'approve':
        return 'อนุมัติ';
      case 'reject':
        return 'ปฏิเสธ';
      case 'login':
        return 'เข้าสู่ระบบ';
      case 'logout':
        return 'ออกจากระบบ';
      default:
        return action;
    }
  }

  String _formatDateTh(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final year = date.year + 543;
      final month = _getMonthName(date.month);
      final day = date.day;
      final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      return '$day $month $year เวลา $time น.';
    } catch (e) {
      return timestamp;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return AppColors.success;
      case 'update':
        return Colors.blue;
      case 'delete':
        return AppColors.error;
      case 'approve':
        return AppColors.primary;
      case 'reject':
        return AppColors.warning;
      case 'login':
        return Colors.teal;
      case 'logout':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'approve':
        return Icons.check_circle;
      case 'reject':
        return Icons.cancel;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      default:
        return Icons.info;
    }
  }
}

