import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/nature_background.dart';
import '../../../../data/models/pdpa_log_model.dart';

class PdpaLogsScreen extends StatefulWidget {
  const PdpaLogsScreen({super.key});

  @override
  State<PdpaLogsScreen> createState() => _PdpaLogsScreenState();
}

class _PdpaLogsScreenState extends State<PdpaLogsScreen> {
  bool _isLoading = true;
  List<PdpaLog> _logs = [];
  final AdminService _adminService = AdminService(); // Use local instance

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await _adminService.getPdpaLogs();
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NatureBackground.header(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('ประวัติการยอมรับ PDPA', style: GoogleFonts.prompt()),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const HeroIcon(HeroIcons.arrowLeft, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _logs.isEmpty
                  ? Center(child: Text('ไม่พบข้อมูล', style: GoogleFonts.prompt()))
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return _buildLogCard(log);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildLogCard(PdpaLog log) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green[50],
            child: const HeroIcon(HeroIcons.checkBadge, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                   log.user?.fullName ?? 'Unknown User',
                   style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                 ),
                 Text(
                   'Version: ${log.version} • IP: ${log.ipAddress ?? "N/A"}',
                   style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[600]),
                 ),
                 Text(
                   'ยอมรับเมื่อ: ${DateFormatter.formatThaiDateTime(log.acceptedAt)}',
                   style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[500]),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
