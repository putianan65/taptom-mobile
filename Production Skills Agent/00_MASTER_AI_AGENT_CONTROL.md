# 🤖 MASTER AI AGENT CONTROL DOCUMENT
## เอกสารควบคุม AI Agent แบบสมบูรณ์ - สั่งครั้งเดียวทำจนจบ

**Version:** 2.0.0 (Ultimate Edition)  
**Last Updated:** 2026-01-29  
**Project:** TapTom - Drug Plant Management System  
**Framework:** Flutter 3.x (Dart)  
**Backend API:** http://localhost:3000/docs (Swagger)  
**Context:** แอปจัดการเกษตรพืชเสพติดภายใต้กฎหมายไทย พร้อมระบบ GAP

---

## 📖 สารบัญเอกสาร

### 🎯 เอกสารหลัก (ต้องอ่านก่อนเริ่มงาน)
1. **00_MASTER_AI_AGENT_CONTROL.md** ⭐ **นี่คือตัวนี้ - START HERE**
2. **01_COMPLETE_ROLE_FEATURE_MAP.md** - แผนที่ Feature ทุก Role (User/Admin/Super Admin)
3. **02_API_INTEGRATION_MASTER.md** - API Integration แบบครบถ้วน
4. **03_PIN_AND_SECURITY_FLOW.md** - PIN, Permission, Security ทั้งหมด
5. **04_GAP_SYSTEM_COMPLETE.md** - ระบบ GAP Form, Draft, Submission ครบวงจร
6. **05_BUG_PREVENTION_SYSTEM.md** - ป้องกันและแก้ Bug แบบ Proactive
7. **06_PERFORMANCE_OPTIMIZATION_ADVANCED.md** - Performance ขั้นสูง
8. **07_PRODUCTION_DEPLOYMENT_FINAL.md** - เตรียม Production แบบครบ

### 📐 เอกสารเสริม (ใช้เมื่อต้องการ)
- **DESIGN_SYSTEM_COMPLETE.md** - Design System ครบวงจร (สี, ไอคอน, Typography)
- **TESTING_AUTOMATION_GUIDE.md** - การทดสอบแบบอัตโนมัติ
- **ERROR_HANDLING_PATTERNS.md** - รูปแบบการจัดการ Error

---

## 🎯 Mission Statement

**คำสั่งเดียว จบทุกงาน**

AI Agent ต้องสามารถ:
1. ✅ ตรวจสอบสถานะปัจจุบันของโปรเจกต์
2. ✅ วิเคราะห์ส่วนที่ยังไม่เสร็จ/มีบัค
3. ✅ วางแผนการทำงานอย่างเป็นระบบ
4. ✅ ดำเนินการพัฒนา/แก้ไขจนสมบูรณ์
5. ✅ ทดสอบและ Optimize
6. ✅ เตรียมพร้อม Production
7. ✅ สร้างเอกสารประกอบ

**ทั้งหมดนี้โดยไม่ต้องหยุดรอคำสั่งเพิ่มเติม**

---

## 🚀 AI Agent Workflow (Auto-Pilot Mode)

### Phase 1: Reconnaissance (5-10 นาที)
```bash
# 1. อ่านเอกสารทั้งหมด
📄 อ่าน: 00_MASTER_AI_AGENT_CONTROL.md (นี่)
📄 อ่าน: 01_COMPLETE_ROLE_FEATURE_MAP.md
📄 อ่าน: 02_API_INTEGRATION_MASTER.md
📄 อ่าน: 03_PIN_AND_SECURITY_FLOW.md
📄 อ่าน: 04_GAP_SYSTEM_COMPLETE.md
📄 อ่าน: 05_BUG_PREVENTION_SYSTEM.md

# 2. ตรวจสอบสถานะโค้ด
flutter analyze
dart fix --dry-run
flutter test

# 3. เช็ค API
curl http://localhost:3000/docs
# หรือ เปิด browser ดู Swagger

# 4. ตรวจสอบโครงสร้าง
tree lib/ -L 3
```

### Phase 2: Analysis & Planning (10-15 นาที)
```markdown
สร้าง Checklist สำหรับ:
- [ ] Features ที่ยังไม่ทำ (ดูจาก 01_COMPLETE_ROLE_FEATURE_MAP.md)
- [ ] API ที่ยังไม่ integrate (ดูจาก 02_API_INTEGRATION_MASTER.md)
- [ ] Bug ที่พบ (ดูจาก 05_BUG_PREVENTION_SYSTEM.md)
- [ ] Security Issues (ดูจาก 03_PIN_AND_SECURITY_FLOW.md)
- [ ] Performance Issues (ดูจาก 06_PERFORMANCE_OPTIMIZATION_ADVANCED.md)
```

