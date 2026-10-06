import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/design.dart';

/// Gives any widget a tactile press: a slight scale-down, a selection haptic
/// and a pointer cursor on the web. Use for cards and custom buttons that do
/// not want a Material ink ripple.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.975,
    this.haptic = true,
    this.semanticLabel,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final String? semanticLabel;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  bool get _active =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return Semantics(
      button: _active,
      enabled: _active,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: _active ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _active ? (_) => _set(true) : null,
          onTapUp: _active ? (_) => _set(false) : null,
          onTapCancel: _active ? () => _set(false) : null,
          onTap: _active
              ? () {
                  if (widget.haptic) HapticFeedback.selectionClick();
                  widget.onTap?.call();
                }
              : null,
          onLongPress: _active ? widget.onLongPress : null,
          child: AnimatedScale(
            scale: _down && !reduce ? widget.scale : 1,
            duration: Motion.instant,
            curve: Motion.standard,
            child: AnimatedOpacity(
              opacity: widget.enabled ? 1 : 0.5,
              duration: Motion.quick,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
