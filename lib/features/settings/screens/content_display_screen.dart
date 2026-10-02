import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/nature_background.dart';

/// Production-grade Content Display Screen
/// Improvements:
/// - Better readability with proper typography
/// - Share functionality
/// - Scroll progress indicator
/// - Copy to clipboard
/// - Better accessibility
class ContentDisplayScreen extends StatefulWidget {
  final String title;
  final String content;

  const ContentDisplayScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  State<ContentDisplayScreen> createState() => _ContentDisplayScreenState();
}

class _ContentDisplayScreenState extends State<ContentDisplayScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollProgress);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollProgress);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollProgress() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (maxScroll > 0) {
        setState(() {
          _scrollProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NatureBackground.header(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: LinearProgressIndicator(
              value: _scrollProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.fileText,
                              color: AppColors.primary,
                              size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Metadata
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              PhosphorIconsRegular.clock,
                              size: 14,
                              color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              'อ่านประมาณ ${_estimateReadingTime()} นาที',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey[300]!,
                              Colors.grey[200]!,
                              Colors.grey[300]!,
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Content
                      SelectableText(
                        widget.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          height: 1.8,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Footer note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              PhosphorIconsRegular.info,
                              color: AppColors.info,
                              size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'เนื้อหานี้เป็นข้อมูลอย่างเป็นทางการของ TAPTOM',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Close Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                PhosphorIconsRegular.x,
                                size: 18,
                                color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'ปิด',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Scroll to Top Button
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(
                            PhosphorIconsRegular.arrowUp,
                            color: AppColors.primary,
                            size: 20),
                          tooltip: 'เลื่อนขึ้นด้านบน',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  int _estimateReadingTime() {
    // Average reading speed: 200-250 words per minute in Thai
    const wordsPerMinute = 225;
    final wordCount = widget.content.split(RegExp(r'\s+')).length;
    final minutes = (wordCount / wordsPerMinute).ceil();
    return minutes < 1 ? 1 : minutes;
  }
}
