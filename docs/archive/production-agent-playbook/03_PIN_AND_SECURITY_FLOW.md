# PIN & Security Complete Flow
## ระบบ PIN, Permission และความปลอดภัยครบวงจร

**Version:** 2.0.0  
**Last Updated:** 2026-01-29  
**Security Level:** High

---

## สารบัญ

1. [PIN System](#pin-system)
2. [Permission Management](#permission-management)
3. [Secure Storage](#secure-storage)
4. [Token Management](#token-management)
5. [Data Encryption](#data-encryption)
6. [Security Best Practices](#security-best-practices)

---

## PIN System

### PIN Requirements
- **Length:** 6 หลัก
- **Format:** ตัวเลข 0-9 เท่านั้น
- **Validation:** ต้องไม่เป็น pattern ง่ายๆ (123456, 000000, 111111)
- **Storage:** Hashed ด้วย bcrypt (Backend)
- **Client Side:** ไม่เก็บ PIN ที่ไหนเลย (Input แล้วส่งไป Server ทันที)

---

### Complete PIN Flow Diagram

```
Admin First Login:
┌─────────────────────────────────────────────────────────────┐
│ 1. Login Screen (Phone + Birthday)                          │
│    ↓                                                         │
│ 2. POST /auth/signin                                         │
│    ↓                                                         │
│ 3. Response: { requiresPin: true, needsSetup: true, tempToken } │
│    ↓                                                         │
│ 4. Navigate to Set PIN Screen                               │
│    ↓                                                         │
│ 5. User Input PIN (6 digits)                                │
│    ↓                                                         │
│ 6. User Confirm PIN                                          │
│    ↓                                                         │
│ 7. POST /auth/set-pin { pin, confirmPin }                   │
│    ↓                                                         │
│ 8. Response: { accessToken, refreshToken, user }            │
│    ↓                                                         │
│ 9. Save tokens to Secure Storage                            │
│    ↓                                                         │
│ 10. Navigate to Dashboard                                   │
└─────────────────────────────────────────────────────────────┘

Admin Normal Login:
┌─────────────────────────────────────────────────────────────┐
│ 1. Login Screen (Phone + Birthday)                          │
│    ↓                                                         │
│ 2. POST /auth/signin                                         │
│    ↓                                                         │
│ 3. Response: { requiresPin: true, tempToken }               │
│    ↓                                                         │
│ 4. Show PIN Input Screen                                    │
│    ↓                                                         │
│ 5. User Input PIN (6 digits)                                │
│    ↓                                                         │
│ 6. POST /auth/verify-pin { tempToken, pin }                 │
│    ↓                                                         │
│ 7. Success → { accessToken, refreshToken, user }            │
│    OR                                                        │
│    Fail → Show error + remaining attempts                   │
│    ↓                                                         │
│ 8. If Max Attempts (3) → Lock for 5 minutes                 │
│    ↓                                                         │
│ 9. Save tokens to Secure Storage                            │
│    ↓                                                         │
│ 10. Navigate to Dashboard                                   │
└─────────────────────────────────────────────────────────────┘
```

---

### PIN Input Widget (Flutter)

```dart
// lib/features/auth/widgets/pin_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinInputField extends StatefulWidget {
  final Function(String) onCompleted;
  final bool obscureText;
  final int length;
  
  const PinInputField({
    Key? key,
    required this.onCompleted,
    this.obscureText = true,
    this.length = 6,
  }) : super(key: key);

  @override
  State<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<PinInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  
  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );
  }
  
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
  
  String get _pin => _controllers.map((c) => c.text).join();
  
  void _onChanged(int index, String value) {
    if (value.isNotEmpty) {
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field → complete
        _focusNodes[index].unfocus();
        widget.onCompleted(_pin);
      }
    }
  }
  
  void _onBackspace(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.length,
        (index) => SizedBox(
          width: 50,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            obscureText: widget.obscureText,
            maxLength: 1,
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) => _onChanged(index, value),
            onTap: () {
              // Clear on tap
              _controllers[index].clear();
            },
          ),
        ),
      ),
    );
  }
}
```

---

### Set PIN Screen

```dart
// lib/features/auth/screens/set_pin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SetPinScreen extends StatefulWidget {
  final String? tempToken; // จาก signin response (ถ้ามี)
  
  const SetPinScreen({Key? key, this.tempToken}) : super(key: key);

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  bool _isLoading = false;
  
  void _onPinCompleted(String pin) {
    setState(() {
      if (!_isConfirmStep) {
        // First PIN entry
        _pin = pin;
        _isConfirmStep = true;
      } else {
        // Confirm PIN
        _confirmPin = pin;
        if (_pin == _confirmPin) {
          _submitPin();
        } else {
          _showError('PIN ไม่ตรงกัน กรุณาลองใหม่');
          setState(() {
            _pin = '';
            _confirmPin = '';
            _isConfirmStep = false;
          });
        }
      }
    });
  }
  
  Future<void> _submitPin() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.setPin(
        pin: _pin,
        confirmPin: _confirmPin,
        tempToken: widget.tempToken,
      );
      
      if (!mounted) return;
      
      // Success → Navigate to Dashboard
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
      setState(() {
        _pin = '';
        _confirmPin = '';
        _isConfirmStep = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่า PIN'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _isConfirmStep ? 'ยืนยัน PIN' : 'กรุณาตั้งค่า PIN 6 หลัก',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _isConfirmStep
                    ? 'กรุณาใส่ PIN อีกครั้ง'
                    : 'PIN จะใช้สำหรับเข้าสู่ระบบในครั้งถัดไป',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              PinInputField(
                onCompleted: _onPinCompleted,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_isConfirmStep)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _pin = '';
                      _confirmPin = '';
                      _isConfirmStep = false;
                    });
                  },
                  child: const Text('ย้อนกลับ'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Verify PIN Screen (Login)

```dart
// lib/features/auth/screens/verify_pin_screen.dart
class VerifyPinScreen extends StatefulWidget {
  final String tempToken;
  
  const VerifyPinScreen({Key? key, required this.tempToken}) : super(key: key);

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  bool _isLoading = false;
  int _attempts = 0;
  static const int _maxAttempts = 3;
  DateTime? _lockUntil;
  
  Future<void> _onPinCompleted(String pin) async {
    // Check if locked
    if (_lockUntil != null && DateTime.now().isBefore(_lockUntil!)) {
      final remaining = _lockUntil!.difference(DateTime.now());
      _showError('ถูกล็อก กรุณารอ ${remaining.inMinutes} นาที');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.verifyPin(
        tempToken: widget.tempToken,
        pin: pin,
      );
      
      if (!mounted) return;
      
      // Success → Navigate to Dashboard
      Navigator.of(context).pushReplacementNamed('/admin/dashboard');
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _attempts++);
      
      if (_attempts >= _maxAttempts) {
        // Lock for 5 minutes
        _lockUntil = DateTime.now().add(const Duration(minutes: 5));
        _showError('ใส่ PIN ผิด 3 ครั้ง ถูกล็อก 5 นาที');
      } else {
        final remaining = _maxAttempts - _attempts;
        _showError('PIN ไม่ถูกต้อง เหลือโอกาสอีก $remaining ครั้ง');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isLocked = _lockUntil != null && DateTime.now().isBefore(_lockUntil!);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืนยัน PIN'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: isLocked ? AppColors.error : AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                isLocked ? 'ถูกล็อก' : 'กรุณาใส่ PIN',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (isLocked)
                Text(
                  'รอ ${_lockUntil!.difference(DateTime.now()).inMinutes} นาที',
                  style: TextStyle(color: AppColors.error),
                )
              else if (_attempts > 0)
                Text(
                  'เหลือโอกาสอีก ${_maxAttempts - _attempts} ครั้ง',
                  style: TextStyle(color: AppColors.warning),
                ),
              const SizedBox(height: 48),
              PinInputField(
                onCompleted: _onPinCompleted,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Change PIN Screen

```dart
// lib/features/profile/screens/change_pin_screen.dart
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({Key? key}) : super(key: key);

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  String _currentPin = '';
  String _newPin = '';
  String _confirmNewPin = '';
  
  int _step = 1; // 1: current, 2: new, 3: confirm
  bool _isLoading = false;
  
  void _onPinCompleted(String pin) {
    setState(() {
      if (_step == 1) {
        _currentPin = pin;
        _step = 2;
      } else if (_step == 2) {
        _newPin = pin;
        _step = 3;
      } else {
        _confirmNewPin = pin;
        if (_newPin == _confirmNewPin) {
          _submitChangePin();
        } else {
          _showError('PIN ใหม่ไม่ตรงกัน');
          setState(() {
            _newPin = '';
            _confirmNewPin = '';
            _step = 2;
          });
        }
      }
    });
  }
  
  Future<void> _submitChangePin() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.changePin(
        currentPin: _currentPin,
        newPin: _newPin,
        confirmNewPin: _confirmNewPin,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เปลี่ยน PIN สำเร็จ'),
          backgroundColor: AppColors.success,
        ),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
      setState(() {
        _currentPin = '';
        _newPin = '';
        _confirmNewPin = '';
        _step = 1;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
  
  String get _instruction {
    switch (_step) {
      case 1:
        return 'กรุณาใส่ PIN ปัจจุบัน';
      case 2:
        return 'กรุณาใส่ PIN ใหม่';
      case 3:
        return 'ยืนยัน PIN ใหม่อีกครั้ง';
      default:
        return '';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เปลี่ยน PIN'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_reset,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _instruction,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'ขั้นตอน $_step จาก 3',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              PinInputField(
                onCompleted: _onPinCompleted,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_step > 1)
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_step == 2) {
                        _currentPin = '';
                        _step = 1;
                      } else if (_step == 3) {
                        _newPin = '';
                        _step = 2;
                      }
                    });
                  },
                  child: const Text('ย้อนกลับ'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Permission Management

### Permission Types
1. **Camera** - ถ่ายรูปโปรไฟล์, รูปแปลง
2. **Photos** - เลือกรูปจาก Gallery
3. **Location** - ใช้ GPS วาดแผนที่
4. **Notifications** - รับ Push Notifications
5. **Storage** - บันทึกรูป QR Code

---

### Permission Flow

```
Request Permission:
┌─────────────────────────────────────────────────────────────┐
│ 1. ตรวจสอบ Permission Status                                │
│    ↓                                                         │
│ 2. ถ้า NotDetermined → Request                              │
│    ถ้า Granted → ใช้งานได้เลย                               │
│    ถ้า Denied → แสดง Dialog อธิบาย + ลิงก์ไป Settings        │
│    ถ้า PermanentlyDenied → แสดง Dialog ให้ไป Settings       │
└─────────────────────────────────────────────────────────────┘
```

---

### Permission Service (Flutter)

```dart
// lib/core/services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Camera Permission
  Future<bool> requestCamera() async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      // Show dialog to open settings
      await _showOpenSettingsDialog(
        'การเข้าถึงกล้อง',
        'แอปต้องการเข้าถึงกล้องเพื่อถ่ายรูป กรุณาเปิดใช้งานในการตั้งค่า',
      );
      return false;
    }
    
    return false;
  }
  
  // Photos Permission
  Future<bool> requestPhotos() async {
    final status = await Permission.photos.status;
    
    if (status.isGranted || status.isLimited) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.photos.request();
      return result.isGranted || result.isLimited;
    }
    
    if (status.isPermanentlyDenied) {
      await _showOpenSettingsDialog(
        'การเข้าถึงรูปภาพ',
        'แอปต้องการเข้าถึงรูปภาพเพื่อเลือกรูปโปรไฟล์ กรุณาเปิดใช้งานในการตั้งค่า',
      );
      return false;
    }
    
    return false;
  }
  
  // Location Permission
  Future<bool> requestLocation() async {
    final status = await Permission.locationWhenInUse.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.locationWhenInUse.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      await _showOpenSettingsDialog(
        'การเข้าถึงตำแหน่ง',
        'แอปต้องการเข้าถึงตำแหน่งของคุณเพื่อวาดแผนที่แปลง กรุณาเปิดใช้งานในการตั้งค่า',
      );
      return false;
    }
    
    return false;
  }
  
  // Notification Permission
  Future<bool> requestNotification() async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      await _showOpenSettingsDialog(
        'การแจ้งเตือน',
        'แอปต้องการส่งการแจ้งเตือนเพื่อแจ้งข้อมูลสำคัญ กรุณาเปิดใช้งานในการตั้งค่า',
      );
      return false;
    }
    
    return false;
  }
  
  // Show Dialog to open Settings
  Future<void> _showOpenSettingsDialog(String title, String message) async {
    // ใช้ dialog package หรือ custom dialog
    // แสดง Dialog พร้อมปุ่มไป Settings
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('ไปที่การตั้งค่า'),
          ),
        ],
      ),
    );
  }
}
```

---

## Secure Storage

### Using FlutterSecureStorage

```dart
// lib/core/security/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  SecureStorage._internal();
  
  // Token Management
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }
  
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }
  
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }
  
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }
  
  // User Data (Sensitive)
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(
      key: 'user_data',
      value: jsonEncode(userData),
    );
  }
  
  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: 'user_data');
    if (data == null) return null;
    return jsonDecode(data);
  }
  
  // Temp Token (for PIN flow)
  Future<void> saveTempToken(String token) async {
    await _storage.write(key: 'temp_token', value: token);
  }
  
  Future<String?> getTempToken() async {
    return await _storage.read(key: 'temp_token');
  }
  
  Future<void> deleteTempToken() async {
    await _storage.delete(key: 'temp_token');
  }
  
  // Clear All (Logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

