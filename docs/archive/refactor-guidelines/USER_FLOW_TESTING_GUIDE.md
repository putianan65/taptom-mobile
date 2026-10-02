# User Flow & Testing Guide
## คู่มือการทดสอบ User Flow ทุก Role

**Version:** 1.0.0  
**Last Updated:** 2026-01-28

---

## Testing Philosophy

การทดสอบต้องครอบคลุม:
1. **Happy Path** - การใช้งานปกติที่ถูกต้อง
2. **Error Cases** - กรณีที่เกิดข้อผิดพลาด
3. **Edge Cases** - กรณีพิเศษหรือ boundary conditions
4. **Performance** - ความเร็วและความลื่นไหล
5. **UX** - ประสบการณ์ผู้ใช้

---

## USER ROLE - Complete Testing Guide

### User Flow 1: Registration (ลงทะเบียน)

#### Scenario 1: Happy Path - ลงทะเบียนสำเร็จ
```
Steps:
1. เปิดแอป → เห็นหน้า Welcome/Splash
2. กด "ลงทะเบียน"
3. กรอกข้อมูล:
   - ชื่อ: "สมชาย"
   - นามสกุล: "ใจดี"
   - เบอร์โทร: "0812345678"
   - อาชีพ: เลือก "เกษตรกร"
   - จังหวัด: เลือก "เชียงใหม่"
   - อำเภอ: เลือก "เมือง"
   - ตำบล: เลือก "ช้างเผือก"
4. กด "เลือกรูปภาพ"
5. เลือกจากแกลเลอรี่หรือถ่ายรูปใหม่
6. ดู preview รูปภาพ
7. กด "ลงทะเบียน"
8. เห็น loading indicator
9. เห็นข้อความ "ลงทะเบียนสำเร็จ รอการอนุมัติ"
10. ระบบพาไปหน้า Pending Status

Expected Results:
Form validation ทำงานถูกต้อง
Camera/Gallery permission ขอถูกต้อง
รูปภาพ compress และ upload สำเร็จ
API call สำเร็จ (201 Created)
ข้อมูลเก็บใน local storage
แสดง success message
Navigate ไป pending screen
Loading state แสดงผล
ไม่มี crash หรือ error
```

**Test Checklist:**
- [ ] ทุก field validate ถูกต้อง
- [ ] Required fields แสดง error เมื่อเว้นว่าง
- [ ] เบอร์โทรต้องเป็น 10 หลัก
- [ ] อัพโหลดรูปขนาด < 5MB
- [ ] Compress รูปก่อนส่ง
- [ ] Permission dialog แสดงถูกต้อง
- [ ] Loading state แสดงขณะ submit
- [ ] Success message แสดง
- [ ] ข้อมูลเก็บใน local storage
- [ ] Navigate ถูก screen

#### Scenario 2: Error Cases

**Case 2.1: Missing Required Fields**
```
Steps:
1. เปิดหน้าลงทะเบียน
2. เว้นชื่อว่าง
3. กด "ลงทะเบียน"

Expected:
แสดง error "กรุณากรอกชื่อ"
ปุ่มยังไม่ submit
Focus ไปที่ field ที่ขาด
```

**Case 2.2: Invalid Phone Number**
```
Steps:
1. กรอกเบอร์โทร "123" (สั้นเกินไป)
2. กด "ลงทะเบียน"

Expected:
แสดง error "เบอร์โทรไม่ถูกต้อง (10 หลัก)"
```

**Case 2.3: Image Too Large**
```
Steps:
1. เลือกรูปขนาด 15MB
2. พยายาม upload

Expected:
แสดง error "ขนาดรูปภาพต้องไม่เกิน 5MB"
แนะนำให้เลือกรูปใหม่
```

