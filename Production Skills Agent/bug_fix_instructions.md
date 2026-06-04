# คำสั่ง AI Agent: แก้ไข Bug และตรวจสอบความปลอดภัย Drug Plant API Application

## 🎯 วัตถุประสงค์
ให้ AI Agent ดำเนินการแก้ไข Bug ที่ระบุและตรวจสอบความปลอดภัยของ Application อย่างเป็นระบบ แบ่งเป็น 4 ระดับความสำคัญ

---

## ⚠️ BUG PRIORITY 1: Token Refresh ไม่ทำงาน (CRITICAL)

### 📋 รายละเอียดปัญหา
จาก Log ที่ให้มา:
```
🔑 Got 401 - attempting refresh token...
🔑 Refresh token exists: true
🔄 Calling refresh endpoint...
❌ Refresh failed with error: DioException [bad response]: status code 400
Response: {message: Token expired. Please sign in again., error: Unauthorized, statusCode: 401}
```

**ปัญหา:** Refresh Token Mechanism ไม่ทำงาน ส่งผลให้ User ต้อง Login ใหม่ตลอดเวลา

### ✅ งานที่ต้องทำ

#### 1.1 ตรวจสอบและแก้ไขฝั่ง Backend API
```bash
# คำสั่งสำหรับ AI Agent
1. ค้นหาไฟล์ Authentication Controller/Service ใน Backend
2. ตรวจสอบ endpoint `/auth/refresh`
3. ยืนยันว่า:
   - Endpoint รับ refreshToken จาก Header หรือ Body อย่างถูกต้อง
   - Logic การตรวจสอบ refreshToken ทำงานได้
   - refreshToken ไม่หมดอายุเร็วเกินไป (แนะนำ 7-30 วัน)
   - Response ส่ง accessToken และ refreshToken ใหม่กลับมา
```

**ตัวอย่าง Code ที่ควรเป็น (Node.js/NestJS):**
```typescript
// auth.service.ts
async refreshTokens(refreshToken: string) {
  try {
    // 1. Verify refresh token
    const payload = await this.jwtService.verifyAsync(refreshToken, {
      secret: process.env.JWT_REFRESH_SECRET
    });
    
    // 2. ตรวจสอบว่า token ยังไม่ถูก revoke
    const isRevoked = await this.isTokenRevoked(refreshToken);
    if (isRevoked) {
      throw new UnauthorizedException('Token has been revoked');
    }
    
    // 3. Generate new tokens
    const newAccessToken = await this.generateAccessToken(payload);
    const newRefreshToken = await this.generateRefreshToken(payload);
    
    // 4. บันทึก refresh token ใหม่ (optional: revoke token เก่า)
    await this.saveRefreshToken(payload.sub, newRefreshToken);
    
    return {
      accessToken: newAccessToken,
      refreshToken: newRefreshToken
    };
  } catch (error) {
    throw new UnauthorizedException('Invalid refresh token');
  }
}
```

#### 1.2 ตรวจสอบและแก้ไขฝั่ง Frontend (Flutter)
```dart
// ค้นหาไฟล์ API Client / Interceptor
// ตรวจสอบ Refresh Token Logic

class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // 1. ตรวจสอบว่าไม่ใช่ refresh endpoint (ป้องกัน infinite loop)
      if (err.requestOptions.path.contains('/auth/refresh')) {
        // ถ้า refresh ล้มเหลว -> ให้ logout
        await _authService.logout();
        return handler.reject(err);
      }
      
      // 2. ลองทำ refresh
      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null) {
          await _authService.logout();
          return handler.reject(err);
        }
        
        // 3. เรียก refresh endpoint
        final response = await _dio.post('/auth/refresh',
          data: {'refreshToken': refreshToken}, // หรือใส่ใน header
          options: Options(headers: {
            'Authorization': 'Bearer $refreshToken' // ถ้า API ต้องการ
          })
        );
        
        // 4. บันทึก token ใหม่
        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];
        await _storage.saveTokens(newAccessToken, newRefreshToken);
        
        // 5. Retry request เดิมด้วย access token ใหม่
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
        
      } catch (refreshError) {
        // Refresh ล้มเหลว -> logout
        await _authService.logout();
        return handler.reject(err);
      }
    }
    
    return handler.next(err);
  }
}
```

