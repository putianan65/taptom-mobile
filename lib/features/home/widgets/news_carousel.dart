import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';

class NewsCarousel extends StatefulWidget {
  const NewsCarousel({super.key});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _newsItems = [
    {
      'title': 'กฎหมายพืชกระท่อม 2568: ข้อควรระวังและบทลงโทษล่าสุดจาก ป.ป.ส.',
      'date': 'อัปเดตล่าสุด',
      'image': 'assets/images/ปปส.jpg', // ONCB Image
      'fallbackUrl':
          'https://placehold.co/600x400/C62828/FFFFFF/png?text=Laws+2568',
      'url': 'https://www.oncb.go.th/',
      'color': '0xFFC62828',
      'isAsset': true,
    },
    {
      'title': 'มาตรฐาน GAP พืชกระท่อม: คู่มือการขอรับรองจากกรมวิชาการเกษตร',
      'date': 'คู่มือเกษตรกร',
      'image': 'assets/images/GAP.jpg', // GAP Image
      'fallbackUrl':
          'https://placehold.co/600x400/2E7D32/FFFFFF/png?text=GAP+Standard',
      'url': 'https://www.doa.go.th/gap/',
      'color': '0xFF2E7D32',
      'isAsset': true,
    },
    {
      'title': 'คลังความรู้พืชกระท่อม: สรรพคุณ การปลูก และการแปรรูปที่ถูกต้อง',
      'date': 'สาระน่ารู้',
      'image': 'assets/images/กสก.webp', // DOAE Image
      'fallbackUrl':
          'https://placehold.co/600x400/F57F17/FFFFFF/png?text=Kratom+Knowledge',
      'url': 'https://www.doae.go.th/',
      'color': '0xFFF57F17',
      'isAsset': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _newsItems.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const HeroIcon(
                    HeroIcons.bookOpen, // Changed icon to Book/Knowledge
                    style: HeroIconStyle.solid,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'คลังความรู้และกฎหมาย', // Changed Title
                    style: GoogleFonts.prompt(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // GAP-FIX-003: Removed dead button - "ดูทั้งหมด" had no functionality
              // Future: Navigate to news listing page when implemented
              // TextButton(
              //   onPressed: () {
              //     // TODO: Navigate to full news listing
              //   },
              //   child: Text(
              //     'ดูทั้งหมด',
              //     style: GoogleFonts.prompt(fontSize: 12),
              //   ),
              // ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _newsItems.length,
            itemBuilder: (context, index) {
              return _buildNewsCard(_newsItems[index]);
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    return GestureDetector(
      onTap: () => _launchNewsUrl(news['url']),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Color(int.parse(news['color'])).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Image
              news['isAsset'] == true
                  ? Image.asset(
                      news['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        // Fallback to Cached Network Image if Asset fails
                        if (news.containsKey('fallbackUrl')) {
                          return CachedNetworkImage(
                            imageUrl: news['fallbackUrl'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.surface,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white30,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                Container(color: AppColors.surface),
                          );
                        }
                        return Container(color: AppColors.surface);
                      },
                    )
                  : CachedNetworkImage(
                      imageUrl: news['image'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Color(int.parse(news['color'])),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.textLight.withOpacity(0.3),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Color(int.parse(news['color'])),
                        child: Center(
                          child: HeroIcon(
                            HeroIcons.photo,
                            color: AppColors.textLight.withOpacity(0.5),
                            size: 40,
                          ),
                        ),
                      ),
                    ),

              // 2. Gradient Overlay (Enhanced for Readability)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.textPrimary.withOpacity(
                        0.9,
                      ), // Darker at bottom
                    ],
                    stops: const [0.3, 1.0], // Start gradient earlier
                  ),
                ),
              ),

              // 3. Text Content
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(int.parse(news['color'])),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowStrong,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        news['date'],
                        style: GoogleFonts.prompt(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      news['title'],
                      style: GoogleFonts.prompt(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 4,
                            color: AppColors.textPrimary,
                          ),
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 8,
                            color: AppColors.textPrimary.withOpacity(0.5),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 4. Link Icon Helper
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: HeroIcon(
                    HeroIcons.arrowTopRightOnSquare,
                    color: AppColors.textLight,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _newsItems.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Color(int.parse(_newsItems[index]['color']))
                : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Future<void> _launchNewsUrl(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