**Case 2.4: Network Error**
```
Steps:
1. ปิด WiFi/Mobile data
2. กรอกข้อมูลครบ
3. กด "ลงทะเบียน"

Expected:
แสดง error "ไม่สามารถเชื่อมต่อได้"
แสดงปุ่ม "ลองอีกครั้ง"
เก็บข้อมูลไว้ (ไม่หาย)
```

**Case 2.5: Duplicate Phone Number**
```
Steps:
1. กรอกเบอร์โทรที่มีอยู่แล้ว
2. กด "ลงทะเบียน"

Expected:
API return 409 Conflict
แสดง error "เบอร์โทรนี้ถูกใช้แล้ว"
แนะนำให้ Login หรือใช้เบอร์อื่น
```

#### Scenario 3: Edge Cases

**Case 3.1: ชื่อยาวมาก**
```
Input: ชื่อ 100 ตัวอักษร
Expected: ควร limit ที่ 50 ตัวอักษร หรือรองรับได้
```

**Case 3.2: จังหวัดที่มีตัวอักษรพิเศษ (ตาก)**
```
Expected:
แสดง "ตาก" ถูกต้อง (ไม่เพี้ยน)
UTF-8 encoding ถูกต้อง
```

**Case 3.3: App Backgrounded ระหว่างการลงทะเบียน**
```
Steps:
1. กรอกข้อมูลครึ่งหนึ่ง
2. กด Home button (app goes to background)
3. เปิด app กลับมา

Expected:
ข้อมูลที่กรอกไว้ยังอยู่
ไม่ต้องกรอกใหม่
```

---

### User Flow 2: Login (เข้าสู่ระบบ)

#### Scenario 1: Happy Path - Login สำเร็จ
```
Steps:
1. เปิดแอป → หน้า Welcome
2. กด "เข้าสู่ระบบ"
3. กรอกเบอร์โทร: "0812345678"
4. กรอกรหัสผ่าน
5. กด "เข้าสู่ระบบ"
6. เห็น loading
7. เข้าสู่หน้า Home/Dashboard

Expected:
Login API call สำเร็จ
Token เก็บใน Secure Storage
User data เก็บใน Redux/Context
Navigate ไปหน้าที่ถูกต้อง (ตาม status)
  - Pending → Pending Screen
  - Approved → Home Screen
  - Rejected → Rejection Screen
Remember me (ถ้าเลือก)
```

**Test Checklist:**
- [ ] Validation ทำงานถูกต้อง
- [ ] Show/Hide password ทำงาน
- [ ] Loading state แสดง
- [ ] Token เก็บปลอดภัย
- [ ] Auto-login ครั้งต่อไป (ถ้า remember)
- [ ] Navigate ตาม user status

#### Scenario 2: Error Cases

**Case 2.1: Wrong Password**
```
Expected:
แสดง error "เบอร์โทรหรือรหัสผ่านไม่ถูกต้อง"
ไม่ระบุว่าส่วนไหนผิด (security)
Input ยังคงอยู่
```

**Case 2.2: User Not Found**
```
Expected:
แสดง error "ไม่พบข้อมูลผู้ใช้"
แนะนำให้ลงทะเบียน
```

**Case 2.3: Account Suspended**
```
Expected:
แสดง error "บัญชีถูกระงับ กรุณาติดต่อเจ้าหน้าที่"
แสดงช่องทางติดต่อ
```

---

### User Flow 3: View Profile (ดูข้อมูลส่วนตัว)

#### Scenario 1: Happy Path
```
Steps:
1. Login สำเร็จ
2. ไปหน้า Profile
3. เห็นข้อมูลทั้งหมด:
   - รูปภาพ
   - ชื่อ-นามสกุล
   - เบอร์โทร
   - อาชีพ
   - จังหวัด/อำเภอ/ตำบล
   - สถานะ (รอ/อนุมัติ/ปฏิเสธ)
   - วันที่สมัคร
   - วันที่อนุมัติ (ถ้ามี)

Expected:
โหลดข้อมูลจาก API หรือ cache
แสดงข้อมูลครบถ้วน
รูปภาพโหลดเร็ว (cached)
Loading state แสดง
สถานะแสดงถูกต้อง
```