### Phase 3: Execution (ตามจำนวนงาน)
```markdown
สำหรับแต่ละ Task:
1. อ่านเอกสารที่เกี่ยวข้อง
2. ตรวจสอบ Code ที่มีอยู่
3. วางแผนการทำงาน
4. เขียน Code ตาม Standards
5. เขียน Tests
6. ทดสอบใน Device/Emulator
7. แก้ไข Bug (ถ้ามี)
8. Commit & Document
```

### Phase 4: Quality Assurance (ทุกครั้งหลัง Feature เสร็จ)
```bash
# Code Quality
flutter analyze
dart format .

# Testing
flutter test
flutter drive --target=test_driver/app.test.dart

# Performance
flutter run --profile
# ตรวจสอบ DevTools

# Security
# ตรวจสอบตาม 03_PIN_AND_SECURITY_FLOW.md
```

### Phase 5: Pre-Production (ก่อน Deploy)
```bash
# Build Release
flutter build apk --release
flutter build ios --release

# ตรวจสอบตาม 07_PRODUCTION_DEPLOYMENT_FINAL.md
# - Security Checklist
# - Performance Checklist
# - App Store Requirements
```

---

## 🎨 Project Overview

### โครงสร้างหลัก
```
lib/
├── core/                    # โค้ดร่วม
│   ├── config/             # Environment, Router
│   ├── constants/          # Colors, Strings, Assets
│   ├── network/            # API Client, Interceptors
│   ├── security/           # Secure Storage, Encryption
│   ├── services/           # Background Services
│   ├── themes/             # App Theme
│   ├── utils/              # Helpers, Validators
│   └── widgets/            # Shared Widgets
│
├── data/models/            # Data Models
│
├── features/               # Features (Feature-First)
│   ├── auth/              # Authentication
│   ├── admin/             # Admin Features
│   ├── home/              # Dashboard
│   ├── gap/               # GAP Forms (1.1-1.7)
│   ├── map/               # Map & Plot Drawing
│   ├── chat/              # AI Chatbot
│   ├── notification/      # Notifications
│   ├── profile/           # User Profile
│   └── plot/              # Plot Management
│
├── main.dart              # Entry Point
└── app.dart               # App Configuration
```

### User Roles
1. **USER** - เกษตรกรทั่วไป
   - ลงทะเบียน, Login
   - จัดการแปลง (Create, Edit, Delete)
   - บันทึก GAP Forms
   - ดูสถานะการอนุมัติ

2. **ADMIN** - ผู้ดูแลระดับจังหวัด/อำเภอ
   - Login ด้วย PIN (6 หลัก)
   - อนุมัติ/ปฏิเสธ User
   - ตรวจสอบและอนุมัติ GAP
   - ดูสถิติในเขต
   - ติดต่อ Super Admin

3. **SUPER_ADMIN** - ผู้ดูแลระบบ
   - Dashboard รวม
   - จัดการ Admin ทั้งหมด
   - จัดการ User ทั้งประเทศ
   - ดู Reports
   - System Settings

---

## 🔐 Critical Security Points

### 1. PIN System (Admin/Super Admin)
```dart
// ✅ ถูกต้อง
- PIN 6 หลัก (ตัวเลขเท่านั้น)
- Hashed ก่อนเก็บ (bcrypt)
- Max 3 attempts ก่อน lock
- Timeout 5 นาที หลัง lock
- เก็บใน flutter_secure_storage

// ❌ ผิด
- เก็บ PIN แบบ plain text
- ไม่มี rate limiting
- ไม่มี timeout
```

### 2. Token Management
```dart
// Access Token: 1 ชั่วโมง
// Refresh Token: 7 วัน
// ใช้ flutter_secure_storage เก็บ

// Auto-refresh ก่อน expire
if (tokenWillExpireIn(5)) {
  await refreshToken();
}
```

### 3. Sensitive Data
```dart
// ❌ ห้ามเก็บใน SharedPreferences:
- Auth tokens
- PIN
- User passwords
- ID Card numbers

// ✅ ต้องใช้ FlutterSecureStorage:
const storage = FlutterSecureStorage();
await storage.write(key: 'token', value: token);
```

### 4. Permissions
```dart
// ขอ Permission แบบ Just-in-Time
// ไม่ขอทั้งหมดตอน startup

// Camera: เมื่อจะถ่ายรูป
// Location: เมื่อจะวาดแผนที่
// Storage: เมื่อจะอัพโหลดรูป
```

---

## 📱 GAP System Overview

### GAP Categories (7 ประเภท)
1. **GAP 1.1** - GAP Records (บันทึกทั่วไป)
2. **GAP 1.2** - GAP Inputs (ปัจจัยการผลิต)
3. **GAP 1.3** - Field Management (การจัดการแปลง)
4. **GAP 1.4** - Harvests (การเก็บเกี่ยว)
5. **GAP 1.5** - Post-Harvest (หลังเก็บเกี่ยว)
6. **GAP 1.6** - Worker Training (อบรม)
7. **GAP 1.7** - Traceability (ระบบตรวจสอบ)

