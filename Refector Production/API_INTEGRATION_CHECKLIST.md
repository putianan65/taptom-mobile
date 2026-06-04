# API Integration Checklist
## รายการตรวจสอบการเชื่อมต่อ API

**Version:** 1.0.0  
**Last Updated:** 2026-01-28  
**API Documentation:** http://localhost:3000/docs (Swagger)

---

## 🔍 API Documentation Access

### Swagger UI
**URL:** `http://localhost:3000/docs`

**ใช้สำหรับ:**
- ตรวจสอบ API endpoints ทั้งหมด
- ทดสอบ API calls โดยตรง
- ดู Request/Response schemas
- ตรวจสอบ Authentication requirements
- Verify API ทำงานครบถูกต้องสมบูรณ์

**วิธีใช้:**
```bash
# 1. รัน backend server
cd backend
npm run dev

# 2. เปิดเบราว์เซอร์
http://localhost:3000/docs

# 3. ทดสอบ API
- เลือก endpoint
- กด "Try it out"
- กรอก parameters
- กด "Execute"
- ดู Response
```

---

## 📡 API Architecture Overview

### Base Configuration
```javascript
// config/api.js
export const API_CONFIG = {
  BASE_URL: process.env.API_BASE_URL,
  TIMEOUT: 30000,
  RETRY_ATTEMPTS: 3,
  RETRY_DELAY: 1000,
};

// API Client Setup
import axios from 'axios';

const apiClient = axios.create({
  baseURL: API_CONFIG.BASE_URL,
  timeout: API_CONFIG.TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Request Interceptor
apiClient.interceptors.request.use(
  async (config) => {
    const token = await getAuthToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Handle token refresh
      await refreshToken();
      return apiClient.request(error.config);
    }
    return Promise.reject(error);
  }
);
```

---

## 🔐 Authentication APIs

### 1. User Registration
**Endpoint:** `POST /api/auth/register`

**Request:**
```json
{
  "firstName": "สมชาย",
  "lastName": "ใจดี",
  "phoneNumber": "0812345678",
  "occupation": "เกษตรกร",
  "province": "เชียงใหม่",
  "district": "เมือง",
  "subDistrict": "ช้างเผือก",
  "profileImage": "base64_string_or_url"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "user_123",
    "status": "pending_approval",
    "message": "รอการอนุมัติจากเจ้าหน้าที่"
  }
}
```

**Checklist:**
- [ ] API Connection สำเร็จ
- [ ] Validation Error Handling
- [ ] Upload Image ได้
- [ ] เก็บข้อมูล Local หลัง Register
- [ ] แสดง Success/Error Message
- [ ] Loading State

**Storage:**
- เก็บ userId ใน Local Storage
- เก็บ status ใน Local Storage
- ไม่เก็บ Password

---

### 2. User Login
**Endpoint:** `POST /api/auth/login`

**Request:**
```json
{
  "phoneNumber": "0812345678",
  "password": "hashed_password"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "user_123",
    "token": "jwt_token",
    "refreshToken": "refresh_token",
    "role": "user",
    "profile": {
      "firstName": "สมชาย",
      "lastName": "ใจดี",
      "status": "approved"
    }
  }
}
```

**Checklist:**
- [ ] API Connection สำเร็จ
- [ ] Token จัดเก็บใน Secure Storage
- [ ] Refresh Token จัดเก็บใน Secure Storage
- [ ] Auto Login หลัง Register (ถ้ามี)
- [ ] Error Handling (Wrong Password, User Not Found)

**Storage:**
- Token → Secure Storage
- Refresh Token → Secure Storage
- User Profile → Redux/Context

---

### 3. Admin PIN Login
**Endpoint:** `POST /api/admin/login`

**Request:**
```json
{
  "adminId": "admin_123",
  "pin": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "adminId": "admin_123",
    "token": "jwt_token",
    "role": "admin",
    "province": "เชียงใหม่"
  }
}
```

**Checklist:**
- [ ] PIN Input Component ทำงานได้
- [ ] PIN Validation (6 หลัก)
- [ ] PIN Encryption ก่อนส่ง
- [ ] Error Handling (Wrong PIN)
- [ ] Lock Account หลังพยายาม 5 ครั้ง

