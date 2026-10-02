import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// Long-form text such as the terms of use or the privacy policy, set for
/// comfortable reading: a narrow measure, generous line height, and lines
/// that look like headings (numbered or short and ending without a full
/// stop) promoted to headings.
class ContentDisplayScreen extends StatelessWidget {
  const ContentDisplayScreen({super.key, required this.title, required this.content});

  final String title;
  final String content;

  static final _numbered = RegExp(r'^(\d+(\.\d+)*\.?|[๑-๙]+\.)\s');

  bool _isHeading(String line) {
    final t = line.trim();
    if (t.isEmpty || t.length > 70) return false;
    return _numbered.hasMatch(t) && !t.contains('  ') && t.split(' ').length <= 10;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lines = content.trim().split('\n');
    final blocks = <Widget>[];
    final para = StringBuffer();

    void flush() {
      final text = para.toString().trim();
      if (text.isNotEmpty) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: SelectableText(text, style: context.text.bodyLarge?.copyWith(height: 1.75, color: p.ink)),
          ),
        );
      }
      para.clear();
    }

    for (final line in lines) {
      if (line.trim().isEmpty) {
        flush();
      } else if (_isHeading(line)) {
        flush();
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm),
            child: Text(line.trim(), style: context.text.titleMedium),
          ),
        );
      } else {
        if (para.isNotEmpty) para.write('\n');
        para.write(line.trim());
      }
    }
    flush();

    return PageScaffold(
      title: title,
      slivers: [
        SliverToBoxAdapter(
          child: ContentWidth(
            maxWidth: 680,
            padding: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: blocks),
          ),
        ),
      ],
    );
  }
}