### Workflow
```
User Create GAP → Draft → Save → Submit → Admin Review → Approve/Reject
                   ↓
              LocalDB (SQLite)
```

### Draft System
```dart
// เก็บ Draft ใน SQLite
class GapDraft {
  String id;
  String plotId;
  String category; // "1.1", "1.2", etc.
  Map<String, dynamic> formData;
  DateTime savedAt;
  bool isSubmitted;
}

// Auto-save ทุก 30 วินาที
Timer.periodic(Duration(seconds: 30), (timer) {
  saveDraft();
});
```

---

## 🐛 Bug Prevention Strategy

### Common Bug Patterns (Flutter)
1. **RenderFlex Overflow**
   ```dart
   // ✅ ใช้ ScrollView
   SingleChildScrollView(child: Column(...))
   ```

2. **Context across async gaps**
   ```dart
   // ✅ ตรวจสอบ mounted
   await someAsyncOp();
   if (!mounted) return;
   Navigator.pop(context);
   ```

3. **Memory Leaks**
   ```dart
   // ✅ Dispose controllers
   @override
   void dispose() {
     _controller.dispose();
     _subscription.cancel();
     super.dispose();
   }
   ```

4. **State Management Issues**
   ```dart
   // ✅ ใช้ Provider/Riverpod
   // ❌ ไม่ใช้ setState ใน Widget ใหญ่
   ```

---

## ⚡ Performance Targets

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| App Launch | < 2s | 1.8s | ✅ |
| Screen Transition | < 300ms | 250ms | ✅ |
| List Scroll FPS | 60fps | 58fps | ⚠️ |
| API Response | < 1s | 800ms | ✅ |
| Image Load | < 2s | 1.5s | ✅ |
| Memory Usage | < 150MB | 120MB | ✅ |

---

## 📋 AI Agent Decision Tree

```
เริ่มงาน
  ↓
อ่านเอกสารทั้งหมด (Phase 1)
  ↓
วิเคราะห์สถานะปัจจุบัน (Phase 2)
  ↓
มี Feature ที่ยังไม่ทำ?
  ├─ ใช่ → ดูใน 01_COMPLETE_ROLE_FEATURE_MAP.md → ทำตาม Spec
  └─ ไม่ → ต่อไป
  ↓
มี API ที่ยังไม่ integrate?
  ├─ ใช่ → ดูใน 02_API_INTEGRATION_MASTER.md → Integrate
  └─ ไม่ → ต่อไป
  ↓
มี Bug?
  ├─ ใช่ → ดูใน 05_BUG_PREVENTION_SYSTEM.md → แก้
  └─ ไม่ → ต่อไป
  ↓
Performance ผ่าน Targets?
  ├─ ไม่ → ดูใน 06_PERFORMANCE_OPTIMIZATION_ADVANCED.md → Optimize
  └─ ใช่ → ต่อไป
  ↓
Security ครบ?
  ├─ ไม่ → ดูใน 03_PIN_AND_SECURITY_FLOW.md → เพิ่ม Security
  └─ ใช่ → ต่อไป
  ↓
Production Ready?
  ├─ ไม่ → ดูใน 07_PRODUCTION_DEPLOYMENT_FINAL.md → เตรียม
  └─ ใช่ → เสร็จสมบูรณ์ 🎉
```

---

## 🎯 Core Principles (ย้ำอีกครั้ง)

### 1. Zero Hardcode
```dart
// ❌ ผิด
const color = Color(0xFF123456);
const apiUrl = "https://api.example.com";

// ✅ ถูก
import 'package:taptom/core/constants/app_colors.dart';
final color = AppColors.primary;

import 'package:flutter_dotenv/flutter_dotenv.dart';
final apiUrl = dotenv.env['API_URL'];
```

### 2. Design System Consistency (80-10-10)
```dart
// 80% Primary (เขียวเข้ม)
AppColors.primary = Color(0xFF2E7D32);

// 10% Secondary (เขียวน้ำทะเล)
AppColors.secondary = Color(0xFF00796B);

// 10% Status (Success/Error/Warning)
AppColors.success = Color(0xFF388E3C);
AppColors.error = Color(0xFFD32F2F);
AppColors.warning = Color(0xFFFFA000);
```

### 3. Clean Architecture
```
Presentation Layer (UI)
     ↓
Domain Layer (Use Cases)
     ↓
Data Layer (Repository)
     ↓
Network/Local Storage
```

### 4. Testing Pyramid
```
      E2E (10%)
         ↑
   Integration (20%)
         ↑
      Unit (70%)
```