**Test Checklist:**
- [ ] API call หรือใช้ cache
- [ ] แสดงข้อมูลครบถ้วน
- [ ] รูปภาพโหลดเร็ว
- [ ] Loading skeleton แสดง
- [ ] Error handling (ถ้า API fail)
- [ ] Refresh to update data

---

### User Flow 4: Edit Profile (แก้ไขข้อมูล)

#### Scenario 1: Happy Path - แก้ไขสำเร็จ
```
Steps:
1. ไปหน้า Profile
2. กด "แก้ไข" หรือไอคอนดินสอ
3. แก้ไขข้อมูล:
   - เปลี่ยนชื่อ
   - เปลี่ยนอาชีพ
   - เปลี่ยนรูปภาพ
4. กด "บันทึก"
5. เห็น loading
6. เห็นข้อความ "บันทึกสำเร็จ"
7. ข้อมูลอัพเดท

Expected:
Form pre-filled ด้วยข้อมูลเดิม
Validation ทำงาน
Upload รูปใหม่ได้
API call สำเร็จ
UI อัพเดททันที
Cache invalidated
```

**Test Checklist:**
- [ ] Pre-fill ข้อมูลเดิม
- [ ] Validation ทุก field
- [ ] Upload รูปได้
- [ ] Compress รูปก่อน upload
- [ ] API call สำเร็จ
- [ ] Update UI ทันที
- [ ] Cache updated
- [ ] Success message แสดง

#### Scenario 2: Error Cases

**Case 2.1: Network Error ระหว่างบันทึก**
```
Expected:
แสดง error "ไม่สามารถบันทึกได้"
ข้อมูลยังไม่อัพเดท
แสดงปุ่ม "ลองอีกครั้ง"
ข้อมูลที่แก้ยังคงอยู่
```

**Case 2.2: แก้ไขแล้วไม่บันทึก (ออกจากหน้า)**
```
Expected:
แสดง confirmation dialog
"คุณมีการเปลี่ยนแปลงที่ยังไม่บันทึก ต้องการออกหรือไม่?"
- ออก → ยกเลิกการแก้ไข
- บันทึก → บันทึกก่อนออก
```

---

### User Flow 5: Pending Status Screen (รอการอนุมัติ)

#### Expected UI:
```
┌─────────────────────────────────────┐
│  [Icon: Hourglass/Clock]            │
│                                     │
│  รอการอนุมัติจากเจ้าหน้าที่         │
│                                     │
│  ข้อมูลของคุณอยู่ระหว่างการตรวจสอบ │
│  จากเจ้าหน้าที่ กรุณารอสักครู่      │
│                                     │
│  [ปุ่ม: ตรวจสอบสถานะ]              │
│  [ปุ่ม: แก้ไขข้อมูล]               │
│                                     │
│  ต้องการความช่วยเหลือ?              │
│  [ลิงก์ติดต่อเจ้าหน้าที่]          │
└─────────────────────────────────────┘
```

**Test Checklist:**
- [ ] แสดงข้อความชัดเจน
- [ ] มีปุ่มตรวจสอบสถานะ
- [ ] มีปุ่มแก้ไขข้อมูล
- [ ] มีช่องทางติดต่อ
- [ ] Pull to refresh
- [ ] Push notification เมื่อสถานะเปลี่ยน

---

### User Flow 6: Approved Status (อนุมัติแล้ว)

#### Expected Features:
```
เข้าใช้งานฟีเจอร์ทั้งหมดได้
ดูข้อมูลชุมชน
เข้าร่วมกิจกรรม
ดูข่าวสาร
ติดต่อเจ้าหน้าที่
แก้ไข Profile
ดู Dashboard/Statistics
```

---

### User Flow 7: Rejected Status (ถูกปฏิเสธ)

