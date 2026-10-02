# AI Agent Control Document
## เอกสารควบคุม AI Agent สำหรับการพัฒนา Project แบบต่อเนื่อง

**Version:** 1.0.1 (Flutter Edition)
**Last Updated:** 2026-01-29
**Project Type:** Community Enterprise Application
**Target Platform:** iOS/Android
**Framework:** Flutter (Dart)
**Context:** แอปเกี่ยวกับเกษตรพืชเสพติดที่อยู่ภายใต้การควบคุมโดยกฎหมายของประเทศไทย

---

## ภาพรวม (Overview)

เอกสารนี้ออกแบบมาเพื่อให้ AI Agent สามารถจัดการ Project แบบต่อเนื่องโดยไม่ต้องหยุดพัก พร้อมรักษามาตรฐานคุณภาพสูงสุดและความพร้อมสำหรับ Production บนพื้นฐานของ Flutter Framework

### เป้าหมายหลัก
- ลด Hardcode และ Code ที่ไม่จำเป็น
- เพิ่ม Performance และ Optimization (Dart/Flutter best practices)
- ให้ App ลื่นไหลพร้อม Loading Effects ที่สวยงาม
- จัดการ API Integration ให้ครบถ้วน
- ตรวจสอบ Bug และแก้ไขให้สมบูรณ์
- เตรียมความพร้อมสำหรับ Production และ App Store
- จัดการข้อมูล Local Storage อย่างเหมาะสม (SharedPreferences/FlutterSecureStorage)

---

## Local Storage Strategy

### ข้อมูลที่ควรเก็บ Local
```dart
// ใช้ shared_preferences สำหรับข้อมูลทั่วไป
import 'package:shared_preferences/shared_preferences.dart';

// ข้อมูลที่เหมาะสมเก็บ Local:
- User preferences (ภาษา, theme)
- Cache API responses (จังหวัด, อำเภอ, ตำบล - JSON String)
- App settings
- Last sync timestamp
- Static content (คำแนะนำ, FAQ)

// ข้อมูลที่ต้องเก็บ Secure (ใช้ flutter_secure_storage):
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

- Auth token (JWT)
- Refresh token
- PIN (hashed)
- User credentials
```

### ข้อจำกัดการเก็บข้อมูล Local
1. **ขนาด**: ต้องไม่เก็บข้อมูลขนาดใหญ่เกินไป (< 50MB)
2. **ความปลอดภัย**: ข้อมูล Sensitive ต้องใช้ Secure Storage เท่านั้น
3. **อายุข้อมูล**: ข้อมูลที่เปลี่ยนบ่อยควรมี Expiry time

---

## Core Principles (Flutter-specific)

### 1. Zero Hardcode Policy
```dart
// ไม่ดี
const apiUrl = "https://api.example.com";
const primaryColor = Color(0xFF007AFF);

// ดี
import 'package:flutter_dotenv/flutter_dotenv.dart';
final apiUrl = dotenv.env['API_URL'];

import 'package:taptom/core/constants/app_colors.dart';
final color = AppColors.primary;
```

### 2. Clean Code Standards (Dart)
- ใช้ `const` constructor เมื่อทำได้ เพื่อ Performance
- แยก Widget ที่ซับซ้อนออกมาเป็นไฟล์แยก (Extract Widgets)
- ไม่ใช้ `setState` ใน Widget ขนาดใหญ่ ให้ใช้ State Management (Provider/Riverpod/Bloc)
- ไม่มี Unused Imports (`dart fix` หรือ `flutter analyze` ต้องผ่าน)
- ไม่มี `print()` ใน Production Code (ใช้ Logger หรือ `debugPrint` แทน)

### 3. Performance First
- ใช้ `ListView.builder` แทน `ListView` ปกติสำหรับรายการยาว
- ใช้ `const` Widgets เพื่อลดการ Rebuild
- Image Optimization (ใช้ `cached_network_image`)
- ระวัง Memory Leak จาก StreamSubscription (ต้อง cancel ใน `dispose`)

---

## Development Workflow

### Phase 1: Code Quality Check (ทุกครั้งก่อนเริ่มงาน)
```bash
# 1. ตรวจสอบโค้ด
flutter analyze

# 2. จัดรูปแบบโค้ด
dart format .

# 3. ตรวจสอบ Dependencies
flutter pub outdated
```

### Phase 2: Feature Development
1. อ่านเอกสาร Feature Spec / User Story
2. ตรวจสอบ API Swagger
3. เขียน Widget/Logic ตาม Clean Architecture
    - **Presentation**: Screen, Widget, Provider/Controller
    - **Domain**: Entity, Usecase, Repository Interface
    - **Data**: Model, Repository Impl, Datasource
4. เขียน Tests (Unit/Widget Tests)
5. ทดสอบบน Emulator/Device

