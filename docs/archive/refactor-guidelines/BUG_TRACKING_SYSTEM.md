# Bug Tracking & Resolution System
## ระบบติดตามและแก้ไข Bug (Flutter Edition)

**Version:** 1.0.1 (Flutter Edition)
**Last Updated:** 2026-01-29

---

## Common Bug Patterns & Solutions (Flutter)

### 1. RenderFlex Overflow
**อาการ:** แถบคาดสีเหลือง-ดำ แสดงว่าเนื้อหาล้นหน้าจอ
**การแก้ไข:**
```dart
// ผิด
Column(
  children: [
    Header(),
    Form(), // ยาวเกินจอ
  ],
)

// ถูก (ใช้ ScrollView)
SingleChildScrollView(
  child: Column(
    children: [
      Header(),
      Form(),
    ],
  ),
)

// ถูก (ใช้ Expanded ใน Column ขนาด Fixed)
Column(
  children: [
    Header(),
    Expanded(child: ListView(...)),
  ],
)
```

### 2. BuildContext usage across async gaps
**อาการ:** Warning `Don't use 'BuildContext's across async gaps.`
**การแก้ไข:**
```dart
// ผิด
await authProvider.login();
Navigator.of(context).pop(); // context อาจจะไม่อยู่แล้ว

// ถูก (ตรวจสอบ mounted)
await authProvider.login();
if (!mounted) return;
Navigator.of(context).pop();
```

### 3. Provider Not Found
**อาการ:** `Error: Could not find the correct Provider<T> above this Widget`
**สาเหตุ:** ไม่ได้ wrap widget ใน `ChangeNotifierProvider` หรือ context อยู่ผิดชั้น
**การแก้ไข:**
ตรวจสอบ `main.dart` หรือ `MultiProvider` ว่าได้ประกาศ Provider ไว้ใน Tree ที่สูงกว่าจุดที่เรียกใช้ `Provider.of` หรือ `context.read`

---

## Known Issues & Status

### Critical Issues (P0)

#### FIXED: จังหวัดตากแสดงภาษาเพี้ยน
**Root Cause:** Encoding
**Solution:** แก้ไขการ Encode/Decode JSON ให้รองรับ UTF-8 (ใน Dart มักจัดการให้อัตโนมัติถ้าระบุ content-type headers ถูกต้อง)

#### FIXED: PIN Input ไม่ทำงานบน Android
**Root Cause:** Widget configuration
**Solution:** เปลี่ยน `keyboardType` เป็น `TextInputType.number`

---

## Bug Report Template

```markdown
**Title:** [ชื่อปัญหาสั้นๆ]
**Description:** [รายละเอียด]
**Steps:**
1. ไปที่หน้า...
2. กดปุ่ม...
**Expected:** [ควรจะเป็นอย่างไร]
**Actual:** [สิ่งที่เกิดขึ้นจริง]
**Error Log:** (ถ้ามี - copy จาก Debug Console)
```

---

## Bug Resolution Checklist
เมื่อแก้ Bug เสร็จต้องเช็ค:
- [ ] หายจริงใน Simulator/Device
- [ ] ไม่กระทบฟีเจอร์อื่น (Regression Test)
- [ ] ลบ print/log debug ออกหมดแล้ว
- [ ] Code Format เรียบร้อย (`dart format .`)