#### 1.3 ตรวจสอบ API Endpoint Configuration
```yaml
# ตรวจสอบว่า endpoint ถูกต้องหรือไม่
# Flutter: ตรวจสอบไฟล์ api_config.dart หรือ .env

BASE_URL=http://10.0.2.2:3000/api/v1
REFRESH_TOKEN_ENDPOINT=/auth/refresh  # ตรวจสอบว่าถูกต้อง
```

#### 1.4 Testing Plan
```bash
# สร้าง Test Cases
1. ทดสอบ Login -> รอให้ Access Token หมดอายุ -> เรียก API -> ควร refresh สำเร็จ
2. ทดสอบ Refresh Token หมดอายุ -> ควร redirect ไป Login
3. ทดสอบ Network Error ระหว่าง Refresh -> ควรแสดง Error Message
4. ทดสอบ Concurrent Requests ระหว่าง Refresh -> ควรรอ Refresh เสร็จก่อนทำต่อ
```

---

## 🔒 PRIORITY 2: ความปลอดภัย API Key (HIGH)

### 📋 ปัญหา: GEMINI API Key ถูก Hardcode
**ความเสี่ยง:** API Key อาจถูก Decompile จาก APK และนำไปใช้งานโดยไม่ได้รับอนุญาต

### ✅ งานที่ต้องทำ

#### 2.1 ย้าย API Key ไปฝั่ง Backend
```typescript
// Backend: สร้าง Proxy Endpoint สำหรับเรียก Gemini
// gemini.controller.ts

@Controller('ai')
export class GeminiController {
  constructor(private geminiService: GeminiService) {}
  
  @Post('generate')
  @UseGuards(JwtAuthGuard)
  async generate(@Body() dto: GenerateDto, @User() user: any) {
    // Rate limiting per user
    await this.checkRateLimit(user.id);
    
    // เรียก Gemini API ด้วย API Key จาก Environment Variable
    return await this.geminiService.generate(dto.prompt, {
      userId: user.id,
      maxTokens: dto.maxTokens || 1000
    });
  }
}
```

```typescript
// gemini.service.ts
import { GoogleGenerativeAI } from '@google/generative-ai';

@Injectable()
export class GeminiService {
  private genAI: GoogleGenerativeAI;
  
  constructor() {
    // API Key จาก Environment Variable
    this.genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  }
  
  async generate(prompt: string, options: any) {
    const model = this.genAI.getGenerativeModel({ model: 'gemini-pro' });
    
    // Validate และ Sanitize input
    if (prompt.length > 5000) {
      throw new BadRequestException('Prompt too long');
    }
    
    const result = await model.generateContent(prompt);
    const response = await result.response;
    
    // Log usage
    await this.logUsage(options.userId, response.usage);
    
    return {
      text: response.text(),
      usage: response.usage
    };
  }
}
```

#### 2.2 ใช้ Environment Variables
```bash
# Backend: .env
GEMINI_API_KEY=your_actual_api_key_here

# .env.example (commit ลง git)
GEMINI_API_KEY=your_gemini_api_key

# .gitignore
.env
.env.local
```

#### 2.3 ลบ API Key ออกจาก Frontend
```dart
// ❌ ลบ Code นี้
const String geminiApiKey = 'AIzaSy...';

// ✅ เปลี่ยนเป็นเรียกผ่าน Backend
class AIService {
  final ApiClient _apiClient;
  
  Future<String> generateContent(String prompt) async {
    final response = await _apiClient.post('/ai/generate', {
      'prompt': prompt,
      'maxTokens': 1000
    });
    
    return response.data['text'];
  }
}
```

