import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../design/design.dart';
import '../effects/farmer_mascot.dart';
import 'buttons.dart';

/// Compact status pill. Colour is reserved for status, so badges are the
/// main place tones appear in the interface.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = Tone.neutral,
    this.icon,
    this.dot = true,
  });

  final String label;
  final Tone tone;
  final IconData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = p.toneColor(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.toneSoft(tone),
        borderRadius: Radii.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ] else if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width message strip for warnings and hints inside a page.
class InlineBanner extends StatelessWidget {
  const InlineBanner({
    super.key,
    required this.message,
    this.title,
    this.tone = Tone.info,
    this.icon,
    this.action,
  });

  final String message;
  final String? title;
  final Tone tone;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = p.toneColor(tone);
    return Container(
      padding: const EdgeInsets.all(Space.md + 2),
      decoration: BoxDecoration(
        color: p.toneSoft(tone),
        borderRadius: Radii.control,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ??
                switch (tone) {
                  Tone.danger => AppIcons.warningCircle,
                  Tone.warning => AppIcons.warning,
                  Tone.success || Tone.brand => AppIcons.checkCircle,
                  _ => AppIcons.info,
                },
            size: 20,
            color: fg,
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title!, style: context.text.titleSmall?.copyWith(color: fg)),
                Text(
                  message,
                  style: context.text.bodySmall?.copyWith(color: p.ink),
                ),
                if (action != null) ...[const SizedBox(height: Space.sm), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty state with Lung Tom and an optional call to action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.mood = MascotMood.think,
    this.showMascot = true,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final MascotMood mood;
  final bool showMascot;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Space.xxl,
        vertical: compact ? Space.lg : Space.x3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMascot && icon == null)
            FarmerMascot(size: compact ? 84 : 116, mood: mood)
          else if (icon != null)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: p.surfaceSunken,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: p.inkSubtle),
            ),
          const SizedBox(height: Space.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.titleMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: Space.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: p.inkMuted),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Space.xl),
            AppButton.tonal(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    ).animate().fadeIn(duration: Motion.base).moveY(begin: 8, end: 0);
  }
}

/// Error state with a retry button. Keeps technical detail out of sight.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'โหลดข้อมูลไม่สำเร็จ',
    this.message,
    this.onRetry,
    this.compact = false,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title,
      message: message ?? 'ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต แล้วลองอีกครั้ง',
      mood: MascotMood.think,
      actionLabel: onRetry == null ? null : 'ลองอีกครั้ง',
      onAction: onRetry,
      compact: compact,
    );
  }
}

/// Snackbar-based toasts with a tone icon.
abstract final class AppToast {
  static void show(
    BuildContext context,
    String message, {
    Tone tone = Tone.neutral,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final p = context.palette;
    final iconColor = switch (tone) {
      Tone.success || Tone.brand => context.isDark ? p.success : const Color(0xFF9CCB9A),
      Tone.danger => context.isDark ? p.danger : const Color(0xFFF0A08B),
      Tone.warning => context.isDark ? p.warning : const Color(0xFFE9C46A),
      _ => context.isDark ? p.inkMuted : const Color(0xFFB9C2B9),
    };
    final icon = switch (tone) {
      Tone.success || Tone.brand => AppIcons.checkCircle,
      Tone.danger => AppIcons.warningCircle,
      Tone.warning => AppIcons.warning,
      _ => AppIcons.info,
    };
    if (tone == Tone.danger) HapticFeedback.mediumImpact();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: Space.md),
              Expanded(child: Text(message)),
            ],
          ),
          action: actionLabel == null
              ? null
              : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
          duration: Duration(seconds: tone == Tone.danger ? 5 : 3),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, tone: Tone.success);

  static void error(BuildContext context, String message) =>
      show(context, message, tone: Tone.danger);

  static void info(BuildContext context, String message) =>
      show(context, message, tone: Tone.info);
}

