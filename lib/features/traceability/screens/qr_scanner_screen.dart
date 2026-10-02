import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/widgets/widgets.dart';

/// Scans the QR on a TAPTOM package and opens its traceability report.
/// A lot code can also be typed in when the label is damaged.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  /// Pulls the lot number out of a scanned value: a bare code or a link
  /// ending in /traceability/{lot}.
  static String? lotFrom(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (value.contains('/traceability/')) {
      final lot = value.split('/traceability/').last.split(RegExp(r'[?#/]')).first;
      return lot.isEmpty ? null : Uri.decodeComponent(lot);
    }
    return value.contains(RegExp(r'\s')) ? null : value;
  }

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  final _scanner = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  late final _line = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  bool _done = false;
  bool _torch = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _line.value = 0.5;
    } else if (!_line.isAnimating) {
      _line.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _line.dispose();
    _scanner.dispose();
    super.dispose();
  }

  void _open(String lot) {
    if (_done) return;
    _done = true;
    HapticFeedback.mediumImpact();
    _scanner.stop();
    context.push('/traceability/${Uri.encodeComponent(lot)}').then((_) {
      if (!mounted) return;
      _done = false;
      _scanner.start();
    });
  }

  void _onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.firstOrNull?.rawValue;
    final lot = raw == null ? null : QrScannerScreen.lotFrom(raw);
    if (lot != null) _open(lot);
  }

  Future<void> _typeCode() async {
    final lot = await AppDialogs.prompt(
      context,
      title: 'กรอกรหัสล็อต',
      message: 'รหัสอยู่ใต้ QR บนบรรจุภัณฑ์',
      hint: 'เช่น TPT-2568-0042',
      confirmLabel: 'ตรวจสอบ',
      maxLines: 1,
    );
    if (lot != null && lot.isNotEmpty && mounted) _open(lot.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final window = (size.shortestSide * 0.68).clamp(200.0, 320.0);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _scanner,
              onDetect: _onDetect,
              errorBuilder: (context, error, _) => _CameraUnavailable(onType: _typeCode),
            ),
            IgnorePointer(
              child: CustomPaint(painter: _Cutout(window: window, color: const Color(0xFF0B110D).withValues(alpha: 0.72))),
            ),
            Center(
              child: SizedBox.square(
                dimension: window,
                child: Stack(
                  children: [
                    const Positioned.fill(child: CustomPaint(painter: _Corners())),
                    AnimatedBuilder(
                      animation: _line,
                      builder: (context, _) => Positioned(
                        left: 16,
                        right: 16,
                        top: 16 + (window - 32) * _line.value,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: const LinearGradient(
                              colors: [Color(0x00E9C46A), Color(0xFFE9C46A), Color(0x00E9C46A)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: top + Space.md,
              left: Space.lg,
              right: Space.lg,
              child: Row(
                children: [
                  _RoundButton(icon: AppIcons.back, tooltip: 'ย้อนกลับ', onTap: () => Navigator.of(context).maybePop()),
                  const Spacer(),
                  _RoundButton(
                    icon: _torch ? AppIcons.sun : AppIcons.sunDim,
                    tooltip: _torch ? 'ปิดไฟฉาย' : 'เปิดไฟฉาย',
                    onTap: () async {
                      await _scanner.toggleTorch();
                      if (mounted) setState(() => _torch = !_torch);
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              left: Space.xl,
              right: Space.xl,
              top: size.height / 2 + window / 2 + Space.xl,
              child: Column(
                children: [
                  Text(
                    'ส่อง QR บนบรรจุภัณฑ์',
                    style: context.text.titleMedium?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ดูแปลงที่ปลูก วันเก็บเกี่ยว และผลการรับรอง GAP',
                    style: context.text.bodySmall?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Positioned(
              left: Space.xl,
              right: Space.xl,
              bottom: bottom + Space.xl,
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: _typeCode,
                  icon: const Icon(AppIcons.edit, size: 18),
                  label: const Text('กรอกรหัสล็อตเอง'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(dimension: 44, child: Icon(icon, color: Colors.white, size: 22)),
        ),
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.onType});

  final VoidCallback onType;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0B110D),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FarmerMascot(size: 120, mood: MascotMood.think),
              const SizedBox(height: Space.lg),
              Text('เปิดกล้องไม่ได้', style: context.text.titleMedium?.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                'อนุญาตให้แอปใช้กล้อง หรือกรอกรหัสล็อตแทน',
                style: context.text.bodySmall?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.xl),
              AppButton(label: 'กรอกรหัสล็อต', onPressed: onType),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dims everything except a rounded square in the middle.
class _Cutout extends CustomPainter {
  const _Cutout({required this.window, required this.color});

  final double window;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(
      Rect.fromCenter(center: size.center(Offset.zero), width: window, height: window),
      const Radius.circular(24),
    );
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Cutout old) => old.window != window || old.color != color;
}

class _Corners extends CustomPainter {
  const _Corners();

  @override
  void paint(Canvas canvas, Size size) {
    const len = 28.0;
    const r = 24.0;
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height;
    final corners = [
      Path()
        ..moveTo(0, len + r)
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(len + r, 0),
      Path()
        ..moveTo(w - len - r, 0)
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
        ..lineTo(w, len + r),
      Path()
        ..moveTo(w, h - len - r)
        ..lineTo(w, h - r)
        ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
        ..lineTo(w - len - r, h),
      Path()
        ..moveTo(len + r, h)
        ..lineTo(r, h)
        ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
        ..lineTo(0, h - len - r),
    ];
    for (final c in corners) {
      canvas.drawPath(c, paint);
    }
  }

  @override
  bool shouldRepaint(_Corners old) => false;
}