### Phase 3: Testing & Validation
1. ทดสอบ User Flow (Happy/Unhappy paths)
2. ทดสอบการแสดงผลบนขนาดหน้าจอต่างๆ (Responsive)
3. ตรวจสอบ Error Handling (เน็ตหลุด, API Error)

### Phase 4: Pre-Production Check
1. ลบ Mock Data
2. ลบ `debugPrint` หรือ Logs ที่ไม่จำเป็น
3. ตรวจสอบ Environment Variables (Prod)
4. Build AppBundle/IPA

---

## User Roles & Responsibilities

### 1. User (ผู้ใช้ทั่วไป)
- **Features**: ลงทะเบียน, Login, จัดการ Profile, เลือกอาชีพ/พื้นที่, รออนุมัติ
- **Checklist**: Validation ครบ, Upload รูปได้, เลือก Location ถูกต้อง, UI ไม่เพี้ยน

### 2. Admin (ผู้ดูแลระดับจังหวัด)
- **Features**: Login (PIN), Approve/Reject User, ดูสถิติในเขต, จัดการ Profile
- **Checklist**: PIN Flow ปลอดภัย, Filter User ได้ถูกต้อง, Data Update Realtime/Near-realtime

### 3. Super Admin (ผู้ดูแลระดับสูงสุด)
- **Features**: Dashboard, จัดการ Admin/User ทั้งหมด, Settings
- **Checklist**: กราฟแสดงผลถูกต้อง, Export ข้อมูลได้, จัดการ Role ได้

---

## Technical Standards

### File Structure (Example)
```
lib/
├── core/                   # Shared logic, utilities, constants
│   ├── constants/
│   ├── error/
│   ├── network/
│   ├── theme/
│   └── widgets/            # Common widgets (Button, Input)
├── data/
│   ├── datasources/
│   ├── models/             # JSON parsing models
│   └── repositories/       # Implementation of repositories
├── domain/
│   ├── entities/           # Business objects
│   ├── repositories/       # Interfaces
│   └── usecases/
├── features/               # Feature-based folder structure
│   ├── auth/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   ├── provider/   # or widgets
│   │   │   └── widgets/
│   │   └── ...
│   ├── home/
│   └── ...
└── main.dart
```

### Naming Conventions
- **Classes**: PascalCase (e.g., `LoginScreen`, `AuthService`)
- **Variables/Functions**: camelCase (e.g., `isLoading`, `fetchData`)
- **Files**: snake_case (e.g., `login_screen.dart`, `auth_service.dart`)
- **Constants**: lowerCamelCase หรือ kPascalCase (Flutter style prefer `kPrimaryColor` or just `primaryColor`) แต่ถ้าเป็น const ระดับ Global อาจใช้ SCREAMING_SNAKE_CASE ได้ตามความเหมาะสมของทีม แต่ Dart Guide แนะนำ lowerCamelCase สำหรับ constant variables

---

## UI/UX Standards

### Loading States
- ทุก Async Action ต้องแสดง Loading Indicator
- ใช้ Skeleton Loading สำหรับ List

### Error Handling
- แสดง Dialog หรือ Snackbar เมื่อเกิด Error ที่ User ควรรู้
- จัดการ Empty State อย่างสวยงาม

### Theme
- ใช้ค่าจาก `Theme.of(context)` หรือ `AppColors` constant
- หลีกเลี่ยง hardcoded Color/FontSize ใน Widget โดยตรง

---

## AI Agent Instructions

### คำสั่งหลักสำหรับ Agent

1. **เมื่อเริ่มงาน:**
   - อ่าน `AI_AGENT_CONTROL.md` (ฉบับนี้)
   - `flutter analyze` เพื่อดูสถานะปัจจุบัน
   - ตรวจสอบ `pubspec.yaml` ดู dependencies

2. **เมื่อพัฒนา Feature:**
   - ใช้ Provider/Riverpod/Bloc ตามที่โปรเจกต์ใช้อยู่ (ปัจจุบันดูเหมือนใช้ `Provider`)
   - แยก UI และ Logic ออกจากกัน
   - Reuse Widgets ใน `core/widgets` ให้มากที่สุด

3. **เมื่อแก้ Bug:**
   - Reproduce ให้ได้ก่อน
   - แก้ไขที่ต้นเหตุ
   - ตรวจสอบผลกระทบข้างเคียง (Side Effects)

4. **ห้ามทำ (Never Do):**
   - ห้าม Hardcode String/Color
   - ห้ามทิ้ง `print` ไว้ใน Production
   - ห้ามแก้ไฟล์ Library ใน `flutter_plugins`
   - ห้าม Force Unwrap (`!`) ถ้าไม่มั่นใจ 100% ว่าไม่ null

---

**Contact & Support:**
Technical Lead: [ชื่อ]
API Docs: ดูใน README หรือ Swagger Project
Design System: ยึดตาม `UI_UX_DESIGN_GUIDELINES.md`
