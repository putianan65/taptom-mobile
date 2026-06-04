import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/security/secure_storage.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SecureStorage _secureStorage = SecureStorage();
  
  UserModel? _currentUser;
  String? _tempToken;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;

  AuthProvider(this._authService);

  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser;
  String? get tempToken => _tempToken;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  /// Load tokens and user on startup
  Future<void> loadTokensFromStorage() async {
    // ✅ Use centralized SecureStorage to ensure consistency (AndroidOptions)
    _accessToken = await _secureStorage.getAccessToken();
    _refreshToken = await _secureStorage.getRefreshToken();
    
    if (_accessToken != null && _currentUser == null) {
      try {
        _currentUser = await _authService.getCurrentUser();
      } catch (e) {
        // If getting user fails, we might need to clear tokens, but let api interceptor handle 401
        print('Error loading user profile: $e');
      }
    }
    notifyListeners();
  }

  Future<bool> loadUser() async {
    _setLoading(true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn(String phone, String birthdate) async {
    _setLoading(true);
    try {
      final response = await _authService.signIn(phone, birthdate);
      
      // If we get here without exception, it's a direct login (no PIN needed)
      _currentUser = response;
      _tempToken = null;
      
      // 🔄 RELOAD TOKENS: AuthService saved them, but we need to update our memory cache
      await loadTokensFromStorage();
      
      notifyListeners();

    } on PinRequiredException catch (e) {
      _tempToken = e.tempToken;
      notifyListeners();
      rethrow;
    } on PinNotSetException catch (e) {
      _tempToken = e.tempToken;
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyPin(String pin) async {
    if (_tempToken == null) throw Exception('Token not found');
    
    _setLoading(true);
    try {
      final response = await _authService.verifyPin(pin, _tempToken!);
      
      if (response['accessToken'] != null) {
        _accessToken = response['accessToken'];
        _refreshToken = response['refreshToken'];
        await _saveTokens();
      }
      
      // Load user profile after PIN verification
      _currentUser = await _authService.getCurrentUser();
      _tempToken = null;
      notifyListeners();
      
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setPin(String pin) async {
    if (_tempToken == null) throw Exception('Token not found');

    _setLoading(true);
    try {
      final response = await _authService.setPin(pin, _tempToken!);
      
      final accessToken = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;
      final user = response['user'] as UserModel?;

      if (accessToken != null) {
        _accessToken = accessToken;
        _refreshToken = refreshToken;
        await _saveTokens();
      }

      if (user != null) {
        _currentUser = user;
      }

      _tempToken = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveTokens() async {
    if (_accessToken != null && _refreshToken != null) {
      await _secureStorage.saveTokens(
        accessToken: _accessToken!, 
        refreshToken: _refreshToken!
      );
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      // ✅ Use correct method from SecureStorage wrapper
      await _secureStorage.clearTokens();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshAccessToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token');
    }
    try {
      final response = await _authService.refreshToken(_refreshToken!);
      if (response['accessToken'] != null) {
        _accessToken = response['accessToken'];
        // Update both tokens if refresh token is rotated, otherwise just access token
        // But SecureStorage requires both arguments. Assuming refresh token stays same unless returned.
        final newRefreshToken = response['refreshToken'] ?? _refreshToken!;
        
        await _secureStorage.saveTokens(
          accessToken: _accessToken!, 
          refreshToken: newRefreshToken
        );
        notifyListeners();
      }
    } catch (e) {
      await signOut();
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  // Helper for setting user directly
  void setUser(UserModel user) {
     _currentUser = user;
     notifyListeners();
  }

  /// Update user profile
  Future<void> updateProfile(UserModel updatedUser) async {
    _setLoading(true);
    try {
      final user = await _authService.updateProfile(updatedUser);
      _currentUser = user;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
}