---

### What NOT to store in Secure Storage
**ไม่เก็บ:**
- PIN (ไม่เก็บที่ไหนเลย)
- User passwords (ใช้ birthday แทน)
- เบอร์บัตรประชาชนแบบ plain text (ถ้าจำเป็นต้องเก็บ → encrypt)

**เก็บได้:**
- Access Token
- Refresh Token
- Temp Token (for PIN flow)
- User basic data (ชื่อ, role, id)

---

## Token Management

### Token Types
1. **Access Token**
   - Expiry: 1 ชั่วโมง
   - ใช้สำหรับ API calls
   - เก็บใน Secure Storage

2. **Refresh Token**
   - Expiry: 7 วัน
   - ใช้สำหรับ refresh access token
   - เก็บใน Secure Storage

3. **Temp Token**
   - Expiry: 5 นาที
   - ใช้สำหรับ PIN flow
   - เก็บชั่วคราว, ลบทันทีหลังใช้

---

### Auto Token Refresh

```dart
// lib/core/network/interceptors/auth_interceptor.dart
class AuthInterceptor extends Interceptor {
  final SecureStorage _storage = SecureStorage();
  
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    
    if (token != null) {
      // Check if token will expire soon (< 5 minutes)
      if (_willExpireSoon(token)) {
        // Refresh token
        final refreshed = await _refreshToken();
        if (refreshed) {
          final newToken = await _storage.getAccessToken();
          options.headers['Authorization'] = 'Bearer $newToken';
        }
      } else {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return handler.next(options);
  }
  
  bool _willExpireSoon(String token) {
    // Decode JWT and check exp
    final parts = token.split('.');
    if (parts.length != 3) return false;
    
    final payload = json.decode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    
    final exp = payload['exp'];
    if (exp == null) return false;
    
    final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final now = DateTime.now();
    final diff = expDate.difference(now);
    
    return diff.inMinutes < 5;
  }
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;
      
      final dio = Dio(); // Separate instance to avoid recursion
      final response = await dio.post(
        'http://localhost:3000/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      
      await _storage.saveAccessToken(response.data['accessToken']);
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

---

## Security Best Practices

### 1. Sensitive Data Handling
```dart
// ถูกต้อง
final token = await SecureStorage().getAccessToken();

