import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/design.dart';
import 'pressable.dart';

/// Flat card with a hairline border. Depth comes from the border and the
/// paper background, not from drop shadows.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = Radii.card,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final BorderRadius radius;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final box = Container(
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? p.line),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Pressable(onTap: onTap, scale: 0.985, child: box);
  }
}

/// Section title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: Space.md),
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: context.text.titleMedium),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Small rounded square holding an icon, tinted by tone.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.tone = Tone.brand,
    this.size = 40,
    this.filled = false,
  });

  final IconData icon;
  final Tone tone;
  final double size;

  /// Solid background with inverse icon instead of a soft tint.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = p.toneColor(tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? fg : p.toneSoft(tone),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: filled ? p.surface : fg,
      ),
    );
  }
}

/// Inset grouped list: rows share one card and are separated by hairlines.
class ListGroup extends StatelessWidget {
  const ListGroup({super.key, required this.children, this.header});

  final List<Widget> children;
  final String? header;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(Divider(height: 1, indent: 64, color: p.line));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: Space.sm),
            child: Text(header!, style: context.text.labelMedium),
          ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: Radii.card,
            border: Border.all(color: p.line),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

/// A row inside [ListGroup] or a standalone list.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.tone = Tone.brand,
    this.destructive = false,
    this.showChevron,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Tone tone;
  final bool destructive;

  /// Defaults to true when [onTap] is set and there is no [trailing].
  final bool? showChevron;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final effectiveTone = destructive ? Tone.danger : tone;
    final chevron = showChevron ?? (onTap != null && trailing == null);
    final lead = leading ??
        (icon != null ? IconTile(icon: icon!, tone: effectiveTone, size: 36) : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: dense ? Space.sm + 2 : Space.md,
          ),
          child: Row(
            children: [
              if (lead != null) ...[lead, const SizedBox(width: Space.md)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.titleSmall?.copyWith(
                        color: destructive ? p.danger : p.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        style: context.text.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: Space.sm),
                trailing!,
              ],
              if (chevron) ...[
                const SizedBox(width: Space.xs),
                Icon(AppIcons.chevronRight, size: 18, color: p.inkSubtle),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Label/value pair for detail screens.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
    this.icon,
    this.trailing,
  });

  final String label;
  final String value;
  final bool mono;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final valueStyle = context.text.bodyMedium?.copyWith(
      color: p.ink,
      fontWeight: FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: p.inkSubtle),
            ),
            const SizedBox(width: Space.md),
          ],
          Expanded(
            flex: 4,
            child: Text(label, style: context.text.bodyMedium?.copyWith(color: p.inkMuted)),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            flex: 6,
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: mono ? valueStyle?.mono : valueStyle,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: Space.sm), trailing!],
        ],
      ),
    );
  }
}

/// Thin labelled divider, e.g. "หรือ".
class LabeledDivider extends StatelessWidget {
  const LabeledDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          child: Text(label, style: context.text.labelMedium),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
