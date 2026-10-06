import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/widgets.dart';

class _NewsItem {
  const _NewsItem({
    required this.category,
    required this.title,
    required this.source,
    required this.image,
    required this.url,
  });

  final String category;
  final String title;
  final String source;
  final String image;
  final String url;
}

/// Short carousel of official guidance for kratom growers. Advances on its
/// own, pauses while the user is touching it, and opens the source website.
class NewsCarousel extends StatefulWidget {
  const NewsCarousel({super.key});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  static const _items = [
    _NewsItem(
      category: 'คู่มือเกษตรกร',
      title: 'มาตรฐาน GAP พืชกระท่อม: ขั้นตอนขอรับรองกับกรมวิชาการเกษตร',
      source: 'กรมวิชาการเกษตร',
      image: 'assets/images/news/gap-standard.jpg',
      url: 'https://www.doa.go.th/',
    ),
    _NewsItem(
      category: 'กฎหมาย',
      title: 'ข้อกฎหมายพืชกระท่อมล่าสุด สิ่งที่ผู้ปลูกต้องรู้',
      source: 'สำนักงาน ป.ป.ส.',
      image: 'assets/images/news/oncb-building.jpg',
      url: 'https://www.oncb.go.th/',
    ),
    _NewsItem(
      category: 'ส่งเสริมการเกษตร',
      title: 'กิจกรรมและโครงการสนับสนุนเกษตรกรจากกรมส่งเสริมการเกษตร',
      source: 'กรมส่งเสริมการเกษตร',
      image: 'assets/images/news/doae-campaign.jpg',
      url: 'https://www.doae.go.th/',
    ),
  ];

  final _controller = PageController(viewportFraction: 0.88);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_controller.hasClients) return;
      if (MediaQuery.of(context).disableAnimations) return;
      final next = (_page + 1) % _items.length;
      _controller.animateToPage(next, duration: Motion.slower, curve: Motion.emphasized);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(_NewsItem item) async {
    final uri = Uri.parse(item.url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) AppToast.error(context, 'เปิดลิงก์ไม่สำเร็จ');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: Listener(
            onPointerDown: (_) => _timer?.cancel(),
            onPointerUp: (_) => _schedule(),
            child: PageView.builder(
              controller: _controller,
              padEnds: false,
              itemCount: _items.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final item = _items[i];
                return Padding(
                  padding: EdgeInsets.only(right: Space.md, left: i == 0 ? 0 : 0),
                  child: Pressable(
                    onTap: () => _open(item),
                    semanticLabel: item.title,
                    child: ClipRRect(
                      borderRadius: Radii.card,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(item.image, fit: BoxFit.cover),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.25, 1],
                                colors: [Color(0x00000000), Color(0xD9101812)],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(Space.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: Radii.chip,
                                  ),
                                  child: Text(
                                    item.category,
                                    style: context.text.labelMedium?.copyWith(color: Colors.white),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.titleMedium?.copyWith(
                                    color: Colors.white,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      item.source,
                                      style: context.text.labelMedium?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.75),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      AppIcons.arrowUpRight,
                                      size: 12,
                                      color: Colors.white.withValues(alpha: 0.75),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _items.length; i++)
              AnimatedContainer(
                duration: Motion.base,
                curve: Motion.emphasized,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? p.brand : p.lineStrong,
                  borderRadius: Radii.chip,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
