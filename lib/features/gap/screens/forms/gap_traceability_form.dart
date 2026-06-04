import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/gap_service.dart';
import '../../widgets/gap_form_wrapper.dart';

class GapTraceabilityForm extends StatefulWidget {
  final String plotId;
  final bool isReadOnly;

  const GapTraceabilityForm({
    super.key, 
    required this.plotId,
    this.isReadOnly = false,
  });

  @override
  State<GapTraceabilityForm> createState() => _GapTraceabilityFormState();
}

class _GapTraceabilityFormState extends State<GapTraceabilityForm> {
  final _gapService = GapService();
  List<dynamic> _harvests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final harvests = await _gapService.getHarvests(widget.plotId);

      if (!mounted) return;
      setState(() {
        _harvests = harvests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ไม่สามารถโหลดข้อมูลได้',
                style: GoogleFonts.prompt(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  // ═══════════════════════════════════════════
  // QR CODE GENERATION & SHARING
  // ═══════════════════════════════════════════

  void _showQrDialog(BuildContext context, String lotId) {
    final qrData = 'https://taptom.app/traceability/$lotId';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const HeroIcon(
                HeroIcons.qrCode,
                color: Colors.deepPurple,
                size: 22,
                style: HeroIconStyle.solid,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'QR Code ล็อต',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.deepPurple,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Lot Number
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                lotId,
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepPurple,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ให้ผู้บริโภคสแกนเพื่อดูข้อมูลผลผลิต',
              style: GoogleFonts.prompt(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('ปิด', style: GoogleFonts.prompt()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _shareQrCode(lotId, qrData);
                  },
                  icon: const Icon(Icons.share, color: Colors.white, size: 18),
                  label: Text(
                    'แชร์ QR Code',
                    style: GoogleFonts.prompt(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _shareQrCode(String lotId, String qrData) {
    SharePlus.instance.share(
      ShareParams(
        text: 'สแกน QR เพื่อตรวจสอบผลผลิต\nLot: $lotId\n$qrData',
      ),
    );
  }

  // ═══════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return GapFormWrapper(
      title: '7. ตรวจติดตาม',
      subtitle: 'ระบบตรวจสอบย้อนกลับ (Traceability)',
      headerIcon: HeroIcons.qrCode,
      headerColor: Colors.deepPurple,
      onSave: widget.isReadOnly ? null : () => navigator.pop(true),
      hasUnsavedChanges: false,
      child: _isLoading
          ? _buildSkeletonLoader()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FormInfoCard(
                    message:
                        'สร้าง QR Code เพื่อให้ผู้บริโภคสแกนตรวจสอบข้อมูลผลผลิตของคุณ',
                    icon: HeroIcons.qrCode,
                    color: Colors.deepPurple,
                  ),

                  FormSectionCard(
                    title: 'ประวัติล็อตการผลิต',
                    example:
                        'รายการล็อตทั้งหมด ${_harvests.length} ล็อต',
                    icon: HeroIcons.clipboardDocumentList,
                    iconColor: Colors.indigo,
                    child: _harvests.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _harvests.asMap().entries.map((entry) {
                              return _buildLotCard(entry.value, entry.key);
                            }).toList(),
                          ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════
  // LOT CARD — with QR Code button
  // ═══════════════════════════════════════════

  Widget _buildLotCard(Map<String, dynamic> harvest, int index) {
    final lotId =
        harvest['lotNumber']?.toString() ??
        harvest['id']?.toString() ??
        'LOT-${DateTime.now().millisecondsSinceEpoch}';
    final date = _formatDate(harvest['harvestDate']);
    final quantity =
        '${harvest['yieldAmount'] ?? '-'} ${harvest['yieldUnit'] ?? 'กก.'}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Lot icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const HeroIcon(
                HeroIcons.cubeTransparent,
                color: Colors.indigo,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Lot info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lotId,
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HeroIcon(
                        HeroIcons.calendarDays,
                        color: Colors.grey,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          date,
                          style: GoogleFonts.prompt(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HeroIcon(
                        HeroIcons.scale,
                        color: Colors.grey,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        quantity,
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ✅ QR Code Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showQrDialog(context, lotId),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HeroIcon(
                        HeroIcons.qrCode,
                        color: Colors.deepPurple,
                        size: 24,
                        style: HeroIconStyle.solid,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'QR',
                        style: GoogleFonts.prompt(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildSkeletonCard(height: 80),
          const SizedBox(height: 16),
          _buildSkeletonCard(height: 200),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.deepPurple.withOpacity(0.3),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: HeroIcon(
              HeroIcons.qrCode,
              color: Colors.grey.shade400,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีข้อมูลการเก็บเกี่ยว',
            style: GoogleFonts.prompt(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'บันทึกข้อมูลในหมวด 4 ก่อนเพื่อสร้าง QR Code',
            style: GoogleFonts.prompt(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('d MMM yyyy', 'th').format(dt);
    } catch (e) {
      return date.toString();
    }
  }
}