**Storage:**
- PIN ต้อง Hash ก่อนเก็บ
- Token → Secure Storage

---

### 4. Set/Change PIN
**Endpoint:** `POST /api/admin/set-pin`

**Request:**
```json
{
  "adminId": "admin_123",
  "oldPin": "123456", // ถ้าเป็น Change PIN
  "newPin": "654321",
  "confirmPin": "654321"
}
```

**Checklist:**
- [ ] Set PIN ครั้งแรกทำงานได้
- [ ] Change PIN ทำงานได้
- [ ] Confirm PIN Match Validation
- [ ] PIN Strength Validation
- [ ] Success Confirmation

---

## 👤 User Profile APIs

### 5. Get User Profile
**Endpoint:** `GET /api/user/profile/:userId`

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": "user_123",
    "firstName": "สมชาย",
    "lastName": "ใจดี",
    "phoneNumber": "0812345678",
    "occupation": "เกษตรกร",
    "province": "เชียงใหม่",
    "district": "เมือง",
    "subDistrict": "ช้างเผือก",
    "profileImage": "https://cdn.example.com/images/user_123.jpg",
    "status": "approved",
    "createdAt": "2026-01-15T10:30:00Z",
    "approvedBy": "admin_456",
    "approvedAt": "2026-01-16T14:20:00Z"
  }
}
```

**Checklist:**
- [ ] API Connection สำเร็จ
- [ ] แสดงข้อมูลครบถ้วน
- [ ] แสดงรูปภาพได้
- [ ] Loading State ขณะ Fetch
- [ ] Error Handling
- [ ] Cache ข้อมูล

**Storage:**
- Cache Profile Data ใน Redux/Context
- Cache Timeout: 5 นาที

---

### 6. Update User Profile
**Endpoint:** `PUT /api/user/profile/:userId`

**Request:**
```json
{
  "firstName": "สมชาย",
  "lastName": "ใจดีมาก",
  "occupation": "เกษตรกร",
  "profileImage": "base64_or_url"
}
```

**Checklist:**
- [ ] API Connection สำเร็จ
- [ ] Upload รูปใหม่ได้
- [ ] Update ข้อมูลอื่นๆ ได้
- [ ] Validation Error Handling
- [ ] Success Message
- [ ] Refresh Profile หลัง Update

---

### 6.1. Submit GAP (Good Agricultural Practices)
**Endpoint:** `POST /api/user/gap/submit`

**Context:** แอปนี้เกี่ยวกับเกษตรพืชเสพติดที่อยู่ภายใต้การควบคุมโดยกฎหมายของประเทศไทย

**Request:**
```json
{
  "userId": "user_123",
  "gapData": {
    "farmLocation": {
      "latitude": 18.7883,
      "longitude": 98.9853,
      "area": "5 ไร่"
    },
    "cropType": "กัญชา",
    "plantingDate": "2026-01-15",
    "harvestDate": "2026-04-15",
    "certificationNumber": "GAP-2026-001",
    "documents": [
      "permit_document.pdf",
      "land_deed.pdf"
    ],
    "practices": {
      "soilManagement": true,
      "waterManagement": true,
      "pestControl": true,
      "recordKeeping": true
    }
  },
  "submitToAdmin": true
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "gapId": "gap_123",
    "status": "pending_admin_review",
    "submittedAt": "2026-01-28T10:00:00Z",
    "adminNotified": true
  }
}
```

**Checklist:**
- [ ] API Connection สำเร็จ
- [ ] กรอกข้อมูล GAP ครบถ้วน
- [ ] Upload เอกสารได้
- [ ] หลังกดบันทึก สามารถกดส่งต่อให้ Admin ตรวจสอบได้
- [ ] Admin ได้รับ notification
- [ ] แสดงสถานะ "รอการตรวจสอบจาก Admin"
- [ ] User สามารถแก้ไข GAP ก่อนส่งได้
- [ ] Validation ครบถ้วน

**Important Notes:**
- ข้อมูล GAP เกี่ยวข้องกับกฎหมาย ต้องจัดเก็บอย่างปลอดภัย
- ต้องมี audit trail ทุกการเปลี่ยนแปลง
- เอกสารต้อง encrypt
- Admin ต้องตรวจสอบและอนุมัติ

---

### 7. Upload Profile Image
**Endpoint:** `POST /api/user/upload-image`

**Request:**
```javascript
const formData = new FormData();
formData.append('userId', 'user_123');
formData.append('image', {
  uri: imageUri,
  type: 'image/jpeg',
  name: 'profile.jpg',
});
```

**Checklist:**
- [ ] Camera Permission Request
- [ ] Gallery Permission Request
- [ ] Image Compression ก่อน Upload
- [ ] Progress Indicator
- [ ] Error Handling (Size Limit, Format)
- [ ] Preview ก่อน Upload

**Image Requirements:**
- Max Size: 5MB
- Formats: JPG, PNG
- Compression: 80%
- Max Dimension: 1024x1024

---

## 🏛️ Admin APIs

### 8. Get Pending Users
**Endpoint:** `GET /api/admin/pending-users/:province`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "userId": "user_123",
      "firstName": "สมชาย",
      "lastName": "ใจดี",
      "occupation": "เกษตรกร",
      "province": "เชียงใหม่",
      "district": "เมือง",
      "profileImage": "url",
      "createdAt": "2026-01-20T10:00:00Z"
    }
  ],
  "total": 15,
  "page": 1,
  "pageSize": 20
}
```

