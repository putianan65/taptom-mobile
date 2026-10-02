import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/support_service.dart';
import '../../../../core/widgets/custom_popup.dart';
import '../../../../data/models/ticket_model.dart';
import '../../../../data/models/user_model.dart'; // For UserRole
import '../../../../core/services/auth_service.dart';
import '../../auth/auth_provider.dart';

class TicketDetailScreen extends StatefulWidget {
  final String id;
  final Ticket? ticket;

  const TicketDetailScreen({super.key, required this.id, this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final SupportService _supportService = SupportService();
  final _replyController = TextEditingController();
  bool _isSending = false;
  Ticket? _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    // Load if null logic omitted for brevity, assuming passed or updated
  }

  @override
  Widget build(BuildContext context) {
    if (_ticket == null) return const Scaffold(body: Center(child: Text('Error')));
    
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.superAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดตั๋ว #${_ticket!.id.substring(0, 4)}', style: const TextStyle()),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isAdmin)
             PopupMenuButton<String>(
               icon: const Icon(PhosphorIconsRegular.notePencil, color: Colors.white),
               onSelected: _updateStatus,
               itemBuilder: (context) => [
                 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'
               ].map((status) => PopupMenuItem(
                 value: status,
                 child: Text(status, style: const TextStyle()),
               )).toList(),
             ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Ticket Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ticket!.subject,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _ticket!.message,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Text('โดย: ${_ticket!.user.fullName}', style: TextStyle(fontSize: 12)),
                          const Spacer(),
                          Text('สถานะ: ${_ticket!.status}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Replies
                ..._ticket!.replies.map((reply) => _buildReplyBubble(reply, user?.id)),
              ],
            ),
          ),
          
          if (_ticket!.status != 'CLOSED')
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: 'ตอบกลับ...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendReply,
                    icon: _isSending 
                        ? const CircularProgressIndicator()
                        : const Icon(PhosphorIconsRegular.paperPlaneTilt, color: AppColors.primary),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyBubble(TicketReply reply, String? currentUserId) {
    final isMe = reply.author.id == currentUserId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12, left: isMe ? 40 : 0, right: isMe ? 0 : 40),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reply.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reply.author.fullName,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    
    try {
      await _supportService.replyToTicket(ticketId: _ticket!.id, message: text);
      // Ideally refresh ticket from API to get new reply
      // For now just clear input
      _replyController.clear();
      CustomPopup.showSuccess(context, message: 'ตอบกลับสำเร็จ');
    } catch (e) {
      CustomPopup.showError(context, message: e.toString());
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _supportService.updateTicketStatus(_ticket!.id, newStatus);
      setState(() {
        // Optimistic update - in real app should ideally reload
         _ticket = Ticket(
           id: _ticket!.id, 
           subject: _ticket!.subject, 
           message: _ticket!.message, 
           status: newStatus, 
           priority: _ticket!.priority, 
           createdAt: _ticket!.createdAt, 
           user: _ticket!.user, 
           replies: _ticket!.replies
         );
      });
      CustomPopup.showSuccess(context, message: 'เปลี่ยนสถานะเป็น $newStatus เรียบร้อย');
    } catch (e) {
      CustomPopup.showError(context, message: e.toString());
    }
  }

  Future<void> _closeTicket() async {
    await _updateStatus('CLOSED');
  }
}
