# Bug Prevention & Resolution System
## ระบบป้องกันและแก้ไข Bug แบบ Proactive

**Version:** 2.0.0  
**Last Updated:** 2026-01-29  
**Approach:** Prevention > Detection > Resolution

---

## สารบัญ

1. [Bug Prevention Strategy](#bug-prevention-strategy)
2. [Common Flutter Bugs](#common-flutter-bugs)
3. [Testing Strategy](#testing-strategy)
4. [Debug Tools](#debug-tools)
5. [Bug Resolution Workflow](#bug-resolution-workflow)

---

## Bug Prevention Strategy

### Prevention Checklist (ทำก่อนเขียนโค้ดทุกครั้ง)

```dart
// DO
1. อ่าน Requirements ให้ชัดเจน
2. ดู API Spec ใน Swagger
3. เช็ค Existing Code Patterns
4. ใช้ Type Safety (Dart)
5. Null Safety ครบ

// DON'T
1. Copy-paste โค้ดโดยไม่เข้าใจ
2. Skip validation
3. Hardcode values
4. Ignore warnings
5. ไม่ทดสอบก่อน commit
```

---

## Common Flutter Bugs & Solutions

### 1. RenderFlex Overflow

**อาการ:**
```
════════ Exception caught by rendering library ═════════════════════════════════
A RenderFlex overflowed by 99 pixels on the bottom.
```

**สาเหตุ:**
- Content ยาวเกินจอ
- ไม่มี ScrollView

**วิธีแก้:**
```dart
// ผิด
Column(
  children: [
    Header(),
    VeryLongForm(), // ยาวเกินจอ
  ],
)

// ถูก (Option 1: SingleChildScrollView)
SingleChildScrollView(
  child: Column(
    children: [
      Header(),
      VeryLongForm(),
    ],
  ),
)

// ถูก (Option 2: ListView)
ListView(
  children: [
    Header(),
    VeryLongForm(),
  ],
)

// ถูก (Option 3: Expanded)
Column(
  children: [
    Header(),
    Expanded(
      child: ListView(...),
    ),
  ],
)
```

---

### 2. BuildContext Across Async Gaps

**อาการ:**
```
Don't use 'BuildContext's across async gaps.
```

**สาเหตุ:**
- ใช้ `context` หลัง `await` โดยไม่เช็ค `mounted`

**วิธีแก้:**
```dart
// ผิด
Future<void> _loadData() async {
  await someAsyncOperation();
  Navigator.pop(context); // context อาจจะไม่อยู่แล้ว
}

// ถูก
Future<void> _loadData() async {
  await someAsyncOperation();
  if (!mounted) return; // เช็คก่อน
  Navigator.pop(context);
}
```

---

### 3. Provider Not Found

**อาการ:**
```
Error: Could not find the correct Provider<T> above this Widget
```

**สาเหตุ:**
- ไม่ได้ wrap widget ใน Provider
- Context ผิดชั้น

**วิธีแก้:**
```dart
// ผิด
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ยังไม่มี Provider
    final authProvider = context.read<AuthProvider>(); // Error!
    
    return MaterialApp(...);
  }
}

// ถูก
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PlotProvider()),
      ],
      child: MaterialApp(...),
    );
  }
}

// ใช้ใน Widget ข้างใน
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>(); // OK!
    ...
  }
}
```

---

### 4. Memory Leaks

**อาการ:**
- App ใช้ Memory เพิ่มขึ้นเรื่อยๆ
- App ช้าลงเมื่อใช้งานนาน

**สาเหตุ:**
- ไม่ dispose Controllers
- ไม่ cancel Subscriptions
- ไม่ cancel Timers

**วิธีแก้:**
```dart
// ผิด
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final _controller = TextEditingController();
  StreamSubscription? _subscription;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _subscription = someStream.listen(...);
    _timer = Timer.periodic(Duration(seconds: 1), ...);
  }
  
  // ไม่มี dispose!
}

// ถูก
class _MyScreenState extends State<MyScreen> {
  final _controller = TextEditingController();
  StreamSubscription? _subscription;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _subscription = someStream.listen(...);
    _timer = Timer.periodic(Duration(seconds: 1), ...);
  }
  
  @override
  void dispose() {
    _controller.dispose(); // Dispose controller
    _subscription?.cancel(); // Cancel subscription
    _timer?.cancel(); // Cancel timer
    super.dispose();
  }
}
```

---

### 5. setState() Called After dispose()

**อาการ:**
```
setState() called after dispose()
```

**สาเหตุ:**
- เรียก `setState()` หลังจาก widget ถูก dispose แล้ว

**วิธีแก้:**
```dart
// ผิด
Future<void> _loadData() async {
  final data = await fetchData();
  setState(() {
    _data = data; // อาจจะเรียกหลัง dispose
  });
}

// ถูก
Future<void> _loadData() async {
  final data = await fetchData();
  if (mounted) { // เช็คก่อน
    setState(() {
      _data = data;
    });
  }
}
```

---

### 6. Null Check Operator Used on Null Value

**อาการ:**
```
Null check operator used on a null value
```

**สาเหตุ:**
- ใช้ `!` กับ value ที่เป็น null

**วิธีแก้:**
```dart
// ผิด
String getName() {
  return user!.name; // user อาจเป็น null
}

// ถูก (Option 1: Null-aware)
String? getName() {
  return user?.name;
}

// ถูก (Option 2: Default value)
String getName() {
  return user?.name ?? 'Unknown';
}

// ถูก (Option 3: เช็คก่อน)
String? getName() {
  if (user == null) return null;
  return user.name;
}
```

---

### 7. Duplicate Keys

**อาการ:**
```
Multiple widgets used the same GlobalKey
```

**สาเหตุ:**
- ใช้ GlobalKey ซ้ำ

**วิธีแก้:**
```dart
// ผิด
final _formKey = GlobalKey<FormState>(); // แชร์ระหว่าง widgets

ListView.builder(
  itemCount: 10,
  itemBuilder: (context, index) => Form(
    key: _formKey, // ใช้ซ้ำ!
    child: ...,
  ),
)

// ถูก (Option 1: สร้างใหม่แต่ละตัว)
ListView.builder(
  itemCount: 10,
  itemBuilder: (context, index) => Form(
    key: GlobalKey<FormState>(), // สร้างใหม่
    child: ...,
  ),
)

// ถูก (Option 2: ใช้ ValueKey)
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(
    key: ValueKey(items[index].id), // Unique key
    item: items[index],
  ),
)
```

---

### 8. Incorrect Use of ParentDataWidget

**อาการ:**
```
Incorrect use of ParentDataWidget
```

**สาเหตุ:**
- ใช้ `Expanded`, `Flexible`, `Positioned` ผิดที่

**วิธีแก้:**
```dart
// ผิด
Container(
  child: Expanded( // Expanded ต้องอยู่ใน Row/Column
    child: Text('Hello'),
  ),
)

// ถูก
Column(
  children: [
    Expanded(
      child: Text('Hello'),
    ),
  ],
)

// ผิด
Container(
  child: Positioned( // Positioned ต้องอยู่ใน Stack
    top: 10,
    child: Text('Hello'),
  ),
)

// ถูก
Stack(
  children: [
    Positioned(
      top: 10,
      child: Text('Hello'),
    ),
  ],
)
```

---

## Testing Strategy

### Test Pyramid
```
        E2E (10%)
           ↑
    Integration (20%)
           ↑
       Unit (70%)
```

### 1. Unit Tests

**ทดสอบ:**
- Functions
- Methods
- Business Logic

**ตัวอย่าง:**
```dart
// test/core/utils/validators_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taptom/core/utils/validators.dart';

void main() {
  group('Phone Validator', () {
    test('should return true for valid phone', () {
      expect(Validators.isValidPhone('0812345678'), true);
    });
    
    test('should return false for invalid phone', () {
      expect(Validators.isValidPhone('123'), false);
      expect(Validators.isValidPhone('08123456789'), false);
      expect(Validators.isValidPhone('1234567890'), false);
    });
  });
  
  group('ID Card Validator', () {
    test('should return true for valid ID card', () {
      expect(Validators.isValidIdCard('1234567890123'), true);
    });
    
    test('should return false for invalid ID card', () {
      expect(Validators.isValidIdCard('123'), false);
      expect(Validators.isValidIdCard('12345678901234'), false);
    });
  });
}
```

---

### 2. Widget Tests

**ทดสอบ:**
- UI Components
- User Interactions
- Widget Tree

**ตัวอย่าง:**
```dart
// test/widgets/custom_button_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taptom/core/widgets/app_button.dart';

void main() {
  testWidgets('AppButton displays text and triggers onPressed', (tester) async {
    bool pressed = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Click Me',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );
    
    // Verify text
    expect(find.text('Click Me'), findsOneWidget);
    
    // Tap button
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    
    // Verify callback
    expect(pressed, true);
  });
  
  testWidgets('AppButton shows loading when isLoading=true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Submit',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );
    
    // Verify loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Submit'), findsNothing);
  });
}
```

---

### 3. Integration Tests

**ทดสอบ:**
- User Flows
- API Integration
- Navigation

**ตัวอย่าง:**
```dart
// integration_test/login_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taptom/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Login Flow', () {
    testWidgets('should login successfully with valid credentials', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Find login button
      final loginButton = find.text('เข้าสู่ระบบ');
      expect(loginButton, findsOneWidget);
      
      // Tap login
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
      
      // Enter phone
      await tester.enterText(
        find.byKey(const Key('phone_field')),
        '0812345678',
      );
      
      // Enter birthday
      await tester.tap(find.byKey(const Key('birthday_field')));
      await tester.pumpAndSettle();
      // ... select date
      
      // Submit
      await tester.tap(find.text('ยืนยัน'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Verify dashboard
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
```

---

## Debug Tools

### 1. Flutter DevTools

**Features:**
- Widget Inspector
- Timeline (Performance)
- Memory
- Network
- Logging

**การใช้:**
```bash
# รัน app ใน debug mode
flutter run

# เปิด DevTools
# URL จะแสดงใน console
```

**สิ่งที่ควรเช็ค:**
- Widget Tree ซ้อนกันเกินไปไหม
- Rebuild บ่อยเกินไปไหม
- Memory leak มีไหม
- FPS ต่ำไหม

---

### 2. Logging

```dart
// lib/core/utils/logger.dart
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );
  
  static void debug(String message) {
    if (kDebugMode) {
      _logger.d(message);
    }
  }
  
  static void info(String message) {
    if (kDebugMode) {
      _logger.i(message);
    }
  }
  
  static void warning(String message) {
    if (kDebugMode) {
      _logger.w(message);
    }
  }
  
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.e(message, error, stackTrace);
    }
  }
}

// Usage
AppLogger.debug('User logged in');
AppLogger.error('API call failed', exception, stackTrace);
```

---

### 3. Crash Reporting (Firebase Crashlytics)

```dart
// lib/main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pass all uncaught errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  // Pass all uncaught asynchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(MyApp());
}

// Manual crash reporting
try {
  // some code
} catch (e, stack) {
  FirebaseCrashlytics.instance.recordError(e, stack);
}
```

---

## Bug Resolution Workflow

### Step 1: Reproduce
```
1. อ่าน Bug Report
2. ทำตามขั้นตอนที่ระบุ
3. ยืนยันว่าเจอ Bug จริง
4. บันทึก Steps to Reproduce
```

### Step 2: Isolate
```
1. หา Root Cause
2. ใช้ Debug Tools
3. เพิ่ม Logs
4. ลด Scope (ปิดฟีเจอร์อื่นทีละตัว)
```

### Step 3: Fix
```
1. เขียน Test ที่ Reproduce Bug
2. แก้ไขโค้ด
3. รัน Test → ต้องผ่าน
4. ทดสอบ Manual
```

### Step 4: Verify
```
1. ทดสอบ Happy Path
2. ทดสอบ Edge Cases
3. ทดสอบ Regression (ฟีเจอร์อื่นยังทำงานไหม)
4. ให้คนอื่นทดสอบ
```

### Step 5: Document
```
1. อัพเดท CHANGELOG
2. เขียน Comment ในโค้ด (ถ้าจำเป็น)
3. อัพเดท Test Cases
4. Close Bug Report
```

---

## Bug Prevention Checklist

### ก่อนเขียนโค้ด:
- [ ] อ่าน Requirements ชัดเจน
- [ ] ดู API Spec
- [ ] เช็ค Existing Patterns

### ขณะเขียนโค้ด:
- [ ] ใช้ Type Safety
- [ ] Null Safety ครบ
- [ ] Validation ครบ
- [ ] Error Handling ครบ
- [ ] ไม่ Hardcode

### หลังเขียนโค้ด:
- [ ] เขียน Tests
- [ ] รัน `flutter analyze` ผ่าน
- [ ] รัน `flutter test` ผ่าน
- [ ] ทดสอบบน Device จริง
- [ ] ทดสอบ Edge Cases

### ก่อน Commit:
- [ ] `dart format .` เรียบร้อย
- [ ] ลบ debug code
- [ ] ลบ unused imports
- [ ] ลบ TODO comments (หรือแปลงเป็น Issue)
- [ ] Code review (ถ้ามีทีม)

---

## Bug Priority Matrix

### P0 - Critical (แก้ทันที)
- App Crash
- Data Loss
- Security Vulnerabilities
- Cannot Login/Register

### P1 - High (แก้ภายใน 1 วัน)
- Major Feature Broken
- Performance < 50% Target
- API Integration Failed

### P2 - Medium (แก้ภายใน 1 สัปดาห์)
- Minor UI Issues
- Missing Validation
- Inconsistent Design

### P3 - Low (แก้เมื่อมีเวลา)
- Nice-to-have Features
- UI Polish
- Minor UX Improvements

---

## Quality Gate Checklist

### ก่อน Merge to Main:
- [ ] All Tests Pass
- [ ] Code Coverage > 80%
- [ ] `flutter analyze` ผ่าน
- [ ] Manual Testing ผ่าน
- [ ] Code Review Approved
- [ ] No P0/P1 Bugs
- [ ] Performance Check ผ่าน

### ก่อน Deploy to Production:
- [ ] All Quality Gates ผ่าน
- [ ] Security Audit ผ่าน
- [ ] Performance Targets ทุกตัวผ่าน
- [ ] E2E Tests ผ่าน
- [ ] Beta Testing ผ่าน
- [ ] Rollback Plan พร้อม

---

**Document Status:** Production Ready  
**Bug Count Target:** 0 Critical, < 3 High  
**Last Review:** 2026-01-29