**Checklist:**
- [ ] Filter ตามจังหวัดได้
- [ ] Pagination ทำงานได้
- [ ] Search ทำงานได้
- [ ] Sort ได้ (วันที่, ชื่อ)
- [ ] Loading State
- [ ] Empty State

**Storage:**
- Cache: 1 นาที
- Refresh เมื่อ Approve/Reject

---

### 9. Approve User
**Endpoint:** `POST /api/admin/approve-user`

**Request:**
```json
{
  "userId": "user_123",
  "adminId": "admin_456",
  "notes": "ตรวจสอบเรียบร้อย"
}
```

**Response:**
```json
{
  "success": true,
  "message": "อนุมัติสำเร็จ",
  "data": {
    "userId": "user_123",
    "status": "approved",
    "approvedAt": "2026-01-28T10:00:00Z"
  }
}
```

**Checklist:**
- [ ] API Connection สำเร็จ
- [ ] Update UI ทันที
- [ ] Refresh List
- [ ] Success Message
- [ ] Error Handling
- [ ] Optimistic Update

---

### 10. Reject User
**Endpoint:** `POST /api/admin/reject-user`

**Request:**
```json
{
  "userId": "user_123",
  "adminId": "admin_456",
  "reason": "ข้อมูลไม่ครบถ้วน"
}
```

**Checklist:**
- [ ] API Connection สำเร็จ
- [ ] Confirm Dialog
- [ ] Reason Required
- [ ] Update UI ทันที
- [ ] Success Message

---

### 11. Get Admin Profile
**Endpoint:** `GET /api/admin/profile/:adminId`

**Checklist:**
- [ ] แสดงข้อมูล Admin
- [ ] แสดงจำนวน User ที่ดูแล
- [ ] แสดงสถิติการอนุมัติ
- [ ] Update Profile ได้

---

### 12. Update Admin Profile
**Endpoint:** `PUT /api/admin/profile/:adminId`

**Checklist:**
- [ ] Upload รูป Profile ได้
- [ ] Camera/Gallery Permission
- [ ] Update ข้อมูลอื่นๆ ได้
- [ ] Success Message

---

### 13. Contact Super Admin
**Endpoint:** `POST /api/admin/contact-superadmin`

**Request:**
```json
{
  "adminId": "admin_123",
  "subject": "ต้องการความช่วยเหลือ",
  "message": "ลืม PIN และไม่สามารถเข้าใช้งานได้",
  "urgency": "high",
  "attachments": []
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "ticketId": "ticket_456",
    "status": "open",
    "createdAt": "2026-01-28T10:00:00Z",
    "estimatedResponse": "ภายใน 24 ชั่วโมง"
  }
}
```

