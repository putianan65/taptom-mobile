import 'package:flutter/material.dart';

import '../../../core/utils/status_labels.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/plot_model.dart';

/// List card for a plot: boundary thumbnail, name, size and location, and
/// the review status.
class PlotCard extends StatelessWidget {
  const PlotCard({
    super.key,
    required this.plot,
    this.onTap,
    this.trailing,
    this.showOwner = false,
  });

  final PlotModel plot;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showOwner;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, tone) = StatusLabels.plot(plot.status);
    final area = plot.areaRai == null ? null : '${plot.areaRai!.toStringAsFixed(1)} ไร่';
    final place = [plot.district, plot.province]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(', ');
    final meta = [area, if (place.isNotEmpty) place].whereType<String>().join(' · ');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          Hero(
            tag: 'plot-shape-${plot.id}',
            child: PlotShape(points: plot.boundary, size: 68),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plot.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium,
                ),
                if (showOwner && (plot.ownerName ?? '').isNotEmpty)
                  Text(
                    plot.ownerName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: p.ink),
                  ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                const SizedBox(height: Space.sm),
                Row(
                  children: [
                    StatusBadge(label: label, tone: tone),
                    if ((plot.species ?? '').isNotEmpty) ...[
                      const SizedBox(width: Space.sm),
                      Flexible(
                        child: Text(
                          plot.species!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          trailing ?? Icon(AppIcons.chevronRight, size: 18, color: p.inkSubtle),
        ],
      ),
    );
  }
}
