import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/design.dart';
import 'pressable.dart';

enum ButtonVariant { primary, secondary, tonal, ghost, danger }

enum ButtonSize { regular, compact }

/// The app's button. One component, five variants, consistent height and a
/// built-in loading state that keeps the button width stable.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.regular,
    this.loading = false,
    this.expand = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = ButtonSize.regular,
    this.loading = false,
    this.expand = false,
  }) : variant = ButtonVariant.secondary;

  const AppButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = ButtonSize.regular,
    this.loading = false,
    this.expand = false,
  }) : variant = ButtonVariant.tonal;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = ButtonSize.regular,
    this.loading = false,
    this.expand = false,
  }) : variant = ButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = ButtonSize.regular,
    this.loading = false,
    this.expand = false,
  }) : variant = ButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;
    final (Color bg, Color fg, Color? border) = switch (variant) {
      ButtonVariant.primary => (p.brand, p.onBrand, null),
      ButtonVariant.secondary => (p.surface, p.ink, p.lineStrong),
      ButtonVariant.tonal => (p.brandSoft, p.brandStrong, null),
      ButtonVariant.ghost => (Colors.transparent, p.brand, null),
      ButtonVariant.danger => (p.danger, context.isDark ? p.inkInverse : Colors.white, null),
    };
    final height = size == ButtonSize.regular ? 52.0 : 40.0;
    final hPad = size == ButtonSize.regular ? 20.0 : 14.0;
    final textStyle = (size == ButtonSize.regular
            ? context.text.labelLarge
            : context.text.labelMedium?.copyWith(fontWeight: FontWeight.w600))
        ?.copyWith(color: fg);
    final iconSize = size == ButtonSize.regular ? 20.0 : 17.0;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: fg),
          const SizedBox(width: Space.sm),
        ],
        Flexible(
          child: Text(
            label,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: Space.sm),
          Icon(trailingIcon, size: iconSize, color: fg),
        ],
      ],
    );

    return Pressable(
      enabled: enabled,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
      haptic: false,
      child: AnimatedContainer(
        duration: Motion.quick,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        decoration: BoxDecoration(
          color: enabled || loading ? bg : p.surfaceSunken,
          borderRadius: Radii.control,
          border: border != null ? Border.all(color: border) : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              opacity: loading ? 0 : 1,
              duration: Motion.quick,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: enabled ? fg : p.inkSubtle),
                child: IconTheme.merge(
                  data: IconThemeData(color: enabled ? fg : p.inkSubtle),
                  child: content,
                ),
              ),
            ),
            if (loading)
              SizedBox.square(
                dimension: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: fg,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Square icon button with a tinted background, used in headers and toolbars.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.background,
    this.foreground,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? background;
  final Color? foreground;

  /// Small count bubble on the corner, hidden when null or zero.
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final button = Pressable(
      onTap: onPressed,
      semanticLabel: tooltip,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: background ?? p.surface,
                  borderRadius: BorderRadius.circular(size * 0.32),
                  border: background == null
                      ? Border.all(color: p.line)
                      : null,
                ),
                child: Icon(icon, size: size * 0.48, color: foreground ?? p.ink),
              ),
            ),
            if ((badge ?? 0) > 0)
              Positioned(
                top: -3,
                right: -3,
                child: _CountBubble(count: badge!),
              ),
          ],
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

class _CountBubble extends StatelessWidget {
  const _CountBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.danger,
        borderRadius: Radii.chip,
        border: Border.all(color: p.surface, width: 2),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: context.text.labelSmall?.copyWith(
          color: Colors.white,
          fontSize: 10,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
