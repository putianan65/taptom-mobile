# Complete Role & Feature Map
## แผนที่ Feature ทุก Role พร้อมสถานะและ Checklist

**Version:** 2.0.0  
**Last Updated:** 2026-01-29  
**Purpose:** แผนที่ครบวงจรสำหรับทุก Feature ของทุก Role

---

## Overview

เอกสารนี้เป็น **Single Source of Truth** สำหรับทุก Feature ในระบบ  
แยกตาม Role และมี Checklist ละเอียดเพื่อตรวจสอบความสมบูรณ์

---

## USER ROLE - Complete Feature Map

### 1. Authentication & Onboarding

#### 1.1 Registration (ลงทะเบียน)
**Status:** Complete / In Progress / Not Started

**Screens:**
- `SignUpScreen` → `lib/features/auth/screens/sign_up_screen.dart`

**Features Checklist:**
- [ ] **Form Validation**
  - [ ] ชื่อ (ไม่เว้นว่าง, ไทย/อังกฤษ)
  - [ ] นามสกุล (ไม่เว้นว่าง, ไทย/อังกฤษ)
  - [ ] เบอร์โทร (10 หลัก, 08xxxxxxxx)
  - [ ] ID Card (13 หลัก, validate checksum)
  - [ ] วันเกิด (อายุ > 18 ปี)
  - [ ] ที่อยู่ (ไม่เว้นว่าง)
  - [ ] รหัสไปรษณีย์ (5 หลัก)
  
- [ ] **Location Selection (Cascading)**
  - [ ] จังหวัด → โหลดจาก API `/locations/provinces`
  - [ ] อำเภอ → โหลดตามจังหวัด `/locations/districts?provinceCode=`
  - [ ] ตำบล → โหลดตามอำเภอ `/locations/subdistricts?districtCode=`
  - [ ] เก็บ Cache ใน Local (30 วัน)
  - [ ] Dropdown สวยงาม, Search ได้
  
- [ ] **Occupation Selection**
  - [ ] โหลดจาก API `/occupations`
  - [ ] แสดงเป็น List/Dropdown
  - [ ] เก็บ Cache ใน Local (30 วัน)
  
- [ ] **Profile Image Upload**
  - [ ] ขอ Permission (Camera/Gallery)
  - [ ] เลือกจาก Gallery หรือถ่ายใหม่
  - [ ] Crop & Resize (max 1024x1024)
  - [ ] Compress (< 500KB)
  - [ ] Preview ก่อน Upload
  - [ ] Upload ไป `/upload` endpoint
  - [ ] แสดง Progress
  
- [ ] **Terms & Conditions**
  - [ ] แสดง PDPA Dialog
  - [ ] Checkbox ยอมรับ (required)
  - [ ] เก็บ Log consent
  
- [ ] **API Integration**
  - [ ] POST `/api/v1/auth/signup`
  - [ ] Request Body ครบถ้วน
  - [ ] Handle 201 Success
  - [ ] Handle 409 Conflict (เบอร์ซ้ำ)
  - [ ] Handle 400 Validation Error
  - [ ] Handle Network Error
  
- [ ] **Loading States**
  - [ ] Show CircularProgressIndicator ขณะ Submit
  - [ ] Disable ปุ่มขณะกำลังส่ง
  - [ ] Overlay Loading (ไม่ให้กดซ้ำ)
  
- [ ] **Success Flow**
  - [ ] แสดง Success Dialog
  - [ ] เก็บ Token ใน Secure Storage
  - [ ] Navigate → Pending Approval Screen
  
- [ ] **Error Handling**
  - [ ] แสดง Error Dialog/SnackBar
  - [ ] เบอร์ซ้ำ → แนะนำให้ Login
  - [ ] Network Error → Retry option
  - [ ] Validation Error → Highlight field

**API Endpoint:**
```
POST /api/v1/auth/signup
Body: {
  phone, birthday, firstName, lastName, idCard,
  province, district, subDistrict, address, postalCode,
  occupation, profileImage
}
Response: { accessToken, refreshToken, user }
```

---

#### 1.2 Login (เข้าสู่ระบบ)
**Status:** Complete / In Progress / Not Started

**Screens:**
- `LoginScreen` → `lib/features/auth/screens/login_screen.dart`

**Features Checklist:**
- [ ] **Form Fields**
  - [ ] เบอร์โทร (10 หลัก)
  - [ ] วันเกิด (DatePicker)
  
- [ ] **Validation**
  - [ ] เบอร์โทรถูกรูปแบบ
  - [ ] วันเกิดไม่เว้นว่าง
  
- [ ] **API Integration**
  - [ ] POST `/api/v1/auth/signin`
  - [ ] Handle 200 Success → Navigate to Dashboard
  - [ ] Handle 401 Unauthorized → แสดง Error
  - [ ] Handle Network Error
  
- [ ] **Loading State**
  - [ ] Show Loading ขณะเรียก API
  
- [ ] **Success Flow**
  - [ ] เก็บ Token ใน Secure Storage
  - [ ] Navigate → Dashboard
  
- [ ] **Error Handling**
  - [ ] Invalid credentials → Clear form
  - [ ] Account pending → Show message
  - [ ] Account rejected → แนะนำติดต่อ Admin

**API Endpoint:**
```
POST /api/v1/auth/signin
Body: { phone, birthday }
Response (USER): { accessToken, refreshToken, user }
Response (ADMIN): { requiresPin: true, tempToken }
```

---

#### 1.3 Pending Approval Screen
**Status:** Complete / In Progress / Not Started

