import 'package:flutter/material.dart';

import '../design/design.dart';

/// Shimmer driver shared by every skeleton below it, so all placeholders on a
/// screen pulse in sync from a single animation controller.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  static ShimmerState? of(BuildContext context) =>
      context.findAncestorStateOfType<ShimmerState>();

  @override
  State<Shimmer> createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  Animation<double> get animation => _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A single placeholder block.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = Radii.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shimmer = Shimmer.of(context);
    final base = p.surfaceSunken;
    final highlight = Color.lerp(base, p.surface, 0.7)!;
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (shimmer == null) return box;
    return AnimatedBuilder(
      animation: shimmer.animation,
      builder: (context, child) {
        final t = shimmer.animation.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1.6 + 3.2 * t, 0),
            end: Alignment(-0.6 + 3.2 * t, 0),
            colors: [base, highlight, base],
          ).createShader(bounds),
          child: child,
        );
      },
      child: box,
    );
  }
}

/// Placeholder shaped like a list card: thumbnail, two lines and a pill.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.thumbnail = true});

  final bool thumbnail;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.card,
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          if (thumbnail) ...[
            const SkeletonBox(width: 64, height: 64, radius: Radii.sm),
            const SizedBox(width: Space.md),
          ],
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 150, height: 16),
                SizedBox(height: Space.sm),
                SkeletonBox(width: 110, height: 12),
                SizedBox(height: Space.md),
                SkeletonBox(width: 72, height: 20, radius: Radii.pill),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A vertical list of [SkeletonCard]s wrapped in a [Shimmer].
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 4,
    this.thumbnail = true,
    this.padding = EdgeInsets.zero,
  });

  final int count;
  final bool thumbnail;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: padding,
        child: Column(
          children: [
            for (var i = 0; i < count; i++) ...[
              SkeletonCard(thumbnail: thumbnail),
              if (i < count - 1) const SizedBox(height: Space.md),
            ],
          ],
        ),
      ),
    );
  }
}