#### Expected UI:
```
┌─────────────────────────────────────┐
│  [Icon: X/Warning]                  │
│                                     │
│  คำขอสมัครสมาชิกถูกปฏิเสธ           │
│                                     │
│  เหตุผล: [แสดงเหตุผลจาก Admin]      │
│                                     │
│  [ปุ่ม: สมัครใหม่อีกครั้ง]         │
│  [ปุ่ม: ติดต่อเจ้าหน้าที่]         │
└─────────────────────────────────────┘
```

**Test Checklist:**
- [ ] แสดงเหตุผลการปฏิเสธ
- [ ] มีปุ่มสมัครใหม่
- [ ] มีช่องทางติดต่อ
- [ ] Data ถูกลบหรือเก็บไว้? (ตาม requirement)

---

## ADMIN ROLE - Complete Testing Guide

### Admin Flow 1: First Time Setup (ตั้งค่า PIN ครั้งแรก)

#### Scenario 1: Happy Path
```
Steps:
1. Login ด้วยบัญชี Admin ครั้งแรก
2. ระบบตรวจสอบว่ายังไม่มี PIN
3. แสดงหน้า Set PIN
4. กรอก PIN: "123456" (6 หลัก)
5. Confirm PIN: "123456"
6. กด "ตั้งค่า PIN"
7. เห็น loading
8. เห็นข้อความ "ตั้งค่า PIN สำเร็จ"
9. PIN เก็บใน Secure Storage (hashed)
10. Navigate ไปหน้า Admin Dashboard

Expected:
PIN validation (6 หลัก, ตัวเลขเท่านั้น)
Confirm PIN ต้องตรงกัน
PIN ถูก hash ก่อนเก็บ
เก็บใน Secure Storage
Success message แสดง
Navigate ถูกต้อง
```

**Test Checklist:**
- [ ] PIN field accepts only numbers
- [ ] PIN length validation (exactly 6)
- [ ] Confirm PIN matching
- [ ] Strong PIN validation (ไม่ใช่ 111111, 123456 ง่ายเกินไป)
- [ ] PIN hashed before storage
- [ ] Stored in Secure Storage
- [ ] Success message
- [ ] Navigate to dashboard

#### Scenario 2: Error Cases

**Case 2.1: PIN ไม่ตรงกัน**
```
Steps:
PIN: "123456"
Confirm: "654321"

Expected:
แสดง error "PIN ไม่ตรงกัน"
ปุ่มยังไม่ submit
```

**Case 2.2: PIN สั้นเกินไป**
```
Steps:
PIN: "123" (3 หลัก)

Expected:
แสดง error "PIN ต้องเป็น 6 หลัก"
```

**Case 2.3: PIN ง่ายเกินไป**
```
Steps:
PIN: "111111" หรือ "123456"

Expected:
แสดงคำเตือน "PIN นี้ไม่ปลอดภัย แนะนำให้เปลี่ยน"
ยังสามารถใช้ได้ (แต่เตือน)
```

---

### Admin Flow 2: Login with PIN

#### Scenario 1: Happy Path
```
Steps:
1. เปิดแอป (Admin mode)
2. แสดงหน้า PIN Login
3. กรอก PIN: "123456"
4. กด "เข้าสู่ระบบ" หรือ auto-submit
5. เห็น loading
6. เข้าสู่ Admin Dashboard

Expected:
PIN input UI สวยงาม (dots/circles)
Auto-submit เมื่อครบ 6 หลัก
Loading state แสดง
Verify PIN กับที่เก็บไว้
Token/Session ถูกสร้าง
Navigate to dashboard
```

**Test Checklist:**
- [ ] PIN input UI intuitive
- [ ] Auto-submit หรือมีปุ่ม submit
- [ ] Loading state
- [ ] PIN verification
- [ ] Success navigate
- [ ] Haptic feedback (optional)

#### Scenario 2: Error Cases

