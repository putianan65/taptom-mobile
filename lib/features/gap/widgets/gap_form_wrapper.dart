import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';

/// Wrapper for GAP forms to ensure consistent layout and styling
class GapFormWrapper extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData headerIcon;
  final Color headerColor;
  final Widget child;
  final VoidCallback? onSave;
  final VoidCallback? onSaveDraft; // Optional draft save
  final bool isSaving;
  final bool hasUnsavedChanges; // GAP-FIX-002: Track unsaved changes

  const GapFormWrapper({
    super.key,
    required this.title,
    required this.subtitle,
    required this.headerIcon,
    required this.headerColor,
    required this.child,
    this.onSave,
    this.onSaveDraft,
    this.isSaving = false,
    this.hasUnsavedChanges = true, // Default to true for safety
  });

  @override
  State<GapFormWrapper> createState() => _GapFormWrapperState();
}

class _GapFormWrapperState extends State<GapFormWrapper> {
  Future<bool> _onWillPop() async {
    // GAP-FIX-002: Only show confirmation if there are unsaved changes
    if (!widget.hasUnsavedChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'ออกจากฟอร์ม?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'ข้อมูลที่ยังไม่ได้บันทึกจะสูญหาย\nคุณต้องการออกหรือไม่?',
          style: const TextStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'ออก',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // GAP-BUG-002: Wrap with PopScope to confirm before discarding unsaved data
    return PopScope(
      canPop: !widget.hasUnsavedChanges, // GAP-FIX-002: Allow pop if no unsaved changes
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.textPrimary),
            onPressed: () async {
              // GAP-FIX-002: Use shared method for consistent behavior
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (widget.onSaveDraft != null)
              TextButton(
                onPressed: widget.isSaving ? null : widget.onSaveDraft,
                child: Text(
                  'บันทึกร่าง',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
        bottomNavigationBar: widget.onSave == null ? null : Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.isSaving ? null : widget.onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: widget.isSaving
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.textLight,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'บันทึกข้อมูล',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
          ),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior
              .onDrag, // GAP-BUG-014: Dismiss keyboard on scroll
          child: Column(
            children: [
              // Header Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.headerColor.withValues(alpha: 0.8), widget.headerColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.headerColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.headerIcon,
                        color: AppColors.textLight,
                        size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Reusable content area
              const SizedBox(
                height: 24,
              ), // GAP-FIX: Ensure spacing between header and content
              widget.child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard form section card
class FormSectionCard extends StatelessWidget {
  final String title;
  final String example;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const FormSectionCard({
    super.key,
    required this.title,
    required this.example,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        example,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Info card for form guidance
class FormInfoCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const FormInfoCard({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown with "Other" option support
class FormDropdownWithOther extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;
  final IconData icon;

  const FormDropdownWithOther({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  State<FormDropdownWithOther> createState() => _FormDropdownWithOtherState();
}

class _FormDropdownWithOtherState extends State<FormDropdownWithOther> {
  final TextEditingController _otherController = TextEditingController();
  bool _isOther = false;

  @override
  void initState() {
    super.initState();
    _checkIfOther();
  }

  @override
  void didUpdateWidget(FormDropdownWithOther oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _checkIfOther();
    }
  }

  void _checkIfOther() {
    if (widget.value.isNotEmpty && !widget.options.contains(widget.value)) {
      _isOther = true;
      _otherController.text = widget.value;
    } else {
      _isOther = widget.value == 'อื่นๆ (ระบุ)';
    }
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _isOther ? 'อื่นๆ (ระบุ)' : widget.value.isEmpty ? null : widget.value,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(widget.icon, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.hint,
                        style: TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              isExpanded: true,
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(PhosphorIconsRegular.caretDown, color: Colors.grey, size: 20),
              ),
              items: [
                ...widget.options.map((option) => DropdownMenuItem(
                  value: option,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      option,
                      style: const TextStyle(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )),
                DropdownMenuItem(
                  value: 'อื่นๆ (ระบุ)',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'อื่นๆ (ระบุ)',
                      style: const TextStyle(),
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _isOther = value == 'อื่นๆ (ระบุ)';
                  if (!_isOther) {
                    _otherController.clear();
                  }
                });
                widget.onChanged(value ?? '');
              },
            ),
          ),
        ),

        // Other text field
        if (_isOther) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _otherController,
            decoration: InputDecoration(
              hintText: 'ระบุ${widget.label}',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(),
            onChanged: widget.onChanged,
          ),
        ],
      ],
    );
  }
}

/// Dialog for incomplete fields
Future<bool> showIncompleteFieldsDialog(
  BuildContext context, {
  required String formTitle,
  required List<String> incompleteFields,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(PhosphorIconsRegular.warning, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ข้อมูลไม่ครบถ้วน',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ฟอร์ม "$formTitle" มีข้อมูลที่ยังไม่ได้กรอก:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              ...incompleteFields.map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsFill.circle, size: 6, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(field, style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Text(
                'คุณต้องการบันทึกต่อไปหรือไม่?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('กลับไปกรอก', style: const TextStyle()),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('บันทึกต่อไป', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Success dialog after form submission
Future<void> showGapSuccessDialog(
  BuildContext context, {
  required String formTitle,
  required String formSubtitle,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsFill.checkCircle,
              color: AppColors.success,
              size: 64,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            formTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            formSubtitle,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'ตกลง',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
