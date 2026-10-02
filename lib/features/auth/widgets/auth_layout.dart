import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/widgets/widgets.dart';

/// Shared frame for sign-in, sign-up and the PIN steps.
///
/// Phones get the living field as a header with the form on a paper sheet
/// that slides over it. Wide windows split into a scenic panel and a centred
/// form column.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.mood = MascotMood.wave,
    this.heroTitle = 'ปลูกอย่างมีมาตรฐาน\nตรวจสอบได้ทุกต้น',
    this.heroBody =
        'บันทึกแปลง เก็บข้อมูล GAP ครบทั้ง 7 หมวด และออกเลข Lot ให้ผู้ซื้อสแกนตรวจสอบย้อนกลับได้',
    this.topAction,
    this.footer,
    this.onBack,
    this.compactHero = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final MascotMood mood;
  final String heroTitle;
  final String heroBody;

  /// Small action in the top-right corner of the hero.
  final Widget? topAction;
  final Widget? footer;

  /// Shows a back button in the hero when set.
  final VoidCallback? onBack;

  /// Shorter header for long forms such as sign-up.
  final bool compactHero;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 960 ? _wide(context) : _compact(context);
  }

  Widget _formColumn(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: context.text.headlineLarge),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: Space.xs),
          Text(
            subtitle!,
            style: context.text.bodyMedium?.copyWith(color: p.inkMuted),
          ),
        ],
        const SizedBox(height: Space.xxl),
        child,
        if (footer != null) ...[const SizedBox(height: Space.x3), footer!],
      ],
    );
  }

  Widget _compact(BuildContext context) {
    final p = context.palette;
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final heroHeight = (size.height * (compactHero ? 0.24 : 0.34))
        .clamp(compactHero ? 170.0 : 230.0, 340.0);
    final mascotSize = (heroHeight * 0.62).clamp(110.0, 170.0);

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight + 40,
            child: FieldBackdrop(horizon: compactHero ? 0.62 : 0.55),
          ),
          Positioned(
            top: top + Space.md,
            left: Space.gutter,
            right: Space.md,
            child: Row(
              children: [
                if (onBack != null) ...[
                  AppIconButton(
                    icon: AppIcons.back,
                    tooltip: 'ย้อนกลับ',
                    onPressed: onBack,
                  ),
                  const SizedBox(width: Space.md),
                ],
                const Wordmark(markSize: 36),
                const Spacer(),
                if (topAction != null) topAction!,
              ],
            ),
          ),
          if (!compactHero)
            Positioned(
              right: Space.lg,
              top: heroHeight - mascotSize * 0.98 + 6,
              child: FarmerMascot(size: mascotSize, mood: mood)
                  .animate()
                  .fadeIn(duration: Motion.slow)
                  .moveY(begin: 24, end: 0, curve: Motion.emphasized),
            ),
          Positioned.fill(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: EdgeInsets.only(top: heroHeight),
                child: Container(
                  constraints: BoxConstraints(minHeight: size.height - heroHeight),
                  decoration: BoxDecoration(
                    color: p.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: Breakpoints.maxForm),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          Space.gutter + 4,
                          Space.x3,
                          Space.gutter + 4,
                          Space.x3 + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: _formColumn(context)
                            .animate()
                            .fadeIn(duration: Motion.slow, curve: Motion.standard)
                            .moveY(begin: 16, end: 0, curve: Motion.emphasized),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wide(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: Row(
        children: [
          Expanded(
            flex: 11,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const FieldBackdrop(horizon: 0.6),
                Padding(
                  padding: const EdgeInsets.fromLTRB(56, 48, 56, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (onBack != null) ...[
                            AppIconButton(
                              icon: AppIcons.back,
                              tooltip: 'ย้อนกลับ',
                              onPressed: onBack,
                            ),
                            const SizedBox(width: Space.lg),
                          ],
                          const Wordmark(
                            markSize: 44,
                            subtitle: 'ระบบบันทึกแปลงและมาตรฐาน GAP',
                          ),
                        ],
                      ),
                      const SizedBox(height: 56),
                      Text(heroTitle, style: context.text.displayMedium)
                          .animate()
                          .fadeIn(duration: Motion.slower)
                          .moveY(begin: 12, end: 0, curve: Motion.emphasized),
                      const SizedBox(height: Space.lg),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Text(
                          heroBody,
                          style: context.text.bodyLarge?.copyWith(color: p.inkMuted),
                        ),
                      ).animate(delay: 150.ms).fadeIn(duration: Motion.slower),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 64,
                  child: FarmerMascot(size: 230, mood: mood)
                      .animate(delay: 200.ms)
                      .fadeIn(duration: Motion.slow)
                      .moveY(begin: 40, end: 0, curve: Motion.emphasized),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 9,
            child: Stack(
              children: [
                if (topAction != null)
                  Positioned(top: 32, right: 32, child: topAction!),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _formColumn(context)
                          .animate()
                          .fadeIn(duration: Motion.slow)
                          .moveX(begin: 16, end: 0, curve: Motion.emphasized),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
