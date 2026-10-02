import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/auth_provider.dart';

/// Animated splash. Restores the saved session in parallel with a short
/// intro (a living field at dawn, the mark, then Lung Tom), and hands over to
/// the right home screen as soon as both are done.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minimumIntro = Duration(milliseconds: 1900);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();
    final reduce = MediaQuery.of(context).disableAnimations;
    await Future.wait([
      if (!auth.isRestored) auth.restoreSession(),
      Future.delayed(reduce ? const Duration(milliseconds: 400) : _minimumIntro),
    ]);
    if (!mounted) return;
    final user = auth.currentUser;
    context.go(user == null ? Routes.login : Routes.homeFor(user.role));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = MediaQuery.sizeOf(context);
    final mascotSize = (size.shortestSide * 0.42).clamp(140.0, 220.0);

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FieldBackdrop(horizon: 0.5),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: size.height * 0.12),
                const LogoMark(size: 76)
                    .animate()
                    .fadeIn(duration: Motion.slow)
                    .scaleXY(begin: 0.85, end: 1, curve: Motion.emphasized, duration: Motion.slower),
                const SizedBox(height: Space.xl),
                Text(
                  'TAPTOM',
                  style: context.text.displayMedium?.copyWith(letterSpacing: 4),
                )
                    .animate(delay: 180.ms)
                    .fadeIn(duration: Motion.slow)
                    .moveY(begin: 10, end: 0, curve: Motion.emphasized),
                const SizedBox(height: Space.xs),
                Text(
                  'สมุดบันทึกแปลงดิจิทัล\nมาตรฐาน GAP และการตรวจสอบย้อนกลับ',
                  textAlign: TextAlign.center,
                  style: context.text.bodyLarge?.copyWith(color: p.inkMuted),
                ).animate(delay: 320.ms).fadeIn(duration: Motion.slow),
                const Spacer(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: FarmerMascot(size: mascotSize, mood: MascotMood.wave)
                  .animate(delay: 420.ms)
                  .fadeIn(duration: Motion.slow)
                  .moveY(begin: 60, end: 0, curve: Motion.emphasized, duration: 700.ms),
            ),
          ),
        ],
      ),
    );
  }
}
