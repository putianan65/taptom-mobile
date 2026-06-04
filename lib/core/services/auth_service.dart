import 'dart:convert';
import 'package:dio/dio.dart';
import '../../data/models/user_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../security/secure_storage.dart';
import '../utils/logger.dart';

/// Exception thrown when Admin needs to set PIN
class PinNotSetException implements Exception {
  final String tempToken;
  final UserModel? user;

  PinNotSetException({required this.tempToken, this.user});

  @override
  String toString() => 'PinNotSetException: Admin needs to set PIN';
}

/// Exception thrown when Admin needs to verify PIN
class PinRequiredException implements Exception {
  final String tempToken;
  final String? userRole;

  PinRequiredException({required this.tempToken, this.userRole});

  @override
  String toString() => 'PinRequiredException: Admin needs to verify PIN (Role: $userRole)';
}

class AuthException implements Exception {
  final String message;
  final String code;

  AuthException(this.message, {this.code = 'AUTH_ERROR'});

  @override
  String toString() => message;
}

abstract class AuthService {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signIn(
    String phone,
    String password,
  ); // password = birthdate
  Future<UserModel> signInWithPin(
    String phone,
    String pin,
  ); // for admin/super admin
  Future<void> signOut();
  Future<UserModel> updateProfile(UserModel user);
  Future<Map<String, dynamic>> setPin(
    String pin,
    String tempToken,
  ); // Set PIN for Admin/Super Admin - returns Map with user and tokens
  Future<void> changePin(String oldPin, String newPin); // Change existing PIN
  Future<Map<String, dynamic>> refreshToken(String refreshToken); // NEW
  Future<Map<String, dynamic>> verifyPin(String pin, String tempToken); // NEW
}

class ApiAuthService implements AuthService {
  final ApiClient _apiClient = ApiClient();
  final SecureStorage _storage = SecureStorage(); // We might not need this if Provider handles it, but keeping for now

