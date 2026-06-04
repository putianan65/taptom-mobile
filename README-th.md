# TAPTOM Mobile

**ภาษา: ไทย** | [English](./README.md)

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart&logoColor=white)
![Provider](https://img.shields.io/badge/State-Provider-6C63FF)
![Riverpod](https://img.shields.io/badge/State-Riverpod-00B0FF)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)
![License](https://img.shields.io/badge/License-Private-red)

แอปพลิเคชันมือถือสำหรับบริหารจัดการข้อมูลการเกษตรแบบรวมศูนย์ พัฒนาด้วย Flutter ออกแบบมาเพื่อเกษตรกรและเจ้าหน้าที่ รองรับมาตรฐาน **GAP (Good Agricultural Practices)** และระบบ **ตรวจสอบย้อนกลับ (Traceability)** ผ่านการสแกน QR Code

---

## เกี่ยวกับแอปพลิเคชัน

TAPTOM Mobile คือแพลตฟอร์มบริหารจัดการข้อมูลเกษตรกรรม ที่เชื่อมต่อเกษตรกรกับเจ้าหน้าที่ผ่านแอปพลิเคชันมือถือเพียงตัวเดียว แอปนี้ถูกออกแบบมาเพื่อแก้ปัญหาที่เกิดขึ้นจริงในภาคเกษตรกรรมไทย ได้แก่ ข้อมูลฟาร์มกระจัดกระจาย ขาดระบบควบคุมคุณภาพตามมาตรฐาน และไม่สามารถตรวจสอบย้อนกลับแหล่งที่มาของผลผลิตได้

เกษตรกรสามารถลงทะเบียนแปลงพร้อมวาดขอบเขตพื้นที่บนแผนที่แบบ GIS, บันทึกข้อมูล GAP ครบทั้ง 7 หมวด, และสร้างเลข Lot สำหรับตรวจสอบย้อนกลับ ส่วนเจ้าหน้าที่สามารถตรวจสอบข้อมูล อนุมัติแปลง ตรวจประเมิน GAP และบริหารจัดการชุมชนเกษตรกรที่ตนดูแล ทั้งหมดนี้ทำงานบนระบบ Role-Based Access Control (Farmer, Admin, Super Admin)

---

## ฟีเจอร์หลัก

### ระบบยืนยันตัวตนและความปลอดภัย
- เข้าสู่ระบบด้วยเบอร์โทรศัพท์ + วันเกิด (ไม่ใช้รหัสผ่าน)
- ยืนยัน PIN 6 หลัก พร้อมระบบ Rate Limiting และล็อกเมื่อกรอกผิดเกินกำหนด
- JWT Access/Refresh Token lifecycle พร้อม Silent Refresh อัตโนมัติเมื่อได้รับ 401
- เก็บ Token แบบเข้ารหัสผ่าน `FlutterSecureStorage` (EncryptedSharedPreferences บน Android)

### จัดการแปลงเกษตรและแผนที่
- แผนที่แบบ Interactive ด้วย **MapLibre GL** พร้อมเครื่องมือวาด Polygon
- ลงทะเบียนขอบเขตแปลงในรูปแบบ GeoJSON พร้อมคำนวณพื้นที่ (ไร่)
- อัปโหลดรูปภาพประกอบแปลงหลายรูป
- ลำดับชั้นที่ตั้ง: ภาค > จังหวัด > อำเภอ > ตำบล

### ระบบ GAP (7 หมวด)
- **1.1** ข้อมูลทั่วไป (แหล่งน้ำ, ลักษณะดิน)
- **1.2** ปัจจัยการผลิต (ปุ๋ย, สารเคมี พร้อมข้อมูลความปลอดภัย)
- **1.3** กิจกรรมการจัดการแปลง
- **1.4** บันทึกการเก็บเกี่ยว
- **1.5** การจัดการหลังเก็บเกี่ยว
- **1.6** ความปลอดภัยและการฝึกอบรมแรงงาน
- **1.7** การสร้าง Lot และการตรวจสอบย้อนกลับ
- ติดตามความคืบหน้าการปฏิบัติตามมาตรฐานแบบ Real-time พร้อม Visual Indicator
- รองรับบันทึก Draft แบบ Offline ผ่าน SQLite สำหรับพื้นที่สัญญาณไม่ดี

### ระบบ QR Code ตรวจสอบย้อนกลับ (สาธารณะ)
- สแกน QR Code เพื่อดูรายงานตรวจสอบย้อนกลับแบบครบวงจร
- ไม่ต้องเข้าสู่ระบบ -- ผู้บริโภคและผู้รับซื้อเข้าถึงได้โดยตรง
- แสดงข้อมูลตลอดห่วงโซ่: แปลงต้นทาง, บันทึก GAP, ข้อมูลเก็บเกี่ยว, การจัดการหลังเก็บเกี่ยว

### AI Chat Assistant
- รับคำสั่งเสียงผ่าน `speech_to_text`
- เชื่อมต่อบริการ AI ผ่าน HTTP สำหรับให้คำแนะนำด้านการเกษตร

### Dashboard ตามบทบาทผู้ใช้
- **เกษตรกร**: ภาพรวมแปลง, ความคืบหน้า GAP, สถิติผลผลิต, แผนภูมิ
- **Admin**: Workflow อนุมัติผู้ใช้/แปลง, ตรวจประเมิน GAP, ระบบส่งข้อความ, แผนที่ภาพรวมแปลงทั้งหมด
- **Super Admin**: จัดการ Admin, บันทึก Audit Log, วิเคราะห์ข้อมูลระดับแพลตฟอร์ม

### ฟีเจอร์เสริม
- ระบบแจ้งเตือนภายในแอป
- ระบบส่งข้อความระหว่าง Admin กับเกษตรกร และ Support Ticket
- สร้างไฟล์ PDF สำหรับใบรับรอง GAP และรายงานการปฏิบัติตามมาตรฐาน
- รองรับ Dark Mode และภาษาไทย
- ติดตามความยินยอม PDPA (พ.ร.บ.คุ้มครองข้อมูลส่วนบุคคล)

---

## สถาปัตยกรรม

```
lib/
├── main.dart                    # จุดเริ่มต้นแอป, ตั้งค่า DI, โหลด Token
├── app.dart                     # GoRouter config, MultiProvider tree
├── locator.dart                 # GetIt service locator (DI)
├── core/
│   ├── config/                  # Environment variables (flutter_dotenv)
│   ├── constants/               # ค่าคงที่ของแอป
│   ├── l10n/                    # ไฟล์ Localization
│   ├── network/
│   │   ├── api_client.dart      # Dio HTTP client พร้อม interceptors
│   │   ├── api_endpoints.dart   # ศูนย์รวม endpoint ทั้งหมด
│   │   └── interceptors/       # Auth injection, token refresh, error handling
│   ├── security/
│   │   └── secure_storage.dart  # เก็บ Token และ PIN แบบเข้ารหัส
│   ├── services/                # 20 service classes (auth, plot, GAP, PDF ฯลฯ)
│   ├── themes/                  # Material 3 light/dark theme
│   ├── utils/                   # Helpers (GeoJSON parsing, formatters)
│   └── widgets/                 # Shared core widgets
├── data/
│   └── models/                  # 12 data models (User, Plot, GAP ฯลฯ)
├── features/
│   ├── auth/                    # หน้า Login, สมัครสมาชิก, PIN
│   ├── home/                    # Splash, Dashboard (เกษตรกร + Admin)
│   ├── map/                     # MapLibre วาดแปลง, รายละเอียดแปลง
│   ├── gap/                     # ฟอร์ม GAP 7 หมวด + สรุป
│   ├── traceability/            # สแกน QR + รายงาน (เข้าถึงได้โดยไม่ต้อง Login)
│   ├── chat/                    # AI chat assistant พร้อมสั่งงานด้วยเสียง
│   ├── certificate/             # สร้างใบรับรอง PDF
│   ├── admin/                   # หน้า Admin (17 หน้าจอ)
│   ├── super_admin/             # หน้า Super Admin (5 หน้าจอ)
│   ├── profile/                 # จัดการข้อมูลส่วนตัว
│   ├── settings/                # ตั้งค่า Theme, ภาษา
│   ├── notifications/           # ศูนย์แจ้งเตือน
│   ├── approval/                # Workflow อนุมัติแปลง
│   ├── contact/                 # ข้อมูลติดต่อ
│   └── shared/                  # Support tickets (ใช้ร่วมกันทุก Role)
└── widgets/                     # Global reusable widgets
```

**การตัดสินใจเชิงสถาปัตยกรรมที่สำคัญ:**
- **Layered Architecture** แยก UI (features), Business Logic (services/providers) และ Data (models/network) ออกจากกันอย่างชัดเจน
- **Dual State Management**: Provider สำหรับ state ที่ผูกกับ widget tree + GetIt สำหรับ singleton ระดับ global (ให้ AuthProvider เข้าถึงได้จาก interceptor โดยไม่ต้องใช้ BuildContext)
- **Centralized API Client** ด้วย Dio interceptors จัดการ auth injection, auto-refresh เมื่อได้ 401 พร้อม concurrency lock ป้องกัน refresh ซ้ำ, และ auto-retry เมื่อได้ 429
- **Feature-first Organization** แต่ละโมดูลเป็นเจ้าของ screens, widgets และ providers ของตัวเอง

---

## Tech Stack และ Libraries

| หมวดหมู่ | Library | หน้าที่ |
|----------|---------|---------|
| **State Management** | `provider` | จัดการ state ผ่าน ChangeNotifier ใน widget tree |
| | `flutter_riverpod` | Declarative state สำหรับโมดูลเฉพาะ |
| | `get_it` | Service Locator สำหรับ DI นอก widget tree |
| **Routing** | `go_router` | Declarative routing พร้อม auth redirect guards |
| **Networking** | `dio` | HTTP client พร้อม interceptors |
| | `pretty_dio_logger` | แสดง log request/response ในโหมด Debug |
| | `flutter_dotenv` | จัดการ environment variables |
| | `supabase_flutter` | เชื่อมต่อ backend service |
| **แผนที่และตำแหน่ง** | `maplibre_gl` | แสดงแผนที่ vector แบบ interactive |
| | `geolocator` | ระบุตำแหน่ง GPS ของอุปกรณ์ |
| | `permission_handler` | จัดการ runtime permissions |
| **ฟอร์ม** | `flutter_form_builder` | สร้างฟอร์มแบบ declarative |
| | `form_builder_validators` | validation rules สำเร็จรูป |
| **ความปลอดภัย** | `flutter_secure_storage` | เก็บ Token/PIN แบบเข้ารหัส |
| **Local Storage** | `sqflite` | เก็บ draft GAP แบบ offline |
| | `shared_preferences` | เก็บการตั้งค่าผู้ใช้ (theme, locale) |
| **PDF** | `pdf` + `printing` | สร้างใบรับรองและรายงาน |
| | `share_plus` | แชร์ไฟล์ PDF ผ่าน native share sheet |
| **QR Code** | `mobile_scanner` | สแกน QR Code ผ่านกล้อง |
| | `qr_flutter` | สร้างรูป QR Code |
| **AI และเสียง** | `http` | สื่อสารกับบริการ AI chat |
| | `speech_to_text` | แปลงเสียงพูดเป็นข้อความ |
| **UI** | `google_fonts` | Typography (ไทย + อังกฤษ) |
| | `heroicons` | ชุดไอคอน |
| | `google_nav_bar` | Bottom navigation |
| | `fl_chart` | แผนภูมิบน Dashboard |
| | `cached_network_image` | แคชรูปภาพพร้อม placeholder |
| **Utilities** | `intl` | จัดรูปแบบวันที่/ตัวเลข (ภาษาไทย) |
| | `image_picker` | ถ่ายรูปและเลือกจากแกลเลอรี |
| | `url_launcher` | เปิดลิงก์ภายนอก |
| | `path_provider` | หาเส้นทางไฟล์ในระบบ |
| | `package_info_plus` | แสดงเวอร์ชันแอป |

---

## เริ่มต้นใช้งาน

### สิ่งที่ต้องมี

- Flutter SDK >= 3.10.4
- Dart SDK >= 3.10.4
- Android Studio / Xcode (สำหรับ emulator หรืออุปกรณ์จริง)
- TAPTOM Backend (NestJS) ที่พร้อมใช้งาน

### การติดตั้ง

```bash
# 1. Clone repository
git clone https://github.com/your-username/taptom-mobile.git
cd taptom-mobile

# 2. สร้างไฟล์ environment
cp .env.example .env
# แก้ไข .env กำหนดค่า API_BASE_URL

# 3. ติดตั้ง dependencies
flutter pub get

# 4. รันแอปพลิเคชัน
flutter run
```

### Environment Variables

สร้างไฟล์ `.env` ไว้ที่ root ของโปรเจกต์:

```env
API_BASE_URL=https://your-api-domain.com
```

---

## การเชื่อมต่อ Backend

แอปพลิเคชันนี้เชื่อมต่อกับ **TAPTOM Backend** ที่พัฒนาด้วย NestJS โดย API Client (`lib/core/network/api_client.dart`) รองรับ:

- ใส่ Bearer Token อัตโนมัติในทุก request
- Silent Token Refresh เมื่อได้รับ 401 Unauthorized พร้อม concurrency lock ป้องกันการ refresh ซ้ำ
- Auto-retry เมื่อได้รับ 429 (rate limiting) ด้วย backoff 1 วินาที สูงสุด 2 ครั้ง
- จัดการ error แบบมีโครงสร้าง พร้อมข้อความภาษาไทย
- Timeout 8 วินาทีสำหรับ connect/receive

API endpoints ถูกจัดการรวมศูนย์ใน `api_endpoints.dart` ครอบคลุมกว่า 50 endpoints ทั้งระบบยืนยันตัวตน, แปลงเกษตร, ฟอร์ม GAP, ตรวจสอบย้อนกลับ, การจัดการ Admin, ระบบส่งข้อความ และ Analytics