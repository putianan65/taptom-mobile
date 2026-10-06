import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/services/notification_service.dart';
import '../../../data/models/notification_model.dart';

/// In-app notifications, polled while the app is in the foreground.
///
/// Polling pauses when the app is backgrounded and stops on sign-out, so a
/// signed-out device never keeps calling an authenticated endpoint.
class NotificationProvider extends ChangeNotifier with WidgetsBindingObserver {
  NotificationProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  final NotificationService _service = NotificationService();

  static const _interval = Duration(seconds: 30);

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _polling = false;
  Timer? _timer;
  NotificationModel? _latestNotification;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Newest arrival since the last poll, shown as an in-app banner.
  NotificationModel? get latestNotification => _latestNotification;

  void startPolling() {
    _polling = true;
    refresh();
    _schedule();
  }

  void stopPolling() {
    _polling = false;
    _timer?.cancel();
    _timer = null;
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _fetch(silent: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_polling) return;
    if (state == AppLifecycleState.resumed) {
      _fetch(silent: true);
      _schedule();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  Future<void> refresh() => _fetch(silent: false);

  Future<void> _fetch({required bool silent, int limit = 50}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final fresh = await _service.getNotifications(limit: limit);
      if (fresh.isNotEmpty &&
          _notifications.isNotEmpty &&
          fresh.first.id != _notifications.first.id &&
          !fresh.first.isRead) {
        _latestNotification = fresh.first;
      }
      _notifications = fresh;
      _unreadCount = fresh.where((n) => !n.isRead).length;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading) return;
    await _fetch(silent: false, limit: _notifications.length + 20);
  }

  void dismissBanner() {
    _latestNotification = null;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    _unreadCount = (_unreadCount - 1).clamp(0, 999);
    notifyListeners();
    await _service.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    _notifications = [
      for (final n in _notifications) n.isRead ? n : n.copyWith(isRead: true),
    ];
    _unreadCount = 0;
    notifyListeners();
    await Future.wait(unread.map((n) => _service.markAsRead(n.id)));
  }

  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final removed = _notifications.removeAt(index);
    if (!removed.isRead) _unreadCount = (_unreadCount - 1).clamp(0, 999);
    notifyListeners();
    await _service.deleteNotification(id);
  }

  /// Clears everything; called on sign-out.
  void reset() {
    stopPolling();
    _notifications = [];
    _unreadCount = 0;
    _latestNotification = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopPolling();
    super.dispose();
  }
}