**Screens:**
- `PendingApprovalScreen` → `lib/features/auth/screens/pending_approval_screen.dart`

**Features Checklist:**
- [ ] **Display**
  - [ ] Icon/Image สื่อว่ารออนุมัติ
  - [ ] ข้อความชัดเจน "รอการอนุมัติจากผู้ดูแล"
  - [ ] แสดงข้อมูลที่ลงทะเบียน (Read-only)
  
- [ ] **Actions**
  - [ ] ปุ่ม "ออกจากระบบ"
  - [ ] ปุ่ม "ตรวจสอบสถานะ" (Refresh)
  
- [ ] **Auto Refresh**
  - [ ] ตรวจสอบสถานะทุก 30 วินาที
  - [ ] ถ้าได้รับการอนุมัติ → Navigate to Dashboard
  - [ ] ถ้าถูกปฏิเสธ → แสดง Reason + แนะนำติดต่อ Admin

---

### 2. Dashboard (หน้าหลัก)

#### 2.1 User Dashboard
**Status:** Complete / In Progress / Not Started

**Screens:**
- `DashboardScreen` → `lib/features/home/screens/dashboard_screen.dart`

**Features Checklist:**
- [ ] **Welcome Banner**
  - [ ] แสดงชื่อผู้ใช้
  - [ ] แสดงรูปโปรไฟล์
  - [ ] วันที่/เวลาปัจจุบัน
  
- [ ] **Quick Stats Cards**
  - [ ] จำนวนแปลงทั้งหมด
  - [ ] แปลงที่รออนุมัติ
  - [ ] GAP ที่บันทึกแล้ว
  - [ ] การแจ้งเตือนใหม่
  
- [ ] **Plot List/Grid**
  - [ ] แสดงรายการแปลงทั้งหมด
  - [ ] แสดงสถานะแต่ละแปลง (Approved/Pending/Rejected)
  - [ ] Thumbnail รูปแปลง
  - [ ] กดเพื่อดูรายละเอียด
  
- [ ] **Quick Actions**
  - [ ] ปุ่มสร้างแปลงใหม่
  - [ ] ปุ่มบันทึก GAP
  - [ ] ปุ่มดู Notifications
  - [ ] ปุ่มไป Profile
  
- [ ] **Pull to Refresh**
  - [ ] รองรับ Pull-to-Refresh
  - [ ] โหลดข้อมูลใหม่
  
- [ ] **Performance**
  - [ ] Load เร็ว (< 2 วินาที)
  - [ ] Smooth scrolling (60fps)
  - [ ] Image lazy loading

**API Endpoints:**
```
GET /api/v1/users/me → User Profile
GET /api/v1/plots → List of Plots
GET /api/v1/notifications?unreadOnly=true → Unread count
```

---

### 3. Plot Management (จัดการแปลง)

#### 3.1 Create Plot (สร้างแปลงใหม่)
**Status:** Complete / In Progress / Not Started

**Screens:**
- `MapDrawingScreen` → `lib/features/map/screens/map_drawing_screen.dart`
- `SavePlotDialog` → `lib/features/map/widgets/save_plot_dialog.dart`

**Features Checklist:**
- [ ] **Map Integration**
  - [ ] ใช้ Google Maps / Mapbox
  - [ ] Request Location Permission
  - [ ] แสดงตำแหน่งปัจจุบัน
  - [ ] Zoom in/out
  - [ ] Move map
  
- [ ] **Drawing Tools**
  - [ ] Polygon Drawing Mode
  - [ ] วาดเส้นขอบแปลง (touch points)
  - [ ] ปิดรูป Polygon อัตโนมัติ
  - [ ] แสดง Area ที่วัดได้ (ตร.ม./ไร่)
  - [ ] ปุ่ม Undo (ลบจุดล่าสุด)
  - [ ] ปุ่ม Clear All
  
- [ ] **Marker Placement**
  - [ ] วาง Marker บนแปลง
  - [ ] แสดง Info เมื่อกด Marker
  
- [ ] **Plot Information Form**
  - [ ] ชื่อแปลง (required)
  - [ ] ประเภทพืช (Dropdown)
  - [ ] จำนวนต้น (ถ้ามี)
  - [ ] รูปภาพแปลง (อัพโหลดได้หลายรูป)
  - [ ] หมายเหตุ (optional)
  
- [ ] **GeoJSON Export**
  - [ ] แปลง Polygon → GeoJSON
  - [ ] บันทึก Coordinates
  - [ ] คำนวณพื้นที่
  
- [ ] **API Integration**
  - [ ] POST `/api/v1/plots`
  - [ ] Request Body มี geometry (GeoJSON)
  - [ ] Handle Success
  - [ ] Handle Error
  
- [ ] **Validation**
  - [ ] Polygon ต้องมีอย่างน้อย 3 จุด
  - [ ] Area > 0
  - [ ] ชื่อแปลงไม่เว้นว่าง
  
- [ ] **Performance**
  - [ ] Map render smooth
  - [ ] Drawing responsive
  - [ ] ไม่ lag เมื่อวาดจุดเยอะ

**API Endpoint:**
```
POST /api/v1/plots
Body: {
  name, plantType, plantCount, description,
  geometry: { type: "Polygon", coordinates: [[...]] },
  images: ["url1", "url2"]
}
```

---

#### 3.2 View Plot Detail
**Status:** Complete / In Progress / Not Started

**Screens:**
- `PlotDetailScreen` → `lib/features/plot/screens/plot_detail_screen.dart`

