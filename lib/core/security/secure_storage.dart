import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for sensitive data like tokens and PIN attempts
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final _storage = const FlutterSecureStorage(
    // Kept until a migration moves existing sessions to the new default
    // store; switching now would sign every Android user out.
    // ignore: deprecated_member_use
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _pinKey = 'user_pin_hash';
  static const String _userKey = 'cached_user';
  
  // PIN Rate Limiting Keys
  static const String _pinAttemptsKey = 'pin_attempts';
  static const String _pinLockUntilKey = 'pin_lock_until';
  
  // Token Expiry Tracking
  static const String _tokenExpiryKey = 'access_token_expiry';
  static const Duration _accessTokenLifetime = Duration(minutes: 15); // Backend: 15 min
  static const Duration _refreshThreshold = Duration(minutes: 2); // Refresh 2 min before expiry

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    // Save token expiry time (current time + 15 minutes)
    final expiryTime = DateTime.now().add(_accessTokenLifetime).millisecondsSinceEpoch;
    await _storage.write(key: _tokenExpiryKey, value: expiryTime.toString());
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
  }

  /// Last known profile, used to open the app offline.
  Future<void> saveUserJson(String json) async {
    await _storage.write(key: _userKey, value: json);
  }

  Future<String?> readUserJson() => _storage.read(key: _userKey);

  Future<void> clearUserJson() async {
    await _storage.delete(key: _userKey);
  }

  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  // ==================== PIN Rate Limiting Methods ====================

  /// Get current PIN attempt count
  Future<int> getPinAttempts() async {
    final attempts = await _storage.read(key: _pinAttemptsKey);
    return int.tryParse(attempts ?? '0') ?? 0;
  }

  /// Increment PIN attempt count
  Future<void> incrementPinAttempts() async {
    final currentAttempts = await getPinAttempts();
    await _storage.write(
      key: _pinAttemptsKey,
      value: (currentAttempts + 1).toString(),
    );
  }

  /// Reset PIN attempt count
  Future<void> resetPinAttempts() async {
    await _storage.delete(key: _pinAttemptsKey);
  }

  /// Set lockout time (in minutes from now)
  Future<void> setPinLockout(int minutes) async {
    final lockUntil = DateTime.now().add(Duration(minutes: minutes));
    await _storage.write(
      key: _pinLockUntilKey,
      value: lockUntil.millisecondsSinceEpoch.toString(),
    );
  }

  /// Get remaining lockout time in minutes
  Future<int> getRemainingLockoutMinutes() async {
    final lockUntilStr = await _storage.read(key: _pinLockUntilKey);
    if (lockUntilStr == null) return 0;

    final lockUntil = DateTime.fromMillisecondsSinceEpoch(
      int.tryParse(lockUntilStr) ?? 0,
    );
    final now = DateTime.now();

    if (now.isAfter(lockUntil)) {
      // Lockout expired, clear it
      await _storage.delete(key: _pinLockUntilKey);
      await resetPinAttempts();
      return 0;
    }

    return lockUntil.difference(now).inMinutes + 1;
  }

  /// Check if PIN entry is currently locked
  Future<bool> isPinLocked() async {
    final remainingMinutes = await getRemainingLockoutMinutes();
    return remainingMinutes > 0;
  }

  /// Clear all PIN-related lockout data
  Future<void> clearPinLockout() async {
    await _storage.delete(key: _pinAttemptsKey);
    await _storage.delete(key: _pinLockUntilKey);
  }

  // ==================== Token Expiry Methods ====================

  /// Check if access token needs refresh (within 2 minutes of expiry)
  Future<bool> shouldRefreshToken() async {
    final expiryStr = await _storage.read(key: _tokenExpiryKey);
    if (expiryStr == null) return false;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(
      int.tryParse(expiryStr) ?? 0,
    );
    final now = DateTime.now();
    final refreshTime = expiryTime.subtract(_refreshThreshold);

    return now.isAfter(refreshTime);
  }

  /// Get remaining token lifetime in minutes
  Future<int> getTokenRemainingMinutes() async {
    final expiryStr = await _storage.read(key: _tokenExpiryKey);
    if (expiryStr == null) return 0;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(
      int.tryParse(expiryStr) ?? 0,
    );
    final now = DateTime.now();

    if (now.isAfter(expiryTime)) return 0;
    return expiryTime.difference(now).inMinutes;
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final expiryStr = await _storage.read(key: _tokenExpiryKey);
    if (expiryStr == null) return true;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(
      int.tryParse(expiryStr) ?? 0,
    );
    return DateTime.now().isAfter(expiryTime);
  }
}