#### 2.4 ตั้งค่า Rate Limiting (ป้องกันการใช้งานเกิน)
```typescript
// Backend: rate-limit.guard.ts
import { Injectable, CanActivate, HttpException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RateLimiterMemory } from 'rate-limiter-flexible';

@Injectable()
export class RateLimitGuard implements CanActivate {
  private rateLimiter = new RateLimiterMemory({
    points: 100, // จำนวน requests
    duration: 3600, // per hour
  });
  
  async canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const userId = request.user?.id;
    
    try {
      await this.rateLimiter.consume(userId);
      return true;
    } catch {
      throw new HttpException('Too many requests', 429);
    }
  }
}
```

#### 2.5 Monitor และ Alert
```typescript
// Backend: ติดตั้ง monitoring
// gemini.service.ts

async logUsage(userId: string, usage: any) {
  await this.prisma.apiUsageLog.create({
    data: {
      userId,
      service: 'GEMINI',
      tokensUsed: usage.totalTokens,
      cost: this.calculateCost(usage.totalTokens),
      timestamp: new Date()
    }
  });
  
  // Alert ถ้าใช้เกินวงเงิน
  const dailyUsage = await this.getDailyUsage();
  if (dailyUsage > 1000) { // $1000/day
    await this.sendAlert('High API usage detected');
  }
}
```

---

## 🐛 PRIORITY 3: ตรวจสอบ Bug หลังบันทึก GAP (MEDIUM)

### 📋 ปัญหาที่ต้องตรวจสอบ
เมื่อบันทึกข้อมูล GAP 1.1-1.6 แล้วกดเข้าไปดูอีกครั้ง อาจมีข้อมูลผิดพลาดหรือแสดงผลไม่ถูกต้อง

### ✅ งานที่ต้องทำ

#### 3.1 สร้าง Test Cases แบบครอบคลุม
```typescript
// Backend: __tests__/gap.e2e.spec.ts

describe('GAP Forms End-to-End', () => {
  let plotId: string;
  let accessToken: string;
  
  beforeAll(async () => {
    // Setup test plot
    plotId = await createTestPlot();
    accessToken = await loginAsTestUser();
  });
  
  describe('GAP 1.1 - General Info', () => {
    it('should save and retrieve complete form data', async () => {
      const formData = {
        seasonLabel: 'รอบปลูก 2568/1',
        startDate: '2024-01-01',
        farmerName: 'สมชาย ใจดี',
        farmingSystem: 'NON_ORGANIC',
        waterSource: 'น้ำฝน',
        cropType: 'ผัก'
      };
      
      // 1. บันทึก
      await request(app.getHttpServer())
        .put(`/plots/${plotId}/gap`)
        .set('Authorization', `Bearer ${accessToken}`)
        .send(formData)
        .expect(200);
      
      // 2. ดึงข้อมูลกลับมา
      const response = await request(app.getHttpServer())
        .get(`/plots/${plotId}/gap`)
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      
      // 3. ตรวจสอบว่าข้อมูลถูกต้อง
      expect(response.body.seasonLabel).toBe(formData.seasonLabel);
      expect(response.body.startDate).toBe(formData.startDate);
      expect(response.body.farmingSystem).toBe(formData.farmingSystem);
    });
    
    it('should handle Thai characters correctly', async () => {
      const formData = {
        seasonLabel: 'รอบปลูก 2568/1 ภาคฤดูร้อน',
        farmerName: 'สมชาย ใจดี'
      };
      
      await request(app.getHttpServer())
        .put(`/plots/${plotId}/gap`)
        .send(formData)
        .expect(200);
      
      const response = await request(app.getHttpServer())
        .get(`/plots/${plotId}/gap`)
        .expect(200);
      
      // ตรวจสอบภาษาไทยไม่เพี้ยน
      expect(response.body.seasonLabel).toBe(formData.seasonLabel);
    });
  });
  
  describe('GAP 1.2 - Inputs', () => {
    it('should save and retrieve input records', async () => {
      const inputData = {
        type: 'FERTILIZER',
        name: 'ปุ๋ยยูเรีย',
        amount: 10,
        unit: 'kg',
        usedDate: '2024-02-01',
        source: 'ร้านเกษตรไทย'
      };
      
      // บันทึก
      const createResponse = await request(app.getHttpServer())
        .post(`/plots/${plotId}/inputs`)
        .send(inputData)
        .expect(201);
      
      const inputId = createResponse.body.id;
      
      // ดึงรายการ
      const listResponse = await request(app.getHttpServer())
        .get(`/plots/${plotId}/inputs`)
        .expect(200);
      
      const savedInput = listResponse.body.find(i => i.id === inputId);
      expect(savedInput.name).toBe(inputData.name);
      expect(savedInput.amount).toBe(inputData.amount);
    });
  });
  
  // เพิ่ม test สำหรับ GAP 1.3-1.6 ต่อไปในรูปแบบเดียวกัน
});
```

