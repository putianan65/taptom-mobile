import 'package:flutter/material.dart';

import '../../../core/constants/pdpa_content.dart';
import '../../../core/widgets/widgets.dart';

/// PDPA consent. The accept button unlocks only after the user has scrolled
/// to the end of the notice and ticked the confirmation.
class PdpaConsentDialog extends StatefulWidget {
  const PdpaConsentDialog({super.key});

  /// Returns true when the user accepts.
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => const PdpaConsentDialog(),
    );
    return result ?? false;
  }

  @override
  State<PdpaConsentDialog> createState() => _PdpaConsentDialogState();
}

class _PdpaConsentDialogState extends State<PdpaConsentDialog> {
  final _scroll = ScrollController();
  bool _readToEnd = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (!_readToEnd &&
          _scroll.position.pixels >= _scroll.position.maxScrollExtent - 48) {
        setState(() => _readToEnd = true);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.md),
            child: Row(
              children: [
                const IconTile(icon: AppIcons.privacy),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ความยินยอม PDPA', style: context.text.headlineSmall),
                      Text(
                        'พ.ร.บ.คุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: p.line),
          Expanded(
            child: Scrollbar(
              controller: _scroll,
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(Space.xl, Space.lg, Space.xl, Space.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(PdpaContent.title, style: context.text.titleMedium),
                    const SizedBox(height: Space.md),
                    Text(
                      PdpaContent.fullContent,
                      style: context.text.bodyMedium?.copyWith(height: 1.7),
                    ),
                    const SizedBox(height: Space.lg),
                    Text(
                      PdpaContent.references,
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              Space.xl,
              Space.md,
              Space.xl,
              Space.md + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(top: BorderSide(color: p.line)),
            ),
            child: Column(
              children: [
                AnimatedOpacity(
                  opacity: _readToEnd ? 1 : 0.5,
                  duration: Motion.quick,
                  child: CheckboxListTile(
                    value: _checked,
                    onChanged: _readToEnd ? (v) => setState(() => _checked = v ?? false) : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'ข้าพเจ้าได้อ่านและยินยอมให้เก็บ ใช้ และเปิดเผยข้อมูลส่วนบุคคลตามที่ระบุไว้',
                      style: context.text.bodyMedium,
                    ),
                  ),
                ),
                if (!_readToEnd)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: Text(
                      'เลื่อนอ่านให้ถึงท้ายเอกสารก่อนยืนยัน',
                      style: context.text.bodySmall?.copyWith(color: p.warning),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: 'ไม่ยินยอม',
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: AppButton(
                        label: 'ยินยอม',
                        onPressed: _checked ? () => Navigator.of(context).pop(true) : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