**Checklist:**
- [ ] Admin สามารถส่งข้อความถึง Super Admin
- [ ] แนบไฟล์ได้ (ถ้าจำเป็น)
- [ ] ระดับความเร่งด่วน (low, medium, high, urgent)
- [ ] Super Admin ได้รับ notification
- [ ] Admin ได้รับ ticket ID
- [ ] สามารถติดตามสถานะได้

**Use Cases:**
- ลืม PIN
- ปัญหาทางเทคนิค
- ขอคำแนะนำ
- รายงานปัญหาผู้ใช้
- ขอสิทธิ์เพิ่มเติม

---

### 14. Review GAP Submission
**Endpoint:** `GET /api/admin/gap/pending`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "gapId": "gap_123",
      "userId": "user_123",
      "userName": "สมชาย ใจดี",
      "cropType": "กัญชา",
      "submittedAt": "2026-01-28T10:00:00Z",
      "status": "pending_review"
    }
  ]
}
```

**Checklist:**
- [ ] Admin เห็น GAP submissions
- [ ] Filter ตามสถานะ
- [ ] ดูรายละเอียดได้
- [ ] Approve/Reject GAP

---

### 15. Approve/Reject GAP
**Endpoint:** `POST /api/admin/gap/:gapId/review`

**Request:**
```json
{
  "adminId": "admin_123",
  "action": "approve",
  "notes": "ตรวจสอบเอกสารเรียบร้อย",
  "conditions": [
    "ต้องมีการตรวจสอบภาคสนาม",
    "ต้องรายงานผลทุก 3 เดือน"
  ]
}
```

**Checklist:**
- [ ] Admin สามารถอนุมัติ GAP
- [ ] Admin สามารถปฏิเสธ GAP พร้อมเหตุผล
- [ ] ระบุเงื่อนไขเพิ่มเติมได้
- [ ] User ได้รับ notification
- [ ] บันทึก audit log

---

## 👑 Super Admin APIs

### 13. Get All Users
**Endpoint:** `GET /api/superadmin/users`

**Query Params:**
```
?page=1&pageSize=50&province=เชียงใหม่&status=approved&search=สมชาย
```

**Checklist:**
- [ ] Pagination ทำงานได้
- [ ] Filter Multiple Criteria
- [ ] Search ทำงานได้
- [ ] Export ข้อมูล (CSV/Excel)
- [ ] Performance ดี (ข้อมูลเยอะ)

---

### 14. Get All Admins
**Endpoint:** `GET /api/superadmin/admins`

**Checklist:**
- [ ] แสดงรายชื่อ Admin ทั้งหมด
- [ ] Add/Edit/Delete Admin
- [ ] Suspend/Activate Admin
- [ ] Reset PIN

---

### 15. Get Dashboard Stats
**Endpoint:** `GET /api/superadmin/dashboard`

**Response:**
```json
{
  "success": true,
  "data": {
    "totalUsers": 1500,
    "pendingUsers": 45,
    "approvedUsers": 1400,
    "rejectedUsers": 55,
    "totalAdmins": 20,
    "usersByProvince": {
      "เชียงใหม่": 300,
      "กรุงเทพฯ": 500
    },
    "usersByOccupation": {
      "เกษตรกร": 800,
      "ประมง": 300,
      "ปศุสัตว์": 400
    },
    "registrationTrend": [
      { "date": "2026-01", "count": 150 },
      { "date": "2026-02", "count": 200 }
    ]
  }
}
```

**Checklist:**
- [ ] แสดงกราฟสถิติ
- [ ] Real-time Update
- [ ] Filter ตามช่วงเวลา
- [ ] Export Reports
- [ ] Performance ดี

---

## 🗺️ Location APIs

### 16. Get Provinces
**Endpoint:** `GET /api/location/provinces`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "province_01",
      "name": "เชียงใหม่",
      "region": "ภาคเหนือ"
    },
    {
      "id": "province_02",
      "name": "กรุงเทพมหานคร",
      "region": "ภาคกลาง"
    }
  ]
}
```

