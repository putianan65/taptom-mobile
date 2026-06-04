# Code Quality Standards
## มาตรฐานคุณภาพโค้ดและแนวทางการเขียน (Flutter Edition)

**Version:** 1.0.1 (Flutter Edition)
**Last Updated:** 2026-01-29

---

## 🎯 Core Principles

### 1. Clean Code
- Code ต้องอ่านง่าย เข้าใจง่าย
- Naming conventions ชัดเจน (Effective Dart)
- Widgets ควรมีขนาดเล็ก (Extract Widget)
- DRY (Don't Repeat Yourself)
- KISS (Keep It Simple, Stupid)

### 2. Maintainability
- Code ต้องแก้ไขง่าย
- Structure ชัดเจน (Feature-first or Layer-first)
- Documentation ครบถ้วน (Comments for complex logic)
- Tests ครอบคลุม (Unit, Widget, Integration)

### 3. Performance
- Optimize เมื่อจำเป็น
- ใช้ `const` constructor เสมอเมื่อทำได้
- หลีกเลี่ยงการ Rebuild โดยไม่จำเป็น (ใช้ `Consumer`, `Selector` หรือ `const`)
- ระวัง Memory Leak (Dispose controllers, streams)

---

## 📁 Project Structure (Feature-first)

### Recommended Structure
```
lib/
├── core/                   # โค้ดที่ใช้ร่วมกันทั้งโปรเจกต์
│   ├── config/             # Config ต่างๆ (Router, Theme, Env)
│   ├── constants/          # Constants (Colors, Assets, Dimens)
│   ├── error/              # Custom Exceptions, Failures
│   ├── network/            # Dio/Http Client, Interceptors
│   ├── utils/              # Utility functions (Validators, Formatters)
│   └── widgets/            # Generic Widgets (CustomButton, CustomTextField)
│
├── data/                   # Data Layer (ถ้าใช้ Clean Arch แบบรวม)
│   ├── datasources/
│   ├── models/
│   └── repositories/
│
├── features/               # แยกตาม Feature
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/   # Presentation Layer
│   │       ├── pages/      # Screens (LoginScreen)
│   │       ├── providers/  # State Management (AuthProvider)
│   │       └── widgets/    # Feature-specific widgets
│   │
│   ├── home/
│   └── profile/
│
├── main.dart               # Entry point
└── app.dart                # MaterialApp setup
```

---

## 📝 Naming Conventions (Dart Style)

### Files & Folders
```dart
// ✅ ดี (snake_case)
lib/features/auth/presentation/pages/login_screen.dart
lib/core/utils/date_formatter.dart

// ❌ ไม่ดี
lib/features/Auth/LoginScreen.dart
lib/utils/dateFormatter.dart
```

### Classes & Types
```dart
// ✅ UpperCamelCase
class LoginScreen extends StatefulWidget { ... }
class AuthRepository { ... }
enum UserStatus { active, inactive }

// ❌ ไม่ดี
class loginScreen extends StatefulWidget { ... }
class auth_repository { ... }
```

### Variables & Functions
```dart
// ✅ lowerCamelCase
String userName = 'John';
void fetchUserProfile() { ... }
final bool isValid = true;

// ❌ ไม่ดี
String UserName = 'John';
void FetchUserProfile() { ... }
```

### Constants
```dart
// ✅ lowerCamelCase (Preferred) or SCREAMING_SNAKE_CASE
const double defaultPadding = 16.0;
const int maxRetries = 3;

// หรือถ้าเป็น Class-level static const
class AppConstants {
  static const String appName = 'TapTom';
}
```

---

## 🏗️ Component (Widget) Structure

### Stateful Widget Template
```dart
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  final String title;

  const MyWidget({
    super.key,
    required this.title,
  });

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // State variables
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    // Dispose controllers, streams
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    // ... logic
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Center(child: Text('Content'));
  }
}
```

---

## 🎨 Styling Best Practices

### Theme & Colors
```dart
// ✅ ใช้ Theme Context
Text(
  'Hello',
  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
    color: Theme.of(context).colorScheme.primary,
  ),
);

// ✅ ใช้ Constants class
import 'package:taptom/core/constants/app_colors.dart';

Container(
  color: AppColors.primary,
);

// ❌ ไม่ Hardcode สี
Container(
  color: Color(0xFF123456), // Avoid this
);
```

### Padding & Spacing
```dart
// ✅ ใช้ Constants หรือ Size Config
Padding(
  padding: const EdgeInsets.all(AppDimens.paddingMd), // 16.0
  child: ...
)
```

---

## ⚡ Performance Optimization Rules

### 1. Use const constructors
```dart
// ✅ ดี
const SizedBox(height: 10);
const Text('Static Text');

// ❌ ไม่ดี (Rebuilds unnecessarily)
SizedBox(height: 10);
Text('Static Text');
```

### 2. ListView.builder
```dart
// ✅ ดี - สร้าง Item เท่าที่เห็นบนจอ
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ListItem(items[index]),
);

// ❌ ไม่ดี - สร้างทุก Item ทีเดียว (ถ้า list ยาว)
ListView(
  children: items.map((item) => ListItem(item)).toList(),
);
```

### 3. Image Caching
```dart
// ✅ ดี
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => CircularProgressIndicator(),
);
```

---

## 🧪 Testing Standards

### Unit Test Template
```dart
// test/features/auth/auth_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  late AuthUseCase authUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authUseCase = AuthUseCase(mockAuthRepository);
  });

  test('should return User when login is successful', () async {
    // Arrange
    when(mockAuthRepository.login(any, any))
        .thenAnswer((_) async => Right(tUser));

    // Act
    final result = await authUseCase.execute(tParams);

    // Assert
    expect(result, Right(tUser));
    verify(mockAuthRepository.login(any, any));
  });
}
```

### Widget Test Template
```dart
// test/widgets/custom_button_test.dart
void main() {
  testWidgets('CustomButton displays text and triggers onTap', (tester) async {
    bool pressed = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Click Me',
            onTap: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Click Me'), findsOneWidget);
    
    await tester.tap(find.byType(CustomButton));
    expect(pressed, true);
  });
}
```

---

## 🔒 Security Best Practices

### 1. Secure Storage
- ใช้ `flutter_secure_storage` สำหรับ Token, PIN, Credentials
- อย่าเก็บ Sensitive Data ใน `SharedPreferences` (มันเป็นแค่ XML/Plist ธรรมดา)

### 2. API Security
- ใช้ HTTPS เสมอ
- ทำ Certificate Pinning (ถ้าจำเป็นสำหรับ High Security)
- ไม่เก็บ API Keys ใน Git (ใช้ `.env`)

### 3. Input Validation
- Validate Form ก่อนส่งไป Backend
- Sanitize input ถ้าแสดงผล HTML/Markdown

---

## 📚 Documentation Standards

### Code Comments (Dart Doc)
```dart
/// Authenticates the user with [username] and [password].
/// 
/// Returns a [User] object if successful, or throws an [AuthException].
/// 
/// Example:
/// ```dart
/// final user = await authService.login('user', 'pass');
/// ```
Future<User> login(String username, String password) async { ... }
```
