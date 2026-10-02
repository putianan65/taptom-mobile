import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// Round floating button for map toolbars.
class MapFab extends StatelessWidget {
  const MapFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final button = Pressable(
      onTap: onPressed,
      semanticLabel: tooltip,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: active ? p.brand : p.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: p.shadow, blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, size: 21, color: active ? p.onBrand : p.ink),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// Floating title card at the top of a full-screen map.
class MapTopBar extends StatelessWidget {
  const MapTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: EdgeInsets.fromLTRB(onBack == null ? Space.lg : Space.sm, Space.sm, Space.sm, Space.sm),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.96),
        borderRadius: Radii.card,
        border: Border.all(color: p.line),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              tooltip: 'ย้อนกลับ',
              onPressed: onBack,
              icon: const Icon(AppIcons.back),
            ),
            const SizedBox(width: Space.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(subtitle!, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Small colour key for plot statuses on a map.
class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: context.text.labelMedium?.copyWith(color: p.ink)),
          ],
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.94),
        borderRadius: Radii.chip,
        border: Border.all(color: p.line),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          item(const Color(0xFF2F7041), 'อนุมัติแล้ว'),
          item(const Color(0xFFC8931F), 'รอตรวจสอบ'),
          item(const Color(0xFFC0553D), 'ไม่ผ่าน'),
        ],
      ),
    );
  }
}
