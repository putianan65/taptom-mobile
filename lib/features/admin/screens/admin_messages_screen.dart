import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/models/user_model.dart';
import '../../auth/auth_provider.dart';
import '../providers/message_provider.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ NEW: Load conversations with unread counts
      context.read<MessageProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isSuperAdmin = user?.role == UserRole.superAdmin;

    // Theme Configuration
    final bgColor = isSuperAdmin ? null : const Color(0xFFF5F7FA);
    final bgGradient = isSuperAdmin ? LuxuryTheme.backgroundGradient : null;
    final textColor = isSuperAdmin ? Colors.white : Colors.black87;
    final subTextColor = isSuperAdmin ? LuxuryTheme.textSecondary : Colors.grey[600];
    final cardColor = isSuperAdmin ? LuxuryTheme.glassSurface : Colors.white;
    final primaryColor = isSuperAdmin ? LuxuryTheme.purpleNeon : AppColors.adminPrimary;
    final accentColor = isSuperAdmin ? LuxuryTheme.cyanNeon : AppColors.secondary;

    return Stack(
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            gradient: bgGradient,
          ),
        ),
        
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'ข้อความสนทนา', 
              style: isSuperAdmin 
                  ? GoogleFonts.outfit(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    )
                  : GoogleFonts.prompt(
                      color: Colors.black, 
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
            ),
            backgroundColor: isSuperAdmin ? Colors.transparent : Colors.white,
            elevation: isSuperAdmin ? 0 : 1,
            centerTitle: !isSuperAdmin,
            iconTheme: IconThemeData(
              color: isSuperAdmin ? Colors.white : Colors.black,
            ),
            leading: isSuperAdmin 
                ? Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: LuxuryTheme.glassSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: LuxuryTheme.glassBorder),
                    ),
                    child: IconButton(
                      icon: const HeroIcon(HeroIcons.arrowLeft, color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                    ),
                  )
                : IconButton(
                    icon: const HeroIcon(HeroIcons.arrowLeft, color: Colors.black),
                    onPressed: () => context.pop(),
                  ),
          ),
          body: Consumer<MessageProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: isSuperAdmin ? LuxuryTheme.cyanNeon : primaryColor,
                  ),
                );
              }

              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       HeroIcon(
                         HeroIcons.exclamationCircle, 
                         color: AppColors.error, 
                         size: 48,
                       ),
                       const SizedBox(height: 16),
                       Text(
                         'เกิดข้อผิดพลาด: ${provider.error}', 
                         style: GoogleFonts.prompt(
                           color: isSuperAdmin ? Colors.white70 : Colors.grey[700],
                         ),
                       ),
                       TextButton(
                         onPressed: () => provider.loadConversations(),
                         child: Text(
                           'ลองใหม่', 
                           style: TextStyle(
                             color: isSuperAdmin ? LuxuryTheme.cyanNeon : primaryColor,
                           ),
                         ),
                       )
                    ],
                  ),
                );
              }

              final conversations = provider.conversationList; // ✅ Updated

              if (conversations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HeroIcon(
                        HeroIcons.chatBubbleLeftRight, 
                        size: 64, 
                        color: (isSuperAdmin ? Colors.white : Colors.grey).withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ยังไม่มีการสนทนา',
                        style: GoogleFonts.prompt(
                          color: (isSuperAdmin ? Colors.white : Colors.black).withOpacity(0.5), 
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: primaryColor,
                onRefresh: () => provider.loadConversations(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final msg = conversation.lastMessage;
                    final partner = conversation.partner;
                    final unreadCount = conversation.unreadCount;
                    
                    if (msg == null) return const SizedBox.shrink();

                    return _buildConversationTile(
                      context, 
                      provider, 
                      msg, 
                      partner,
                      unreadCount: unreadCount, // ✅ Pass unread count
                      isSuperAdmin: isSuperAdmin,
                      cardColor: cardColor,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      accentColor: accentColor,
                      primaryColor: primaryColor,
                    );
                  },
                ),
              );
            },
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: isSuperAdmin ? [] : [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () async {
                final result = await context.push('/admin/messages/new');
                if (result == true && mounted) {
                  context.read<MessageProvider>().loadConversations();
                }
              },
              backgroundColor: primaryColor,
              elevation: 0,
              icon: const HeroIcon(HeroIcons.pencilSquare, color: Colors.white),
              label: Text(
                'เริ่มสนทนาใหม่', 
                style: isSuperAdmin 
                    ? GoogleFonts.outfit(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      )
                    : GoogleFonts.prompt(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationTile(
    BuildContext context, 
    MessageProvider provider, 
    Message lastMsg, 
    UserModel partner, {
    required int unreadCount, // ✅ Receive unread count
    required bool isSuperAdmin,
    required Color cardColor,
    required Color textColor,
    required Color? subTextColor,
    required Color accentColor,
    required Color primaryColor,
  }) {
    // Check if unread based on count > 0
    final isUnread = unreadCount > 0;

    // Border config
    final border = isSuperAdmin 
        ? Border.all(
            color: isUnread ? LuxuryTheme.cyanNeon : LuxuryTheme.glassBorder,
            width: isUnread ? 1.5 : 1,
          )
        : Border.all(
            color: isUnread ? primaryColor.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
            width: isUnread ? 1.5 : 1,
          );

    final shadow = isSuperAdmin ? <BoxShadow>[] : [
      BoxShadow(
        color: Colors.grey.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: border,
        boxShadow: shadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigate to detail screen passing the partner ID to filter the thread
            context.push('/admin/messages/${partner.id}', extra: partner); 
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSuperAdmin 
                        ? LuxuryTheme.purpleNeon.withOpacity(0.1)
                        : primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSuperAdmin 
                          ? LuxuryTheme.purpleNeon.withOpacity(0.3)
                          : primaryColor.withOpacity(0.3)
                    ),
                    image: (partner.photoUrl != null && partner.photoUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(partner.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (partner.photoUrl == null || partner.photoUrl!.isEmpty)
                      ? Center(
                          child: Text(
                            partner.firstName.isNotEmpty ? partner.firstName[0] : '?',
                            style: isSuperAdmin 
                                ? GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: LuxuryTheme.purpleNeon,
                                  )
                                : GoogleFonts.prompt(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                          ),
                        )
                      : null,
                ),
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
                              partner.fullName,
                              style: isSuperAdmin 
                                  ? GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textColor,
                                    )
                                  : GoogleFonts.prompt(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatDate(lastMsg.createdAt),
                            style: isSuperAdmin
                                ? GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: subTextColor,
                                  )
                                : GoogleFonts.prompt(
                                    fontSize: 12,
                                    color: subTextColor,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (lastMsg.sender.id != partner.id)
                            Text(
                              'คุณ: ',
                              style: isSuperAdmin
                                  ? GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: subTextColor,
                                    )
                                  : GoogleFonts.prompt(
                                      fontSize: 14,
                                      color: subTextColor,
                                    ),
                            ),
                          Expanded(
                            child: Text(
                              lastMsg.message,
                              style: isSuperAdmin
                                  ? GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: isUnread ? Colors.white : subTextColor,
                                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                    )
                                  : GoogleFonts.prompt(
                                      fontSize: 14,
                                      color: isUnread ? Colors.black87 : subTextColor,
                                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                    ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isUnread)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    decoration: BoxDecoration(
                      color: isSuperAdmin ? LuxuryTheme.cyanNeon : AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (isSuperAdmin ? LuxuryTheme.cyanNeon : AppColors.error).withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: GoogleFonts.prompt(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year+543}';
  }
}
