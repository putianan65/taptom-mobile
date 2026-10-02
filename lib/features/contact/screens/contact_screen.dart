import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/map_styles.dart';
import '../../../core/widgets/widgets.dart';

/// Contact details for the project team at GISTNU, Naresuan University.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  MaplibreMapController? _controller;

  static const _office = LatLng(16.7427, 100.1955);

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) AppToast.error(context, 'เปิดลิงก์ไม่สำเร็จ');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final maps = 'https://www.google.com/maps/search/?api=1&query=${_office.latitude},${_office.longitude}';

    return PageScaffold(
      title: 'ติดต่อเจ้าหน้าที่',
      subtitle: 'ศูนย์ภูมิสารสนเทศเพื่อการพัฒนาภาคเหนือตอนล่าง',
      slivers: [
        SliverToBoxAdapter(
          child: ContentWidth(
            maxWidth: Breakpoints.maxForm + 80,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  padding: EdgeInsets.zero,
                  clip: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 180,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(color: p.hero),
                            IgnorePointer(
                              child: MaplibreMap(
                                styleString: MapStyles.satellite,
                                initialCameraPosition: const CameraPosition(target: _office, zoom: 15.5),
                                compassEnabled: false,
                                trackCameraPosition: false,
                                onMapCreated: (c) => _controller = c,
                                onStyleLoadedCallback: () => _controller?.addCircle(
                                  CircleOptions(
                                    geometry: _office,
                                    circleRadius: 8,
                                    circleColor: MapStyles.plotFill,
                                    circleStrokeColor: '#FFFFFF',
                                    circleStrokeWidth: 3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(Space.lg),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('GISTNU มหาวิทยาลัยนเรศวร', style: context.text.titleSmall),
                                  Text('ต.ท่าโพธิ์ อ.เมือง จ.พิษณุโลก 65000', style: context.text.bodySmall),
                                ],
                              ),
                            ),
                            AppButton.secondary(
                              label: 'นำทาง',
                              icon: AppIcons.compass,
                              size: ButtonSize.compact,
                              onPressed: () => _open(context, maps),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).entrance(context),
                const SizedBox(height: Space.xxl),
                const SectionHeader(title: 'ช่องทางติดต่อ'),
                ListGroup(
                  children: [
                    ListRow(
                      icon: AppIcons.phone,
                      title: '055 968 707',
                      subtitle: 'จันทร์ถึงศุกร์ 08:30 ถึง 16:30 น.',
                      onTap: () => _open(context, 'tel:055968707'),
                    ),
                    ListRow(
                      icon: AppIcons.mail,
                      title: 'gistnu@nu.ac.th',
                      subtitle: 'ตอบกลับภายใน 2 วันทำการ',
                      onTap: () => _open(context, 'mailto:gistnu@nu.ac.th'),
                    ),
                    ListRow(
                      icon: AppIcons.external,
                      title: 'gistnu.nu.ac.th',
                      subtitle: 'เว็บไซต์ศูนย์',
                      onTap: () => _open(context, 'https://www.gistnu.nu.ac.th/'),
                    ),
                    ListRow(
                      icon: AppIcons.megaphone,
                      title: 'Facebook GISTNU',
                      subtitle: 'ข่าวสารและการอบรม',
                      onTap: () => _open(context, 'https://www.facebook.com/gistnu'),
                    ),
                  ],
                ).entrance(context, index: 1),
                const SizedBox(height: Space.xxl),
                const InlineBanner(
                  tone: Tone.info,
                  title: 'เรื่องการตรวจแปลง',
                  message: 'ติดต่อเจ้าหน้าที่ในพื้นที่ของคุณโดยตรงจะได้คำตอบเร็วที่สุด ดูชื่อได้ในการแจ้งเตือนผลการตรวจ',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

