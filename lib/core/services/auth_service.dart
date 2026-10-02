import 'dart:convert';

import 'package:dio/dio.dart' show Options;

import '../../data/models/user_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../security/secure_storage.dart';
import '../utils/logger.dart';

/// Thrown when an admin signs in for the first time and must create a PIN.
class PinNotSetException implements Exception {
  PinNotSetException({required this.tempToken, this.user});

  final String tempToken;
  final UserModel? user;

  @override
  String toString() => 'PinNotSetException';
}

/// Thrown when an admin or super admin must confirm their PIN.
class PinRequiredException implements Exception {
  PinRequiredException({required this.tempToken, this.userRole});

  final String tempToken;
  final String? userRole;

  @override
  String toString() => 'PinRequiredException($userRole)';
}

/// Auth failure with a user-facing message.
class AuthException implements Exception {
  AuthException(this.message, {this.code = 'AUTH_ERROR'});

  final String message;
  final String code;

  @override
  String toString() => message;
}

abstract class AuthService {
  /// Current profile, or null when there is no valid session. Throws
  /// [ApiException] with [ApiException.isNetwork] when offline so callers can
  /// fall back to the cached profile.
  Future<UserModel?> getCurrentUser();

  /// Sign in with phone number and birthday (`yyyy-MM-dd`, Gregorian).
  Future<UserModel> signIn(String phone, String birthday);

  /// Registers a new farmer account.
  Future<void> signUp(Map<String, dynamic> data);
  Future<void> signOut();
  Future<UserModel> updateProfile(UserModel user);
  Future<Map<String, dynamic>> setPin(String pin, String tempToken);
  Future<void> changePin(String oldPin, String newPin);
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
  Future<Map<String, dynamic>> verifyPin(String pin, String tempToken);
}

class ApiAuthService implements AuthService {
  final ApiClient _api = ApiClient();
  final SecureStorage _storage = SecureStorage();

