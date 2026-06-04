import 'package:flutter/material.dart';

/// 🦴 Skeleton Loader Widget
/// Shows animated placeholder while content is loading
///
/// Improves perceived performance by showing realistic content shape
/// instead of just a spinner
///
/// Usage:
/// ```dart
/// if (isLoading) {
///   return SkeletonLoader(
///     width: 300,
///     height: 150,
///     borderRadius: 12,
///   );
/// }
/// ```

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 12,
    this.padding,
    this.margin,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(_animationController);

    // Loop animation
    _animationController.forward();
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: Colors.grey[300]?.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// 🦴 Skeleton Plot Card - Loading state for plot cards
/// Shows 3 skeleton loaders stacked vertically
class SkeletonPlotCard extends StatelessWidget {
  final int count;

  const SkeletonPlotCard({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header line (plot name)
              SkeletonLoader(
                width: double.infinity,
                height: 20,
                borderRadius: 8,
              ),
              const SizedBox(height: 8),
              // Content line 1
              SkeletonLoader(
                width: double.infinity,
                height: 16,
                borderRadius: 8,
              ),
              const SizedBox(height: 6),
              // Content line 2
              SkeletonLoader(width: 200, height: 16, borderRadius: 8),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

/// 🦴 Skeleton Dashboard Widget - Multiple skeletons for dashboard
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // News Carousel skeleton
          SkeletonLoader(width: double.infinity, height: 180, borderRadius: 20),
          const SizedBox(height: 28),

          // Quick Actions skeleton
          SkeletonLoader(width: double.infinity, height: 60, borderRadius: 12),
          const SizedBox(height: 28),

          // Stats Bar skeleton
          SkeletonLoader(width: double.infinity, height: 80, borderRadius: 12),
          const SizedBox(height: 28),

          // Plot Cards skeleton
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  SkeletonLoader(
                    width: double.infinity,
                    height: 100,
                    borderRadius: 12,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

/// 🦴 Skeleton List Tile - Generic list item loader
class SkeletonListTile extends StatelessWidget {
  final int count;
  final double height;

  const SkeletonListTile({super.key, this.count = 5, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(
            width: double.infinity,
            height: height,
            borderRadius: 12,
          ),
        );
      },
    );
  }
}