**Case 2.1: Wrong PIN**
```
Steps:
1. กรอก PIN ผิด: "999999"
2. Submit

Expected:
แสดง error "PIN ไม่ถูกต้อง"
นับจำนวนครั้งที่ผิด (max 5 ครั้ง)
Clear PIN input
```

**Case 2.2: Too Many Failed Attempts**
```
Steps:
1. กรอก PIN ผิด 5 ครั้ง

Expected:
Lock account ชั่วคราว (15-30 นาที)
แสดง error "คุณกรอก PIN ผิดหลายครั้ง กรุณาลองใหม่ในอีก 15 นาที"
Timer countdown แสดง
หรือให้ reset PIN ผ่าน Admin อื่น
```

---

### Admin Flow 3: View Pending Users (ดูรายการผู้ใช้รอการอนุมัติ)

#### Scenario 1: Happy Path
```
Steps:
1. Login Admin สำเร็จ
2. ไปหน้า "ผู้ใช้รอการอนุมัติ"
3. เห็น list ของ users ในเขตพื้นที่
4. แต่ละ card แสดง:
   - รูปภาพ
   - ชื่อ-นามสกุล
   - อาชีพ
   - จังหวัด/อำเภอ/ตำบล
   - วันที่สมัคร
   - [ปุ่ม: ดูรายละเอียด]
   - [ปุ่ม: อนุมัติ]
   - [ปุ่ม: ปฏิเสธ]

Expected:
List เฉพาะ users ในเขตที่ดูแล
Pagination ถ้า users มาก
Search ได้
Filter ได้ (วันที่, อาชีพ, ตำบล)
Sort ได้ (วันที่ใหม่สุด, เก่าสุด)
Pull to refresh
Loading state
Empty state (ไม่มี users)
```

**Test Checklist:**
- [ ] Filter users โดยเขตพื้นที่
- [ ] Pagination ทำงาน
- [ ] Search ทำงาน
- [ ] Filter options ครบ
- [ ] Sort ถูกต้อง
- [ ] Pull to refresh
- [ ] Loading skeleton
- [ ] Empty state
- [ ] Performance ดี (list ยาว)

---

### Admin Flow 4: View User Detail (ดูรายละเอียดผู้ใช้)

#### Scenario 1: Happy Path
```
Steps:
1. จาก list กด "ดูรายละเอียด" user หนึ่ง
2. เปิดหน้า detail
3. เห็นข้อมูลทั้งหมด:
   - รูปภาพขนาดใหญ่
   - ข้อมูลส่วนตัวครบถ้วน
   - ประวัติการสมัคร
   - เหตุผลในการสมัคร (ถ้ามี)
   - [ปุ่ม: อนุมัติ]
   - [ปุ่ม: ปฏิเสธ]
   - [ปุ่ม: กลับ]

Expected:
แสดงข้อมูลครบถ้วน
รูปภาพคมชัด (zoom ได้)
Loading state
ปุ่มทำงานได้
```

**Test Checklist:**
- [ ] แสดงข้อมูลครบ
- [ ] รูปภาพ zoom ได้
- [ ] Loading state
- [ ] Buttons ทำงาน
- [ ] Back navigation

---

### Admin Flow 5: Approve User (อนุมัติผู้ใช้)

#### Scenario 1: Happy Path
```
Steps:
1. จากหน้า detail หรือจาก list
2. กด "อนุมัติ"
3. แสดง confirmation dialog:
   "ต้องการอนุมัติผู้ใช้ [ชื่อ] หรือไม่?"
   [ยกเลิก] [อนุมัติ]
4. กด "อนุมัติ"
5. เห็น loading
6. API call สำเร็จ
7. แสดง success message "อนุมัติสำเร็จ"
8. User หายจาก pending list
9. User ได้รับ notification (Push)
10. Refresh list อัตโนมัติ

Expected:
Confirmation dialog แสดง
Loading state
API call สำเร็จ
Optimistic update (UI อัพเดททันที)
Success message
List refresh
User notification sent
ไม่มี crash หรือ error
```

