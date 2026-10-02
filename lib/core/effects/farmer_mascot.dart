import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Expressions for Lung Tom (ลุงต้อม), the farmer who guides users through
/// the app.
enum MascotMood {
  /// Smiling and waving; used when greeting.
  wave,

  /// Calm smile; the default idle pose.
  happy,

  /// Eyes closed in a big smile; used after something succeeds.
  joy,

  /// Looking aside with a flat mouth; used for empty and error states.
  think,
}

/// Lung Tom: a Thai farmer in a woven ngob hat, an indigo mo hom shirt and a
/// checked pha khao ma scarf, drawn entirely in code so he stays crisp at any
/// size and can be animated part by part.
///
/// Idle motion is a slow breath, natural blinking and, in [MascotMood.wave],
/// a friendly wave. All motion stops when the platform asks for reduced
/// motion.
class FarmerMascot extends StatefulWidget {
  const FarmerMascot({
    super.key,
    this.size = 160,
    this.mood = MascotMood.happy,
    this.animated = true,
  });

  final double size;
  final MascotMood mood;
  final bool animated;

  @override
  State<FarmerMascot> createState() => _FarmerMascotState();
}

class _FarmerMascotState extends State<FarmerMascot>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier(0.6);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _time.value = 0.6 + elapsed.inMicroseconds / 1e6;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(FarmerMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final run = widget.animated && !reduce;
    if (run && !_ticker.isActive) _ticker.start();
    if (!run && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ลุงต้อม',
      image: true,
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.1,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: MascotPainter(mood: widget.mood, time: _time),
          ),
        ),
      ),
    );
  }
}

/// Paints the mascot inside a 200 x 220 design box scaled to fit.
class MascotPainter extends CustomPainter {
  MascotPainter({required this.mood, required ValueListenable<double> time})
      : _time = time,
        super(repaint: time);

  final MascotMood mood;
  final ValueListenable<double> _time;

  static const _straw = Color(0xFFD8B26A);
  static const _strawDark = Color(0xFFB48A45);
  static const _strawLine = Color(0xFFC49A55);
  static const _skin = Color(0xFFC98A58);
  static const _skinShade = Color(0xFFB0744A);
  static const _ink = Color(0xFF1E2420);
  static const _brow = Color(0xFF4A3B2E);
  static const _stache = Color(0xFF5E4C3D);
  static const _lip = Color(0xFF7A3B2B);
  static const _shirt = Color(0xFF2F3B52);
  static const _shirtShade = Color(0xFF263045);
  static const _scarf = Color(0xFFF1E8D3);
  static const _check = Color(0xFF2F6B3B);
  static const _leaf = Color(0xFF3F7D45);
  static const _leafVein = Color(0xFF9CC79A);
  static const _blush = Color(0x59E28C6E);

  @override
  void paint(Canvas canvas, Size size) {
    final t = _time.value;
    final scale = math.min(size.width / 200, size.height / 220);
    canvas
      ..save()
      ..translate(
        (size.width - 200 * scale) / 2,
        (size.height - 220 * scale) / 2,
      )
      ..scale(scale);

    // Breathing: the head and hat bob a little, the body stays planted.
    final breath = math.sin(t * 2 * math.pi / 3.4);
    final headLift = breath * 1.4;

    // Blink roughly every four seconds, closing for ~140 ms.
    final phase = (t % 4.3) / 4.3;
    var blink = 0.0;
    if (phase > 0.94) {
      final k = (phase - 0.94) / 0.06;
      blink = math.sin(k * math.pi);
    }

    _body(canvas);
    if (mood == MascotMood.wave || mood == MascotMood.joy) {
      final wave = mood == MascotMood.wave
          ? -0.18 + math.sin(t * 2 * math.pi / 1.15) * 0.28
          : 0.22 + math.sin(t * 2 * math.pi / 2.2) * 0.05;
      _arm(canvas, wave);
    }

    canvas
      ..save()
      ..translate(0, -headLift);
    _head(canvas, blink);
    canvas
      ..save()
      ..translate(100, 92)
      ..rotate(math.sin(t * 2 * math.pi / 6.8) * 0.018)
      ..translate(-100, -92);
    _hat(canvas);
    canvas
      ..restore()
      ..restore()
      ..restore();
  }

