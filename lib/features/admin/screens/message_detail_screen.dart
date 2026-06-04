import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/nature_background.dart';
import '../../../../data/models/user_model.dart';
import '../providers/message_provider.dart';
import '../../auth/auth_provider.dart';
import '../../../../data/models/message_model.dart';

class MessageDetailScreen extends StatefulWidget {
  final String id; // Partner User ID
  final Message? message; 

  const MessageDetailScreen({super.key, required this.id, this.message});

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // ✅ FIX: Load messages and scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().loadMessages();
      context.read<MessageProvider>().markThreadAsRead(widget.id);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ FIX: ไม่ซ้อน addPostFrameCallback, ใช้ jumpTo แทน animateTo
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessageProvider>();
    final authUser = context.watch<AuthProvider>().currentUser;
    final isSuperAdmin = authUser?.role == UserRole.superAdmin;
    final thread = provider.getThread(widget.id);
    
    // Determine Partner User Model for UI
    UserModel? partner;
    if (widget.message != null) {
      partner = provider.getPartner(widget.message!);
    } else if (thread.isNotEmpty) {
      partner = provider.getPartner(thread.first);
    } else {
      final extra = GoRouterState.of(context).extra;
      if (extra is UserModel) {
        partner = extra;
      }
    }

    final partnerName = partner?.fullName ?? 'Unknown';

    Widget scaffoldContent = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isSuperAdmin 
                  ? LuxuryTheme.cyanNeon.withOpacity(0.2) 
                  : Colors.white.withOpacity(0.2),
              backgroundImage: (partner?.photoUrl != null) 
                ? NetworkImage(partner!.photoUrl!) 
                : null,
              child: (partner?.photoUrl == null) 
                ? Text(
                    partnerName.isNotEmpty ? partnerName[0] : '?', 
                    style: GoogleFonts.prompt(
                      color: isSuperAdmin ? LuxuryTheme.cyanNeon : Colors.white,
                      fontWeight: FontWeight.bold,
                    )
                  ) 
                : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                partnerName, 
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.bold, 
                  color: Colors.white, 
                  fontSize: 18
                )
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                icon: const HeroIcon(HeroIcons.arrowLeft, color: Colors.white),
                onPressed: () => context.pop(),
              ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isSuperAdmin ? Colors.transparent : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: isSuperAdmin ? null : const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Expanded(
              child: thread.isEmpty
                ? Center(
                    child: Text(
                      'เริ่มต้นบทสนทนา', 
                      style: GoogleFonts.prompt(
                        color: isSuperAdmin ? Colors.white54 : Colors.grey
                      )
                    )
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: thread.length,
                    itemBuilder: (context, index) {
                      final msg = thread[index];
                      final isMe = msg.sender.id == authUser?.id;
                      return _buildChatBubble(msg, isMe, isSuperAdmin);
                    },
                  ),
            ),
            _buildReplyArea(widget.id, thread, isSuperAdmin),
          ],
        ),
      ),
    );

    if (isSuperAdmin) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LuxuryTheme.backgroundGradient,
        ),
        child: scaffoldContent,
      );
    } else {
      return NatureBackground.header(
        child: scaffoldContent,
      );
    }
  }

  Widget _buildChatBubble(Message msg, bool isMe, bool isSuperAdmin) {
    // Basic Markdown Image Support: ![alt](url)
    final imageRegex = RegExp(r'!\[(.*?)\]\((.*?)\)');
    final match = imageRegex.firstMatch(msg.message);
    String? imageUrl;
    String textMessage = msg.message;

    if (match != null) {
      imageUrl = match.group(2);
      textMessage = msg.message.replaceAll(match.group(0)!, '').trim();
    }

    final bubbleColor = isMe 
        ? (isSuperAdmin ? LuxuryTheme.purpleNeon : AppColors.primary)
        : (isSuperAdmin ? LuxuryTheme.glassSurface : Colors.white);
        
    final textColor = isMe 
        ? Colors.white 
        : (isSuperAdmin ? Colors.white : Colors.black87);
        
    final timeColor = isMe 
        ? Colors.white70 
        : (isSuperAdmin ? Colors.white60 : Colors.grey[500]);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: isSuperAdmin && !isMe ? Border.all(color: LuxuryTheme.glassBorder) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                loadingProgress.expectedTotalBytes!
                              : null,
                             color: isSuperAdmin ? LuxuryTheme.cyanNeon : AppColors.primary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => 
                      Container(
                        height: 100,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                        ),
                      ),
                  ),
                ),
              ),
            if (textMessage.isNotEmpty)
              Text(
                textMessage,
                style: GoogleFonts.prompt(
                  color: textColor,
                  fontSize: 15,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.createdAt),
              style: GoogleFonts.prompt(
                color: timeColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyArea(String recipientId, List<Message> thread, bool isSuperAdmin) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isSuperAdmin ? LuxuryTheme.midnightBlue.withOpacity(0.9) : Colors.white,
        border: isSuperAdmin ? Border(top: BorderSide(color: LuxuryTheme.glassBorder)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                style: GoogleFonts.prompt(
                  color: isSuperAdmin ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'พิมพ์ข้อความ...',
                  hintStyle: GoogleFonts.prompt(
                    color: isSuperAdmin ? Colors.white38 : Colors.grey[400]
                  ),
                  filled: true,
                  fillColor: isSuperAdmin ? LuxuryTheme.glassSurface : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: isSuperAdmin ? BorderSide(color: LuxuryTheme.glassBorder) : BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: isSuperAdmin ? BorderSide(color: LuxuryTheme.glassBorder) : BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: isSuperAdmin ? BorderSide(color: LuxuryTheme.cyanNeon) : BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, 
                    vertical: 10
                  ),
                ),
                minLines: 1,
                maxLines: 4,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: isSuperAdmin ? LuxuryTheme.purpleNeon : AppColors.primary,
              child: IconButton(
                icon: _isSending 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(
                        color: Colors.white, 
                        strokeWidth: 2
                      )
                    )
                  : const HeroIcon(
                      HeroIcons.paperAirplane, 
                      color: Colors.white, 
                      size: 20
                    ),
                onPressed: _isSending 
                  ? null 
                  : () => _sendMessage(recipientId, thread),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String recipientId, List<Message> thread) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    // ✅ เพิ่ม: Validate message length
    if (text.length > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ข้อความยาวเกิน 5000 ตัวอักษร', 
            style: GoogleFonts.prompt()
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    
    try {
      if (thread.isNotEmpty) {
        // Reply to the latest message in the thread
        final lastMsg = thread.last;
        await context.read<MessageProvider>().replyMessage(
          messageId: lastMsg.id,
          message: text,
        );
      } else {
        // Fallback to sendMessage for new threads
        await context.read<MessageProvider>().sendMessage(
          recipientId: recipientId,
          message: text,
        );
      }
      
      if (mounted) {
        _replyController.clear();
        // ✅ FIX: Scroll หลังส่งข้อความ
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ส่งข้อความไม่สำเร็จ: $e', 
              style: GoogleFonts.prompt()
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(DateTime date) {
    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}