import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  Timer? _pollingTimer;

  /// Latest new notification for banner popup
  NotificationModel? _latestNotification;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  NotificationModel? get latestNotification => _latestNotification;

  // Start polling when provider is initialized (or called specifically)
  void startPolling() {
    _fetchNotifications(silent: false); // Initial fetch
    _pollingTimer?.cancel();
    // ✅ ลด polling จาก 60s → 15s เพื่อให้เห็น notification เร็วขึ้น (ก่อนมี FCM)
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchNotifications(silent: true);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> _fetchNotifications({bool silent = false, int limit = 50}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final newNotifications = await _service.getNotifications(limit: limit);
      
      // Calculate unread count locally
      _unreadCount = newNotifications.where((n) => !n.isRead).length;
      
      // ✅ ตรวจจับ notification ใหม่สำหรับแสดง banner
      if (newNotifications.isNotEmpty && _notifications.isNotEmpty) {
        if (newNotifications.first.id != _notifications.first.id) {
          _latestNotification = newNotifications.first;
        }
      }
      
      // Update list if changed
      if (_notifications.length != newNotifications.length || 
          _hasContentChanged(_notifications, newNotifications)) {
        _notifications = newNotifications;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  bool _hasContentChanged(List<NotificationModel> oldList, List<NotificationModel> newList) {
    if (oldList.isEmpty && newList.isEmpty) return false;
    if (oldList.isEmpty || newList.isEmpty) return true;
    return oldList.first.id != newList.first.id;
  }

  Future<void> loadMore() async {
    if (_isLoading) return;
    await _fetchNotifications(limit: _notifications.length + 20);
  }

  /// Dismiss banner popup
  void dismissBanner() {
    _latestNotification = null;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
      notifyListeners();
      
      await _service.markAsRead(id);
    }
  }

  Future<void> deleteNotification(String id) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final wasUnread = !_notifications[index].isRead;
      _notifications.removeAt(index);
      if (wasUnread) {
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      }
      notifyListeners();

      await _service.deleteNotification(id);
    }
  }

  Future<void> createTestNotification() async {
    await _service.createNotification(
      title: 'ทดสอบการแจ้งเตือน',
      message: 'นี่คือการแจ้งเตือนทดสอบ ${DateTime.now().toLocal()}',
      type: 'INFO',
    );
    _fetchNotifications(silent: true);
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