  void _body(Canvas canvas) {
    final shirt = Path()
      ..moveTo(38, 220)
      ..cubicTo(38, 186, 56, 166, 84, 160)
      ..lineTo(116, 160)
      ..cubicTo(144, 166, 162, 186, 162, 220)
      ..close();
    canvas.drawPath(shirt, Paint()..color = _shirt);
    canvas.drawLine(
      const Offset(100, 178),
      const Offset(100, 220),
      Paint()
        ..color = _shirtShade
        ..strokeWidth = 2,
    );

    final neck = Path()
      ..moveTo(88, 146)
      ..lineTo(112, 146)
      ..lineTo(114, 166)
      ..quadraticBezierTo(100, 172, 86, 166)
      ..close();
    canvas.drawPath(neck, Paint()..color = _skinShade);

    // Pha khao ma: a checked scarf around the neck with one end hanging.
    final scarf = Path()
      ..moveTo(70, 166)
      ..quadraticBezierTo(100, 182, 130, 166)
      ..lineTo(136, 174)
      ..quadraticBezierTo(100, 196, 64, 174)
      ..close()
      ..moveTo(107, 182)
      ..lineTo(122, 179)
      ..lineTo(127, 214)
      ..quadraticBezierTo(118, 218, 110, 216)
      ..close();
    canvas
      ..save()
      ..clipPath(scarf)
      ..drawPaint(Paint()..color = _scarf);
    final vertical = Paint()..color = _check.withValues(alpha: 0.85);
    final horizontal = Paint()..color = _check.withValues(alpha: 0.5);
    for (double x = 56; x < 140; x += 8) {
      canvas.drawRect(Rect.fromLTWH(x, 160, 3, 60), vertical);
    }
    for (double y = 160; y < 220; y += 8) {
      canvas.drawRect(Rect.fromLTWH(56, y, 90, 3), horizontal);
    }
    canvas.restore();
  }