**Features Checklist:**
- [ ] **Plot Information Display**
  - [ ] ชื่อแปลง
  - [ ] สถานะ (Approved/Pending/Rejected)
  - [ ] ประเภทพืช
  - [ ] พื้นที่ (ตร.ม./ไร่)
  - [ ] วันที่สร้าง
  - [ ] ผู้สร้าง
  
- [ ] **Map View**
  - [ ] แสดงขอบเขตแปลงบนแผนที่
  - [ ] Markers (ถ้ามี)
  - [ ] Zoom to fit bounds
  
- [ ] **Image Gallery**
  - [ ] แสดงรูปภาพทั้งหมด
  - [ ] Swipe ดูรูป
  - [ ] Fullscreen view
  
- [ ] **GAP History**
  - [ ] รายการ GAP ที่บันทึกไว้
  - [ ] แสดงสถานะแต่ละรายการ
  - [ ] กดดูรายละเอียด
  
- [ ] **Actions**
  - [ ] ปุ่มแก้ไขแปลง (ถ้าเป็นเจ้าของ)
  - [ ] ปุ่มลบแปลง (ถ้าเป็นเจ้าของ + Confirm Dialog)
  - [ ] ปุ่มบันทึก GAP ใหม่
  
- [ ] **Performance**
  - [ ] Image lazy loading
  - [ ] Map render เร็ว

**API Endpoint:**
```
GET /api/v1/plots/:id
Response: { plot details, geometry, images, gap_records }
```

---

#### 3.3 Edit Plot
**Status:** Complete / In Progress / Not Started

**Features Checklist:**
- [ ] เหมือน Create Plot แต่:
  - [ ] Pre-fill ข้อมูลเดิม
  - [ ] แสดง Polygon เดิมบนแผนที่
  - [ ] สามารถแก้ไข Polygon ได้
  - [ ] สามารถเพิ่ม/ลบรูปภาพ
  
- [ ] **API Integration**
  - [ ] PATCH `/api/v1/plots/:id`
  - [ ] ส่งเฉพาะฟิลด์ที่เปลี่ยน

---

#### 3.4 Delete Plot
**Status:** Complete / In Progress / Not Started

**Features Checklist:**
- [ ] **Confirmation Dialog**
  - [ ] แสดงคำเตือน
  - [ ] ยืนยันอีกครั้ง
  
- [ ] **API Integration**
  - [ ] DELETE `/api/v1/plots/:id`
  - [ ] Soft Delete (ไม่ลบจริง)
  
- [ ] **Success Flow**
  - [ ] แสดง Success message
  - [ ] Navigate กลับ
  - [ ] Refresh list

---

### 4. GAP System (Good Agricultural Practices)

#### 4.1 GAP Main Screen
**Status:** Complete / In Progress / Not Started

**Screens:**
- `GapMainScreen` → `lib/features/gap/screens/gap_main_screen.dart`

**Features Checklist:**
- [ ] **Category Cards (7 ประเภท)**
  - [ ] 1.1 GAP Records
  - [ ] 1.2 GAP Inputs
  - [ ] 1.3 Field Management
  - [ ] 1.4 Harvests
  - [ ] 1.5 Post-Harvest
  - [ ] 1.6 Worker Training
  - [ ] 1.7 Traceability
  
- [ ] **Each Card Shows:**
  - [ ] ชื่อหมวด
  - [ ] ไอคอน
  - [ ] จำนวนที่บันทึกแล้ว
  - [ ] สถานะ (Draft/Submitted/Approved)
  
- [ ] **Actions**
  - [ ] กดเพื่อเข้าฟอร์มหมวดนั้นๆ
  - [ ] ดู History การบันทึก
  
- [ ] **Plot Selector**
  - [ ] เลือกแปลงที่จะบันทึก GAP
  - [ ] แสดงรายชื่อแปลงที่ Approved

---

#### 4.2 GAP 1.1 - Records Form
**Status:** Complete / In Progress / Not Started

**Screens:**
- `GapRecordsFormScreen` → `lib/features/gap/screens/gap_records_form_screen.dart`

**Features Checklist:**
- [ ] **Form Fields (ตาม Spec)**
  - [ ] วันที่บันทึก
  - [ ] กิจกรรม (Dropdown)
  - [ ] รายละเอียด
  - [ ] ผลลัพธ์
  - [ ] รูปภาพประกอบ (optional)
  
- [ ] **Draft System**
  - [ ] Auto-save ทุก 30 วินาที → SQLite
  - [ ] Resume จาก Draft
  - [ ] แสดง "Last saved" timestamp
  
- [ ] **Validation**
  - [ ] Required fields ไม่เว้นว่าง
  - [ ] วันที่ไม่เกินวันปัจจุบัน
  
- [ ] **Actions**
  - [ ] บันทึก Draft
  - [ ] Submit (ส่งให้ Admin ตรวจ)
  
- [ ] **API Integration**
  - [ ] POST `/api/v1/gap-records`
  - [ ] Handle Success/Error

**API Endpoint:**
```
POST /api/v1/gap-records
Body: {
  plotId, recordDate, activity, details, result, images
}
```

---

#### 4.3 GAP 1.2 - Inputs Form
**Status:** Complete / In Progress / Not Started

**Features Checklist:**
- [ ] **Form Fields**
  - [ ] ประเภทปัจจัย (SEED/FERTILIZER/PESTICIDE/MATERIAL)
  - [ ] ชื่อปัจจัย
  - [ ] ปริมาณ
  - [ ] หน่วย
  - [ ] ผู้จัดจำหน่าย
  - [ ] วันที่ซื้อ
  - [ ] ใบรับรอง (ถ้ามี) - อัพโหลด PDF/Image
  
