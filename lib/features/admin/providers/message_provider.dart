import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import '../../../core/network/api_exception.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/conversation_model.dart';
import '../../auth/auth_provider.dart';

class MessageProvider extends ChangeNotifier {
  final AdminService _adminService;
  final SuperAdminService _superAdminService;
  final AuthProvider _authProvider;

  List<Message> _inbox = [];
  List<Message> _sent = [];
  bool _isLoading = false;
  String? _error;

  MessageProvider(
    this._adminService,
    this._superAdminService, 
    this._authProvider,
  );

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get all messages as a flat list sorted by date
  List<Message> get allMessages => [..._inbox, ..._sent]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Group messages by "Conversation Partner"
  Map<String, List<Message>> get conversations {
    final currentUserId = _authProvider.user?.id;
    if (currentUserId == null) return {};

    final grouped = groupBy(allMessages, (Message msg) {
      if (msg.sender.id == currentUserId) {
        final recipientId = msg.recipient?.id;
        if (recipientId == null) {
          debugPrint('Warning: Message ${msg.id} has null recipient');
          return 'unknown'; 
        }
        return recipientId;
      } else {
        return msg.sender.id;
      }
    });
    
    // Keep 'unknown' to prevent message loss
    
    // Sort messages within each conversation (Oldest to Newest)
    for (var key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return grouped;
  }

  /// Get list of latest message for each conversation
  List<Message> get latestMessages {
    final convs = conversations;
    final latest = <Message>[];

    convs.forEach((userId, msgs) {
      if (msgs.isNotEmpty) {
        latest.add(msgs.last);
      }
    });

    latest.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return latest;
  }

  /// Get specific conversation thread by Partner User ID
  List<Message> getThread(String partnerId) {
    return conversations[partnerId] ?? [];
  }

  /// Get Partner User info from a message
  UserModel getPartner(Message msg) {
    final currentUserId = _authProvider.user?.id;
    if (msg.sender.id == currentUserId) {
      return msg.recipient ?? UserModel(
        id: 'unknown', 
        firstName: 'Unknown', 
        lastName: '', 
        role: UserRole.farmer, 
        phone: ''
      );
    } else {
      return msg.sender;
    }
  }

  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isSuperAdmin = _authProvider.user?.role == UserRole.superAdmin;
      
      if (isSuperAdmin) {
        final results = await Future.wait([
          _superAdminService.getMessages(box: 'INBOX'),
          _superAdminService.getMessages(box: 'SENT'),
        ]);
        _inbox = results[0];
        _sent = results[1];
      } else {
        final results = await Future.wait([
          _adminService.getMessages(type: 'INBOX'),
          _adminService.getMessages(type: 'SENT'),
        ]);
        _inbox = results[0];
        _sent = results[1];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // เพิ่ม error handling ที่ดีขึ้น
  Future<void> sendMessage({
    required String recipientId,
    required String message,
    String subject = 'ข้อความสนทนา',
  }) async {
    try {
      final isSuperAdmin = _authProvider.user?.role == UserRole.superAdmin;
      
      if (isSuperAdmin) {
        await _superAdminService.sendMessage(
          recipientId: recipientId,
          subject: subject,
          message: message,
        );
      } else {
        await _adminService.sendMessage(
          recipientId: recipientId,
          subject: subject,
          message: message,
        );
      }
      
      await loadMessages();
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw 'คุณไม่มีสิทธิ์ส่งข้อความถึงผู้ใช้นี้';
      } else if (e.isNotFound) {
        throw 'ไม่พบผู้รับที่ระบุ';
      } else if (e.statusCode == 429) {
        throw 'คุณส่งข้อความบ่อยเกินไป กรุณารอสักครู่';
      }
      throw 'ส่งข้อความไม่สำเร็จ: ${e.serverMessage ?? e.message}';
    } catch (e) {
      throw 'เกิดข้อผิดพลาด: $e';
    }
  }

  Future<void> replyMessage({
    required String messageId,
    required String message,
  }) async {
    try {
      final isSuperAdmin = _authProvider.user?.role == UserRole.superAdmin;
      
      if (isSuperAdmin) {
        await _superAdminService.replyMessage(
          messageId: messageId, 
          message: message
        );
      } else {
        await _adminService.replyMessage(
          messageId: messageId,
          message: message,
        );
      }
      
      await loadMessages();
    } on ApiException catch (e) {
      if (e.isNotFound) {
        throw 'ไม่พบข้อความที่ต้องการตอบกลับ';
      } else if (e.statusCode == 403) {
        throw 'คุณไม่มีสิทธิ์ตอบกลับข้อความนี้';
      }
      throw 'ตอบกลับไม่สำเร็จ: ${e.serverMessage ?? e.message}';
    } catch (e) {
      throw 'เกิดข้อผิดพลาด: $e';
    }
  }

  // Conversation List Support (API Based)
  List<Conversation> _conversationList = [];
  List<Conversation> get conversationList => _conversationList;
  
  int _totalUnreadCount = 0;
  int get totalUnreadCount => _totalUnreadCount;

  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final isSuperAdmin = _authProvider.user?.role == UserRole.superAdmin;
      List<Conversation> list = [];
      int unread = 0;
      
      if (isSuperAdmin) {
        // Parallel fetch for speed
        final results = await Future.wait([
          _superAdminService.getConversations(),
          _superAdminService.getUnreadTotal(),
        ]);
        list = results[0] as List<Conversation>;
        unread = results[1] as int;
      } else {
        final results = await Future.wait([
          _adminService.getConversations(),
          _adminService.getUnreadTotal(),
        ]);
        list = results[0] as List<Conversation>;
        unread = results[1] as int;
      }
      
      _conversationList = list;
      _totalUnreadCount = unread;
      
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markThreadAsRead(String partnerId) async {
    // 1. Optimistic Update
    final index = _conversationList.indexWhere((c) => c.partner.id == partnerId);
    if (index != -1) {
      final oldUnread = _conversationList[index].unreadCount;
      if (oldUnread > 0) {
        _totalUnreadCount = (_totalUnreadCount - oldUnread).clamp(0, 999);
        _conversationList[index] = Conversation(
           partner: _conversationList[index].partner,
           lastMessage: _conversationList[index].lastMessage != null 
             ? Message( // Clone with READ status
                 id: _conversationList[index].lastMessage!.id,
                 subject: _conversationList[index].lastMessage!.subject,
                 message: _conversationList[index].lastMessage!.message,
                 status: 'READ',
                 createdAt: _conversationList[index].lastMessage!.createdAt,
                 sender: _conversationList[index].lastMessage!.sender,
                 recipient: _conversationList[index].lastMessage!.recipient,
               )
             : null,
           unreadCount: 0,
        );
        notifyListeners();
      }
    }

    // 2. Call API
    try {
       final isSuperAdmin = _authProvider.user?.role == UserRole.superAdmin;
       if (isSuperAdmin) {
         await _superAdminService.markAsRead(partnerId);
       } else {
         await _adminService.markAsRead(partnerId);
       }
    } catch (e) {
      debugPrint('Failed to mark as read: $e');
      // Revert if needed, but for Read status usually we don't strict revert
    }
  }
}