#### 3.2 ตรวจสอบ Database Schema
```sql
-- ตรวจสอบว่า columns ทั้งหมดมี charset และ collation ถูกต้อง
SHOW FULL COLUMNS FROM gap_general_info;
SHOW FULL COLUMNS FROM gap_inputs;
SHOW FULL COLUMNS FROM gap_field_activities;
SHOW FULL COLUMNS FROM gap_harvests;

-- ถ้าไม่ใช่ utf8mb4, ต้องแก้ไข
ALTER TABLE gap_general_info CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE gap_inputs CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### 3.3 ตรวจสอบ Date/Time Handling
```typescript
// Backend: ตรวจสอบว่า Date serialization ทำงานถูกต้อง
// gap.service.ts

async getGapData(plotId: string) {
  const data = await this.prisma.gapGeneralInfo.findFirst({
    where: { plotId }
  });
  
  if (!data) return null;
  
  // ✅ แปลง Date เป็น ISO String สำหรับ Frontend
  return {
    ...data,
    startDate: data.startDate ? data.startDate.toISOString().split('T')[0] : null,
    createdAt: data.createdAt.toISOString(),
    updatedAt: data.updatedAt.toISOString()
  };
}
```

```dart
// Flutter: ตรวจสอบ Date parsing
class GapFormModel {
  final String? startDate;
  
  factory GapFormModel.fromJson(Map<String, dynamic> json) {
    return GapFormModel(
      // ✅ ตรวจสอบว่า parse ได้ทุกรูปแบบ
      startDate: json['startDate'] != null 
        ? _parseDate(json['startDate'])
        : null,
    );
  }
  
  static String? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      // รองรับทั้ง ISO String และ Date String
      final date = DateTime.parse(value.toString());
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }
}
```

#### 3.4 ตรวจสอบ Enum Values
```typescript
// Backend: ตรวจสอบว่า Enum ตรงกันระหว่าง Frontend-Backend
// gap.entity.ts

export enum FarmingSystem {
  ORGANIC = 'ORGANIC',
  NON_ORGANIC = 'NON_ORGANIC',
  GAP_TRANSITION = 'GAP_TRANSITION'
}

export enum InputType {
  SEED = 'SEED',
  FERTILIZER = 'FERTILIZER',
  CHEMICAL = 'CHEMICAL',
  OTHER = 'OTHER'
}
```

```dart
// Flutter: ต้องตรงกับ Backend
enum FarmingSystem {
  ORGANIC,
  NON_ORGANIC,
  GAP_TRANSITION;
  
  String get value => name;
  