- [ ] **Draft System** (เหมือน 4.2)
- [ ] **Validation**
- [ ] **API Integration**

**API Endpoint:**
```
POST /api/v1/gap-inputs
Body: {
  plotId, inputType, name, quantity, unit,
  supplier, purchaseDate, certificate
}
```

---

#### 4.4 GAP 1.3 - Field Management
**Status:** Complete / In Progress / Not Started

**Features Checklist:**
- [ ] **Form Fields**
  - [ ] ประเภทกิจกรรม (SOIL_PREPARATION/WATERING/WEEDING/IPM/RISK_EVENT)
  - [ ] วันที่ทำกิจกรรม
  - [ ] รายละเอียด
  - [ ] ผู้ปฏิบัติงาน
  - [ ] รูปภาพประกอบ
  
- [ ] **API Integration**

**API Endpoint:**
```
POST /api/v1/field-management
Body: {
  plotId, activityType, activityDate, details, worker, images
}
```

---

#### 4.5 GAP 1.4 - Harvests
**Status:** Complete / In Progress / Not Started

**Features Checklist:**
- [ ] **Form Fields**
  - [ ] วันที่เก็บเกี่ยว
  - [ ] ปริมาณ (kg)
  - [ ] คุณภาพ (เกรด A/B/C)
  - [ ] สภาพอากาศขณะเก็บ
  - [ ] ผู้เก็บเกี่ยว
  - [ ] รูปภาพผลผลิต
  
- [ ] **API Integration**

**API Endpoint:**
```
POST /api/v1/harvests
Body: {
  plotId, harvestDate, quantity, quality, weather, harvester, images
}
```

---

#### 4.6 GAP 1.5 - Post-Harvest
**Status:** Complete / In Progress / Not Started

**Features Checklist:**
- [ ] **Form Fields**
  - [ ] harvestId (เลือกจากรายการที่เก็บเกี่ยวแล้ว)
  - [ ] ขั้นตอนหลังเก็บเกี่ยว (ตากแห้ง/บรรจุ/etc.)
  - [ ] วันที่ดำเนินการ
  - [ ] สถานที่เก็บ
  - [ ] อุณหภูมิ/ความชื้น (ถ้ามี)
  - [ ] รูปภาพ
  
- [ ] **API Integration**

**API Endpoint:**
```
POST /api/v1/post-harvest
Body: {
  harvestId, process, processDate, storage, temperature, humidity, images
}
```

---

#### 4.7 GAP 1.6 - Worker Training
**Status:** Complete / In Progress / Not Started

**Features Checklist:**
- [ ] **Form Fields**
  - [ ] หัวข้ออบรม
  - [ ] วันที่อบรม
  - [ ] วิทยากร
  - [ ] จำนวนผู้เข้าอบรม
  - [ ] สถานที่
  - [ ] รายชื่อผู้เข้าอบรม (List)
  - [ ] รูปกิจกรรม
  
- [ ] **API Integration**

**API Endpoint:**
```
POST /api/v1/worker-training
Body: {
  plotId, topic, trainingDate, trainer, attendees, location, images
}
```

---

#### 4.8 GAP 1.7 - Traceability
**Status:** Complete / In Progress / Not Started

**Features Checklist:**
- [ ] **Form Fields**
  - [ ] harvestId
  - [ ] Lot Number (auto-generate)
  - [ ] จุดหมายปลายทาง
  - [ ] ประเภทปลายทาง (ส่งออก/ขายในประเทศ)
  - [ ] วันที่จัดส่ง
  
- [ ] **QR Code**
  - [ ] Generate QR Code
  - [ ] แสดง QR
  - [ ] Download QR
  
- [ ] **API Integration**

**API Endpoint:**
```
POST /api/v1/traceability
Body: {
  harvestId, destinationType, destination, quantity, unit, shippingDate
}
Response: { lotNumber, qrCodeUrl, publicUrl }
```

---

### 5. Notifications

#### 5.1 Notification List
**Status:** Complete / In Progress / Not Started

**Screens:**
- `NotificationScreen` → `lib/features/notification/screens/notification_screen.dart`

**Features Checklist:**
- [ ] **List Display**
  - [ ] แสดงรายการแจ้งเตือน
  - [ ] แยก Read/Unread
  - [ ] Icon ตามประเภท
  - [ ] วันที่/เวลา
  
- [ ] **Types**
  - [ ] PLOT_APPROVED
  - [ ] PLOT_REJECTED
  - [ ] GAP_APPROVED
  - [ ] GAP_REJECTED
  - [ ] SYSTEM_ANNOUNCEMENT
  
- [ ] **Actions**
  - [ ] Mark as Read
  - [ ] Delete
  - [ ] กดดูรายละเอียด
  
- [ ] **API Integration**
  - [ ] GET `/api/v1/notifications`
  - [ ] PATCH `/api/v1/notifications/:id/read`

---

### 6. Profile Management

#### 6.1 View Profile
**Status:** Complete / In Progress / Not Started

**Screens:**
- `ProfileScreen` → `lib/features/profile/screens/profile_screen.dart`

**Features Checklist:**
- [ ] **Display Information**
  - [ ] รูปโปรไฟล์
  - [ ] ชื่อ-นามสกุล
  - [ ] เบอร์โทร
  - [ ] ที่อยู่
  - [ ] จังหวัด/อำเภอ/ตำบล
  - [ ] อาชีพ
  
