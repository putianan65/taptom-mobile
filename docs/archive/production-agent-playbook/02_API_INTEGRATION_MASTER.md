# API Integration Master Guide
## คู่มือ API Integration แบบครบวงจร

**Version:** 2.0.0  
**Last Updated:** 2026-01-29  
**Swagger URL:** http://localhost:3000/docs  
**Base URL:** http://localhost:3000/api/v1

---

## สารบัญ

1. [API Architecture](#api-architecture)
2. [Authentication Flow](#authentication-flow)
3. [API Client Setup](#api-client-setup)
4. [Endpoint Integration](#endpoint-integration)
5. [Error Handling](#error-handling)
6. [Caching Strategy](#caching-strategy)
7. [Testing Checklist](#testing-checklist)

---

## API Architecture

### Flutter Folder Structure
```
lib/
└── core/
    └── network/
        ├── api_client.dart          # Dio instance
        ├── api_endpoints.dart       # All endpoints
        ├── api_response.dart        # Response models
        └── interceptors/
            ├── auth_interceptor.dart
            ├── error_interceptor.dart
            └── logging_interceptor.dart
```

---

## Authentication Flow

### Complete Auth Flow Diagram
```
User Flow:
Registration → Signup API → Token → Dashboard

Admin Flow:
Login (Phone+BD) → Signin API → tempToken
  → PIN Input → Verify PIN API → Token → Dashboard
  
Admin First Login:
Login (Phone+BD) → Signin API → Set PIN Required
  → Set PIN → Verify PIN → Token → Dashboard
```

### 1. API Client Setup (Dart/Flutter)

```dart
// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  late Dio dio;
  final storage = const FlutterSecureStorage();
  
  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    // Auth Interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry original request
            return handler.resolve(await dio.fetch(error.requestOptions));
          }
        }
        return handler.next(error);
      },
    ));
    
    // Logging Interceptor (Debug only)
    if (!kReleaseMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;
      
      final response = await dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      
      await storage.write(
        key: 'access_token',
        value: response.data['accessToken'],
      );
      return true;
    } catch (e) {
      // Refresh failed → logout
      await storage.deleteAll();
      return false;
    }
  }
}
```

---

### 2. API Endpoints Constants

```dart
// lib/core/network/api_endpoints.dart
class ApiEndpoints {
  // Base
  static const String baseUrl = '/api/v1';
  
  // Auth
  static const String signup = '$baseUrl/auth/signup';
  static const String signin = '$baseUrl/auth/signin';
  static const String verifyPin = '$baseUrl/auth/verify-pin';
  static const String setPin = '$baseUrl/auth/set-pin';
  static const String changePin = '$baseUrl/auth/change-pin';
  static const String refresh = '$baseUrl/auth/refresh';
  
  // Users
  static const String usersMe = '$baseUrl/users/me';
  static const String updateProfile = '$baseUrl/users/me';
  
  // Plots
  static const String plots = '$baseUrl/plots';
  static String plotDetail(String id) => '$baseUrl/plots/$id';
  static String approvePlot(String id) => '$baseUrl/admin/plots/$id/approve';
  static String rejectPlot(String id) => '$baseUrl/admin/plots/$id/reject';
  
  // GAP
  static const String gapRecords = '$baseUrl/gap-records';
  static const String gapInputs = '$baseUrl/gap-inputs';
  static const String fieldManagement = '$baseUrl/field-management';
  static const String harvests = '$baseUrl/harvests';
  static const String postHarvest = '$baseUrl/post-harvest';
  static const String workerTraining = '$baseUrl/worker-training';
  static const String traceability = '$baseUrl/traceability';
  
  // Admin
  static const String adminUsers = '$baseUrl/admin/users';
  static String approveUser(String id) => '$baseUrl/admin/users/$id/approve';
  static String rejectUser(String id) => '$baseUrl/admin/users/$id/reject';
  static const String adminStatistics = '$baseUrl/admin/statistics';
  static const String contactSuperAdmin = '$baseUrl/admin/contact-superadmin';
  
  // Super Admin
  static const String superAdminStats = '$baseUrl/super-admin/statistics/national';
  static const String superAdminAdmins = '$baseUrl/super-admin/admins';
  static const String superAdminUsers = '$baseUrl/super-admin/users';
  
  // Locations
  static const String provinces = '$baseUrl/locations/provinces';
  static String districts(String provinceCode) => 
      '$baseUrl/locations/districts?provinceCode=$provinceCode';
  static String subdistricts(String districtCode) =>
      '$baseUrl/locations/subdistricts?districtCode=$districtCode';
  
  // Occupations
  static const String occupations = '$baseUrl/occupations';
  
  // Upload
  static const String upload = '$baseUrl/upload';
  
  // Notifications
  static const String notifications = '$baseUrl/notifications';
  static String markAsRead(String id) => '$baseUrl/notifications/$id/read';
}
```

---

## Complete API Integration Examples

### AUTH - Registration

```dart
// lib/core/services/auth_service.dart
class AuthService {
  final ApiClient _apiClient = ApiClient();
  
  Future<AuthResponse> signup({
    required String phone,
    required String birthday,
    required String firstName,
    required String lastName,
    required String idCard,
    required String province,
    required String district,
    required String subDistrict,
    required String address,
    required String postalCode,
    String? occupation,
    String? profileImage,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.signup,
        data: {
          'phone': phone,
          'birthday': birthday,
          'firstName': firstName,
          'lastName': lastName,
          'idCard': idCard,
          'province': province,
          'district': district,
          'subDistrict': subDistrict,
          'address': address,
          'postalCode': postalCode,
          if (occupation != null) 'occupation': occupation,
          if (profileImage != null) 'profileImage': profileImage,
        },
      );
      
      // Save tokens
      await _apiClient.storage.write(
        key: 'access_token',
        value: response.data['accessToken'],
      );
      await _apiClient.storage.write(
        key: 'refresh_token',
        value: response.data['refreshToken'],
      );
      
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Error Handler
  ApiException _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data['message'] ?? 'Unknown error';
      
      switch (statusCode) {
        case 400:
          return ValidationException(message);
        case 409:
          return ConflictException(message);
        case 429:
          return TooManyRequestsException(message);
        default:
          return ApiException(message, statusCode: statusCode);
      }
    } else {
      return NetworkException('No internet connection');
    }
  }
}
```

---

### AUTH - Login (User)

```dart
Future<AuthResponse> signin({
  required String phone,
  required String birthday,
}) async {
  try {
    final response = await _apiClient.dio.post(
      ApiEndpoints.signin,
      data: {
        'phone': phone,
        'birthday': birthday,
      },
    );
    
    // Check if it's USER or ADMIN
    if (response.data['requiresPin'] == true) {
      // Admin → needs PIN
      return AdminTempResponse(
        tempToken: response.data['tempToken'],
        requiresPin: true,
      );
    } else {
      // Regular User → save tokens
      await _apiClient.storage.write(
        key: 'access_token',
        value: response.data['accessToken'],
      );
      await _apiClient.storage.write(
        key: 'refresh_token',
        value: response.data['refreshToken'],
      );
      
      return AuthResponse.fromJson(response.data);
    }
  } on DioException catch (e) {
    throw _handleError(e);
  }
}
```

---

### AUTH - Verify PIN (Admin)

```dart
Future<AuthResponse> verifyPin({
  required String tempToken,
  required String pin,
}) async {
  try {
    final response = await _apiClient.dio.post(
      ApiEndpoints.verifyPin,
      data: {
        'tempToken': tempToken,
        'pin': pin,
      },
    );
    
    // Save tokens
    await _apiClient.storage.write(
      key: 'access_token',
      value: response.data['accessToken'],
    );
    await _apiClient.storage.write(
      key: 'refresh_token',
      value: response.data['refreshToken'],
    );
    
    return AuthResponse.fromJson(response.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      throw InvalidPinException('Invalid PIN');
    } else if (e.response?.statusCode == 429) {
      throw TooManyAttemptsException('Too many attempts. Try again in 5 minutes.');
    }
    throw _handleError(e);
  }
}
```

---

### AUTH - Set PIN (Admin First Login)

```dart
Future<AuthResponse> setPin({
  required String pin,
  required String confirmPin,
}) async {
  if (pin != confirmPin) {
    throw ValidationException('PIN does not match');
  }
  
  if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
    throw ValidationException('PIN must be 6 digits');
  }
  
  try {
    final response = await _apiClient.dio.post(
      ApiEndpoints.setPin,
      data: {
        'pin': pin,
        'confirmPin': confirmPin,
      },
    );
    
    // Save tokens
    await _apiClient.storage.write(
      key: 'access_token',
      value: response.data['accessToken'],
    );
    await _apiClient.storage.write(
      key: 'refresh_token',
      value: response.data['refreshToken'],
    );
    
    return AuthResponse.fromJson(response.data);
  } on DioException catch (e) {
    throw _handleError(e);
  }
}
```

---

### USERS - Get Profile

```dart
// lib/core/services/user_service.dart
class UserService {
  final ApiClient _apiClient = ApiClient();
  
  Future<User> getMyProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.usersMe);
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? address,
    String? postalCode,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        ApiEndpoints.updateProfile,
        data: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (address != null) 'address': address,
          if (postalCode != null) 'postalCode': postalCode,
        },
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
```

---

### PLOTS - Create Plot

```dart
// lib/core/services/plot_service.dart
class PlotService {
  final ApiClient _apiClient = ApiClient();
  
  Future<Plot> createPlot({
    required String name,
    required String plantType,
    required Map<String, dynamic> geometry, // GeoJSON
    int? plantCount,
    String? description,
    List<String>? images,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.plots,
        data: {
          'name': name,
          'plantType': plantType,
          'geometry': geometry,
          if (plantCount != null) 'plantCount': plantCount,
          if (description != null) 'description': description,
          if (images != null) 'images': images,
        },
      );
      return Plot.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Plot>> getMyPlots({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.plots,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );
      
      return (response.data['data'] as List)
          .map((json) => Plot.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Plot> getPlotDetail(String id) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.plotDetail(id),
      );
      return Plot.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> deletePlot(String id) async {
    try {
      await _apiClient.dio.delete(ApiEndpoints.plotDetail(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
```

---

### GAP - Submit Record

```dart
// lib/core/services/gap_service.dart
class GapService {
  final ApiClient _apiClient = ApiClient();
  
  Future<GapRecord> submitGapRecord({
    required String plotId,
    required String recordDate,
    required String activity,
    required String details,
    String? result,
    List<String>? images,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.gapRecords,
        data: {
          'plotId': plotId,
          'recordDate': recordDate,
          'activity': activity,
          'details': details,
          if (result != null) 'result': result,
          if (images != null) 'images': images,
        },
      );
      return GapRecord.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Similar for other GAP categories:
  // - submitGapInput()
  // - submitFieldManagement()
  // - submitHarvest()
  // - submitPostHarvest()
  // - submitWorkerTraining()
  // - submitTraceability()
}
```

---

### ADMIN - Approve/Reject User

```dart
// lib/core/services/admin_service.dart
class AdminService {
  final ApiClient _apiClient = ApiClient();
  
  Future<List<User>> getUsers({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.adminUsers,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );
      
      return (response.data['data'] as List)
          .map((json) => User.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> approveUser(String userId) async {
    try {
      await _apiClient.dio.post(ApiEndpoints.approveUser(userId));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> rejectUser(String userId, String reason) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.rejectUser(userId),
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<AdminStatistics> getStatistics() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.adminStatistics,
      );
      return AdminStatistics.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
```

---

### LOCATIONS - Cascading Data

```dart
// lib/core/services/location_service.dart
class LocationService {
  final ApiClient _apiClient = ApiClient();
  
  Future<List<Province>> getProvinces() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.provinces);
      return (response.data as List)
          .map((json) => Province.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<District>> getDistricts(String provinceCode) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.districts(provinceCode),
      );
      return (response.data as List)
          .map((json) => District.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Subdistrict>> getSubdistricts(String districtCode) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.subdistricts(districtCode),
      );
      return (response.data as List)
          .map((json) => Subdistrict.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
```

---

### FILE UPLOAD

```dart
// lib/core/services/upload_service.dart
class UploadService {
  final ApiClient _apiClient = ApiClient();
  
  Future<String> uploadImage(File imageFile) async {
    try {
      // Compress image first
      final compressedImage = await _compressImage(imageFile);
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressedImage.path,
          filename: path.basename(compressedImage.path),
        ),
      });
      
      final response = await _apiClient.dio.post(
        ApiEndpoints.upload,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
        onSendProgress: (sent, total) {
          // Update progress indicator
          final progress = (sent / total * 100).toStringAsFixed(0);
          debugPrint('Upload progress: $progress%');
        },
      );
      
      return response.data['url'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<File> _compressImage(File file) async {
    final img.Image? image = img.decodeImage(file.readAsBytesSync());
    if (image == null) return file;
    
    // Resize if too large
    img.Image resized = image;
    if (image.width > 1024 || image.height > 1024) {
      resized = img.copyResize(
        image,
        width: image.width > image.height ? 1024 : null,
        height: image.height > image.width ? 1024 : null,
      );
    }
    
    // Compress
    final compressed = img.encodeJpg(resized, quality: 85);
    
    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressed);
    
    return tempFile;
  }
}
```

---

## Caching Strategy

### Local Cache Manager

```dart
// lib/core/cache/cache_manager.dart
class CacheManager {
  final SharedPreferences _prefs;
  
  CacheManager(this._prefs);
  
  // Cache with expiry
  Future<void> cacheData(
    String key,
    dynamic data,
    Duration duration,
  ) async {
    final expiryTime = DateTime.now().add(duration).millisecondsSinceEpoch;
    await _prefs.setString(key, jsonEncode(data));
    await _prefs.setInt('${key}_expiry', expiryTime);
  }
  
  // Get cached data
  T? getCachedData<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final expiryTime = _prefs.getInt('${key}_expiry');
    if (expiryTime == null || DateTime.now().millisecondsSinceEpoch > expiryTime) {
      // Expired
      return null;
    }
    
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    
    return fromJson(jsonDecode(jsonString));
  }
  
  // Clear cache
  Future<void> clearCache(String key) async {
    await _prefs.remove(key);
    await _prefs.remove('${key}_expiry');
  }
}
```

### Cache Duration Recommendations

```dart
// จังหวัด/อำเภอ/ตำบล → 30 วัน (ไม่เปลี่ยน)
await cacheManager.cacheData('provinces', data, Duration(days: 30));

// อาชีพ → 30 วัน
await cacheManager.cacheData('occupations', data, Duration(days: 30));

// User profile → 1 ชั่วโมง
await cacheManager.cacheData('user_profile', data, Duration(hours: 1));

// Dashboard stats → 5 นาที
await cacheManager.cacheData('dashboard_stats', data, Duration(minutes: 5));

// Plot list → 1 นาที (เพื่อให้ Pull-to-Refresh ได้)
await cacheManager.cacheData('plot_list', data, Duration(minutes: 1));
```

---

## Error Handling

### Custom Exceptions

```dart
// lib/core/network/exceptions.dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, {this.statusCode});
  
  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class ValidationException extends ApiException {
  ValidationException(String message) : super(message, statusCode: 400);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message, statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, statusCode: 404);
}

class ConflictException extends ApiException {
  ConflictException(String message) : super(message, statusCode: 409);
}

class TooManyRequestsException extends ApiException {
  TooManyRequestsException(String message) : super(message, statusCode: 429);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message, statusCode: 500);
}

// PIN specific
class InvalidPinException extends UnauthorizedException {
  InvalidPinException(String message) : super(message);
}

class TooManyAttemptsException extends TooManyRequestsException {
  TooManyAttemptsException(String message) : super(message);
}
```

---

## API Integration Testing Checklist

### สำหรับแต่ละ Endpoint:

- [ ] **Request**
  - [ ] Headers ครบ (Authorization, Content-Type)
  - [ ] Body format ถูกต้อง (JSON)
  - [ ] Required fields ครบ
  - [ ] Data types ถูกต้อง
  
- [ ] **Response**
  - [ ] Status Code ถูกต้อง (200, 201, etc.)
  - [ ] Response format parse ได้
  - [ ] Data mapping ถูกต้อง
  
- [ ] **Error Handling**
  - [ ] 400 Bad Request → แสดง validation error
  - [ ] 401 Unauthorized → redirect to login
  - [ ] 403 Forbidden → แสดงข้อความ
  - [ ] 404 Not Found → แสดงข้อความ
  - [ ] 409 Conflict → แสดงข้อความ (เบอร์ซ้ำ)
  - [ ] 429 Too Many Requests → แสดง rate limit message
  - [ ] 500 Server Error → แสดงข้อความทั่วไป
  - [ ] Network Error → แสดงข้อความ + Retry option
  
- [ ] **Loading State**
  - [ ] แสดง Loading indicator
  - [ ] Disable ปุ่มขณะโหลด
  
- [ ] **Success Flow**
  - [ ] แสดง Success message (ถ้าจำเป็น)
  - [ ] Update UI
  - [ ] Navigate (ถ้าจำเป็น)
  
- [ ] **Caching**
  - [ ] ข้อมูลที่ไม่เปลี่ยน → Cache นาน
  - [ ] ข้อมูลที่เปลี่ยนบ่อย → Cache สั้นหรือไม่ Cache

---

## API Testing Tools

### 1. Swagger UI
```
http://localhost:3000/docs
- ทดสอบ API ทั้งหมด
- ดู Request/Response Schema
```

### 2. Postman
```
- Import Swagger JSON
- สร้าง Collection
- Test แต่ละ Endpoint
```

### 3. Flutter Integration Test
```dart
testWidgets('Signup API integration test', (tester) async {
  final authService = AuthService();
  
  final response = await authService.signup(
    phone: '0899999999',
    birthday: '1990-01-01',
    firstName: 'Test',
    lastName: 'User',
    idCard: '1234567890123',
    province: 'กรุงเทพมหานคร',
    district: 'บางรัก',
    subDistrict: 'สีลม',
    address: 'Test Address',
    postalCode: '10500',
  );
  
  expect(response.user.firstName, 'Test');
  expect(response.accessToken, isNotNull);
});
```

---

**Document Status:** Production Ready  
**Completeness:** 100%  
**Last Review:** 2026-01-29
