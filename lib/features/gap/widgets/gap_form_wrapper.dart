import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import '../../../core/utils/thai_date.dart';
import '../gap_categories.dart';

/// Shared frame for the seven GAP forms: a collapsing title with the
/// category code, an unsaved-changes guard, an optional draft action and a
/// pinned save bar.
class GapFormWrapper extends StatelessWidget {
  const GapFormWrapper({
    super.key,
    required this.category,
    required this.child,
    this.subtitle,
    this.onSave,
    this.onSaveDraft,
    this.isSaving = false,
    this.hasUnsavedChanges = true,
    this.saveLabel = 'บันทึกข้อมูล',
    this.readOnly = false,
  });

  final GapCategory category;
  final Widget child;
  final String? subtitle;
  final VoidCallback? onSave;
  final VoidCallback? onSaveDraft;
  final bool isSaving;
  final bool hasUnsavedChanges;
  final String saveLabel;
  final bool readOnly;

  Future<bool> _confirmLeave(BuildContext context) async {
    if (!hasUnsavedChanges || readOnly) return true;
    return AppDialogs.confirm(
      context,
      title: 'ออกจากแบบฟอร์ม?',
      message: 'ข้อมูลที่ยังไม่ได้บันทึกจะหายไป',
      confirmLabel: 'ออก',
      cancelLabel: 'กรอกต่อ',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final canPop = !hasUnsavedChanges || readOnly;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave(context) && context.mounted) Navigator.of(context).pop();
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: PageScaffold(
          title: category.title,
          subtitle: subtitle ?? 'หมวด ${category.code} · ${category.description}',
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: AppIconButton(
                icon: AppIcons.back,
                tooltip: 'ย้อนกลับ',
                onPressed: () async {
                  if (await _confirmLeave(context) && context.mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ),
          actions: [
            if (onSaveDraft != null && !readOnly)
              TextButton.icon(
                onPressed: isSaving ? null : onSaveDraft,
                icon: const Icon(AppIcons.draft, size: 18),
                label: const Text('บันทึกร่าง'),
              ),
            const SizedBox(width: Space.sm),
          ],
          bottomBar: onSave == null || readOnly
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md),
                    decoration: BoxDecoration(
                      color: p.surface,
                      border: Border(top: BorderSide(color: p.line)),
                    ),
                    child: AppButton(
                      label: saveLabel,
                      expand: true,
                      loading: isSaving,
                      onPressed: onSave,
                    ),
                  ),
                ),
          slivers: [
            SliverToBoxAdapter(
              child: ContentWidth(
                maxWidth: Breakpoints.maxForm + 80,
                padding: EdgeInsets.zero,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled group of fields inside a GAP form.
class FormSectionCard extends StatelessWidget {
  const FormSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.example,
    this.icon,
  });

  final String title;
  final String? example;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: p.brand),
                  const SizedBox(width: Space.sm),
                ],
                Expanded(child: Text(title, style: context.text.titleSmall)),
              ],
            ),
            if (example != null && example!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(example!, style: context.text.bodySmall),
            ],
            const SizedBox(height: Space.md),
            child,
          ],
        ),
      ),
    );
  }
}

/// Guidance shown at the top of a form.
class FormInfoCard extends StatelessWidget {
  const FormInfoCard({super.key, required this.message, this.tone = Tone.info, this.title});

  final String message;
  final String? title;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: InlineBanner(tone: tone, title: title, message: message),
    );
  }
}

/// Dropdown of common answers with a free-text "other" option.
class FormDropdownWithOther extends StatefulWidget {
  const FormDropdownWithOther({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
    this.icon,
    this.enabled = true,
  });

  static const other = 'อื่น ๆ (ระบุ)';

  final String label;
  final String hint;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;
  final IconData? icon;
  final bool enabled;

  @override
  State<FormDropdownWithOther> createState() => _FormDropdownWithOtherState();
}

class _FormDropdownWithOtherState extends State<FormDropdownWithOther> {
  final _other = TextEditingController();
  bool _isOther = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(FormDropdownWithOther old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _sync();
  }

  void _sync() {
    final v = widget.value;
    if (v.isNotEmpty && !widget.options.contains(v) && v != FormDropdownWithOther.other) {
      _isOther = true;
      if (_other.text != v) _other.text = v;
    } else {
      _isOther = v == FormDropdownWithOther.other;
    }
  }

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _isOther ? FormDropdownWithOther.other : (widget.value.isEmpty ? null : widget.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(widget.label),
        DropdownButtonFormField<String>(
          value: selected,
          isExpanded: true,
          hint: Text(widget.hint, overflow: TextOverflow.ellipsis),
          decoration: InputDecoration(
            prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 20),
          ),
          items: [
            for (final o in [...widget.options, FormDropdownWithOther.other])
              DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: !widget.enabled
              ? null
              : (v) {
                  setState(() {
                    _isOther = v == FormDropdownWithOther.other;
                    if (!_isOther) _other.clear();
                  });
                  widget.onChanged(_isOther ? _other.text : (v ?? ''));
                },
        ),
        if (_isOther) ...[
          const SizedBox(height: Space.sm),
          AppTextField(
            controller: _other,
            hint: 'ระบุ${widget.label}',
            enabled: widget.enabled,
            onChanged: widget.onChanged,
          ),
        ],
      ],
    );
  }
}