**Test Checklist:**
- [ ] Confirmation dialog
- [ ] Loading indicator
- [ ] API call สำเร็จ
- [ ] Optimistic update
- [ ] Success message
- [ ] List refresh
- [ ] User notification
- [ ] No errors

#### Scenario 2: Error Cases

**Case 2.1: Network Error**
```
Expected:
แสดง error "ไม่สามารถอนุมัติได้"
User ยังอยู่ใน list
ปุ่ม "ลองอีกครั้ง"
```

**Case 2.2: User Already Approved (Race Condition)**
```
Expected:
แสดง warning "ผู้ใช้นี้ได้รับการอนุมัติแล้ว"
Remove จาก list
```

---

### Admin Flow 6: Reject User (ปฏิเสธผู้ใช้)

#### Scenario 1: Happy Path
```
Steps:
1. กด "ปฏิเสธ"
2. แสดง dialog พร้อม input เหตุผล:
   "เหตุผลในการปฏิเสธ (จำเป็น)"
   [Text area]
   [ยกเลิก] [ยืนยัน]
3. กรอกเหตุผล: "ข้อมูลไม่ครบถ้วน"
4. กด "ยืนยัน"
5. เห็น loading
6. API call สำเร็จ
7. แสดง success message
8. User หายจาก list
9. User ได้รับ notification พร้อมเหตุผล

Expected:
Dialog มี required field
Validation เหตุผล (ไม่ว่าง)
Loading state
API call สำเร็จ
Success message
List refresh
User notification with reason
```

**Test Checklist:**
- [ ] Dialog แสดง
- [ ] Reason required
- [ ] Validation
- [ ] Loading
- [ ] API call
- [ ] Success message
- [ ] List update
- [ ] Notification sent

---

### Admin Flow 7: Change PIN

#### Scenario 1: Happy Path
```
Steps:
1. ไปหน้า Admin Profile/Settings
2. กด "เปลี่ยน PIN"
3. กรอก PIN เดิม: "123456"
4. กรอก PIN ใหม่: "654321"
5. Confirm PIN ใหม่: "654321"
6. กด "บันทึก"
7. เห็น loading
8. แสดง success message
9. PIN ใหม่ถูกบันทึก

Expected:
Verify PIN เดิมถูกต้อง
Validate PIN ใหม่
Confirm PIN match
Update Secure Storage
Success message
```

**Test Checklist:**
- [ ] Verify old PIN
- [ ] Validate new PIN
- [ ] Confirm match
- [ ] Update storage
- [ ] Success message

---

### Admin Flow 8: Edit Admin Profile

#### Scenario 1: Happy Path
```
Steps:
1. ไปหน้า Admin Profile
2. กด "แก้ไข"
3. แก้ไขข้อมูล:
   - อัพโหลดรูปใหม่
   - เปลี่ยนชื่อ-นามสกุล
   - เปลี่ยนเบอร์ติดต่อ
4. กด "บันทึก"
5. เห็น loading
6. Success message
7. Profile อัพเดท

Expected:
Camera/Gallery permission
Image compress
API call สำเร็จ
UI update
Cache refresh
```

**Test Checklist:**
- [ ] Upload รูปได้
- [ ] Permission request
- [ ] Validation
- [ ] API success
- [ ] UI update
- [ ] Cache refresh

---

### Admin Flow 9: View Statistics

#### Expected Features:
```
Dashboard แสดง:
- จำนวน users รอการอนุมัติ
- จำนวน users ที่อนุมัติแล้ว
- จำนวน users ที่ปฏิเสธ
- กราฟแสดงการสมัครรายเดือน
- กราฟแสดง users ตามอาชีพ
- กราฟแสดง users ตามตำบล
- สถิติการอนุมัติของตัวเอง

Real-time updates
Interactive charts
Export data (optional)
```

---

