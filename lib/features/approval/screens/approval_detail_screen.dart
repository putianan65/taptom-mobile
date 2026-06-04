import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../core/services/pdf_service.dart';
import '../widgets/pin_verification_dialog.dart';

class ApprovalDetailScreen extends StatefulWidget {
  final String id;

  const ApprovalDetailScreen({super.key, required this.id});

  @override
  State<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _plotData;
  Map<String, dynamic>? _gapData;
  final GapService _gapService = GapService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final adminService = context.read<AdminService>();

      final results = await Future.wait([
        adminService.getPlotDetail(widget.id),
        _gapService.getGapData(widget.id),
      ]);

      if (mounted) {
        setState(() {
          _plotData = results[0] as Map<String, dynamic>;
          _gapData = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }

  bool _hasData(String key) {
    if (_gapData == null) return false;
    final data = _gapData![key];
    return data != null && (data as Map).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final plot = _plotData ?? {};
    final name = plot['name'] ?? 'ไม่ระบุชื่อ';
    final ownerName = plot['owner']?['firstName'] ?? 'ไม่ระบุชื่อเกษตรกร';
    const crop = 'ข้าว'; // TODO: Get from GAP data
    final area = plot['areaRai'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'ตรวจสอบ: $name',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(name, ownerName, crop, '$area ไร่'),
            const SizedBox(height: 24),
            Text(
              'รายการตรวจสอบ (Checklist)',
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCheckList(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'reject',
                onPressed: () => _showRejectDialog(),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                label: Text(
                  'ส่งแก้ไข',
                  style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.edit),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'approve',
                onPressed: () => _showApproveDialog(),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                label: Text(
                  'อนุมัติ',
                  style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.check_circle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String name, String owner, String crop, String area) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRow('ชื่อแปลง', name),
          const Divider(height: 24),
          _buildRow('เกษตรกร', owner),
          const Divider(height: 24),
          _buildRow('พืช', crop),
          const Divider(height: 24),
          _buildRow('พื้นที่', area),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.prompt(color: Colors.grey[600])),
        Text(
          value,
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildCheckList() {
    final sections = [
      {'key': 'generalInfo', 'label': '1. ข้อมูลทั่วไป'},
      {'key': 'managementInfo', 'label': '2. การจัดการพื้นที่'},
      {'key': 'inputs', 'label': '3. ปัจจัยการผลิต'}, // Separate API for inputs
      {'key': 'safetyInfo', 'label': '4. ความปลอดภัย'},
      {'key': 'postHarvestInfo', 'label': '5. การจัดการหลังเก็บเกี่ยว'},
      {'key': 'field-activities', 'label': '6. กิจกรรมแปลง'}, // Separate API
      {'key': 'harvests', 'label': '7. การเก็บเกี่ยว'}, // Separate API
    ];

    return Column(
      children: sections.map((section) {
        final key = section['key']!;
        // Inputs/Activities/Harvests verification logic is simplification for now
        final isCompleted =
            _hasData(key) ||
            (key == 'inputs' || key == 'field-activities' || key == 'harvests');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: ListTile(
            leading: Icon(
              isCompleted ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isCompleted ? Colors.green : Colors.orange,
            ),
            title: Text(section['label']!, style: GoogleFonts.prompt()),
            subtitle: Text(
              isCompleted ? 'มีข้อมูลแล้ว' : 'ยังไม่มีข้อมูล',
              style: GoogleFonts.prompt(
                fontSize: 12,
                color: isCompleted ? Colors.green : Colors.orange,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showApproveDialog() {
    showDialog(
      context: context,
      builder: (context) => PinVerificationDialog(
        onSuccess: () async {
          Navigator.of(context).pop(); // Close Dialog
          await _approvePlot();
        },
      ),
    );
  }

  Future<void> _approvePlot() async {
    try {
      final adminService = context.read<AdminService>();
      final ownerId = _plotData?['owner']?['id']?.toString();
      final plotName = _plotData?['name']?.toString();
      await adminService.approvePlot(
        widget.id,
        ownerId: ownerId,
        plotName: plotName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อนุมัติแปลงสำเร็จ! กำลังสร้างใบรับรอง...'),
            backgroundColor: Colors.green,
          ),
        );

        // Generate PDF (Mock data for now as we don't have full data mapping yet)
        final pdfService = PdfService();
        final plot = _plotData ?? {};
        await pdfService.generateGapCertificate(
          widget.id,
          plot['owner']?['firstName'] ?? 'เกษตรกร',
          'ข้าว',
        );

        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ระบุเหตุผลที่ต้องแก้ไข',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            decoration: InputDecoration(
              hintText: 'เช่น ข้อมูลสารเคมีไม่ครบถ้วน',
              hintStyle: GoogleFonts.prompt(color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              errorStyle: GoogleFonts.prompt(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณาระบุเหตุผล';
              }
              if (value.trim().length < 5) {
                return 'เหตุผลต้องมีอย่างน้อย 5 ตัวอักษร';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.prompt()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                await _rejectPlot(reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('ส่งแก้ไข', style: GoogleFonts.prompt()),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectPlot(String reason) async {
    try {
      final adminService = context.read<AdminService>();
      final ownerId = _plotData?['owner']?['id']?.toString();
      final plotName = _plotData?['name']?.toString();
      await adminService.rejectPlot(
        widget.id,
        reason,
        ownerId: ownerId,
        plotName: plotName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งกลับแก้ไขสำเร็จ'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