/// Asks whether to save a form that still has empty fields.
Future<bool> showIncompleteFieldsDialog(
  BuildContext context, {
  required String formTitle,
  required List<String> incompleteFields,
}) {
  final list = incompleteFields.take(6).join(', ');
  final more = incompleteFields.length > 6 ? ' และอีก ${incompleteFields.length - 6} รายการ' : '';
  return AppDialogs.confirm(
    context,
    title: 'ยังกรอกไม่ครบ',
    message: 'ยังไม่ได้กรอก $list$more\n\nบันทึกไว้ก่อนแล้วกลับมากรอกต่อภายหลังได้',
    confirmLabel: 'บันทึกเท่าที่มี',
    cancelLabel: 'กลับไปกรอก',
    icon: AppIcons.warning,
  );
}

/// Confirms a successful save with Lung Tom.
Future<void> showGapSuccessDialog(
  BuildContext context, {
  required String formTitle,
  required String formSubtitle,
}) {
  return AppDialogs.message(
    context,
    title: formTitle,
    message: formSubtitle,
    tone: Tone.success,
    mood: MascotMood.joy,
  );
}

/// Primary call to add a record in list-style forms.
class GapAddButton extends StatelessWidget {
  const GapAddButton({super.key, required this.label, required this.onPressed, this.icon = AppIcons.add});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onPressed,
      child: DottedBox(
        color: p.lineStrong,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: p.brand),
              const SizedBox(width: Space.sm),
              Text(label, style: context.text.labelLarge?.copyWith(color: p.brand)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded rectangle with a dashed outline.
class DottedBox extends StatelessWidget {
  const DottedBox({super.key, required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashPainter(color),
      child: child,
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(Radii.lg));
    final path = Path()..addRRect(rrect.deflate(0.75));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// A saved record in list-style forms (inputs, activities, harvests ...).
class GapRecordTile extends StatelessWidget {
  const GapRecordTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.meta,
    this.onTap,
    this.onDelete,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(Space.md + 2, Space.md, Space.xs, Space.md),
        child: Row(
          children: [
            IconTile(icon: icon, size: 40),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if ((subtitle ?? '').isNotEmpty)
                    Text(subtitle!, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if ((meta ?? '').isNotEmpty)
                    Text(meta!, style: context.text.labelSmall?.copyWith(color: p.inkSubtle)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onDelete != null)
              IconButton(
                tooltip: 'ลบ',
                onPressed: onDelete,
                icon: Icon(AppIcons.delete, size: 20, color: p.inkSubtle),
              )
            else
              const SizedBox(width: Space.sm),
          ],
        ),
      ),
    );
  }
}

/// One option in a single-choice list, styled as a selectable card.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.quick,
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: selected ? p.brandSoft : p.surface,
            borderRadius: Radii.control,
            border: Border.all(color: selected ? p.brand : p.line, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: selected ? p.brandStrong : p.inkMuted),
                const SizedBox(width: Space.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleSmall),
                    if (subtitle != null) Text(subtitle!, style: context.text.bodySmall),
                  ],
                ),
              ),
              Icon(
                selected ? AppIcons.checkCircleFill : AppIcons.checkCircle,
                size: 20,
                color: selected ? p.brand : p.lineStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable field that opens the date picker and shows a Thai date.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.hint = 'เลือกวันที่',
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label),
        Pressable(
          onTap: !enabled
              ? null
              : () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: value ?? now,
                    firstDate: firstDate ?? DateTime(now.year - 10),
                    lastDate: lastDate ?? now,
                    locale: const Locale('th', 'TH'),
                  );
                  if (picked != null) onChanged(picked);
                },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            decoration: BoxDecoration(color: p.surfaceSunken, borderRadius: Radii.control),
            child: Row(
              children: [
                Icon(AppIcons.calendar, size: 20, color: p.inkSubtle),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(
                    value == null ? hint : ThaiDate.long(value!),
                    style: context.text.bodyLarge?.copyWith(color: value == null ? p.inkSubtle : p.ink),
                  ),
                ),
                Icon(AppIcons.chevronDown, size: 18, color: p.inkSubtle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