## SUPER ADMIN ROLE - Complete Testing Guide

### Super Admin Flow 1: Master Dashboard

#### Expected Features:
```
Dashboard แสดง:
Overview Cards:
- Total Users (ทั้งหมด)
- Pending Users (รอการอนุมัติ)
- Active Admins (Admin ที่ active)
- Total Provinces Covered

Charts & Graphs:
- Registration Trend (รายเดือน)
- Users by Province (แผนที่ + กราฟ)
- Users by Occupation
- Admin Performance
- Approval Rate

Recent Activities:
- Latest registrations
- Latest approvals
- Latest rejections
- Admin actions log

Quick Actions:
- [ปุ่ม: จัดการ Admins]
- [ปุ่ม: จัดการ Users]
- [ปุ่ม: ดู Reports]
- [ปุ่ม: System Settings]
```

**Test Checklist:**
- [ ] ทุก metric แสดงถูกต้อง
- [ ] Charts render สวยงาม
- [ ] Real-time updates
- [ ] Responsive design
- [ ] Export data ได้
- [ ] Performance ดี
- [ ] Loading states
- [ ] Error handling

---

### Super Admin Flow 2: Manage Admins

#### Features:
```
รายการ Admin:
- แสดง list ทั้งหมด
- Filter by province
- Search by name
- Sort by date/name

Admin Card แสดง:
- รูปภาพ
- ชื่อ-นามสกุล
- จังหวัดที่ดูแล
- จำนวน users ที่อนุมัติ
- Status (Active/Suspended)
- [ปุ่ม: ดูรายละเอียด]
- [ปุ่ม: แก้ไข]
- [ปุ่ม: Suspend/Activate]
- [ปุ่ม: Reset PIN]
- [ปุ่ม: ลบ]
```

#### Scenario 1: Add New Admin
```
Steps:
1. กด "เพิ่ม Admin"
2. กรอกข้อมูล:
   - ชื่อ-นามสกุล
   - เบอร์โทร
   - จังหวัดที่รับผิดชอบ
   - Email (optional)
3. กด "สร้าง Admin"
4. ระบบสร้าง temporary PIN
5. แสดง temporary PIN ให้ Super Admin
6. Super Admin ส่ง PIN ให้ Admin ใหม่
7. Admin ใหม่ login และเปลี่ยน PIN

Expected:
Validation ครบถ้วน
API create สำเร็จ
Temporary PIN generated
แสดง PIN ให้ copy
Success message
List refresh
```

#### Scenario 2: Edit Admin
```
Expected:
แก้ไขข้อมูลได้
เปลี่ยนจังหวัดได้
API update สำเร็จ
```

#### Scenario 3: Suspend Admin
```
Expected:
Confirmation dialog
Admin ไม่สามารถ login ได้
Users ที่อนุมัติยังคงอยู่
สามารถ activate ใหม่ได้
```

#### Scenario 4: Reset Admin PIN
```
Steps:
1. กด "Reset PIN"
2. Confirmation dialog
3. ระบบสร้าง temporary PIN ใหม่
4. แสดง PIN ให้ copy
5. Super Admin ส่งให้ Admin

Expected:
Generate temporary PIN
Old PIN invalidated
Admin ต้อง reset PIN
```

#### Scenario 5: Delete Admin
```
Expected:
Confirmation dialog พร้อมคำเตือน
"ลบ Admin นี้จะไม่สามารถกู้คืนได้"
Delete API call
Remove จาก list
Users ที่อนุมัติยังคงอยู่
```

**Test Checklist:**
- [ ] CRUD operations ครบ
- [ ] Validation ครบถ้วน
- [ ] Confirmation dialogs
- [ ] API calls สำเร็จ
- [ ] UI updates
- [ ] No data loss

---

### Super Admin Flow 3: Manage All Users