  String? _getRoleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);
      
      return payloadMap['role'];
    } catch (e) {
      AppLogger.error('Failed to decode token role', error: e);
      return null;
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Refresh token failed: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;

    try {
      final response = await _apiClient.get(ApiEndpoints.userProfile);
      final user = UserModel.fromJson(response.data);
      return user;
    } catch (e) {
      // If profile fetch fails (e.g. token expired and refresh failed), clear tokens
      await _storage.clearTokens();
      return null;
    }
  }

  @override
  Future<UserModel> signIn(String phone, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'phone': phone,
          'birthday': password, // Mapped "password" to "birthday"
        },
      );

      final data = response.data;

      // CHECK: Does Admin need to set PIN? (Backend returns 200 + requiresSetup)
      if (data['requiresSetup'] == true) {
        // Store tempToken for set-pin flow
        final tempToken = data['tempToken'] as String?;
        if (tempToken != null) {
          await _storage.saveTokens(accessToken: tempToken, refreshToken: '');
        }
        throw PinNotSetException(
          tempToken: tempToken ?? '',
          user: data['user'] != null ? UserModel.fromJson(data['user']) : null,
        );
      }

      // CHECK: Does Admin need to verify PIN? (existing flow)
      if (data['requiresPin'] == true) {
        final tempToken = data['tempToken'] as String?;
        String? extractedRole;

        if (tempToken != null) {
          await _storage.saveTokens(accessToken: tempToken, refreshToken: '');
          extractedRole = _getRoleFromToken(tempToken);
        }
        
        throw PinRequiredException(
          tempToken: tempToken ?? '',
          userRole: extractedRole,
        );
      }

      // Normal login - save full tokens
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;

      AppLogger.debug('Login successful', params: {
        'has_access_token': accessToken != null,
        'has_refresh_token': refreshToken != null,
        'token_length': accessToken?.length ?? 0,
        // NEVER log actual tokens
      });

      if (accessToken == null) {
        throw Exception('ไม่พบ Access Token จากเซิร์ฟเวอร์');
      }

      // ✅ VALIDATION: Ensure refreshToken is not null or empty
      if (refreshToken == null || refreshToken.isEmpty) {
        AppLogger.error('CRITICAL: Backend did not return refreshToken!', error: Exception('Missing Refresh Token'));
        throw AuthException(
          'เกิดข้อผิดพลาดในการเชื่อมต่อ (Missing Token)',
          code: 'MISSING_REFRESH_TOKEN',
        );
      }

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      if (data['user'] == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้งานจากเซิร์ฟเวอร์');
      }

      var user = UserModel.fromJson(data['user']);
      return user;
    } on PinNotSetException {
      rethrow; // Pass through PIN exceptions
    } on PinRequiredException {
      rethrow;
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('เบอร์โทรศัพท์หรือวันเกิดไม่ถูกต้อง');
      } else if (e.response?.statusCode == 429) {
        throw Exception('ทำรายการถี่เกินไป กรุณารอสักครู่');
      }
      throw Exception('เข้าสู่ระบบไม่สำเร็จ: ${e.message}');
    } catch (e) {
      if (e is PinNotSetException || e is PinRequiredException) rethrow;
      if (e is AuthException) rethrow;
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  @override
  Future<UserModel> signInWithPin(String phone, String pin) async {
    // This is the implementation of verifyPin logic
    throw UnimplementedError('Use verifyPin instead');
  }

  @override
  Future<Map<String, dynamic>> verifyPin(String pin, String tempToken) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyPin,
        data: {
          'pin': pin,
          'tempToken': tempToken,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('PIN ไม่ถูกต้อง');
      }
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'];
        if (message is List) {
          throw Exception(message.join(', '));
        }
        throw Exception(message?.toString() ?? 'ข้อมูลไม่ถูกต้อง');
      }
      throw Exception('เข้าสู่ระบบด้วย PIN ไม่สำเร็จ: ${e.message}');
    }
  }

  @override
  Future<void> signOut() async {
    await _storage.clearTokens();
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    try {
      // Only send fields that Backend accepts for update
      final updateData = <String, dynamic>{};

      // Required base fields
      if (user.firstName.isNotEmpty) updateData['firstName'] = user.firstName;
      if (user.lastName.isNotEmpty) updateData['lastName'] = user.lastName;
      if (user.phone.isNotEmpty) updateData['phone'] = user.phone;

      // Optional fields
      if (user.job != null && user.job!.isNotEmpty)
        updateData['job'] = user.job;
      if (user.region != null && user.region!.isNotEmpty)
        updateData['region'] = user.region;
      if (user.province != null && user.province!.isNotEmpty)
        updateData['province'] = user.province;
      if (user.district != null && user.district!.isNotEmpty)
        updateData['district'] = user.district;
      if (user.subdistrict != null && user.subdistrict!.isNotEmpty)
        updateData['subDistrict'] = user.subdistrict;
      if (user.photoUrl != null && user.photoUrl!.isNotEmpty)
        updateData['photoUrl'] = user.photoUrl;
      if (user.birthDate != null) {
        final day = user.birthDate!.day.toString().padLeft(2, '0');
        final month = user.birthDate!.month.toString().padLeft(2, '0');
        final year = user.birthDate!.year;
        updateData['birthday'] = '$day/$month/$year';
      }

      final response = await _apiClient.put(
        ApiEndpoints.userProfile,
        data: updateData,
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'];
        if (message is List) {
          throw Exception(message.join(', '));
        }
        throw Exception('ข้อมูลไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง');
      } else if (e.response?.statusCode == 404) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }
      throw Exception(
        'อัพเดทโปรไฟล์ไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> setPin(String pin, String tempToken) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.setPin,
        data: {
          'pin': pin,
          // tempToken removed from body
        },
        // Send tempToken in Authorization header
        options: Options(
          headers: {
            'Authorization': 'Bearer $tempToken',
          },
        ),
      );
      final data = response.data;

      // Backend returns full tokens after setting PIN
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;

      if (accessToken == null) {
        throw Exception('ไม่พบ Access Token จากเซิร์ฟเวอร์');
      }

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
      );

      return {
        'user': UserModel.fromJson(data['user']),
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('PIN ไม่ถูกต้อง กรุณากรอก PIN 6 หลัก');
      } else if (e.response?.statusCode == 403) {
        throw Exception('คุณไม่มีสิทธิ์ตั้งค่า PIN');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Token หมดอายุ กรุณา Login ใหม่');
      }
      throw Exception(
        'ตั้งค่า PIN ไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  @override
  Future<void> changePin(String oldPin, String newPin) async {
    try {
      await _apiClient.post(
        ApiEndpoints.changePin,
        data: {'oldPin': oldPin, 'newPin': newPin},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('PIN เดิมไม่ถูกต้อง');
      } else if (e.response?.statusCode == 403) {
        throw Exception('คุณไม่มีสิทธิ์เปลี่ยน PIN');
      }
      throw Exception(
        'เปลี่ยน PIN ไม่สำเร็จ: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }
}