  String? _roleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return (json.decode(payload) as Map<String, dynamic>)['role'] as String?;
    } catch (error) {
      AppLogger.error('Failed to decode token role', error: error);
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _api.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      final response = await _api.get(ApiEndpoints.userProfile);
      final user = UserModel.fromJson(Map<String, dynamic>.from(response.data));
      await _storage.saveUserJson(jsonEncode(user.toJson()));
      return user;
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.isForbidden) {
        await _storage.clearTokens();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<UserModel> signIn(String phone, String birthday) async {
    final Map data;
    try {
      final response = await _api.post(
        ApiEndpoints.login,
        data: {'phone': phone, 'birthday': birthday},
      );
      data = response.data as Map;
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.isNotFound) {
        throw AuthException(
          'เบอร์โทรศัพท์หรือวันเกิดไม่ถูกต้อง',
          code: 'INVALID_CREDENTIALS',
        );
      }
      if (e.isForbidden) {
        throw AuthException(
          e.serverMessage ?? 'บัญชีนี้ถูกระงับการใช้งาน กรุณาติดต่อเจ้าหน้าที่',
          code: 'FORBIDDEN',
        );
      }
      throw AuthException(e.message, code: 'HTTP_${e.statusCode}');
    }

    // First admin sign-in: a PIN must be created.
    if (data['requiresSetup'] == true) {
      throw PinNotSetException(
        tempToken: data['tempToken'] as String? ?? '',
        user: data['user'] is Map
            ? UserModel.fromJson(Map<String, dynamic>.from(data['user']))
            : null,
      );
    }

    // Admin and super admin confirm with a PIN.
    if (data['requiresPin'] == true) {
      final tempToken = data['tempToken'] as String? ?? '';
      throw PinRequiredException(
        tempToken: tempToken,
        userRole: tempToken.isEmpty ? null : _roleFromToken(tempToken),
      );
    }

    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null || refreshToken.isEmpty) {
      AppLogger.error('Sign-in response is missing tokens');
      throw AuthException(
        'ระบบยืนยันตัวตนตอบกลับไม่ครบถ้วน กรุณาลองใหม่',
        code: 'MISSING_TOKEN',
      );
    }
    if (data['user'] is! Map) {
      throw AuthException('ไม่พบข้อมูลผู้ใช้จากเซิร์ฟเวอร์', code: 'MISSING_USER');
    }

    await _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    final user = UserModel.fromJson(Map<String, dynamic>.from(data['user']));
    await _storage.saveUserJson(jsonEncode(user.toJson()));
    return user;
  }

  @override
  Future<void> signUp(Map<String, dynamic> data) async {
    try {
      await _api.post(ApiEndpoints.signup, data: data);
    } on ApiException catch (e) {
      if (e.isConflict) {
        throw AuthException(
          'เบอร์โทรศัพท์นี้ลงทะเบียนแล้ว กรุณาเข้าสู่ระบบ',
          code: 'PHONE_EXISTS',
        );
      }
      throw AuthException(
        e.statusCode == 400 && e.serverMessage != null ? e.serverMessage! : e.message,
        code: 'HTTP_${e.statusCode}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> verifyPin(String pin, String tempToken) async {
    try {
      final response = await _api.post(
        ApiEndpoints.verifyPin,
        data: {'pin': pin, 'tempToken': tempToken},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.isForbidden) {
        throw AuthException('รหัส PIN ไม่ถูกต้อง', code: 'INVALID_PIN');
      }
      throw AuthException(e.message, code: 'HTTP_${e.statusCode}');
    }
  }

  @override
  Future<Map<String, dynamic>> setPin(String pin, String tempToken) async {
    final Map data;
    try {
      final response = await _api.post(
        ApiEndpoints.setPin,
        data: {'pin': pin},
        options: Options(headers: {'Authorization': 'Bearer $tempToken'}),
      );
      data = response.data as Map;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        throw AuthException('การยืนยันตัวตนหมดเวลา กรุณาเข้าสู่ระบบใหม่', code: 'EXPIRED');
      }
      if (e.isForbidden) {
        throw AuthException('บัญชีนี้ไม่ต้องใช้รหัส PIN', code: 'FORBIDDEN');
      }
      throw AuthException(e.message, code: 'HTTP_${e.statusCode}');
    }

    final accessToken = data['accessToken'] as String?;
    if (accessToken == null) {
      throw AuthException('ไม่พบสิทธิ์การเข้าใช้งานจากเซิร์ฟเวอร์', code: 'MISSING_TOKEN');
    }
    final refreshToken = data['refreshToken'] as String? ?? '';
    await _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);

    final user = data['user'] is Map
        ? UserModel.fromJson(Map<String, dynamic>.from(data['user']))
        : null;
    if (user != null) await _storage.saveUserJson(jsonEncode(user.toJson()));
    return {
      'user': user,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  @override
  Future<void> changePin(String oldPin, String newPin) async {
    try {
      await _api.patch(
        ApiEndpoints.changePin,
        data: {'oldPin': oldPin, 'newPin': newPin},
      );
    } on ApiException catch (e) {
      if (e.statusCode == 400 || e.isUnauthorized) {
        throw AuthException('รหัส PIN เดิมไม่ถูกต้อง', code: 'INVALID_PIN');
      }
      throw AuthException(e.message, code: 'HTTP_${e.statusCode}');
    }
  }

  @override
  Future<void> signOut() async {
    await _storage.clearTokens();
    await _storage.clearUserJson();
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    final body = <String, dynamic>{
      if (user.firstName.isNotEmpty) 'firstName': user.firstName,
      if (user.lastName.isNotEmpty) 'lastName': user.lastName,
      if (user.phone.isNotEmpty) 'phone': user.phone,
      if ((user.job ?? '').isNotEmpty) 'job': user.job,
      if ((user.region ?? '').isNotEmpty) 'region': user.region,
      if ((user.province ?? '').isNotEmpty) 'province': user.province,
      if ((user.district ?? '').isNotEmpty) 'district': user.district,
      if ((user.subdistrict ?? '').isNotEmpty) 'subDistrict': user.subdistrict,
      if ((user.photoUrl ?? '').isNotEmpty) 'photoUrl': user.photoUrl,
      if (user.birthDate != null) 'birthday': _formatBirthday(user.birthDate!),
    };
    try {
      // PATCH is the partial-update endpoint; only changed fields are sent.
      final response = await _api.patch(ApiEndpoints.userProfile, data: body);
      final updated = UserModel.fromJson(Map<String, dynamic>.from(response.data));
      await _storage.saveUserJson(jsonEncode(updated.toJson()));
      return updated;
    } on ApiException catch (e) {
      throw AuthException(
        e.statusCode == 400 && e.serverMessage != null ? e.serverMessage! : e.message,
        code: 'HTTP_${e.statusCode}',
      );
    }
  }

  /// Profile updates take the birthday as dd/MM/yyyy (Gregorian), unlike
  /// sign-in which uses ISO dates.
  static String _formatBirthday(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}
