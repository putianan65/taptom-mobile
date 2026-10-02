import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/security/secure_storage.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/user_model.dart';

/// Session state: tokens, the signed-in user and the in-between PIN step for
/// staff accounts.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, {this.onSignedOut});

  final AuthService _authService;
  final SecureStorage _storage = SecureStorage();

  /// Called after sign-out, e.g. to stop notification polling.
  final VoidCallback? onSignedOut;

  UserModel? _currentUser;
  String? _tempToken;
  UserRole? _pendingRole;
  bool _pendingNeedsSetup = false;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  bool _restored = false;
  bool _offline = false;

  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser;
  String? get tempToken => _tempToken;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  /// True once [restoreSession] has finished.
  bool get isRestored => _restored;

  /// True when the session was restored from cache because the network was
  /// unreachable.
  bool get isOffline => _offline;

  /// Role of the account waiting on the PIN step.
  UserRole? get pendingRole => _pendingRole;

  /// Whether the waiting account must create a PIN rather than enter one.
  bool get pendingNeedsSetup => _pendingNeedsSetup;

  /// Restores a saved session. Uses the cached profile when the server is
  /// unreachable so farmers can open the app without signal.
  Future<void> restoreSession() async {
    _accessToken = await _storage.getAccessToken();
    _refreshToken = await _storage.getRefreshToken();

    if (_accessToken != null && _accessToken!.isNotEmpty && _currentUser == null) {
      try {
        _currentUser = await _authService.getCurrentUser();
        _offline = false;
        if (_currentUser == null) {
          _accessToken = null;
          _refreshToken = null;
        }
      } on ApiException catch (e) {
        if (e.isNetwork) {
          _currentUser = await _cachedUser();
          _offline = _currentUser != null;
        }
      } catch (error) {
        debugPrint('Session restore failed: $error');
      }
    }
    _restored = true;
    notifyListeners();
  }

  /// Backwards-compatible alias.
  Future<void> loadTokensFromStorage() => restoreSession();

  Future<UserModel?> _cachedUser() async {
    final raw = await _storage.readUserJson();
    if (raw == null) return null;
    try {
      return UserModel.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
    } catch (_) {
      return null;
    }
  }

  Future<bool> loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return false;
      _currentUser = user;
      _offline = false;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The sign-in responses carry only id, name and role. Territory and
  /// address come from /users/me, so load the full profile once signed in.
  Future<UserModel?> _fullProfile(UserModel? partial) async {
    try {
      return await _authService.getCurrentUser() ?? partial;
    } on Object catch (e) {
      debugPrint('Profile load after sign-in failed: $e');
      return partial;
    }
  }

  Future<void> signIn(String phone, String birthday) async {
    _setLoading(true);
    try {
      final user = await _authService.signIn(phone, birthday);
      _accessToken = await _storage.getAccessToken();
      _refreshToken = await _storage.getRefreshToken();
      _tempToken = null;
      _pendingRole = null;
      _currentUser = await _fullProfile(user);
      _offline = false;
    } on PinRequiredException catch (e) {
      _tempToken = e.tempToken;
      _pendingNeedsSetup = false;
      _pendingRole = e.userRole?.toUpperCase() == 'SUPER_ADMIN'
          ? UserRole.superAdmin
          : UserRole.admin;
      rethrow;
    } on PinNotSetException catch (e) {
      _tempToken = e.tempToken;
      _pendingNeedsSetup = true;
      _pendingRole = e.user?.role ?? UserRole.admin;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyPin(String pin) async {
    final temp = _tempToken;
    if (temp == null) throw AuthException('กรุณาเข้าสู่ระบบอีกครั้ง');

    _setLoading(true);
    try {
      final response = await _authService.verifyPin(pin, temp);
      final access = response['accessToken'] as String?;
      if (access == null) throw AuthException('ยืนยัน PIN ไม่สำเร็จ');
      _accessToken = access;
      _refreshToken = response['refreshToken'] as String?;
      await _saveTokens();

      _currentUser = await _fullProfile(
        response['user'] is Map ? UserModel.fromJson(Map<String, dynamic>.from(response['user'])) : null,
      );
      if (_currentUser != null) {
        await _storage.saveUserJson(jsonEncode(_currentUser!.toJson()));
      }
      _tempToken = null;
      _pendingRole = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setPin(String pin) async {
    final temp = _tempToken;
    if (temp == null) throw AuthException('กรุณาเข้าสู่ระบบอีกครั้ง');

    _setLoading(true);
    try {
      final response = await _authService.setPin(pin, temp);
      final access = response['accessToken'] as String?;
      if (access != null) {
        _accessToken = access;
        _refreshToken = response['refreshToken'] as String?;
        await _saveTokens();
      }
      _currentUser = await _fullProfile(response['user'] as UserModel?);
      _tempToken = null;
      _pendingRole = null;
      _pendingNeedsSetup = false;
    } finally {
      _setLoading(false);
    }
  }

  /// Abandons a half-finished staff sign-in.
  void cancelPinStep() {
    _tempToken = null;
    _pendingRole = null;
    _pendingNeedsSetup = false;
    _storage.clearTokens();
    notifyListeners();
  }

  Future<void> _saveTokens() async {
    final access = _accessToken;
    if (access == null) return;
    await _storage.saveTokens(
      accessToken: access,
      refreshToken: _refreshToken ?? '',
    );
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } finally {
      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      _tempToken = null;
      _pendingRole = null;
      _offline = false;
      onSignedOut?.call();
      notifyListeners();
    }
  }

  Future<void> refreshAccessToken() async {
    final refresh = _refreshToken;
    if (refresh == null || refresh.isEmpty) {
      await signOut();
      throw AuthException('ไม่พบข้อมูลการเข้าสู่ระบบ');
    }
    try {
      final response = await _authService.refreshToken(refresh);
      final access = response['accessToken'] as String?;
      if (access == null) throw AuthException('ต่ออายุการเข้าใช้งานไม่สำเร็จ');
      _accessToken = access;
      _refreshToken = response['refreshToken'] as String? ?? refresh;
      await _saveTokens();
    } catch (error) {
      await signOut();
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.updateProfile(updatedUser);
    } finally {
      _setLoading(false);
    }
  }
}