/// Dialogs in one consistent style.
abstract final class AppDialogs {
  /// Asks for confirmation. Returns true only when the user confirms.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'ยืนยัน',
    String cancelLabel = 'ยกเลิก',
    bool destructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogFrame(
        icon: icon ?? (destructive ? AppIcons.warning : AppIcons.help),
        tone: destructive ? Tone.danger : Tone.brand,
        title: title,
        message: message,
        actions: [
          Expanded(
            child: AppButton.secondary(
              label: cancelLabel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: destructive
                ? AppButton.danger(
                    label: confirmLabel,
                    onPressed: () => Navigator.of(context).pop(true),
                  )
                : AppButton(
                    label: confirmLabel,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Single-button message. Use [mood] to bring Lung Tom in.
  static Future<void> message(
    BuildContext context, {
    required String title,
    String? message,
    Tone tone = Tone.info,
    String buttonLabel = 'ตกลง',
    MascotMood? mood,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => _DialogFrame(
        icon: switch (tone) {
          Tone.success || Tone.brand => AppIcons.checkCircle,
          Tone.danger => AppIcons.warningCircle,
          Tone.warning => AppIcons.warning,
          _ => AppIcons.info,
        },
        tone: tone,
        mood: mood,
        title: title,
        message: message,
        actions: [
          Expanded(
            child: AppButton(
              label: buttonLabel,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  /// Prompts for a short text, e.g. a rejection reason.
  static Future<String?> prompt(
    BuildContext context, {
    required String title,
    String? message,
    String hint = '',
    String confirmLabel = 'ยืนยัน',
    bool destructive = false,
    bool required = true,
    int maxLines = 3,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final canSubmit = !required || controller.text.trim().isNotEmpty;
          return _DialogFrame(
            icon: destructive ? AppIcons.warning : AppIcons.edit,
            tone: destructive ? Tone.danger : Tone.brand,
            title: title,
            message: message,
            body: TextField(
              controller: controller,
              autofocus: true,
              maxLines: maxLines,
              minLines: 1,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: hint),
            ),
            actions: [
              Expanded(
                child: AppButton.secondary(
                  label: 'ยกเลิก',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: AppButton(
                  variant:
                      destructive ? ButtonVariant.danger : ButtonVariant.primary,
                  label: confirmLabel,
                  onPressed: canSubmit
                      ? () => Navigator.of(context).pop(controller.text.trim())
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DialogFrame extends StatelessWidget {
  const _DialogFrame({
    required this.icon,
    required this.tone,
    required this.title,
    required this.actions,
    this.message,
    this.body,
    this.mood,
  });

  final IconData icon;
  final Tone tone;
  final String title;
  final String? message;
  final Widget? body;
  final List<Widget> actions;
  final MascotMood? mood;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mood != null)
                Center(child: FarmerMascot(size: 104, mood: mood!))
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: p.toneSoft(tone),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: p.toneColor(tone), size: 22),
                ),
              const SizedBox(height: Space.lg),
              Text(title, style: context.text.headlineSmall),
              if (message != null) ...[
                const SizedBox(height: Space.sm),
                Text(
                  message!,
                  style: context.text.bodyMedium?.copyWith(color: p.inkMuted),
                ),
              ],
              if (body != null) ...[const SizedBox(height: Space.lg), body!],
              const SizedBox(height: Space.xxl),
              Row(children: actions),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: Motion.quick)
        .scaleXY(begin: 0.96, end: 1, duration: Motion.base, curve: Motion.emphasized);
  }
}

/// Modal bottom sheet with a title row and scrollable body.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required Widget child,
  String? title,
  String? subtitle,
  bool expand = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (context) {
      final body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.sm, Space.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.text.headlineSmall),
                        if (subtitle != null)
                          Text(subtitle, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(AppIcons.close),
                    tooltip: 'ปิด',
                  ),
                ],
              ),
            ),
          Flexible(child: child),
        ],
      );
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: expand
            ? SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.85,
                child: body,
              )
            : body,
      );
    },
  );
}
