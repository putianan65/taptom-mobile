import 'package:flutter/material.dart';

import '../design/design.dart';
import '../effects/farmer_mascot.dart';
import 'feedback.dart';

/// Legacy dialog API, now rendered with [AppDialogs] so every popup in the
/// app shares one style. Prefer [AppDialogs] and [AppToast] in new code.
abstract final class CustomPopup {
  static String _join(String message, String? detail) =>
      detail == null || detail.isEmpty ? message : '$message\n\n$detail';

  static Future<void> showSuccess(
    BuildContext context, {
    String? title,
    required String message,
    String? detail,
    String? buttonText,
    VoidCallback? onDismiss,
    VoidCallback? onConfirm,
  }) async {
    // onConfirm historically closed the dialog itself, so it runs in place of
    // the default pop.
    if (onConfirm != null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => _LegacyDialog(
          title: title ?? 'สำเร็จ',
          message: _join(message, detail),
          tone: Tone.success,
          mood: MascotMood.joy,
          buttonText: buttonText ?? 'ตกลง',
          onPressed: onConfirm,
        ),
      );
      return;
    }
    await AppDialogs.message(
      context,
      title: title ?? 'สำเร็จ',
      message: _join(message, detail),
      tone: Tone.success,
      mood: MascotMood.joy,
      buttonLabel: buttonText ?? 'ตกลง',
    );
    onDismiss?.call();
  }

  static Future<void> showApiError(
    BuildContext context, {
    String? title,
    required String message,
    String? code,
    VoidCallback? onDismiss,
  }) =>
      showError(
        context,
        title: title,
        message: message,
        detail: code == null ? null : 'รหัสข้อผิดพลาด: $code',
        onDismiss: onDismiss,
      );

  static Future<void> showError(
    BuildContext context, {
    String? title,
    required String message,
    String? detail,
    VoidCallback? onDismiss,
  }) async {
    await AppDialogs.message(
      context,
      title: title ?? 'ทำรายการไม่สำเร็จ',
      message: _join(message.replaceFirst('Exception: ', ''), detail),
      tone: Tone.danger,
    );
    onDismiss?.call();
  }

  static Future<void> showInfo(
    BuildContext context, {
    String? title,
    required String message,
    String? detail,
    VoidCallback? onDismiss,
  }) async {
    await AppDialogs.message(
      context,
      title: title ?? 'แจ้งเพื่อทราบ',
      message: _join(message, detail),
      tone: Tone.info,
    );
    onDismiss?.call();
  }

  static Future<void> showWarning(
    BuildContext context, {
    String? title,
    required String message,
    String? detail,
    VoidCallback? onDismiss,
  }) async {
    await AppDialogs.message(
      context,
      title: title ?? 'โปรดตรวจสอบ',
      message: _join(message, detail),
      tone: Tone.warning,
    );
    onDismiss?.call();
  }

  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String? detail,
    String confirmText = 'ยืนยัน',
    String cancelText = 'ยกเลิก',
  }) =>
      AppDialogs.confirm(
        context,
        title: title,
        message: _join(message, detail),
        confirmLabel: confirmText,
        cancelLabel: cancelText,
      );
}

class _LegacyDialog extends StatelessWidget {
  const _LegacyDialog({
    required this.title,
    required this.message,
    required this.tone,
    required this.mood,
    required this.buttonText,
    required this.onPressed,
  });

  final String title;
  final String message;
  final Tone tone;
  final MascotMood mood;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FarmerMascot(size: 104, mood: mood),
              const SizedBox(height: Space.lg),
              Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: Space.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: p.inkMuted),
              ),
              const SizedBox(height: Space.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: onPressed, child: Text(buttonText)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