---

## 🚦 Priority System

### P0 - Critical (ทำทันที)
- Security Vulnerabilities
- App Crashes
- Data Loss
- Cannot Login/Register

### P1 - High (ทำภายใน 1 วัน)
- Major Feature Broken
- Performance < 50% Target
- API Integration Failed

### P2 - Medium (ทำภายใน 1 สัปดาห์)
- Minor UI Issues
- Missing Validation
- Inconsistent Design

### P3 - Low (ทำเมื่อมีเวลา)
- Nice-to-have Features
- UI Polish
- Documentation Improvements

---

## 📞 Communication Protocol

### When to Report
```markdown
1. ✅ เสร็จแต่ละ Feature
   - สรุปสั้นๆ
   - Screenshot (ถ้ามี)
   - Testing Results

2. ⚠️ เจอปัญหาที่แก้ไม่ได้
   - อธิบายปัญหา
   - สิ่งที่ลองแล้ว
   - ข้อมูล Error Log

3. 🎯 ครบ Milestone
   - สรุปงานที่ทำ
   - Checklist ที่ผ่าน
   - สิ่งที่เหลืออยู่

4. 🚀 พร้อม Production
   - Checklist ครบทุกข้อ
   - Performance Metrics
   - Test Results
```

---

## ✅ Final Checklist

### ก่อนเริ่มแต่ละ Session
- [ ] อ่านเอกสารที่เกี่ยวข้อง
- [ ] `flutter analyze` ผ่าน
- [ ] `flutter test` ผ่าน
- [ ] ตรวจสอบ API Swagger

### หลังเสร็จแต่ละ Feature
- [ ] Code ตาม Standards
- [ ] Tests เขียนครบ (> 80% coverage)
- [ ] ทดสอบบน Device จริง
- [ ] ไม่มี Hardcode
- [ ] Performance ตรวจสอบแล้ว
- [ ] Documentation อัพเดท

### ก่อน Commit
- [ ] `dart format .` เสร็จ
- [ ] `flutter analyze` ผ่าน
- [ ] ลบ `debugPrint` ที่ไม่ใช้
- [ ] ลบ Unused Imports
- [ ] ลบ TODO Comments

### ก่อน Production
- [ ] ทุก Checklist ใน 07_PRODUCTION_DEPLOYMENT_FINAL.md ผ่าน
- [ ] Security Audit ผ่าน
- [ ] Performance Targets ทุกตัวผ่าน
- [ ] App Store Requirements ครบ
- [ ] Legal & Privacy Policy พร้อม

---

## 🎓 AI Agent Learning Mode

### When Stuck
```markdown
1. อ่านเอกสารอีกครั้ง (เฉพาะส่วนที่เกี่ยวข้อง)
2. ตรวจสอบ Error Log อย่างละเอียด
3. ดูใน Bug Prevention System
4. ลอง Flutter DevTools
5. ถ้ายังไม่ได้ → รายงานพร้อมข้อมูลครบ
```

### When Success
```markdown
1. บันทึก Pattern ที่ใช้สำเร็จ
2. อัพเดท Documentation (ถ้าจำเป็น)
3. เพิ่ม Test Case
4. ต่อไปยัง Task ถัดไป
```

---

## 🎯 Success Metrics

### Code Quality Score
```
(Test Coverage × 0.3) +
(Zero Hardcode × 0.2) +
(Performance Targets × 0.3) +
(Security Audit × 0.2)
= Total Score (ต้อง > 90%)
```

### Feature Completeness
```
Completed Features / Total Features × 100%
= ต้อง 100% ก่อน Production
```

### Bug Density
```
Total Bugs / Total Features
= ต้อง < 0.5 (1 bug ต่อ 2 features)
```

---

## 🚀 Next Steps

**สำหรับ AI Agent:**

1. อ่านเอกสารข้างล่างนี้ตามลำดับ:
   - `01_COMPLETE_ROLE_FEATURE_MAP.md`
   - `02_API_INTEGRATION_MASTER.md`
   - `03_PIN_AND_SECURITY_FLOW.md`
   - `04_GAP_SYSTEM_COMPLETE.md`
   - `05_BUG_PREVENTION_SYSTEM.md`
   - `06_PERFORMANCE_OPTIMIZATION_ADVANCED.md`
   - `07_PRODUCTION_DEPLOYMENT_FINAL.md`

2. เริ่มทำงานตาม Workflow ข้างบน

3. รายงานความคืบหน้าเมื่อเสร็จแต่ละ Phase

**LET'S BUILD SOMETHING AMAZING! 🚀**

---

**Document Status:** ✅ Production Ready  
**Effectiveness:** ⭐⭐⭐⭐⭐ (5/5)  
**Last Review:** 2026-01-29
