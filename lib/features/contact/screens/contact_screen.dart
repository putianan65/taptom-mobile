import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  MaplibreMapController? _mapController;

  // GISTNU Coordinates (Naresuan University)
  static const double _lat = 16.7427;
  static const double _lng = 100.1955;
  static const String _styleUrl =
      'https://api.maptiler.com/maps/streets/style.json?key=Fb4cbU6chnBsGVsZ5v96';

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchMaps() async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_lat,$_lng',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch Maps');
    }
  }

  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() async {
    if (_mapController == null) return;

    // Add marker at GISTNU location
    await _mapController!.addSymbol(
      const SymbolOptions(
        geometry: LatLng(_lat, _lng),
        iconImage: 'marker-15',
        iconSize: 2.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Beautiful Header with Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/ปกกระท่อม.png', fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Centered Logo and Title
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/Gistnu_new_logo.webp',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: HeroIcon(
                                  HeroIcons.buildingOffice2,
                                  color: AppColors.primary,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ติดต่อเรา',
                          style: GoogleFonts.prompt(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              const Shadow(
                                color: Colors.black38,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: HeroIcon(
                      HeroIcons.arrowLeft,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // About Section
                      Text(
                        'ศูนย์ภูมิสารสนเทศเพื่อการพัฒนาภาคเหนือตอนล่าง',
                        style: GoogleFonts.prompt(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'มหาวิทยาลัยนเรศวร',
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Contact Cards
                      _buildContactCard(
                        icon: HeroIcons.mapPin,
                        iconColor: Colors.red,
                        title: 'ที่อยู่',
                        content:
                            'มหาวิทยาลัยนเรศวร ต.ท่าโพธิ์\nอ.เมือง จ.พิษณุโลก 65000',
                        onTap: _launchMaps,
                      ),
                      _buildContactCard(
                        icon: HeroIcons.phone,
                        iconColor: Colors.green,
                        title: 'โทรศัพท์',
                        content: '0-5596-8707',
                        onTap: () => _launchUrl('tel:055968707'),
                      ),
                      _buildContactCard(
                        icon: HeroIcons.envelope,
                        iconColor: Colors.blue,
                        title: 'อีเมล',
                        content: 'gistnu@nu.ac.th',
                        onTap: () => _launchUrl('mailto:gistnu@nu.ac.th'),
                      ),
                      _buildContactCard(
                        icon: HeroIcons.globeAlt,
                        iconColor: Colors.purple,
                        title: 'เว็บไซต์',
                        content: 'www.gistnu.nu.ac.th',
                        onTap: () => _launchUrl('https://www.gistnu.nu.ac.th/'),
                      ),

                      const SizedBox(height: 24),

                      // Map Section
                      Row(
                        children: [
                          const HeroIcon(
                            HeroIcons.map,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'แผนที่',
                            style: GoogleFonts.prompt(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Real Map
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              MaplibreMap(
                                styleString: _styleUrl,
                                initialCameraPosition: const CameraPosition(
                                  target: LatLng(_lat, _lng),
                                  zoom: 15,
                                ),
                                onMapCreated: _onMapCreated,
                                onStyleLoadedCallback: _onStyleLoaded,
                                compassEnabled: false,
                                rotateGesturesEnabled: false,
                                scrollGesturesEnabled: false,
                                zoomGesturesEnabled: false,
                                tiltGesturesEnabled: false,
                                myLocationEnabled: false,
                              ),
                              // Tap overlay to open Google Maps
                              Positioned.fill(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _launchMaps,
                                    child: Container(),
                                  ),
                                ),
                              ),
                              // Open in Maps button
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: _launchMaps,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const HeroIcon(
                                          HeroIcons.arrowTopRightOnSquare,
                                          color: AppColors.primary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'เปิดแผนที่',
                                          style: GoogleFonts.prompt(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Pin Marker
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 30),
                                  child: HeroIcon(
                                    HeroIcons.mapPin,
                                    style: HeroIconStyle.solid,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Social Media
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'ติดตามข่าวสาร',
                              style: GoogleFonts.prompt(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialButton(
                                  icon: Icons.facebook,
                                  color: const Color(0xFF1877F2),
                                  onTap: () => _launchUrl(
                                    'https://www.facebook.com/gistnu',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _buildSocialButton(
                                  icon: Icons.language,
                                  color: AppColors.primary,
                                  onTap: () => _launchUrl(
                                    'https://www.gistnu.nu.ac.th/',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required HeroIcons icon,
    required Color iconColor,
    required String title,
    required String content,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: HeroIcon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        content,
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: HeroIcon(
                    HeroIcons.chevronRight,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