#### Features:
```
ดู users ทั่วประเทศ:
- แสดงทั้งหมด (ไม่จำกัดเขต)
- Filter multiple:
  - Province
  - Status (Pending/Approved/Rejected)
  - Occupation
  - Date range
- Advanced search
- Bulk actions:
  - Bulk approve
  - Bulk reject
  - Export to CSV/Excel

Actions:
- View detail
- Approve any user
- Reject any user
- Edit user data
- Delete user
- View history
```

**Test Checklist:**
- [ ] แสดง users ทั้งหมด
- [ ] Filters ทำงาน
- [ ] Search ทำงาน
- [ ] Bulk actions ทำงาน
- [ ] Export ได้
- [ ] Performance ดี

---

### Super Admin Flow 4: Reports & Analytics

#### Features:
```
Reports:
1. User Growth Report
   - Daily/Weekly/Monthly
   - Growth rate
   - Trends

2. Geographic Report
   - Users by province
   - Heat map
   - Coverage analysis

3. Occupation Report
   - Distribution
   - Trends
   - Insights

4. Admin Performance Report
   - Approvals per admin
   - Response time
   - Efficiency metrics

5. System Health Report
   - API response times
   - Error rates
   - Uptime

Export Options:
- PDF
- Excel
- CSV
- Charts as images
```

---

### Super Admin Flow 5: System Settings

#### Features:
```
Settings:
- App Configuration
- User Limits
- Approval Rules
- Notification Settings
- Backup & Restore
- System Maintenance
- Logs & Audit Trail
```

---

## General Testing Scenarios

### Cross-Role Testing

#### Scenario 1: User → Admin Interaction
```
1. User สมัครสมาชิก
2. Admin ได้รับ notification
3. Admin เห็น user ใน pending list
4. Admin approve
5. User ได้รับ notification
6. User เข้าใช้งานได้

ทุก step ทำงานเรียบร้อย
Notifications ทันเวลา
No lag หรือ delay
```

#### Scenario 2: Admin → Super Admin Interaction
```
1. Admin ประสบปัญหา (ลืม PIN)
2. ติดต่อ Super Admin
3. Super Admin reset PIN
4. Admin ได้ temporary PIN
5. Admin login และเปลี่ยน PIN

Process ราบรื่น
Communication channel ชัดเจน
```

---

## Device & Platform Testing

### Device Matrix
```
iOS Devices:
- iPhone SE (small screen)
- iPhone 14 Pro (medium)
- iPhone 16 Pro Max (large)
- iPad (tablet)

Android Devices:
- Budget phone (2GB RAM)
- Mid-range (4GB RAM)
- Flagship (8GB+ RAM)
- Tablet

OS Versions:
- iOS 13.0+ (minimum)
- Android 5.0+ (minimum)
- Latest versions
```

### Network Conditions
```
Test กับ:
- WiFi (fast)
- 4G (normal)
- 3G (slow)
- 2G (very slow)
- Offline
- Intermittent connection
```

---

## Final Testing Checklist

### Before Production Release
- [ ] ทุก User Flow ทดสอบแล้ว
- [ ] ทุก Admin Flow ทดสอบแล้ว
- [ ] ทุก Super Admin Flow ทดสอบแล้ว
- [ ] Cross-role interactions ทำงาน
- [ ] Notifications ทำงาน
- [ ] Permissions ขอถูกต้อง
- [ ] Error handling ทุกจุด
- [ ] Loading states ทุกจุด
- [ ] Empty states ทำงาน
- [ ] Offline mode ทำงาน
- [ ] Performance ตาม target
- [ ] Security measures ครบ
- [ ] No critical bugs
- [ ] No high priority bugs
- [ ] UI/UX polished
- [ ] Tested on all devices
- [ ] Tested on all OS versions
- [ ] Tested on all networks

---

**สรุป:** การทดสอบต้องครอบคลุมทุก User Flow, ทุก Role, ทุก Scenario รวมถึง Happy Path, Error Cases และ Edge Cases เพื่อให้แอปพร้อมสำหรับ Production
