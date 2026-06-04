import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/notifications/providers/notification_provider.dart';

class NotificationIcon extends StatelessWidget {
  final Color color;
  
  const NotificationIcon({
    super.key, 
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: HeroIcon(HeroIcons.bell, color: color),
              onPressed: () {
                context.push('/notifications');
              },
            ),
            if (provider.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    provider.unreadCount > 99 ? '99+' : '${provider.unreadCount}',
                    style: GoogleFonts.prompt(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
