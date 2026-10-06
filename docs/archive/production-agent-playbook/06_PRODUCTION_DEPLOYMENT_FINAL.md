# Production Deployment Final Checklist
## เตรียมความพร้อม Production และ App Store แบบครบวงจร

**Version:** 2.0.0  
**Last Updated:** 2026-01-29  
**Target:** App Store (iOS) & Google Play (Android)

---

## สารบัญ

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [App Store Requirements](#app-store-requirements)
3. [Google Play Requirements](#google-play-requirements)
4. [Build & Release](#build-release)
5. [Post-Deployment](#post-deployment)

---

## Pre-Deployment Checklist

### 1. Code Quality

- [ ] **Flutter Analyze**
  ```bash
  flutter analyze
  # ต้องไม่มี errors, 0 issues
  ```

- [ ] **Dart Format**
  ```bash
  dart format .
  # ทุกไฟล์ต้อง formatted
  ```

- [ ] **Tests**
  ```bash
  flutter test
  # Coverage > 80%
  # All tests pass
  ```

- [ ] **No Debug Code**
  - [ ] ลบ `print()` ทั้งหมด
  - [ ] ลบ `debugPrint()` ที่ไม่จำเป็น
  - [ ] ลบ TODO comments
  - [ ] ลบ Mock Data

- [ ] **No Hardcoded Values**
  - [ ] API URLs → .env
  - [ ] Colors → AppColors
  - [ ] Strings → Constants
  - [ ] API Keys → .env (ไม่เช็คใน Git)

---

### 2. Security

- [ ] **HTTPS Only**
  ```dart
  // ถูก
  final apiUrl = 'https://api.example.com';
  
  // ผิด
  final apiUrl = 'http://api.example.com';
  ```

- [ ] **Sensitive Data**
  - [ ] Tokens เก็บใน FlutterSecureStorage
  - [ ] ไม่มี API Keys ใน Code
  - [ ] PIN ไม่เก็บที่ไหนเลย (ส่งไป Server Hash)

- [ ] **Permissions**
  - [ ] Request เฉพาะที่จำเป็น
  - [ ] มี Description ชัดเจน (iOS Info.plist, Android Manifest)

- [ ] **SSL Pinning (Optional)**
  - [ ] Certificate Pinning สำหรับ High Security

---

### 3. Performance

- [ ] **App Launch Time**
  - Target: < 2 วินาที
  - Test: เปิดแอปบน Device จริง

- [ ] **Screen Transitions**
  - Target: < 300ms
  - ไม่มีการสะดุด

- [ ] **List Scrolling**
  - Target: 60 FPS
  - ใช้ ListView.builder
  - ใช้ const Widgets

- [ ] **Image Optimization**
  - Compress images
  - Use cached_network_image
  - Lazy loading

- [ ] **Memory Usage**
  - Target: < 150MB
  - ไม่มี Memory Leaks
  - Dispose ครบ

---

### 4. Functionality

- [ ] **All Features Work**
  - [ ] User Flow ทุกอย่างทำงาน
  - [ ] Admin Flow ทุกอย่างทำงาน
  - [ ] Super Admin Flow ทุกอย่างทำงาน

- [ ] **Error Handling**
  - [ ] Network Error → แสดงข้อความ + Retry
  - [ ] API Error → แสดงข้อความที่เหมาะสม
  - [ ] Validation Error → แสดง Field Error

- [ ] **Offline Support**
  - [ ] Cache ข้อมูลสำคัญ
  - [ ] Queue requests when offline
  - [ ] แสดงสถานะ Offline

---

### 5. UI/UX

- [ ] **Design System**
  - [ ] ใช้สีตาม 80-10-10 Rule
  - [ ] ไอคอนสม่ำเสมอ
  - [ ] Typography consistent

- [ ] **Responsive**
  - [ ] ทดสอบบนหน้าจอขนาดต่างๆ
  - [ ] ไม่มี Overflow
  - [ ] Layout สวยบนทุกขนาด

- [ ] **Loading States**
  - [ ] ทุก Async operation แสดง Loading
  - [ ] Skeleton Loaders สำหรับ Lists

- [ ] **Empty States**
  - [ ] แสดงข้อความเมื่อไม่มีข้อมูล
  - [ ] แนะนำ Action ถัดไป

---

## App Store Requirements (iOS)

### 1. App Information

```yaml
App Name: [ชื่อแอป] (max 30 characters)
Subtitle: [คำบรรยายสั้น] (max 30 characters)
Bundle ID: com.yourcompany.taptom
Version: 1.0.0
Build Number: 1
```

### 2. App Icon

- **Size:** 1024 x 1024 pixels
- **Format:** PNG (no alpha channel)
- **Requirements:**
  - ไม่มีข้อความบน icon
  - ไม่มี rounded corners (iOS จัดการให้)
  - สีสดใส, узнаваемый

### 3. Screenshots (Required)

**iPhone 6.9" Display (iPhone 16 Pro Max)**
- Size: 1290 x 2796 pixels
- Minimum: 3 screenshots
- Maximum: 10 screenshots

**Recommended Screenshots:**
1. Login/Welcome Screen
2. Dashboard
3. Main Feature (Plot/GAP)
4. Admin Panel
5. Feature Highlight

### 4. Privacy Policy & Terms

- [ ] **Privacy Policy URL**
  - Must be accessible without login
  - HTTPS required
  - ภาษาไทยและอังกฤษ

- [ ] **Terms of Service URL**
  - HTTPS required

### 5. App Description

```
[ชื่อแอป] - แอปจัดการเกษตรพืชเสพติดภายใต้กฎหมาย

คุณสมบัติ:
ลงทะเบียนและจัดการข้อมูลเกษตรกร
บันทึกข้อมูล GAP (Good Agricultural Practices)
ติดตามสถานะการอนุมัติ
ระบบ Admin สำหรับผู้ดูแล
Dashboard และรายงาน

เหมาะสำหรับ:
- เกษตรกรที่ปลูกพืชเสพติดภายใต้กฎหมาย
- เจ้าหน้าที่ผู้ดูแล
- หน่วยงานที่เกี่ยวข้อง

(Max 4000 characters)
```

### 6. Keywords

```
เกษตร,กระท่อม,GAP,เกษตรกร,พืชเสพติด,ผู้ดูแล,dashboard,ระบบจัดการ
(Max 100 characters, comma-separated)
```

### 7. Info.plist Permissions

```xml
<!-- ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>แอปต้องการเข้าถึงกล้องเพื่อถ่ายรูปโปรไฟล์และรูปแปลง</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>แอปต้องการเข้าถึงรูปภาพเพื่อเลือกรูปโปรไฟล์และรูปแปลง</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>แอปต้องการตำแหน่งของคุณเพื่อวาดขอบเขตแปลงบนแผนที่</string>
```

### 8. Build Settings

```bash
# ios/Runner.xcodeproj/project.pbxproj
# หรือใช้ Xcode
# Signing & Capabilities:
# - Team: [Your Team]
# - Bundle Identifier: com.yourcompany.taptom
# - Provisioning Profile: [App Store]
# - Code Signing Identity: [iOS Distribution]
```

---

## Google Play Requirements (Android)

### 1. App Information

```yaml
App Name: [ชื่อแอป] (max 50 characters)
Short Description: [คำอธิบายสั้น] (max 80 characters)
Full Description: [คำอธิบายยาว] (max 4000 characters)
Package Name: com.yourcompany.taptom
Version Code: 1
Version Name: 1.0.0
```

### 2. App Icon

- **Size:** 512 x 512 pixels
- **Format:** PNG (32-bit, with alpha)

### 3. Screenshots (Required)

**Phone (Required):**
- Minimum: 2 screenshots
- Maximum: 8 screenshots
- Size: 320px - 3840px (width or height)

**Tablet (Optional):**
- Size: 1024 x 768 minimum

**Recommended Screenshots:**
1. Login/Welcome
2. Dashboard
3. Main Features
4. Admin Panel

### 4. Feature Graphic

- **Size:** 1024 x 500 pixels
- **Format:** PNG or JPEG
- No transparency

### 5. Privacy Policy

- [ ] URL ต้อง accessible
- [ ] HTTPS required
- [ ] ภาษาไทยและอังกฤษ

### 6. Content Rating

- [ ] กรอก Content Rating Questionnaire
- [ ] คาดว่าจะได้ Rating: Everyone / Teen

### 7. AndroidManifest.xml Permissions

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 8. Signing Config

```gradle
// android/app/build.gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

---

## Build & Release

### iOS Build

```bash
# 1. Clean
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build iOS (Release)
flutter build ios --release

# 4. เปิด Xcode
open ios/Runner.xcworkspace

# 5. ใน Xcode:
# - เลือก Product > Archive
# - รอ Archive เสร็จ
# - เลือก Distribute App
# - เลือก App Store Connect
# - Upload

# 6. ไปที่ App Store Connect
# https://appstoreconnect.apple.com
# - เลือก App
# - เลือก Build
# - กรอกข้อมูล
# - Submit for Review
```

### Android Build

```bash
# 1. Clean
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build Android App Bundle (AAB)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab

# 4. Upload to Google Play Console
# https://play.google.com/console
# - เลือก App
# - Production > Create new release
# - Upload AAB
# - กรอกข้อมูล
# - Review > Start rollout to Production
```

### Environment Variables (.env)

```bash
# .env (Production)
API_BASE_URL=https://api.production.com/api/v1
API_TIMEOUT=30000
ENVIRONMENT=production
ENABLE_LOGGING=false
FIREBASE_PROJECT_ID=your-project-id
```

---

## Post-Deployment

### 1. Monitoring

- [ ] **Crashlytics**
  - ตรวจสอบ Crash reports
  - แก้ไข Critical crashes ทันที

- [ ] **Analytics**
  - Firebase Analytics
  - ตรวจสอบ User behavior
  - ตรวจสอบ Conversion funnel

- [ ] **Performance**
  - Firebase Performance
  - App start time
  - Screen rendering

### 2. User Feedback

- [ ] **In-App Feedback**
  - ให้ User แจ้ง Bug ได้ง่าย
  - Feedback button

- [ ] **App Store Reviews**
  - ตรวจสอบ reviews ทุกวัน
  - ตอบกลับ negative reviews
  - แก้ไข issues ที่รายงาน

- [ ] **Support Channels**
  - Email support
  - In-app chat (ถ้ามี)
  - FAQ / Help Center

### 3. Updates

- [ ] **Bug Fixes**
  - Release hotfix สำหรับ Critical bugs
  - Schedule minor updates

- [ ] **New Features**
  - Plan next version
  - Collect feature requests

---

## Launch Day Checklist

### T-24 Hours

- [ ] Final testing on production API
- [ ] Monitor server capacity
- [ ] Prepare support team
- [ ] Draft launch announcement

### T-1 Hour

- [ ] Submit to stores
- [ ] Monitor submission status
- [ ] Prepare social media posts

### Launch

- [ ] App goes live
- [ ] Post announcement
- [ ] Monitor Crashlytics
- [ ] Monitor user feedback
- [ ] Respond to issues immediately

### T+24 Hours

- [ ] Review crash reports
- [ ] Review user feedback
- [ ] Check analytics
- [ ] Plan hotfix (if needed)

---

## Final Quality Gate

### Before Submission:

- [ ] All Tests Pass (Unit, Widget, Integration)
- [ ] Code Coverage > 80%
- [ ] `flutter analyze` ผ่าน (0 issues)
- [ ] Performance Targets ทุกตัวผ่าน
- [ ] Security Audit ผ่าน
- [ ] Manual Testing ครบทุก User Flow
- [ ] Beta Testing Feedback แก้ไขหมดแล้ว
- [ ] Screenshots และ Metadata พร้อม
- [ ] Privacy Policy และ Terms พร้อม
- [ ] Support channels พร้อม
- [ ] Rollback plan พร้อม
- [ ] Team briefed and ready

---

## Rollback Plan

### When to Rollback:

- Critical bug affects > 50% users
- Security vulnerability discovered
- Data loss or corruption
- App crashes on launch

### How to Rollback:

**iOS:**
1. ไปที่ App Store Connect
2. เลือก previous version
3. Submit for review (expedited)

**Android:**
1. ไปที่ Google Play Console
2. Create new release with previous APK/AAB
3. Rollout 100%

**Communication:**
1. แจ้ง users ผ่าน notification
2. Post บน social media
3. Update support team

---

## Emergency Contacts

```
Technical Lead: [Name] - [Phone]
Project Manager: [Name] - [Phone]
DevOps: [Name] - [Phone]
Support Lead: [Name] - [Phone]

Emergency Hotline: [24/7 Phone]
```

---

## Success Metrics (Post-Launch)

### Week 1:
- Downloads: > 100
- Crash-free rate: > 99%
- App Store Rating: > 4.0
- DAU (Daily Active Users): > 50

### Month 1:
- Downloads: > 1,000
- Crash-free rate: > 99.5%
- App Store Rating: > 4.5
- MAU (Monthly Active Users): > 500
- Retention (D7): > 40%

### Month 3:
- Downloads: > 5,000
- Crash-free rate: > 99.9%
- App Store Rating: > 4.5
- MAU: > 2,000
- Retention (D30): > 30%

---

**Document Status:** Production Ready  
**Approved By:** [Tech Lead Name]  
**Deployment Date:** [TBD]  
**Last Review:** 2026-01-29

---

**READY FOR PRODUCTION! **
