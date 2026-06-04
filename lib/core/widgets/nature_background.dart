import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum NatureBackgroundType {
  full, // For Login/Sign Up (Full screen cover)
  header, // For Dashboard (Top section only)
}

class NatureBackground extends StatelessWidget {
  final Widget child;
  final NatureBackgroundType type;

  const NatureBackground({
    super.key,
    required this.child,
    this.type = NatureBackgroundType.full,
  });

  const NatureBackground.header({super.key, required this.child})
    : type = NatureBackgroundType.header;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Layer
          if (type == NatureBackgroundType.full)
            _buildFullBackground(context)
          else
            _buildHeaderBackground(context),

          // Abstract Shapes Painter
          CustomPaint(
            painter: NatureCurvesPainter(
              type: type,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            size: Size.infinite,
          ),

          // Child Content
          type == NatureBackgroundType.full
              ? SafeArea(child: child)
              : child, // Header mode manages its own SafeArea/Padding
        ],
      ),
    );
  }

  Widget _buildFullBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF121212),
                  const Color(0xFF1E1E1E),
                  const Color(0xFF2C2C2C),
                ]
              : [
                  AppColors.background,
                  const Color(0xFFE8F5E9),
                  const Color(0xFFC8E6C9),
                ],
        ),
      ),
    );
  }

  Widget _buildHeaderBackground(BuildContext context) {
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.35, // Top 35%
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/ปกกระท่อม.png'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(color: Theme.of(context).scaffoldBackgroundColor),
        ), // Adapt to theme
      ],
    );
  }
}

class NatureCurvesPainter extends CustomPainter {
  final NatureBackgroundType type;
  final bool isDark;

  NatureCurvesPainter({required this.type, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (type == NatureBackgroundType.full) {
      _drawFullMode(canvas, size);
    } else {
      _drawHeaderMode(canvas, size);
    }
  }

  void _drawFullMode(Canvas canvas, Size size) {
    // 1. Lightest Curve (Furthest Background)
    _drawCurve(
      canvas,
      size,
      color: isDark
          ? Colors.white.withOpacity(0.03)
          : AppColors.primaryLight.withOpacity(0.1),
      heightFactor: 0.35,
      curvatureCheck: true,
    );

    // 2. Middle Curve
    _drawCurve(
      canvas,
      size,
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : AppColors.gradientStart.withOpacity(0.15),
      heightFactor: 0.55,
      curvatureCheck: false,
    );

    // 3. Bottom Heavy Curve (Foreground-ish)
    _drawBottomCurve(
      canvas,
      size,
      color: isDark
          ? AppColors.primary.withOpacity(0.1) // Keep a bit of green identity
          : AppColors.primary.withOpacity(0.05),
    );
  }

  void _drawHeaderMode(Canvas canvas, Size size) {
    // Draw subtle curves ONLY in the top area to add texture to the deep green header

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Bubble/Circle 1
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.1), 100, paint);

    // Bubble/Circle 2
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 60, paint);

    // Smooth Wave at the very bottom of the header area could be managed by the container shape,
    // but let's add a subtle overlay curve.
    final path = Path();
    path.moveTo(0, size.height * 0.25);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.35,
      size.width,
      size.height * 0.2,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint..color = Colors.white.withOpacity(0.03));
  }

  void _drawCurve(
    Canvas canvas,
    Size size, {
    required Color color,
    required double heightFactor,
    required bool curvatureCheck,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * heightFactor);

    if (curvatureCheck) {
      path.quadraticBezierTo(
        size.width * 0.5,
        size.height * (heightFactor - 0.15),
        size.width,
        size.height * heightFactor,
      );
    } else {
      path.quadraticBezierTo(
        size.width * 0.25,
        size.height * (heightFactor + 0.1),
        size.width,
        size.height * (heightFactor - 0.1),
      );
    }

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawBottomCurve(Canvas canvas, Size size, {required Color color}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.7,
      size.width,
      size.height * 0.9,
    );
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant NatureCurvesPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.isDark != isDark;
}