**Checklist:**
- [ ] แสดงชื่อจังหวัดถูกต้อง
- [ ] ไม่มีตัวอักษรเพี้ยน (UTF-8 Encoding)
- [ ] Group ตามภูมิภาค
- [ ] Search ได้
- [ ] Cache ข้อมูล

**Known Issue Fixed:**
- ✅ จังหวัดตาก แสดงภาษาเพี้ยน → แก้ไขด้วย UTF-8 Encoding

---

### 17. Get Districts
**Endpoint:** `GET /api/location/districts/:provinceId`

**Checklist:**
- [ ] Cascade Loading (Province → District → SubDistrict)
- [ ] Performance ดี
- [ ] Cache ข้อมูล

---

### 18. Get Sub Districts
**Endpoint:** `GET /api/location/subdistricts/:districtId`

**Checklist:**
- [ ] แสดงข้อมูลครบถ้วน
- [ ] Performance ดี

---

## 📊 Statistics APIs

### 19. Get User Statistics
**Endpoint:** `GET /api/stats/users`

**Checklist:**
- [ ] แสดงสถิติตามภูมิภาค
- [ ] แสดงสถิติตามอาชีพ
- [ ] Graph Visualization
- [ ] Export ได้

---

## 🔔 Notification APIs

### 20. Get Notifications
**Endpoint:** `GET /api/notifications/:userId`

**Checklist:**
- [ ] Push Notification Setup
- [ ] In-App Notification
- [ ] Badge Count
- [ ] Mark as Read
- [ ] Delete Notification

---

## 📝 Occupation Data

### อาชีพที่เกี่ยวข้องกับรัฐวิสาหกิจชุมชน

**ข้อมูลที่ควรมี:**
```json
{
  "occupations": [
    {
      "id": "occ_01",
      "name": "เกษตรกร",
      "category": "เกษตรกรรม",
      "icon": "🌾"
    },
    {
      "id": "occ_02",
      "name": "ประมง",
      "category": "เกษตรกรรม",
      "icon": "🐟"
    },
    {
      "id": "occ_03",
      "name": "ปศุสัตว์",
      "category": "เกษตรกรรม",
      "icon": "🐄"
    },
    {
      "id": "occ_04",
      "name": "แปรรูปสินค้าเกษตร",
      "category": "อุตสาหกรรม",
      "icon": "🏭"
    },
    {
      "id": "occ_05",
      "name": "หัตถกรรม",
      "category": "อุตสาหกรรม",
      "icon": "🎨"
    },
    {
      "id": "occ_06",
      "name": "ทอผ้า",
      "category": "อุตสาหกรรม",
      "icon": "🧵"
    },
    {
      "id": "occ_07",
      "name": "ค้าขาย/ร้านค้าชุมชน",
      "category": "พาณิชยกรรม",
      "icon": "🏪"
    },
    {
      "id": "occ_08",
      "name": "ท่องเที่ยวชุมชน",
      "category": "บริการ",
      "icon": "🏞️"
    },
    {
      "id": "occ_09",
      "name": "โฮมสเตย์",
      "category": "บริการ",
      "icon": "🏠"
    },
    {
      "id": "occ_10",
      "name": "สหกรณ์",
      "category": "องค์กร",
      "icon": "🤝"
    },
    {
      "id": "occ_11",
      "name": "กลุ่มออมทรัพย์",
      "category": "การเงิน",
      "icon": "💰"
    },
    {
      "id": "occ_12",
      "name": "วิสาหกิจชุมชน",
      "category": "องค์กร",
      "icon": "🏢"
    },
    {
      "id": "occ_13",
      "name": "แปรรูปอาหาร",
      "category": "อุตสาหกรรม",
      "icon": "🍱"
    },
    {
      "id": "occ_14",
      "name": "สมุนไพร",
      "category": "เกษตรกรรม",
      "icon": "🌿"
    },
    {
      "id": "occ_15",
      "name": "พลังงานทดแทน",
      "category": "พลังงาน",
      "icon": "⚡"
    },
    {
      "id": "occ_16",
      "name": "รีไซเคิล/จัดการขยะ",
      "category": "สิ่งแวดล้อม",
      "icon": "♻️"
    },
    {
      "id": "occ_17",
      "name": "การเกษตรอินทรีย์",
      "category": "เกษตรกรรม",
      "icon": "🌱"
    },
    {
      "id": "occ_18",
      "name": "อื่นๆ",
      "category": "ทั่วไป",
      "icon": "📋",
      "requiresDetail": true
    }
  ]
}
```

