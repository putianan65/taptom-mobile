import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../design/design.dart';

/// Label placed above the field. Labels above inputs read better in Thai
/// than floating labels and stay visible while typing.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false, this.trailing});

  final String text;
  final bool required;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm, left: 2),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: text,
                children: [
                  if (required)
                    TextSpan(text: ' *', style: TextStyle(color: p.danger)),
                ],
              ),
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: p.ink,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Text field with a label above and optional helper text.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.helper,
    this.icon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.obscure = false,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onTap,
    this.autofillHints,
    this.initialValue,
    this.focusNode,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final IconData? icon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscure;
  final bool required;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final String? initialValue;
  final FocusNode? focusNode;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      obscureText: obscure,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: obscure ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onTap: onTap,
      autofillHints: autofillHints,
      autovalidateMode: autovalidateMode,
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        helperText: helper,
        counterText: '',
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        suffixIcon: suffix,
      ),
    );
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [FieldLabel(label!, required: required), field],
    );
  }
}

/// Search box that debounces input before calling [onChanged].
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.onChanged,
    this.hint = 'ค้นหา',
    this.debounce = const Duration(milliseconds: 300),
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final Duration debounce;
  final TextEditingController? controller;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() {});
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextField(
      controller: _controller,
      onChanged: _changed,
      textInputAction: TextInputAction.search,
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(AppIcons.search, size: 20, color: p.inkSubtle),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'ล้าง',
                icon: Icon(AppIcons.close, size: 18, color: p.inkSubtle),
                onPressed: () {
                  _controller.clear();
                  _changed('');
                },
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

/// Day / month / Buddhist-era year entry used for the birthday credential.
/// Splitting the date avoids a date picker that older users find awkward.
class ThaiDateFields extends StatelessWidget {
  const ThaiDateFields({
    super.key,
    required this.day,
    required this.month,
    required this.year,
    this.obscure = false,
    this.onCompleted,
  });

  final TextEditingController day;
  final TextEditingController month;
  final TextEditingController year;
  final bool obscure;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    Widget box(
      TextEditingController c,
      String hint,
      int length,
      int flex, {
      bool last = false,
    }) {
      return Expanded(
        flex: flex,
        child: TextField(
          controller: c,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          obscureText: obscure,
          obscuringCharacter: '•',
          maxLength: length,
          textInputAction: last ? TextInputAction.done : TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: context.text.titleLarge?.tabular,
          onChanged: (v) {
            if (v.length == length) {
              if (last) {
                FocusScope.of(context).unfocus();
                onCompleted?.call();
              } else {
                FocusScope.of(context).nextFocus();
              }
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      );
    }

    return Row(
      children: [
        box(day, 'วัน', 2, 2),
        const SizedBox(width: Space.sm),
        box(month, 'เดือน', 2, 2),
        const SizedBox(width: Space.sm),
        box(year, 'ปี พ.ศ.', 4, 3, last: true),
      ],
    );
  }
}

/// Row of PIN dots that fill as digits are entered and shake on error.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.error = false,
    this.errorTick = 0,
  });

  final int length;
  final int filled;
  final bool error;

  /// Increment to replay the shake animation.
  final int errorTick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++)
          AnimatedContainer(
            duration: Motion.quick,
            curve: Motion.emphasized,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: i < filled ? 16 : 14,
            height: i < filled ? 16 : 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: error
                  ? p.danger
                  : (i < filled ? p.brand : Colors.transparent),
              border: Border.all(
                color: error ? p.danger : (i < filled ? p.brand : p.lineStrong),
                width: 1.6,
              ),
            ),
          ),
      ],
    );
    if (errorTick == 0 || context.reduceMotion) return row;
    return row
        .animate(key: ValueKey(errorTick))
        .shakeX(hz: 6, amount: 7, duration: const Duration(milliseconds: 420));
  }
}

/// On-screen numeric keypad. Large targets for outdoor use.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
    this.extra,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  /// Optional widget in the bottom-left slot (e.g. biometrics).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget key(String label) => _PadKey(
          enabled: enabled,
          onTap: () => onDigit(label),
          child: Text(
            label,
            style: context.text.headlineMedium?.copyWith(
              fontFamily: AppFonts.text,
              fontWeight: FontWeight.w500,
            ).tabular,
          ),
        );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(children: [for (final d in row) Expanded(child: key(d))]),
          Row(
            children: [
              Expanded(child: extra ?? const SizedBox(height: 72)),
              Expanded(child: key('0')),
              Expanded(
                child: _PadKey(
                  enabled: enabled,
                  onTap: onBackspace,
                  semanticLabel: 'ลบ',
                  child: Icon(AppIcons.backspace, size: 26, color: p.inkMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({
    required this.child,
    required this.onTap,
    required this.enabled,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    onTap();
                  }
                : null,
            child: SizedBox(height: 64, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}
