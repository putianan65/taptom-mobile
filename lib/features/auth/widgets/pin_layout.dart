import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/widgets/widgets.dart';

/// Frame for the staff PIN steps: a contour-lined header that marks the
/// secure area, then dots and a large keypad.
class PinLayout extends StatelessWidget {
  const PinLayout({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.dots,
    required this.status,
    required this.pad,
    required this.onBack,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget dots;
  final Widget status;
  final Widget pad;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    final height = MediaQuery.sizeOf(context).height;
    final headerHeight = (height * 0.3).clamp(200.0, 280.0);

    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          SizedBox(
            height: headerHeight + top,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ContourBackdrop(),
                Padding(
                  padding: EdgeInsets.fromLTRB(Space.gutter, top + Space.md, Space.gutter, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppIconButton(
                        icon: AppIcons.back,
                        tooltip: 'ยกเลิกการเข้าสู่ระบบ',
                        onPressed: onBack,
                        background: Colors.white.withValues(alpha: 0.12),
                        foreground: p.heroInk,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: p.heroInk, size: 22),
                          ),
                          const SizedBox(width: Space.md),
                          Text(
                            eyebrow,
                            style: context.text.labelLarge?.copyWith(
                              color: p.heroInk.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.md),
                      Text(
                        title,
                        style: context.text.headlineLarge?.copyWith(color: p.heroInk),
                      ).animate().fadeIn(duration: Motion.slow).moveY(begin: 8, end: 0),
                      Text(
                        subtitle,
                        style: context.text.bodyMedium?.copyWith(
                          color: p.heroInk.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: Space.xxl),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: Space.xl),
                      dots,
                      const SizedBox(height: Space.lg),
                      SizedBox(height: 44, child: Center(child: status)),
                      const SizedBox(height: Space.sm),
                      pad,
                      const SizedBox(height: Space.lg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