- [ ] **Actions**
  - [ ] ปุ่มแก้ไขโปรไฟล์
  - [ ] ปุ่มออกจากระบบ

---

#### 6.2 Edit Profile
**Status:** Complete / In Progress / Not Started

**Screens:**
- `EditProfileScreen` → `lib/features/profile/screens/edit_profile_screen.dart`

**Features Checklist:**
- [ ] **Editable Fields**
  - [ ] ชื่อ
  - [ ] นามสกุล
  - [ ] ที่อยู่
  - [ ] รูปโปรไฟล์
  
- [ ] **Non-Editable**
  - [ ] เบอร์โทร
  - [ ] ID Card
  - [ ] วันเกิด
  
- [ ] **API Integration**
  - [ ] PATCH `/api/v1/users/me`

---

### 7. AI Chatbot

#### 7.1 Chat Interface
**Status:** Complete / In Progress / Not Started

**Screens:**
- `ChatScreen` → `lib/features/chat/screens/chat_screen.dart`

**Features Checklist:**
- [ ] **Chat UI**
  - [ ] Message bubbles (User/Bot)
  - [ ] Timestamp
  - [ ] Avatar
  - [ ] Typing indicator
  
- [ ] **Input**
  - [ ] Text input
  - [ ] Send button
  - [ ] Voice input (optional)
  
- [ ] **Features**
  - [ ] แนะนำการปลูกพืช
  - [ ] ตอบคำถามเกี่ยวกับ GAP
  - [ ] แนะนำการใช้แอป
  
- [ ] **API Integration**
  - [ ] POST `/api/v1/chat/message`

---

## ADMIN ROLE - Complete Feature Map

### 1. Authentication

#### 1.1 Admin Login with PIN
**Status:** Complete / In Progress / Not Started

**Screens:**
- `AdminLoginScreen` → `lib/features/auth/screens/login_screen.dart` (same as User but with PIN)
- `PinInputScreen` → `lib/features/auth/widgets/pin_input_field.dart`

**Features Checklist:**
- [ ] **Step 1: Phone + Birthday**
  - [ ] เหมือน User Login
  - [ ] POST `/api/v1/auth/signin`
  - [ ] ถ้าเป็น Admin → ได้ `requiresPin: true` + `tempToken`
  
- [ ] **Step 2: PIN Input**
  - [ ] แสดง PIN Input (6 หลัก)
  - [ ] Masked input (••••••)
  - [ ] POST `/api/v1/auth/verify-pin` with tempToken + PIN
  - [ ] Handle Success → Navigate to Admin Dashboard
  - [ ] Handle Fail → แสดง Error + เหลือกี่ครั้ง (Max 3 attempts)
  - [ ] Handle Max Attempts → Lock 5 นาที
  
- [ ] **First Time Login (No PIN)**
  - [ ] ถ้ายัง ไม่มี PIN → Navigate to Set PIN Screen
  - [ ] POST `/api/v1/auth/set-pin`
  
- [ ] **Security**
  - [ ] Rate limiting (max 3 attempts)
  - [ ] Timeout (5 นาที)
  - [ ] PIN Hashed (bcrypt)

**API Endpoints:**
```
POST /api/v1/auth/signin
Response (Admin): { requiresPin: true, tempToken }

POST /api/v1/auth/verify-pin
Body: { tempToken, pin }
Response: { accessToken, refreshToken, user }

POST /api/v1/auth/set-pin (First time or reset)
Body: { pin, confirmPin }
```

---

#### 1.2 Set/Change PIN
**Status:** Complete / In Progress / Not Started

**Screens:**
- `SetPinScreen` → `lib/features/auth/screens/set_pin_screen.dart`
- `ChangePinScreen` → `lib/features/profile/screens/change_pin_screen.dart`

**Features Checklist:**
- [ ] **Set PIN (First Time)**
  - [ ] Input PIN (6 หลัก)
  - [ ] Confirm PIN
  - [ ] Match validation
  - [ ] POST `/api/v1/auth/set-pin`
  
- [ ] **Change PIN**
  - [ ] Input Current PIN
  - [ ] Input New PIN
  - [ ] Confirm New PIN
  - [ ] PATCH `/api/v1/auth/change-pin`
  
- [ ] **Validation**
  - [ ] PIN ต้องเป็นตัวเลข 6 หลัก
  - [ ] PIN ใหม่ต้องไม่ซ้ำเก่า
  - [ ] Confirm ต้อง Match

---

### 2. Admin Dashboard

#### 2.1 Dashboard Overview
**Status:** Complete / In Progress / Not Started

**Screens:**
- `AdminDashboardScreen` → `lib/features/admin/screens/admin_dashboard_screen.dart`

**Features Checklist:**
- [ ] **Stats Cards**
  - [ ] จำนวน User ทั้งหมดในเขต
  - [ ] User รออนุมัติ
  - [ ] แปลงที่รออนุมัติ
  - [ ] GAP รอตรวจสอบ
  
- [ ] **Quick Actions**
  - [ ] ดูรายการ User รออนุมัติ
  - [ ] ดูรายการแปลงรออนุมัติ
  - [ ] ดูรายการ GAP รอตรวจสอบ
  - [ ] ติดต่อ Super Admin
  
- [ ] **Charts (Optional)**
  - [ ] User Growth Chart
  - [ ] Plot Distribution by District
  
- [ ] **API Integration**
  - [ ] GET `/api/v1/admin/statistics`

**API Endpoint:**
```
GET /api/v1/admin/statistics
Response: {
  totalUsers, pendingUsers, approvedUsers, rejectedUsers,
  totalPlots, pendingPlots,
  totalGapRecords, pendingGapRecords
}
```

