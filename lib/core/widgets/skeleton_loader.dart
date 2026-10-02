import 'package:flutter/material.dart';

import '../design/design.dart';
import 'skeleton.dart';

/// Compatibility wrappers over [Shimmer] and [SkeletonBox].
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 12,
    this.padding,
    this.margin,
  });

  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Shimmer(
        child: SkeletonBox(width: width, height: height, radius: borderRadius),
      ),
    );
  }
}

class SkeletonPlotCard extends StatelessWidget {
  const SkeletonPlotCard({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => SkeletonList(count: count);
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key, this.count = 5, this.height = 80});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) => SkeletonList(
        count: count,
        thumbnail: height >= 72,
        padding: const EdgeInsets.all(Space.lg),
      );
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 84, radius: Radii.lg)),
              SizedBox(width: Space.md),
              Expanded(child: SkeletonBox(height: 84, radius: Radii.lg)),
              SizedBox(width: Space.md),
              Expanded(child: SkeletonBox(height: 84, radius: Radii.lg)),
            ],
          ),
          SizedBox(height: Space.xl),
          SkeletonBox(height: 160, radius: Radii.lg),
        ],
      ),
    );
  }
}
