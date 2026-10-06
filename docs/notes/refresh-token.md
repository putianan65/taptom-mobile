# Refresh Token Analysis & Implementation Report

**Project:** TapTom Flutter App  
**Date:** 2026-02-02  
**Status:** Completed

---

## Executive Summary

วิเคราะห์และปรับปรุงระบบ Refresh Token ใน Flutter Frontend ให้สอดคล้องกับ Backend API ที่มีการ rotate refresh tokens และมีอายุ access token 15 นาที

### การแก้ไขที่ทำ

1. **ลบ Authorization Header ออกจาก Refresh Request** - Backend รับ refresh token จาก body เท่านั้น
2. **เพิ่ม Proactive Token Refresh** - Refresh token อัตโนมัติก่อนหมดอายุ 2 นาที
3. **เพิ่ม Token Expiry Tracking** - ติดตามเวลาหมดอายุของ access token
4. **ป้องกัน Concurrent Refresh** - ใช้ queue system สำหรับ requests ที่รอ refresh

---

## การวิเคราะห์เดิม

### ปัญหาที่พบ

#### 1. การส่ง Refresh Token ซ้ำซ้อน 
**Location:** [`lib/core/network/interceptors/auth_interceptor.dart:52-59`](lib/core/network/interceptors/auth_interceptor.dart:52)

**ปัญหา:**
```dart
// โค้ดเดิม - ส่งทั้ง Header และ Body
final response = await refreshDio.post(
  ApiEndpoints.refreshToken,
  data: {'refreshToken': refreshToken},     // ส่งใน body
  options: Options(
    headers: {'Authorization': 'Bearer $refreshToken'},  // ส่งใน header ด้วย   ),
);
```

**Backend รับจาก Body เท่านั้น:**
```typescript
// src/auth/auth.controller.ts:246
async refreshToken(@Body() dto: RefreshTokenDto) {
  return this.authService.refreshToken(dto.refreshToken);
}
```

#### 2. ไม่มี Proactive Token Refresh 
- Access token มีอายุ 15 นาที
- ต้องรอให้ได้รับ 401 ก่อนถึงจะ refresh
- ทำให้ user experience ไม่ดี (request แรกหลังหมดอายุจะล้มเหลว)

#### 3. ไม่มีการติดตาม Token Expiry 
- ไม่รู้ว่า token จะหมดอายุเมื่อไหร่
- ไม่สามารถ refresh ล่วงหน้าได้

---

## การแก้ไขที่ทำ

### 1. แก้ไข AuthInterceptor

**File:** [`lib/core/network/interceptors/auth_interceptor.dart`](lib/core/network/interceptors/auth_interceptor.dart:1)

#### เพิ่ม Proactive Refresh ใน `onRequest()`

```dart
@override
void onRequest(
  RequestOptions options,
  RequestInterceptorHandler handler,
) async {
  // Don't add token for login/signup/refresh
  if (options.path.contains('/auth/signin') ||
      options.path.contains('/auth/signup') ||
      options.path.contains('/auth/refresh')) {
    return handler.next(options);
  }

  // NEW: Check if token needs proactive refresh (within 2 min of expiry)
  final shouldRefresh = await _storage.shouldRefreshToken();
  if (shouldRefresh && !_isRefreshing) {
    print('Token expiring soon - proactive refresh...');
    final refreshed = await _performRefresh();
    if (refreshed != null) {
      options.headers['Authorization'] = 'Bearer $refreshed';
      return handler.next(options);
    }
  }

  final accessToken = await _storage.getAccessToken();
  if (accessToken != null) {
    options.headers['Authorization'] = 'Bearer $accessToken';
  }

  return handler.next(options);
}
```

#### ปรับปรุง Refresh Logic