**Checklist:**
- [ ] มีตัวเลือกอาชีพครบถ้วน
- [ ] ไม่ใช่แค่ "อื่นๆ" เพียงอย่างเดียว
- [ ] ถ้าเลือก "อื่นๆ" ต้องระบุรายละเอียด
- [ ] Icon แสดงผลสวยงาม
- [ ] Group ตาม Category

---

## 🔄 API Error Handling

### Standard Error Response
```json
{
  "success": false,
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "ไม่พบข้อมูลผู้ใช้",
    "details": {}
  }
}
```

### Error Codes
| Code | Message | Action |
|------|---------|--------|
| AUTH_FAILED | การยืนยันตัวตนล้มเหลว | Redirect to Login |
| TOKEN_EXPIRED | Token หมดอายุ | Refresh Token |
| INVALID_PIN | PIN ไม่ถูกต้อง | Show Error, Count Attempts |
| USER_NOT_FOUND | ไม่พบข้อมูลผู้ใช้ | Show Error Message |
| NETWORK_ERROR | ไม่สามารถเชื่อมต่อได้ | Retry, Show Offline Mode |
| VALIDATION_ERROR | ข้อมูลไม่ถูกต้อง | Show Field Errors |
| PERMISSION_DENIED | ไม่มีสิทธิ์เข้าถึง | Show Error, Redirect |
| SERVER_ERROR | เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ | Retry, Contact Support |

### Error Handling Pattern
```javascript
try {
  setLoading(true);
  const response = await apiCall();
  
  if (response.success) {
    // Handle success
    showSuccessMessage(response.message);
    updateUI(response.data);
  } else {
    // Handle API error
    handleApiError(response.error);
  }
} catch (error) {
  // Handle network error
  if (error.code === 'NETWORK_ERROR') {
    showRetryDialog();
  } else {
    showErrorMessage('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง');
  }
} finally {
  setLoading(false);
}
```

---

## 🚀 API Performance Optimization

### Caching Strategy
```javascript
const CACHE_CONFIG = {
  provinces: { ttl: 86400000 }, // 24 hours
  districts: { ttl: 86400000 }, // 24 hours
  userProfile: { ttl: 300000 }, // 5 minutes
  pendingUsers: { ttl: 60000 }, // 1 minute
  dashboard: { ttl: 180000 }, // 3 minutes
};
```

### Request Batching
```javascript
// Batch multiple requests
const [profile, stats, notifications] = await Promise.all([
  getUserProfile(userId),
  getUserStats(userId),
  getNotifications(userId),
]);
```

### Retry Logic
```javascript
async function apiCallWithRetry(apiFunc, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await apiFunc();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await sleep(1000 * (i + 1)); // Exponential backoff
    }
  }
}
```

---

## ✅ API Integration Testing Checklist

### Pre-Production Tests
- [ ] ทดสอบทุก Endpoint
- [ ] ทดสอบ Error Cases
- [ ] ทดสอบ Network Timeout
- [ ] ทดสอบ Offline Mode
- [ ] ทดสอบ Token Refresh
- [ ] ทดสอบ Concurrent Requests
- [ ] ทดสอบ Large Data Sets
- [ ] ทดสอบ Image Upload (Size Limits)
- [ ] ทดสอบ Pagination
- [ ] Load Testing (100+ users)

### Monitoring
- [ ] API Response Time Tracking
- [ ] Error Rate Monitoring
- [ ] Success Rate Monitoring
- [ ] Crash Reporting Integration
- [ ] Analytics Events

---

## 📚 API Documentation

**ต้องมีเอกสาร:**
- [ ] Swagger/OpenAPI Spec
- [ ] Postman Collection
- [ ] API Change Log
- [ ] Versioning Strategy
- [ ] Deprecation Policy

---

**สำคัญ:** API ต้องพร้อมก่อน Deploy และต้องมี Fallback/Offline Mode