  static FarmingSystem? fromString(String? value) {
    if (value == null) return null;
    return FarmingSystem.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FarmingSystem.NON_ORGANIC,
    );
  }
}
```

#### 3.5 สร้าง Debug Screen
```dart
// Flutter: เพิ่ม Debug Screen แสดงข้อมูล Raw
class GapDebugScreen extends StatelessWidget {
  final String plotId;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GAP Debug')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _apiClient.get('/plots/$plotId/gap'),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Raw Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      jsonEncode(snapshot.data, indent: 2),
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            );
          }
          return CircularProgressIndicator();
        },
      ),
    );
  }
}
```

---

## 🔍 PRIORITY 4: การตรวจสอบและป้องกันเพิ่มเติม (LOW-MEDIUM)

### ✅ งานที่ต้องทำ

#### 4.1 ป้องกัน SQL Injection
```typescript
// Backend: ตรวจสอบว่าใช้ Parameterized Queries
// ❌ อย่าทำแบบนี้
const result = await db.query(`SELECT * FROM plots WHERE id = '${plotId}'`);

// ✅ ใช้ ORM หรือ Parameterized Query
const result = await prisma.plot.findUnique({ where: { id: plotId } });
```

#### 4.2 Validate Input ทุก Endpoint
```typescript
// Backend: ใช้ class-validator
import { IsString, IsNumber, IsEnum, IsOptional, Min, Max } from 'class-validator';

export class CreateInputDto {
  @IsEnum(InputType)
  type: InputType;
  
  @IsString()
  @Length(1, 100)
  name: string;
  
  @IsNumber()
  @Min(0)
  @Max(999999)
  amount: number;
  
  @IsString()
  @Length(1, 20)
  unit: string;
  
  @IsDateString()
  usedDate: string;
  
  @IsOptional()
  @IsString()
  @MaxLength(500)
  source?: string;
}
```

#### 4.3 ตรวจสอบ File Upload Security
```typescript
// Backend: ป้องกัน Malicious File Upload
import { diskStorage } from 'multer';
import { extname } from 'path';

const allowedMimeTypes = [
  'image/jpeg',
  'image/png',
  'image/webp'
];

const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

@Post('upload')
@UseInterceptors(FileInterceptor('file', {
  storage: diskStorage({
    destination: './uploads',
    filename: (req, file, callback) => {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      callback(null, `${uniqueSuffix}${extname(file.originalname)}`);
    }
  }),
  fileFilter: (req, file, callback) => {
    // ตรวจสอบ MIME type
    if (!allowedMimeTypes.includes(file.mimetype)) {
      return callback(new BadRequestException('Invalid file type'), false);
    }
    
    // ตรวจสอบ extension
    const ext = extname(file.originalname).toLowerCase();
    if (!allowedExtensions.includes(ext)) {
      return callback(new BadRequestException('Invalid file extension'), false);
    }
    
    callback(null, true);
  },
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB
  }
}))
async uploadFile(@UploadedFile() file: Express.Multer.File) {
  // เพิ่มการตรวจสอบ file content (magic numbers)
  const isValid = await this.validateImageFile(file.path);
  if (!isValid) {
    fs.unlinkSync(file.path); // ลบไฟล์ปลอม
    throw new BadRequestException('Invalid image file');
  }
  
  return {
    url: `/uploads/${file.filename}`,
    filename: file.filename
  };
}
```

#### 4.4 เพิ่ม Logging และ Monitoring
```typescript
// Backend: เพิ่ม comprehensive logging
import { Logger } from '@nestjs/common';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private logger = new Logger('HTTP');
  
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url, body, user } = request;
    
    this.logger.log(`${method} ${url} - User: ${user?.id}`);
    
    return next.handle().pipe(
      tap({
        next: (data) => {
          this.logger.log(`${method} ${url} - Success`);
        },
        error: (error) => {
          this.logger.error(`${method} ${url} - Error: ${error.message}`);
        }
      })
    );
  }
}
```

#### 4.5 ตั้งค่า CORS อย่างปลอดภัย
```typescript
// Backend: main.ts
app.enableCors({
  origin: [
    'http://localhost:3000',
    'https://yourdomain.com',
    // ❌ ไม่ควรใช้ '*' ใน production
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
});
```

#### 4.6 เพิ่ม Health Check Endpoint
```typescript
// Backend: health.controller.ts
@Controller('health')
export class HealthController {
  @Get()
  check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      database: 'connected', // ตรวจสอบ DB connection
      version: process.env.APP_VERSION
    };
  }
}
```

---

## 📊 Checklist สำหรับ AI Agent

### Phase 1: Critical Bugs (วันที่ 1)
- [ ] แก้ไข Token Refresh Mechanism (Backend + Frontend)
- [ ] ทดสอบ Token Refresh ในทุกสถานการณ์
- [ ] Deploy และทดสอบใน Production-like Environment

### Phase 2: Security (วันที่ 2)
- [ ] ย้าย Gemini API Key ไปฝั่ง Backend
- [ ] ตั้งค่า Rate Limiting
- [ ] ตั้งค่า Monitoring สำหรับ API Usage
- [ ] ลบ API Key ออกจาก Frontend Code
- [ ] Commit changes และ update .gitignore

### Phase 3: GAP Forms Testing (วันที่ 3-4)
- [ ] สร้าง E2E Tests สำหรับ GAP 1.1-1.6
- [ ] ทดสอบภาษาไทย, Date/Time, Enums
- [ ] แก้ไข Bug ที่พบจากการ Test
- [ ] สร้าง Debug Screen (Optional)

### Phase 4: Security Hardening (วันที่ 5)
- [ ] ตรวจสอบ SQL Injection vulnerabilities
- [ ] เพิ่ม Input Validation
- [ ] ปรับปรุง File Upload Security
- [ ] ตั้งค่า Logging และ Monitoring
- [ ] ตรวจสอบ CORS Configuration

### Phase 5: Final Testing (วันที่ 6-7)
- [ ] Integration Testing ทั้งระบบ
- [ ] Performance Testing
- [ ] Security Scan (OWASP ZAP, Snyk)
- [ ] Code Review
- [ ] Documentation Update

---

## 🚀 คำสั่งเฉพาะสำหรับ AI Agent

### ขั้นตอนการทำงาน
```bash
# Step 1: Clone และ Setup Project
git clone <repository>
cd drug-plant-api
npm install