```dart
/// Perform token refresh - returns new access token or null if failed
Future<String?> _performRefresh() async {
  // Prevent concurrent refresh requests
  if (_isRefreshing) {
    print('Waiting for ongoing refresh...');
    return await _waitForRefresh();
  }

  _isRefreshing = true;
  final refreshToken = await _storage.getRefreshToken();

  if (refreshToken == null || refreshToken.isEmpty) {
    print('No refresh token available');
    _isRefreshing = false;
    return null;
  }

  try {
    print('Calling refresh endpoint...');
    final refreshDio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl));
    final response = await refreshDio.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
      // FIXED: No Authorization header needed - /auth/refresh is @Public()
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final newAccessToken = response.data['accessToken'] as String?;
      final newRefreshToken = response.data['refreshToken'] as String?;

      if (newAccessToken != null) {
        // Save new tokens (Backend rotates refresh token)
        await _storage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? refreshToken,
        );
        
        // Notify queued requests
        for (final callback in _refreshQueue) {
          callback(newAccessToken);
        }
        _refreshQueue.clear();
        _isRefreshing = false;
        return newAccessToken;
      }
    }
  } on DioException catch (e) {
    print('Refresh failed with DioError: ${e.response?.statusCode} - ${e.message}');
    if (e.response?.statusCode == 401) {
      print('Refresh token expired or invalid - clearing tokens');
      await _storage.clearTokens();
    }
  } catch (e) {
    print('Refresh failed with error: $e');
  }

  _refreshQueue.clear();
  _isRefreshing = false;
  return null;
}

/// Wait for ongoing refresh to complete
Future<String?> _waitForRefresh() async {
  final completer = Completer<String?>();
  _refreshQueue.add((token) => completer.complete(token));
  return await completer.future;
}
```

### 2. เพิ่ม Token Expiry Tracking ใน SecureStorage

**File:** [`lib/core/security/secure_storage.dart`](lib/core/security/secure_storage.dart:1)

#### เพิ่ม Constants

```dart
// Token Expiry Tracking
static const String _tokenExpiryKey = 'access_token_expiry';
static const Duration _accessTokenLifetime = Duration(minutes: 15); // Backend: 15 min
static const Duration _refreshThreshold = Duration(minutes: 2); // Refresh 2 min before expiry
```

#### ปรับปรุง `saveTokens()`

```dart
Future<void> saveTokens({
  required String accessToken,
  required String refreshToken,
}) async {
  await _storage.write(key: _accessTokenKey, value: accessToken);
  await _storage.write(key: _refreshTokenKey, value: refreshToken);
  // NEW: Save token expiry time (current time + 15 minutes)
  final expiryTime = DateTime.now().add(_accessTokenLifetime).millisecondsSinceEpoch;
  await _storage.write(key: _tokenExpiryKey, value: expiryTime.toString());
}
```

#### เพิ่ม Token Expiry Methods

```dart
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
```

---

## Backend API Specifications

### Token Lifetimes

| Token Type | Lifetime |
|------------|----------|
| Access Token | **15 นาที** |
| Refresh Token | **7 วัน** |

### Refresh Endpoint

**Endpoint:** `POST /auth/refresh`  
**Decorator:** `@Public()` (ไม่ต้องส่ง Authorization header)

**Request:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Success Response (200):**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error Response (401):**
```json
{
  "statusCode": 401,
  "message": "Refresh token expired. Please sign in again."
}
```

### Token Rotation

Backend มีการ **rotate refresh tokens**:
- เมื่อ refresh สำเร็จ จะ revoke token เก่า
- ส่ง refresh token ใหม่กลับมาใน response
- Frontend ต้องเก็บ refresh token ใหม่ทุกครั้ง

---

## Benefits ของการแก้ไข

### 1. Better User Experience
- ไม่มี request ล้มเหลวเพราะ token หมดอายุ
- Refresh ทำงานเบื้องหลังโดยอัตโนมัติ

### 2. Reduced Server Load
- ลด 401 errors จาก expired tokens
- ลดจำนวน retry requests

### 3. Improved Security
- ส่ง refresh token ใน body เท่านั้น (ตาม Backend spec)
- รองรับ token rotation จาก Backend

### 4. Better Error Handling
- ป้องกัน concurrent refresh requests
- Queue system สำหรับ requests ที่รอ refresh

---

## Token Refresh Flow

### Proactive Refresh (ก่อนหมดอายุ)

