import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/traceability_service.dart';
import '../../../core/utils/geo_json_utils.dart';

/// Traceability Report Screen — Public, no login required
/// Displays full farm-to-fork traceability data for a given lot number
class TraceabilityReportScreen extends StatefulWidget {
  final String lotNumber;

  const TraceabilityReportScreen({super.key, required this.lotNumber});

  @override
  State<TraceabilityReportScreen> createState() =>
      _TraceabilityReportScreenState();
}

class _TraceabilityReportScreenState extends State<TraceabilityReportScreen>
    with TickerProviderStateMixin {
  final TraceabilityService _service = TraceabilityService();

  Map<String, dynamic>? _report;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadReport();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final report = await _service.getTraceabilityReport(widget.lotNumber);
      if (!mounted) return;
      setState(() {
        _report = report;
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildReportContent(),
    );
  }

  // ═══════════════════════════════════════════
  // LOADING STATE
  // ═══════════════════════════════════════════

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'กำลังโหลดข้อมูลตรวจสอบย้อนกลับ...',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lot: ${widget.lotNumber}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════════

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsRegular.magnifyingGlassMinus,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ไม่พบข้อมูลล็อต',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ไม่พบข้อมูลสำหรับเลขล็อต "${widget.lotNumber}"\nกรุณาตรวจสอบรหัสล็อตอีกครั้ง',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(PhosphorIconsRegular.arrowLeft),
                  label: Text('กลับ', style: const TextStyle()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _loadReport,
                  icon: const Icon(PhosphorIconsRegular.arrowsClockwise, color: Colors.white),
                  label: Text('ลองใหม่',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // MAIN REPORT CONTENT
  // ═══════════════════════════════════════════

  Widget _buildReportContent() {
    final plot = _report?['plot'] as Map<String, dynamic>? ?? {};
    final farmer = _report?['farmer'] as Map<String, dynamic>? ?? {};
    final gap = _report?['gap'] as Map<String, dynamic>? ?? {};
    final chemicals = (_report?['chemicals'] as List?) ?? [];
    final harvests = (_report?['harvests'] as List?) ?? [];
    final geometry = _report?['geometry'] as Map<String, dynamic>?;
    final lot = _report?['lot'] as Map<String, dynamic>? ?? {};

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          // Header
          _buildSliverHeader(lot, farmer),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Origin / Plot
                _buildOriginSection(plot, geometry),
                const SizedBox(height: 16),

                // Farmer
                _buildFarmerSection(farmer),
                const SizedBox(height: 16),

                // GAP Status
                _buildGapSection(gap),
                const SizedBox(height: 16),

                // Chemical History
                _buildChemicalSection(chemicals),
                const SizedBox(height: 16),

                // Harvest History
                _buildHarvestSection(harvests),
                const SizedBox(height: 16),

                // Footer
                _buildFooter(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SLIVER HEADER
  // ═══════════════════════════════════════════

  Widget _buildSliverHeader(
      Map<String, dynamic> lot, Map<String, dynamic> farmer) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(PhosphorIconsRegular.shareNetwork, color: Colors.white),
          onPressed: _shareReport,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIconsRegular.sealCheck,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Farm-to-Fork Traceability',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ผลการตรวจสอบย้อนกลับ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.qrCode,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Lot: ${widget.lotNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ORIGIN / PLOT SECTION + MAP
  // ═══════════════════════════════════════════

  Widget _buildOriginSection(
      Map<String, dynamic> plot, Map<String, dynamic>? geometry) {
    final plotName = plot['name']?.toString() ?? '-';
    final area = plot['areaRai']?.toString() ?? '-';
    final province = plot['province']?.toString() ?? '-';
    final district = plot['district']?.toString() ?? '-';

    return _buildSection(
      icon: PhosphorIconsRegular.mapPin,
      iconColor: AppColors.primary,
      title: 'แหล่งกำเนิด',
      children: [
        _buildInfoTile('ชื่อแปลง', plotName),
        _buildInfoTile('พื้นที่', '$area ไร่'),
        _buildInfoTile('จังหวัด', province),
        _buildInfoTile('อำเภอ', district),
        if (geometry != null && geometry.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: _buildMiniMap(geometry),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMiniMap(Map<String, dynamic> geometry) {
    final points = GeoJsonUtils.fromPolygon(geometry);
    if (points.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: Center(
          child: Text(
            'ไม่สามารถแสดงแผนที่ได้',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ),
      );
    }

    // Calculate center
    double latSum = 0, lngSum = 0;
    for (final p in points) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    final center = LatLng(latSum / points.length, lngSum / points.length);

    return MapLibreMap(
      initialCameraPosition: CameraPosition(target: center, zoom: 15),
      styleString:
          'https://api.maptiler.com/maps/hybrid/style.json?key=QDE2T3FDvMD9LlgJIFfx',
      onMapCreated: (controller) {
        controller.addFill(FillOptions(
          geometry: [points],
          fillColor: '#2D7A4F',
          fillOpacity: 0.3,
        ));
        controller.addLine(LineOptions(
          geometry: points,
          lineColor: '#2D7A4F',
          lineWidth: 2,
        ));
      },
      compassEnabled: false,
      zoomGesturesEnabled: false,
      scrollGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
    );
  }

  // ═══════════════════════════════════════════
  // FARMER SECTION
  // ═══════════════════════════════════════════

  Widget _buildFarmerSection(Map<String, dynamic> farmer) {
    final name = farmer['fullName']?.toString() ??
        '${farmer['firstName'] ?? ''} ${farmer['lastName'] ?? ''}'.trim();
    final phone = farmer['phone']?.toString() ?? '-';
    final address = farmer['address']?.toString() ?? '-';

    return _buildSection(
      icon: PhosphorIconsRegular.user,
      iconColor: const Color(0xFF3B82F6),
      title: 'ข้อมูลเกษตรกร',
      children: [
        _buildInfoTile('ชื่อ-สกุล', name.isNotEmpty ? name : '-'),
        _buildInfoTile('โทรศัพท์', phone),
        if (address != '-') _buildInfoTile('ที่อยู่', address),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // GAP STATUS SECTION
  // ═══════════════════════════════════════════

  Widget _buildGapSection(Map<String, dynamic> gap) {
    final status = gap['status']?.toString() ?? 'ไม่ทราบ';
    final season = gap['season']?.toString() ?? '-';
    final certifiedDate = gap['certifiedDate']?.toString();

    final isApproved =
        status.toUpperCase() == 'APPROVED' || status.toUpperCase() == 'CERTIFIED';

    return _buildSection(
      icon: PhosphorIconsRegular.shieldCheck,
      iconColor: isApproved ? AppColors.success : AppColors.warning,
      title: 'สถานะมาตรฐาน GAP',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isApproved
                ? AppColors.success.withValues(alpha: 0.08)
                : AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isApproved
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.warning.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isApproved ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.hourglassMedium,
                color: isApproved ? AppColors.success : AppColors.warning,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isApproved ? 'ผ่านการรับรอง' : status,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isApproved ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    if (season != '-')
                      Text(
                        'ฤดูกาล: $season',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (certifiedDate != null)
          _buildInfoTile('วันที่รับรอง', _formatDate(certifiedDate)),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // CHEMICAL HISTORY SECTION
  // ═══════════════════════════════════════════

  Widget _buildChemicalSection(List chemicals) {
    return _buildSection(
      icon: PhosphorIconsRegular.flask,
      iconColor: const Color(0xFFF59E0B),
      title: 'ประวัติการใช้ปัจจัยการผลิต',
      subtitle: '${chemicals.length} รายการล่าสุด',
      children: [
        if (chemicals.isEmpty)
          _buildEmptyIndicator('ไม่มีข้อมูลปัจจัยการผลิต')
        else
          ...chemicals.asMap().entries.map((entry) {
            final chem = entry.value as Map<String, dynamic>;
            final name = chem['name']?.toString() ?? chem['productName']?.toString() ?? '-';
            final type = chem['type']?.toString() ?? '-';
            final date = _formatDate(chem['usageDate']?.toString() ?? chem['dateUsed']?.toString());
            final amount = chem['amount']?.toString() ?? chem['quantity']?.toString() ?? '-';

            return Container(
              margin: EdgeInsets.only(top: entry.key == 0 ? 0 : 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getChemicalColor(type).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getChemicalIcon(type),
                      size: 20,
                      color: _getChemicalColor(type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$type • ปริมาณ: $amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Color _getChemicalColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('ปุ๋ย') || t.contains('fertilizer')) return AppColors.success;
    if (t.contains('สาร') || t.contains('pesticide') || t.contains('chemical')) {
      return AppColors.warning;
    }
    if (t.contains('ชีวภาพ') || t.contains('bio')) return const Color(0xFF8B5CF6);
    return AppColors.info;
  }

  IconData _getChemicalIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('ปุ๋ย') || t.contains('fertilizer')) return PhosphorIconsRegular.plant;
    if (t.contains('สาร') || t.contains('pesticide')) return PhosphorIconsRegular.flask;
    return PhosphorIconsRegular.drop;
  }

  // ═══════════════════════════════════════════
  // HARVEST HISTORY SECTION
  // ═══════════════════════════════════════════

  Widget _buildHarvestSection(List harvests) {
    return _buildSection(
      icon: PhosphorIconsRegular.tractor,
      iconColor: const Color(0xFFFF6F00),
      title: 'ประวัติการเก็บเกี่ยว',
      subtitle: '${harvests.length} รายการล่าสุด',
      children: [
        if (harvests.isEmpty)
          _buildEmptyIndicator('ไม่มีข้อมูลการเก็บเกี่ยว')
        else
          ...harvests.asMap().entries.map((entry) {
            final h = entry.value as Map<String, dynamic>;
            final product = h['productName']?.toString() ?? h['product']?.toString() ?? '-';
            final date = _formatDate(h['harvestDate']?.toString() ?? h['date']?.toString());
            final quantity = h['quantity']?.toString() ?? '-';
            final unit = h['unit']?.toString() ?? 'กก.';
            final lotNum = h['lotNumber']?.toString() ?? '-';

            return Container(
              margin: EdgeInsets.only(top: entry.key == 0 ? 0 : 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6F00).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.leaf,
                          size: 20,
                          color: Color(0xFFFF6F00),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'ปริมาณ: $quantity $unit',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  if (lotNum != '-') ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Lot: $lotNum',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsRegular.sealCheck, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'TapTom Traceability System',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ระบบตรวจสอบย้อนกลับมาตรฐาน GAP',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyIndicator(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(PhosphorIconsRegular.tray,
                size: 36, color: AppColors.textTertiary),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == '-') return '-';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
      ];
      return '${date.day} ${months[date.month]} ${date.year + 543}';
    } catch (_) {
      return dateStr;
    }
  }

  void _shareReport() {
    final text = '''
ผลตรวจสอบย้อนกลับ TapTom
Lot: ${widget.lotNumber}

ตรวจสอบรายละเอียดเพิ่มเติมได้ที่:
https://taptom.app/traceability/${widget.lotNumber}
''';
    SharePlus.instance.share(ShareParams(text: text));
  }
}
