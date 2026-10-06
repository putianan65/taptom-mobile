import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../features/notifications/providers/notification_provider.dart';
import '../../features/settings/settings_provider.dart';
import '../design/design.dart';
import 'buttons.dart';

/// Bell button with the unread count; opens the notification centre.
class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key, this.onHero = false, this.color});

  /// Use translucent styling for dark hero headers.
  final bool onHero;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<SettingsProvider, bool>((s) => s.notificationsEnabled);
    if (!enabled) return const SizedBox.shrink();
    final unread = context.select<NotificationProvider, int>((n) => n.unreadCount);
    final p = context.palette;
    return AppIconButton(
      icon: unread > 0 ? AppIcons.bellActive : AppIcons.bell,
      tooltip: 'การแจ้งเตือน',
      badge: unread,
      background: onHero ? Colors.white.withValues(alpha: 0.12) : null,
      foreground: color ?? (onHero ? p.heroInk : null),
      onPressed: () => context.push(Routes.notifications),
    );
  }
}
