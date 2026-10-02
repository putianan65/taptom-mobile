import 'package:flutter/foundation.dart';
import '../../../../data/models/analytics_model.dart'; // NEW
import '../../../data/models/user_model.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/super_admin_service.dart';

/// Provider to manage admin state for user management
class AdminStateProvider extends ChangeNotifier {
  final AdminService _adminService;
  final SuperAdminService _superAdminService = SuperAdminService();

  AdminStateProvider(this._adminService);

  // State
  List<UserModel> _allUsers = [];
  List<UserModel> _pendingUsers = [];
  List<UserModel> _approvedUsers = [];
  List<UserModel> _deletedUsers = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _dashboardStats = {};
  
  // Analytics State
  GapAnalytics? _gapAnalytics;
  List<UserTrendsData> _userTrends = [];

  // Getters
  List<UserModel> get allUsers => _allUsers;
  List<UserModel> get pendingUsers => _pendingUsers;
  List<UserModel> get approvedUsers => _approvedUsers;
  List<UserModel> get deletedUsers => _deletedUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  GapAnalytics? get gapAnalytics => _gapAnalytics;
  List<UserTrendsData> get userTrends => _userTrends;

  /// Load all users in the admin's territory and split them by membership
  /// status. [status] is accepted for compatibility; both lists are always
  /// computed so dashboard counts stay correct.
  Future<void> loadUsers({String? status}) async {
    _setLoading(true);
    _error = null;
    try {
      final users = await _adminService.getUsers();
      _allUsers = users;
      _pendingUsers = users
          .where((u) => u.membershipStatus == MembershipStatus.pending)
          .toList();
      _approvedUsers = users
          .where((u) => u.membershipStatus == MembershipStatus.approved)
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  List<dynamic> _pendingPlots = [];
  List<dynamic> get pendingPlots => _pendingPlots;

  /// Plots waiting for this admin's review.
  Future<void> loadPendingPlots() async {
    try {
      _pendingPlots = await _adminService.getAdminPlots(status: 'PENDING');
    } catch (_) {
      _pendingPlots = [];
    }
    notifyListeners();
  }

  /// Approve a user membership
  Future<void> approveUser(String userId) async {
    try {
      await _adminService.approveUserMembership(userId);
      // Refresh the users list after approval
      await loadUsers();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  /// Reject a user membership
  Future<void> rejectUser(String userId, String reason) async {
    try {
      // Note: You may need to implement this in AdminService if not already present
      await _adminService.rejectUserMembership(userId, reason);
      // Refresh the users list after rejection
      await loadUsers();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  /// Load deleted users (Super Admin only)
  Future<void> loadDeletedUsers() async {
    try {
      final deletedData = await _superAdminService.getDeletedUsers();
      _deletedUsers = deletedData.map((json) => UserModel.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      _deletedUsers = [];
      notifyListeners();
    }
  }

  /// Restore a deleted user (Super Admin only)
  Future<void> restoreUser(String userId) async {
    try {
      await _superAdminService.restoreUser(userId);
      // Refresh both lists
      await loadUsers();
      await loadDeletedUsers();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  /// Update user role (Super Admin only)
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _superAdminService.updateUserRole(userId, newRole);
      await loadUsers();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  /// Update user details
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _adminService.updateUser(userId, data);
      // Refresh the users list after update
      await loadUsers();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  /// Load stats from admin service
  Future<void> loadStats() async {
    _setLoading(true);
    _error = null;

    try {
      final stats = await _adminService.getDashboardStats();
      _dashboardStats = stats;
    } catch (e) {
      _error = e.toString();
      // Use default stats if API fails
      _dashboardStats = {
        'total': _allUsers.length,
        'approved': _approvedUsers.length,
        'pending': _pendingUsers.length,
      };
    } finally {
      _setLoading(false);
    }
  }

  /// Get user details
  Future<UserModel?> getUser(String userId) async {
    try {
      return await _adminService.getUserDetails(userId);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  int _read(List<String> keys) {
    for (final k in keys) {
      final v = _dashboardStats[k];
      if (v is num) return v.toInt();
    }
    return -1;
  }

  /// Dashboard figures. Server statistics win; local counts fill any gaps.
  Map<String, int> get stats {
    int pick(List<String> keys, int fallback) {
      final v = _read(keys);
      return v >= 0 ? v : fallback;
    }

    return {
      'total': pick(['totalUsers', 'total'], _allUsers.length),
      'approved': _approvedUsers.length,
      'pending': _pendingUsers.length,
      'totalPlots': pick(['totalPlots'], 0),
      'pendingPlots': pick(['pendingPlots', 'pendingApprovals'], _pendingPlots.length),
      'approvedPlots': pick(['approvedPlots'], 0),
    };
  }

  /// Get all users
  List<UserModel> get users => _allUsers;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load Analytics (GAP & Trends)
  Future<void> loadAnalytics() async {
    try {
      final results = await Future.wait([
        _adminService.getGapAnalytics(),
        _adminService.getUserTrends(period: '7d', metric: 'USER_REGISTRATION'),
      ]);
      
      _gapAnalytics = results[0] as GapAnalytics;
      _userTrends = results[1] as List<UserTrendsData>;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load analytics: $e');
    }
  }
}