---

### 3. User Management

#### 3.1 User List (In Admin's Region)
**Status:** Complete / In Progress / Not Started

**Screens:**
- `UserManagementScreen` → `lib/features/admin/screens/user_management_screen.dart`

**Features Checklist:**
- [ ] **Filters**
  - [ ] ทั้งหมด
  - [ ] รออนุมัติ (PENDING)
  - [ ] อนุมัติแล้ว (APPROVED)
  - [ ] ปฏิเสธ (REJECTED)
  
- [ ] **Search**
  - [ ] ค้นหาด้วยชื่อ/เบอร์โทร
  
- [ ] **List Display**
  - [ ] รูปโปรไฟล์
  - [ ] ชื่อ-นามสกุล
  - [ ] เบอร์โทร
  - [ ] จังหวัด/อำเภอ/ตำบล
  - [ ] สถานะ (Badge สี)
  - [ ] วันที่ลงทะเบียน
  
- [ ] **Actions (Long Press / Swipe)**
  - [ ] ดูรายละเอียด
  - [ ] อนุมัติ
  - [ ] ปฏิเสธ
  - [ ] ส่งข้อความ (Notification)
  
- [ ] **API Integration**
  - [ ] GET `/api/v1/admin/users` (filtered by admin's region)

**API Endpoint:**
```
GET /api/v1/admin/users?status=PENDING&page=1&limit=20
Response: {
  data: [{ id, firstName, lastName, phone, province, district, subDistrict, status, createdAt }],
  meta: { total, page, totalPages }
}
```

---

#### 3.2 Approve/Reject User
**Status:** Complete / In Progress / Not Started

**Features Checklist:**
- [ ] **Approve Flow**
  - [ ] Confirmation Dialog
  - [ ] POST `/api/v1/admin/users/:id/approve`
  - [ ] Success → Update List
  - [ ] Send Notification to User
  
- [ ] **Reject Flow**
  - [ ] Reason Input (required)
  - [ ] Confirmation Dialog
  - [ ] POST `/api/v1/admin/users/:id/reject`
  - [ ] Success → Update List
  - [ ] Send Notification + Reason to User

**API Endpoints:**
```
POST /api/v1/admin/users/:id/approve
Response: { message: "User approved" }

POST /api/v1/admin/users/:id/reject
Body: { reason: "..." }
Response: { message: "User rejected" }
```

---

### 4. Plot Management (Admin View)

#### 4.1 Plot List (In Admin's Region)
**Status:** Complete / In Progress / Not Started

**Screens:**
- `AdminPlotListScreen` → `lib/features/admin/screens/admin_plot_list_screen.dart`

**Features Checklist:**
- [ ] **Filters**
  - [ ] รออนุมัติ
  - [ ] อนุมัติแล้ว
  - [ ] ปฏิเสธ
  
- [ ] **List Display**
  - [ ] ชื่อแปลง
  - [ ] เจ้าของ (ชื่อผู้ใช้)
  - [ ] ประเภทพืช
  - [ ] พื้นที่
  - [ ] สถานะ
  - [ ] รูปแปลง (Thumbnail)
  
- [ ] **Actions**
  - [ ] ดูรายละเอียด (แผนที่, ขอบเขต)
  - [ ] อนุมัติ/ปฏิเสธ
  
- [ ] **API Integration**
  - [ ] GET `/api/v1/admin/plots?status=PENDING`

---

#### 4.2 Approve/Reject Plot
**Features Checklist:**
- [ ] เหมือน User Approval
- [ ] POST `/api/v1/admin/plots/:id/approve`
- [ ] POST `/api/v1/admin/plots/:id/reject`

---

### 5. GAP Review

#### 5.1 GAP Records List (Pending Review)
**Status:** Complete / In Progress / Not Started

**Screens:**
- `GapReviewScreen` → `lib/features/admin/screens/gap_review_screen.dart`

**Features Checklist:**
- [ ] **Tabs by Category**
  - [ ] GAP 1.1 - Records
  - [ ] GAP 1.2 - Inputs
  - [ ] GAP 1.3 - Field Management
  - [ ] GAP 1.4 - Harvests
  - [ ] GAP 1.5 - Post-Harvest
  - [ ] GAP 1.6 - Worker Training
  - [ ] GAP 1.7 - Traceability
  
- [ ] **List per Tab**
  - [ ] แสดง GAP ที่ Submit แล้ว
  - [ ] ชื่อผู้ส่ง
  - [ ] แปลง
  - [ ] วันที่ส่ง
  
- [ ] **Actions**
  - [ ] ดูรายละเอียดฟอร์ม
  - [ ] อนุมัติ/ปฏิเสธพร้อมเหตุผล
  
- [ ] **API Integration**
  - [ ] GET `/api/v1/admin/gap/:category` (e.g., `/api/v1/admin/gap/records`)

**API Endpoints:**
```
GET /api/v1/admin/gap/records?status=PENDING
GET /api/v1/admin/gap/inputs?status=PENDING
... (แต่ละ category)
```

---

#### 5.2 Approve/Reject GAP
**Features Checklist:**
- [ ] **Approve**
  - [ ] Review Form Data
  - [ ] Confirm
  - [ ] POST `/api/v1/admin/gap/:category/:id/approve`
  
- [ ] **Reject**
  - [ ] Input Reason
  - [ ] Confirm
  - [ ] POST `/api/v1/admin/gap/:category/:id/reject`

---

### 6. Contact Super Admin

#### 6.1 Support Ticket System
**Status:** Complete / In Progress / Not Started

**Screens:**
- `ContactSuperAdminScreen` → `lib/features/admin/screens/contact_superadmin_screen.dart`

**Features Checklist:**
- [ ] **Create Ticket**
  - [ ] หัวข้อ
  - [ ] รายละเอียดปัญหา
  - [ ] ประเภท (Technical/User Issue/System Request)
  - [ ] แนบไฟล์ (optional)
  
- [ ] **Ticket List**
  - [ ] แสดง Ticket ที่ส่งไปแล้ว
  - [ ] สถานะ (Open/In Progress/Resolved/Closed)
  - [ ] วันที่ส่ง
  - [ ] ดูรายละเอียด + คำตอบจาก Super Admin
  
- [ ] **API Integration**
  - [ ] POST `/api/v1/admin/contact-superadmin`
  - [ ] GET `/api/v1/admin/my-tickets`

---

### 7. Admin Profile

**Features:**
- [ ] ดูโปรไฟล์ตัวเอง
- [ ] แก้ไขข้อมูล (ชื่อ, ที่อยู่)
- [ ] เปลี่ยน PIN (ตาม 1.2)
- [ ] ออกจากระบบ

---

## SUPER ADMIN ROLE - Complete Feature Map

### 1. Master Dashboard

#### 1.1 Overview Dashboard
**Status:** Complete / In Progress / Not Started

**Screens:**
- `SuperAdminDashboardScreen` → `lib/features/admin/screens/super_admin_dashboard.dart` (หรือแยกไฟล์)

**Features Checklist:**
- [ ] **National Statistics**
  - [ ] จำนวน User ทั้งประเทศ
  - [ ] จำนวน Admin ทั้งประเทศ
  - [ ] จำนวนแปลงทั้งหมด
  - [ ] จำนวน GAP ที่บันทึกแล้ว
  
- [ ] **Charts & Graphs**
  - [ ] User Distribution by Province (Bar Chart)
  - [ ] Plot Distribution by Plant Type (Pie Chart)
  - [ ] GAP Compliance Rate (Line Chart)
  - [ ] Monthly Growth Trend
  
- [ ] **Top Lists**
  - [ ] Top 10 Provinces โดย User
  - [ ] Top 10 Active Users
  - [ ] Recent Activities
  
- [ ] **API Integration**
  - [ ] GET `/api/v1/super-admin/statistics/national`

---

### 2. Admin Management

#### 2.1 Admin List
**Status:** Complete / In Progress / Not Started

**Screens:**
- `AdminManagementScreen` → `lib/features/admin/screens/admin_management_screen.dart`

**Features Checklist:**
- [ ] **List Display**
  - [ ] ชื่อ-นามสกุล
  - [ ] เบอร์โทร
  - [ ] ขอบเขตพื้นที่ (จังหวัด/อำเภอ/ตำบล)
  - [ ] สถานะ (Active/Suspended)
  - [ ] วันที่สร้าง
  
- [ ] **Filters**
  - [ ] Province
  - [ ] Status
  
- [ ] **Search**
  - [ ] ค้นหาด้วยชื่อ/เบอร์โทร
  
- [ ] **Actions**
  - [ ] ดูรายละเอียด
  - [ ] แก้ไข
  - [ ] Suspend/Activate
  - [ ] ลบ (Soft Delete)
  
- [ ] **API Integration**
  - [ ] GET `/api/v1/super-admin/admins`

---

#### 2.2 Create New Admin
**Status:** Complete / In Progress / Not Started

**Screens:**
- `CreateAdminScreen` → `lib/features/admin/screens/create_admin_screen.dart`

**Features Checklist:**
- [ ] **Form Fields**
  - [ ] ชื่อ-นามสกุล
  - [ ] เบอร์โทร
  - [ ] ID Card
  - [ ] วันเกิด
  - [ ] ที่อยู่
  - [ ] รูปโปรไฟล์
  
- [ ] **Admin Scope (สำคัญ!)**
  - [ ] Province (required)
  - [ ] District (optional - ถ้าเลือกจะดูแลเฉพาะอำเภอนี้)
  - [ ] Subdistrict (optional - ถ้าเลือกจะดูแลเฉพาะตำบลนี้)
  
- [ ] **PIN Setup**
  - [ ] ไม่ต้องกำหนด PIN ตอนสร้าง
  - [ ] Admin จะตั้ง PIN เองตอน Login ครั้งแรก
  
- [ ] **API Integration**
  - [ ] POST `/api/v1/super-admin/admins`

**API Endpoint:**
```
POST /api/v1/super-admin/admins
Body: {
  phone, birthday, firstName, lastName, idCard,
  province, district, subDistrict, address, postalCode
}
Response: { admin object with temp password or setup link }
```

---

#### 2.3 Edit Admin
**Features Checklist:**
- [ ] แก้ไขข้อมูล Admin
- [ ] เปลี่ยนขอบเขตพื้นที่
- [ ] PATCH `/api/v1/super-admin/admins/:id`

---

#### 2.4 Suspend/Delete Admin
**Features Checklist:**
- [ ] **Suspend**
  - [ ] Admin ยังอยู่ในระบบแต่ไม่สามารถ Login
  - [ ] PATCH `/api/v1/super-admin/admins/:id/suspend`
  
- [ ] **Reactivate**
  - [ ] PATCH `/api/v1/super-admin/admins/:id/activate`
  
- [ ] **Delete**
  - [ ] Soft Delete
  - [ ] Confirmation Dialog + Reason
  - [ ] DELETE `/api/v1/super-admin/admins/:id`

---

### 3. User Management (All Users)

#### 3.1 User List (Nationwide)
**Features Checklist:**
- [ ] **Filters**
  - [ ] Province/District/Subdistrict
  - [ ] Status (Pending/Approved/Rejected)
  - [ ] Registration Date Range
  
- [ ] **Search**
  - [ ] ชื่อ, เบอร์โทร, ID Card
  
- [ ] **Bulk Actions**
  - [ ] Export to CSV/Excel
  - [ ] Bulk Approve (เลือกหลายคน)
  
- [ ] **API Integration**
  - [ ] GET `/api/v1/super-admin/users`

---

### 4. GAP System Overview

**Features Checklist:**
- [ ] **Nationwide GAP Statistics**
  - [ ] Total GAP Records by Category
  - [ ] Compliance Rate
  - [ ] Pending Reviews (ทั้งหมด)
  
- [ ] **Reports**
  - [ ] Export GAP Report (PDF/Excel)
  - [ ] GET `/api/v1/super-admin/gap/report`

---

### 5. Support Ticket Management

#### 5.1 Ticket List (From Admins)
**Status:** Complete / In Progress / Not Started

**Screens:**
- `SupportTicketScreen` → `lib/features/admin/screens/support_ticket_screen.dart`

**Features Checklist:**
- [ ] **List Display**
  - [ ] หัวข้อ
  - [ ] Admin ผู้ส่ง
  - [ ] ประเภท
  - [ ] สถานะ (Open/In Progress/Resolved/Closed)
  - [ ] วันที่ส่ง
  - [ ] Priority (High/Medium/Low)
  
- [ ] **Filters**
  - [ ] Status
  - [ ] Type
  - [ ] Priority
  
- [ ] **Actions**
  - [ ] เปิดดูรายละเอียด
  - [ ] ตอบกลับ
  - [ ] เปลี่ยนสถานะ
  - [ ] Assign to Team Member (ถ้ามี)
  
- [ ] **API Integration**
  - [ ] GET `/api/v1/super-admin/tickets`
  - [ ] PATCH `/api/v1/super-admin/tickets/:id/reply`
  - [ ] PATCH `/api/v1/super-admin/tickets/:id/status`

---

### 6. System Settings

#### 6.1 General Settings
**Features Checklist:**
- [ ] **App Configuration**
  - [ ] ชื่อระบบ
  - [ ] โลโก้
  - [ ] สีธีม (ถ้าต้องการเปลี่ยน)
  - [ ] ข้อความต้อนรับ
  
- [ ] **Notification Settings**
  - [ ] Enable/Disable Push Notifications
  - [ ] Email Notifications
  
- [ ] **Maintenance Mode**
  - [ ] Enable/Disable
  - [ ] Maintenance Message

---

#### 6.2 Data Management
**Features Checklist:**
- [ ] **Backup**
  - [ ] Trigger Manual Backup
  - [ ] Schedule Auto Backup
  - [ ] Download Backup File
  
- [ ] **Logs**
  - [ ] View System Logs
  - [ ] View Audit Logs (ใครทำอะไรเมื่อไหร่)
  - [ ] Export Logs

---

### 7. Reports & Analytics

#### 7.1 Generate Reports
**Features Checklist:**
- [ ] **User Reports**
  - [ ] Export User List (CSV/Excel)
  - [ ] User Growth Report
  - [ ] User Activity Report
  
- [ ] **Plot Reports**
  - [ ] Plot Distribution by Region
  - [ ] Plot by Plant Type
  - [ ] Plot Approval Rate
  
- [ ] **GAP Reports**
  - [ ] GAP Compliance Report
  - [ ] GAP Submission Trend
  - [ ] GAP by Category
  
- [ ] **API Integration**
  - [ ] GET `/api/v1/super-admin/reports/:type`

---

## Cross-Role Features

### 1. Logout
**All Roles:**
- [ ] Clear Secure Storage (Token)
- [ ] Clear Local Cache (optional)
- [ ] Navigate to Login Screen

---

### 2. Deep Links / Push Notifications
**Features:**
- [ ] Handle Deep Links (เปิด Notification → ไปหน้าที่เกี่ยวข้อง)
- [ ] Push Notification Integration
  - [ ] Firebase Cloud Messaging (FCM)
  - [ ] Request Permission
  - [ ] Handle Foreground/Background/Terminated

---

## Completion Status Legend

- **Complete** - ทำเสร็จแล้ว, ทดสอบผ่าน
- **In Progress** - กำลังทำอยู่
- **Not Started** - ยังไม่เริ่ม
- **Blocked** - ติดปัญหา, รอการแก้ไข
- **On Hold** - พักไว้ก่อน

---

## How to Use This Document

### สำหรับ AI Agent:
1. อ่านทุกหัวข้อเพื่อเข้าใจ Scope งาน
2. เช็ค Status แต่ละ Feature
3. เลือก Feature ที่เป็น Not Started หรือ In Progress
4. ทำตาม Checklist ข้างใน
5. ทดสอบจนผ่านทุกข้อ
6. เปลี่ยน Status เป็น Complete

### การ Priority:
1. **P0** - Core Features (Login, Register, Dashboard)
2. **P1** - Primary Features (Plot, GAP Forms)
3. **P2** - Secondary Features (Notifications, Chat)
4. **P3** - Nice-to-have (Analytics Charts, Advanced Filters)

---

**Document Status:** Production Ready  
**Completeness:** 100%  
**Last Review:** 2026-01-29
