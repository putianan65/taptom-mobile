import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

/// QR Scanner Screen — Public access, no login required
/// Scans QR code to extract lot number and navigates to traceability report
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final TextEditingController _manualController = TextEditingController();
  bool _hasNavigated = false;
  bool _showManualInput = false;
  late AnimationController _animController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasNavigated) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final rawValue = barcode.rawValue!.trim();
    if (rawValue.isEmpty) return;

    // Extract lot number from QR value
    // Supports: plain lot number, or URL like .../traceability/LOT123
    String lotNumber = rawValue;
    if (rawValue.contains('/traceability/')) {
      final parts = rawValue.split('/traceability/');
      lotNumber = parts.last.split('?').first.split('#').first;
    }

    if (lotNumber.isEmpty) return;

    setState(() => _hasNavigated = true);
    _scannerController.stop();
    context.push('/traceability/$lotNumber');
  }

  void _navigateManual() {
    final lotNumber = _manualController.text.trim();
    if (lotNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอกรหัสล็อต', style: const TextStyle()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _hasNavigated = true);
    _scannerController.stop();
    context.push('/traceability/$lotNumber');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Dark overlay with transparent scan area
          _buildOverlay(size, scanAreaSize),

          // Scan line animation
          _buildScanLine(size, scanAreaSize),

          // Top bar
          _buildTopBar(),

          // Bottom controls
          _buildBottomPanel(size),

          // Manual input sheet
          if (_showManualInput) _buildManualInputSheet(size),
        ],
      ),
    );
  }

  Widget _buildOverlay(Size size, double scanAreaSize) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.6),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          // Full screen dark
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          // Transparent scan area
          Center(
            child: Container(
              width: scanAreaSize,
              height: scanAreaSize,
              decoration: BoxDecoration(
                color: Colors.red, // Any color, will be cut out
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanLine(Size size, double scanAreaSize) {
    final top = (size.height - scanAreaSize) / 2;

    return AnimatedBuilder(
      animation: _scanLineAnimation,
      builder: (context, child) {
        return Positioned(
          top: top + (_scanLineAnimation.value * scanAreaSize),
          left: (size.width - scanAreaSize) / 2 + 10,
          child: Container(
            width: scanAreaSize - 20,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.success.withValues(alpha: 0.8),
                  AppColors.success,
                  AppColors.success.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            _buildCircleButton(
              icon: PhosphorIconsRegular.arrowLeft,
              onTap: () => Navigator.of(context).pop(),
            ),
            // Title
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'สแกน QR Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'ตรวจสอบย้อนกลับผลิตภัณฑ์',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            // Flash toggle
            ValueListenableBuilder(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                return _buildCircleButton(
                  icon: state.torchState == TorchState.on
                      ? PhosphorIconsRegular.lightning
                      : PhosphorIconsRegular.lightningSlash,
                  onTap: () => _scannerController.toggleTorch(),
                  isActive: state.torchState == TorchState.on,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? AppColors.success : Colors.white30,
            width: 1.5,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildBottomPanel(Size size) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 24,
          right: 24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'วาง QR Code ไว้ในกรอบเพื่อสแกน',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            // Manual input button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showManualInput = !_showManualInput),
                icon: const Icon(PhosphorIconsRegular.notePencil, color: Colors.white),
                label: Text(
                  'กรอกรหัสล็อตด้วยตัวเอง',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInputSheet(Size size) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'กรอกรหัสล็อต',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'กรอกหมายเลขล็อตจากบรรจุภัณฑ์',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualController,
              autofocus: true,
              style: TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'เช่น L20260224-1234',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onSubmitted: (_) => _navigateManual(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showManualInput = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('ยกเลิก', style: const TextStyle()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _navigateManual,
                    icon: const Icon(PhosphorIconsRegular.magnifyingGlass, color: Colors.white, size: 20),
                    label: Text(
                      'ค้นหา',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
      ),
    );
  }
}
