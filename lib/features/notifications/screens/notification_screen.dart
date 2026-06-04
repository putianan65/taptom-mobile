import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart'; // Added
import '../../../core/constants/app_colors.dart';
import '../providers/notification_provider.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/widgets/nature_background.dart'; // Added

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().startPolling();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NatureBackground.header(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'การแจ้งเตือน',
            style: GoogleFonts.prompt(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const HeroIcon(HeroIcons.arrowLeft, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          actions: [
            // Test Button (Remove in prod)
            IconButton(
              icon: const HeroIcon(HeroIcons.plus, color: Colors.white),
              onPressed: () {
                context.read<NotificationProvider>().createTestNotification();
              },
              tooltip: 'สร้างแจ้งเตือนทดสอบ',
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.notifications.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.notifications.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Force refresh logic is inside provider startPolling/fetch
                  provider.startPolling(); 
                },
                child: ListView.separated(
                  controller: _scrollController, // Attach controller
                  padding: const EdgeInsets.all(20),
                  itemCount: provider.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = provider.notifications[index];
                    return _buildNotificationItem(context, notification, provider);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HeroIcon(
            HeroIcons.bellSlash,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'ไม่มีการแจ้งเตือน',
            style: GoogleFonts.prompt(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, 
    NotificationModel notification, 
    NotificationProvider provider
  ) {
    final isRead = notification.isRead;
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const HeroIcon(HeroIcons.trash, color: Colors.red),
      ),
      onDismissed: (_) {
        provider.deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            provider.markAsRead(notification.id);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: isRead 
                ? Border.all(color: Colors.transparent)
                : Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeIcon(notification.type),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.prompt(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 16,
                              color: isRead ? Colors.black87 : AppColors.primary,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message ?? '', // Handle null
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm', 'th').format(notification.createdAt), 
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    HeroIcons icon; // Correct type
    Color color;

    switch (type.toUpperCase()) {
      case 'WARNING':
        icon = HeroIcons.exclamationTriangle;
        color = Colors.orange;
        break;
      case 'ERROR':
        icon = HeroIcons.xCircle;
        color = Colors.red;
        break;
      case 'SUCCESS':
        icon = HeroIcons.checkCircle;
        color = Colors.green;
        break;
      case 'INFO':
      default:
        icon = HeroIcons.informationCircle;
        color = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: HeroIcon(icon, color: color, size: 24),
    );
  }
}