```
User makes API request
    ↓
AuthInterceptor.onRequest()
    ↓
Check: shouldRefreshToken() → true (within 2 min of expiry)
    ↓
_performRefresh()
    ↓
POST /auth/refresh with refreshToken in body
    ↓
Get new tokens → Save to storage
    ↓
Use new access token for original request
    ↓
Request succeeds without 401
```

### Reactive Refresh (หลังได้รับ 401)

```
User makes API request
    ↓
Server returns 401 (token expired)
    ↓
AuthInterceptor.onError()
    ↓
_performRefresh()
    ↓
POST /auth/refresh with refreshToken in body
    ↓
Get new tokens → Save to storage
    ↓
Retry original request with new token
    ↓
Request succeeds
```

### Concurrent Request Handling

```
Request A triggers refresh
    ↓
_isRefreshing = true
    ↓
Request B arrives → _waitForRefresh() → added to queue
Request C arrives → _waitForRefresh() → added to queue
    ↓
Refresh completes → notify all queued requests
    ↓
All requests use new token
```

---

## Files Modified

1. **[`lib/core/network/interceptors/auth_interceptor.dart`](lib/core/network/interceptors/auth_interceptor.dart:1)**
   - ลบ Authorization header จาก refresh request
   - เพิ่ม proactive token refresh
   - เพิ่ม concurrent refresh protection
   - ปรับปรุง error handling

2. **[`lib/core/security/secure_storage.dart`](lib/core/security/secure_storage.dart:1)**
   - เพิ่ม token expiry tracking
   - เพิ่ม `shouldRefreshToken()` method
   - เพิ่ม `getTokenRemainingMinutes()` method
   - เพิ่ม `isTokenExpired()` method
   - ปรับปรุง `saveTokens()` ให้บันทึก expiry time
   - ปรับปรุง `clearTokens()` ให้ลบ expiry time ด้วย

---

## Testing Recommendations

### 1. Token Expiry Scenarios

```dart
// Test 1: Proactive refresh before expiry
// - Set token to expire in 1 minute
// - Make API request
// - Verify refresh happens automatically
// - Verify original request succeeds

// Test 2: Reactive refresh after 401
// - Use expired token
// - Make API request
// - Verify 401 triggers refresh
// - Verify retry succeeds

// Test 3: Concurrent requests during refresh
// - Trigger refresh
// - Make multiple requests while refreshing
// - Verify all requests wait for refresh
// - Verify all requests use new token
```

### 2. Error Scenarios

```dart
// Test 4: Refresh token expired
// - Use expired refresh token
// - Verify tokens are cleared
// - Verify user is logged out

// Test 5: Network error during refresh
// - Simulate network failure
// - Verify graceful error handling
// - Verify tokens remain if refresh fails
```

---

## Documentation for Backend Team

### Frontend Token Management Summary

#### Request Headers
```
Authorization: Bearer <accessToken>
```

#### Refresh Request
```http
POST /auth/refresh
Content-Type: application/json

{
  "refreshToken": "<refreshToken>"
}
```

**Note:** ไม่ส่ง Authorization header สำหรับ `/auth/refresh`

#### Token Storage
- Access Token: Secure Storage (encrypted)
- Refresh Token: Secure Storage (encrypted)
- Token Expiry: Secure Storage (timestamp)

#### Refresh Strategy
1. **Proactive:** Refresh 2 minutes before expiry
2. **Reactive:** Refresh on 401 response
3. **Concurrent Protection:** Queue multiple requests during refresh

#### Expected Backend Behavior
- Accept refresh token from request body
- Return both new access token and new refresh token
- Revoke old refresh token (rotation)
- Return 401 when refresh token is expired/invalid

---

## Conclusion

การแก้ไขนี้ทำให้ระบบ Refresh Token ของ Frontend:
1. **สอดคล้องกับ Backend API** - ส่ง refresh token ใน body เท่านั้น
2. **ปรับปรุง UX** - Proactive refresh ป้องกัน 401 errors
3. **เพิ่มความปลอดภัย** - รองรับ token rotation
4. **มีประสิทธิภาพมากขึ้น** - ป้องกัน concurrent refresh requests

ระบบพร้อมใช้งานและทดสอบได้ทันที 