  void _arm(Canvas canvas, double angle) {
    canvas
      ..save()
      ..translate(148, 184)
      ..rotate(angle);
    final sleeve = Path()
      ..moveTo(-12, 2)
      ..quadraticBezierTo(6, -30, 18, -56)
      ..lineTo(36, -50)
      ..quadraticBezierTo(26, -20, 12, 10)
      ..close();
    canvas.drawPath(sleeve, Paint()..color = _shirt);
    // Cuff
    canvas.drawLine(
      const Offset(18, -55),
      const Offset(35, -49),
      Paint()
        ..color = _shirtShade
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    // Open palm with a thumb and four short fingers.
    final skin = Paint()..color = _skin;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(29, -64), width: 20, height: 18),
      skin,
    );
    for (var i = 0; i < 4; i++) {
      final dx = 22.0 + i * 5.2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx - 2.4, -82 + (i == 0 || i == 3 ? 3 : 0), 4.8, 14),
          const Radius.circular(2.4),
        ),
        skin,
      );
    }
    canvas
      ..save()
      ..translate(18, -62)
      ..rotate(-0.7)
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-2.6, -9, 5.2, 12),
          const Radius.circular(2.6),
        ),
        skin,
      )
      ..restore();
    canvas.restore();
  }

  void _head(Canvas canvas, double blink) {
    final shade = Paint()..color = _skinShade;
    canvas
      ..drawOval(Rect.fromCenter(center: const Offset(66, 122), width: 14, height: 18), shade)
      ..drawOval(Rect.fromCenter(center: const Offset(134, 122), width: 14, height: 18), shade);

    final face = Rect.fromCenter(center: const Offset(100, 120), width: 68, height: 74);
    canvas.drawOval(face, Paint()..color = _skin);

    // Shadow cast by the hat brim.
    canvas
      ..save()
      ..clipPath(Path()..addOval(face))
      ..drawOval(
        Rect.fromCenter(center: const Offset(100, 92), width: 92, height: 28),
        Paint()..color = _skinShade.withValues(alpha: 0.55),
      )
      ..restore();

    final blush = Paint()..color = _blush;
    canvas
      ..drawOval(Rect.fromCenter(center: const Offset(80, 134), width: 14, height: 9), blush)
      ..drawOval(Rect.fromCenter(center: const Offset(120, 134), width: 14, height: 9), blush);

    _eyes(canvas, blink);
    _brows(canvas);

    // Smile lines at the outer corners of the eyes.
    final lines = Paint()
      ..color = _skinShade
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(const Offset(75, 121), const Offset(72, 119), lines)
      ..drawLine(const Offset(75, 124), const Offset(72, 125), lines)
      ..drawLine(const Offset(125, 121), const Offset(128, 119), lines)
      ..drawLine(const Offset(125, 124), const Offset(128, 125), lines);

    canvas.drawPath(
      Path()
        ..moveTo(100, 124)
        ..quadraticBezierTo(96, 133, 101, 134),
      Paint()
        ..color = _skinShade
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final stache = Path()
      ..moveTo(100, 137)
      ..cubicTo(94, 134, 86, 136, 84, 141)
      ..cubicTo(90, 141, 95, 141, 100, 139.5)
      ..cubicTo(105, 141, 110, 141, 116, 141)
      ..cubicTo(114, 136, 106, 134, 100, 137)
      ..close();
    canvas.drawPath(stache, Paint()..color = _stache);

    _mouth(canvas);
  }

  void _eyes(Canvas canvas, double blink) {
    if (mood == MascotMood.joy) {
      final arc = Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawPath(
          Path()
            ..moveTo(82, 123)
            ..quadraticBezierTo(87, 116, 92, 123),
          arc,
        )
        ..drawPath(
          Path()
            ..moveTo(108, 123)
            ..quadraticBezierTo(113, 116, 118, 123),
          arc,
        );
      return;
    }
    final look = mood == MascotMood.think ? const Offset(2, -2) : Offset.zero;
    final ry = 4.6 * (1 - blink) + 0.4;
    final eye = Paint()..color = _ink;
    for (final cx in const [87.0, 113.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, 121) + look,
          width: 7.6,
          height: ry * 2,
        ),
        eye,
      );
      if (blink < 0.5) {
        canvas.drawCircle(
          Offset(cx + 1.3, 119.4) + look,
          1.1,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  void _brows(Canvas canvas) {
    final brow = Paint()
      ..color = _brow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final lift = switch (mood) {
      MascotMood.think => -3.0,
      MascotMood.joy || MascotMood.wave => -1.5,
      MascotMood.happy => 0.0,
    };
    final rightLift = mood == MascotMood.think ? 1.0 : lift;
    canvas
      ..drawPath(
        Path()
          ..moveTo(81, 112 + lift)
          ..quadraticBezierTo(87, 109 + lift, 93, 111 + lift),
        brow,
      )
      ..drawPath(
        Path()
          ..moveTo(107, 111 + rightLift)
          ..quadraticBezierTo(113, 109 + rightLift, 119, 112 + rightLift),
        brow,
      );
  }

  void _mouth(Canvas canvas) {
    if (mood == MascotMood.think) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(101, 147.5), width: 6, height: 5),
        Paint()..color = _lip,
      );
      return;
    }
    final open = mood == MascotMood.joy || mood == MascotMood.wave ? 3.0 : 0.0;
    canvas.drawPath(
      Path()
        ..moveTo(91, 145)
        ..quadraticBezierTo(100, 155 + open, 109, 145)
        ..quadraticBezierTo(100, 148, 91, 145)
        ..close(),
      Paint()..color = _lip,
    );
  }

  void _hat(Canvas canvas) {
    // Underside of the brim.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 92), width: 156, height: 26),
      Paint()..color = _strawDark,
    );

    final dome = Path()
      ..moveTo(22, 90)
      ..cubicTo(48, 84, 62, 62, 82, 50)
      ..quadraticBezierTo(100, 40, 118, 50)
      ..cubicTo(138, 62, 152, 84, 178, 90)
      ..quadraticBezierTo(100, 100, 22, 90)
      ..close();
    canvas.drawPath(dome, Paint()..color = _straw);

    // Woven ribs radiating from the crown, plus one band.
    canvas
      ..save()
      ..clipPath(dome);
    final rib = Paint()
      ..color = _strawLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = -6; i <= 6; i++) {
      canvas.drawPath(
        Path()
          ..moveTo(100, 44)
          ..quadraticBezierTo(100 + i * 6.0, 70, 100 + i * 13.0, 100),
        rib,
      );
    }
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(100, 80), width: 96, height: 18),
      math.pi * 1.05,
      math.pi * 0.9,
      false,
      rib..strokeWidth = 2,
    );
    canvas.restore();

    // A kratom leaf tucked into the band.
    canvas
      ..save()
      ..translate(132, 70)
      ..rotate(-0.55);
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(9, -8, 24, -2)
      ..quadraticBezierTo(10, 6, 0, 0)
      ..close();
    canvas
      ..drawPath(leaf, Paint()..color = _leaf)
      ..drawLine(
        Offset.zero,
        const Offset(22, -2),
        Paint()
          ..color = _leafVein
          ..strokeWidth = 1,
      )
      ..restore();

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 45), width: 14, height: 8),
      Paint()..color = _strawDark,
    );
  }

  @override
  bool shouldRepaint(MascotPainter old) => old.mood != mood;
}