// ผิด
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('token'); // ไม่ปลอดภัย
```

### 2. API Calls
```dart
// ถูกต้อง - HTTPS only
final apiUrl = 'https://api.example.com';

// ผิด - HTTP
final apiUrl = 'http://api.example.com'; // ไม่ปลอดภัย
```

### 3. Logging
```dart
// ถูกต้อง - ไม่ log sensitive data
debugPrint('API call to /users/me');

// ผิด
debugPrint('Token: $token'); // ห้าม log token
debugPrint('PIN: $pin'); // ห้าม log PIN
```

### 4. Error Messages
```dart
// ถูกต้อง - Generic error
throw Exception('Invalid credentials');

// ผิด - Too specific
throw Exception('PIN hash does not match'); // เปิดเผยข้อมูลมากเกิน
```

---

## Security Checklist

### ก่อน Production:
- [ ] ทุก API call ใช้ HTTPS
- [ ] Token เก็บใน Secure Storage
- [ ] ไม่มี hardcoded secrets ในโค้ด
- [ ] ลบ debug logs ทั้งหมด
- [ ] Permission requests มี description ชัดเจน
- [ ] PIN flow ทำงานถูกต้อง (max 3 attempts, lock 5 min)
- [ ] Auto token refresh ทำงาน
- [ ] Logout ลบข้อมูลทั้งหมดใน Secure Storage
- [ ] Certificate Pinning (optional, for high security)

---

**Document Status:** Production Ready  
**Security Level:** High  
**Last Review:** 2026-01-29