# Step 2: สร้าง Branch สำหรับแก้ Bug
git checkout -b fix/critical-bugs-and-security

# Step 3: แก้ไข Code ตาม Priority
# - เริ่มจาก Priority 1 (Token Refresh)
# - จากนั้น Priority 2 (API Key Security)
# - ตามด้วย Priority 3 และ 4

# Step 4: Run Tests
npm run test
npm run test:e2e

# Step 5: Commit และ Push
git add .
git commit -m "fix: resolve token refresh and security issues"
git push origin fix/critical-bugs-and-security

# Step 6: สร้าง Pull Request
```

### การรายงานผล
AI Agent ต้องสร้างไฟล์ `FIXES_REPORT.md` พร้อม:
1. รายการ Bug ที่แก้ไขแล้ว
2. Code Changes สำคัญ
3. Test Results
4. Security Improvements
5. Known Issues (ถ้ามี)
6. Recommendations

---

## 📞 หมายเหตุสำคัญ

### ข้อควรระวัง
1. **อย่าลบ Code เดิมทิ้งทันที** - Comment ไว้ก่อนเผื่อต้องย้อนกลับ
2. **Backup Database** ก่อนทำการ Migration
3. **Test บน Staging** ก่อน Deploy Production
4. **แจ้ง Users** หาก มีการ Breaking Changes

### Contact Points
- Backend API Issue → ตรวจสอบ Logs ใน Server
- Flutter Issue → ตรวจสอบ Logcat/Console
- Database Issue → ตรวจสอบ Query Logs

### Resources
- API Documentation: `/docs` (อ้างอิงจากเอกสารที่แนบมา)
- Postman Collection: สำหรับทดสอบ API
- Flutter DevTools: สำหรับ Debug Frontend

---

**สร้างโดย:** AI Assistant  
**วันที่:** 2024-02-02  
**Version:** 1.0
