import 'package:flutter/material.dart';

import '../design/design.dart';
import 'pressable.dart';

/// Selectable option row used in the GAP forms.
class CheckboxOptionCard extends StatelessWidget {
  const CheckboxOptionCard({
    super.key,
    this.title,
    this.subtitle,
    this.label,
    this.description,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String? title;
  final String? subtitle;
  final String? label;
  final String? description;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final heading = title ?? label ?? '';
    final body = subtitle ?? description;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Pressable(
        onTap: onTap,
        scale: 0.985,
        child: AnimatedContainer(
          duration: Motion.quick,
          padding: const EdgeInsets.all(Space.md + 2),
          decoration: BoxDecoration(
            color: isSelected ? p.brandSoft : p.surface,
            borderRadius: Radii.control,
            border: Border.all(
              color: isSelected ? p.brand.withValues(alpha: 0.55) : p.line,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: isSelected ? p.brand : p.inkSubtle),
                const SizedBox(width: Space.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(heading, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                    if (body != null && body.isNotEmpty)
                      Text(body, style: context.text.bodySmall),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: Motion.quick,
                child: Icon(
                  isSelected ? AppIcons.checkCircleFill : AppIcons.checkCircle,
                  key: ValueKey(isSelected),
                  color: isSelected ? p.brand : p.lineStrong,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
