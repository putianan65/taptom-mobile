import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/gap_service.dart';
import '../../../core/services/admin_service.dart';

class TraceabilityManagementSheet extends StatefulWidget {
  final String plotId;
  final GapService gapService;
  final AdminService adminService;

  const TraceabilityManagementSheet({
    super.key,
    required this.plotId,
    required this.gapService,
    required this.adminService,
  });

  @override
  State<TraceabilityManagementSheet> createState() =>
      _TraceabilityManagementSheetState();
}

class _TraceabilityManagementSheetState
    extends State<TraceabilityManagementSheet> {
  final List<dynamic> _lots = [];
  bool _isLoading = true;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _loadLots();
  }

  Future<void> _loadLots() async {
    setState(() => _isLoading = true);
    try {
      final lots = await widget.gapService.getTraceabilityLots(widget.plotId);
      if (mounted) {
        setState(() {
          _lots.clear();
          _lots.addAll(lots);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ไม่สามารถโหลดข้อมูลได้: $e';
        });
      }
    }
  }

  Future<void> _toggleExported(String id, bool currentValue) async {
    try {
      await widget.adminService.updateTraceability(
        id,
        {'isExported': !currentValue},
      );
      _loadLots(); // Reload
    } catch (e) {
      // Show Error
    }
  }

  Future<void> _deleteLot(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ลบรายการ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        content: Text('ต้องการลบข้อมูลล็อตนี้หรือไม่?', style: GoogleFonts.prompt()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: GoogleFonts.prompt()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('ลบ', style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.adminService.deleteTraceability(id);
        _loadLots();
      } catch (e) {
        // Show Error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(top: 20, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'จัดการ Traceability',
                  style: GoogleFonts.prompt(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.prompt(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadLots,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: Text('ลองใหม่', style: GoogleFonts.prompt(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ),
            )
          else if (_lots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่พบข้อมูลล็อต',
                      style: GoogleFonts.prompt(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
                itemCount: _lots.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final lot = _lots[index];
                  final id = lot['id']?.toString() ?? '';
                  final lotNumber = lot['lotNumber'] ?? id;
                  final isExported = lot['isExported'] == true;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        lotNumber,
                        style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'สถานะ: ${isExported ? "ส่งออกแล้ว" : "รอดำเนินการ"}',
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: isExported ? Colors.green : Colors.orange,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isExported
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isExported ? Colors.green : Colors.grey,
                            ),
                            tooltip: 'เปลี่ยนสถานะส่งออก',
                            onPressed: () => _toggleExported(id, isExported),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteLot(id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
