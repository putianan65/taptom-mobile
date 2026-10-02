# AI Agent Quick Action Commands
# คำสั่งที่พร้อม Execute ทันที

## IMMEDIATE ACTION: Fix Token Refresh (30 mins)

### Backend Fix
```bash
# 1. เปิดไฟล์ auth service
# ค้นหาไฟล์: src/auth/auth.service.ts หรือ auth.controller.ts

# 2. เพิ่ม/แก้ไข refresh endpoint
```

```typescript
// auth.controller.ts
@Post('refresh')
async refresh(@Body() body: { refreshToken: string }) {
  return this.authService.refreshTokens(body.refreshToken);
}

// auth.service.ts
async refreshTokens(refreshToken: string) {
  try {
    const decoded = this.jwtService.verify(refreshToken, {
      secret: process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET
    });
    
    const user = await this.usersService.findOne(decoded.sub);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }
    
    const accessToken = this.generateAccessToken(user);
    const newRefreshToken = this.generateRefreshToken(user);
    
    return {
      accessToken,
      refreshToken: newRefreshToken,
      user: {
        id: user.id,
        role: user.role,
        phone: user.phone
      }
    };
  } catch (error) {
    throw new UnauthorizedException('Invalid refresh token');
  }
}
```

### Frontend Fix (Flutter)
```bash
# ค้นหาไฟล์: lib/services/api_interceptor.dart หรือ lib/services/api_client.dart
```

```dart
// api_interceptor.dart
@override
void onError(DioException err, ErrorInterceptorHandler handler) async {
  if (err.response?.statusCode == 401) {
    final requestPath = err.requestOptions.path;
    
    // ป้องกัน infinite loop
    if (requestPath.contains('/auth/refresh') || 
        requestPath.contains('/auth/signin')) {
      await _clearTokensAndRedirect();
      return handler.reject(err);
    }
    
    try {
      final refreshToken = await _secureStorage.read(key: 'refreshToken');
      
      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearTokensAndRedirect();
        return handler.reject(err);
      }
      
      // เรียก refresh
      final response = await Dio().post(
        '${_baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status! < 500,
        ),
      );
      
      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];
        
        await _secureStorage.write(key: 'accessToken', value: newAccessToken);
        await _secureStorage.write(key: 'refreshToken', value: newRefreshToken);
        
        // Retry original request
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } else {
        await _clearTokensAndRedirect();
        return handler.reject(err);
      }
    } catch (e) {
      print('Refresh token error: $e');
      await _clearTokensAndRedirect();
      return handler.reject(err);
    }
  }
  
  return handler.next(err);
}

Future<void> _clearTokensAndRedirect() async {
  await _secureStorage.delete(key: 'accessToken');
  await _secureStorage.delete(key: 'refreshToken');
  // Navigate to login
  // Get.offAllNamed('/login'); // ถ้าใช้ GetX
}
```

### Quick Test
```bash
# Test refresh token
curl -X POST http://localhost:3000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "YOUR_REFRESH_TOKEN"}'

# ควรได้ response
# {"accessToken": "...", "refreshToken": "..."}
```

---

## IMMEDIATE ACTION: Secure Gemini API Key (20 mins)

### Step 1: Backend Proxy (ต้องทำก่อน)
```bash
# สร้างไฟล์ใหม่: src/gemini/gemini.module.ts
```

```typescript
// gemini.module.ts
import { Module } from '@nestjs/common';
import { GeminiController } from './gemini.controller';
import { GeminiService } from './gemini.service';

@Module({
  controllers: [GeminiController],
  providers: [GeminiService],
  exports: [GeminiService]
})
export class GeminiModule {}
```

```typescript
// gemini.service.ts
import { Injectable, BadRequestException } from '@nestjs/common';
import { GoogleGenerativeAI } from '@google/generative-ai';

@Injectable()
export class GeminiService {
  private genAI: GoogleGenerativeAI;
  
  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY not configured');
    }
    this.genAI = new GoogleGenerativeAI(apiKey);
  }
  
  async generateContent(prompt: string, maxTokens: number = 1000) {
    if (!prompt || prompt.length === 0) {
      throw new BadRequestException('Prompt is required');
    }
    
    if (prompt.length > 5000) {
      throw new BadRequestException('Prompt too long (max 5000 chars)');
    }
    
    const model = this.genAI.getGenerativeModel({ 
      model: 'gemini-pro' 
    });
    
    const result = await model.generateContent(prompt);
    const response = await result.response;
    
    return {
      text: response.text(),
      tokensUsed: response.usage?.totalTokens || 0
    };
  }
}
```

```typescript
// gemini.controller.ts
import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { GeminiService } from './gemini.service';

@Controller('ai')
@UseGuards(JwtAuthGuard)
export class GeminiController {
  constructor(private geminiService: GeminiService) {}
  
  @Post('generate')
  async generate(@Body() body: { prompt: string; maxTokens?: number }) {
    return this.geminiService.generateContent(
      body.prompt, 
      body.maxTokens
    );
  }
}
```

```bash
# เพิ่มใน app.module.ts
# imports: [..., GeminiModule]
```

### Step 2: Update .env
```bash
# เพิ่มใน .env (Backend)
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

### Step 3: Frontend Changes
```dart
// lib/services/ai_service.dart
class AIService {
  final ApiClient _apiClient;
  
  AIService(this._apiClient);
  
  Future<String> generateContent(String prompt) async {
    try {
      final response = await _apiClient.post(
        '/ai/generate',
        data: {
          'prompt': prompt,
          'maxTokens': 1000
        }
      );
      
      return response.data['text'] as String;
    } catch (e) {
      throw Exception('Failed to generate content: $e');
    }
  }
}
```

### Step 4: ลบ API Key จาก Flutter
```bash
# ค้นหาไฟล์ที่มี API Key
grep -r "AIzaSy" lib/

# ลบบรรทัดที่มี hardcoded API key
# แทนที่ด้วยการเรียก AIService ข้างบน
```

---

## IMMEDIATE ACTION: Test GAP Forms (15 mins)

### Manual Testing Script
```bash
# 1. Login
export TOKEN=$(curl -X POST http://localhost:3000/api/v1/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"phone":"0812345678","birthday":"01/01/1990"}' \
  | jq -r '.accessToken')

# 2. Create Test Plot (ถ้ายังไม่มี)
export PLOT_ID=$(curl -X POST http://localhost:3000/api/v1/plots \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name":"แปลงทดสอบ",
    "species":"ผักกาดหอม",
    "treeCount":100,
    "cropYear":2024,
    "province":"กรุงเทพ",
    "geometry":{"type":"Polygon","coordinates":[[[100.5,13.7],[100.6,13.7],[100.6,13.8],[100.5,13.8],[100.5,13.7]]]}
  }' | jq -r '.id')

# 3. Test GAP 1.1 Save
curl -X PUT http://localhost:3000/api/v1/plots/$PLOT_ID/gap \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "seasonLabel":"รอบปลูก 2568/1",
    "startDate":"2024-01-01",
    "farmerName":"สมชาย ใจดี",
    "farmingSystem":"NON_ORGANIC",
    "waterSource":"น้ำฝน",
    "cropType":"ผัก"
  }'

# 4. Test GAP 1.1 Retrieve
curl -X GET http://localhost:3000/api/v1/plots/$PLOT_ID/gap \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# 5. ตรวจสอบว่าข้อมูลครบถ้วน
# - seasonLabel ต้องเป็น "รอบปลูก 2568/1"
# - farmerName ต้องเป็น "สมชาย ใจดี" (ภาษาไทยไม่เพี้ยน)
# - startDate ต้องเป็น "2024-01-01"

# 6. Test GAP 1.2 Add Input
curl -X POST http://localhost:3000/api/v1/plots/$PLOT_ID/inputs \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type":"FERTILIZER",
    "name":"ปุ๋ยยูเรีย",
    "amount":10,
    "unit":"kg",
    "usedDate":"2024-02-01",
    "source":"ร้านเกษตรไทย"
  }'

# 7. Test GAP 1.2 List Inputs
curl -X GET http://localhost:3000/api/v1/plots/$PLOT_ID/inputs \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

### Database Check
```sql
-- เชื่อมต่อ Database และตรวจสอบ
SELECT * FROM gap_general_info ORDER BY created_at DESC LIMIT 1;
SELECT * FROM gap_inputs ORDER BY created_at DESC LIMIT 5;

-- ตรวจสอบ encoding
SHOW VARIABLES LIKE 'character_set%';
SHOW VARIABLES LIKE 'collation%';

-- ถ้า encoding ไม่ใช่ utf8mb4
ALTER DATABASE drug_plant_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

---

## Quick Checklist

```markdown
### Priority 1: Token Refresh
- [ ] แก้ Backend refresh endpoint (auth.service.ts)
- [ ] แก้ Frontend interceptor (api_interceptor.dart)
- [ ] Test manual refresh
- [ ] Test auto refresh on 401
- [ ] Test expired refresh token

### Priority 2: API Key Security
- [ ] สร้าง Backend proxy (gemini.module.ts, service, controller)
- [ ] เพิ่ม GEMINI_API_KEY ใน .env
- [ ] Update app.module.ts
- [ ] แก้ Frontend เรียกผ่าน /ai/generate
- [ ] ลบ hardcoded API key จาก Flutter
- [ ] Test AI generation

### Priority 3: GAP Forms
- [ ] Test GAP 1.1 save/retrieve
- [ ] Test GAP 1.2 inputs
- [ ] ตรวจสอบภาษาไทย
- [ ] ตรวจสอบ Date format
- [ ] ตรวจสอบ Database encoding

### Priority 4: Additional Security
- [ ] เพิ่ม Rate Limiting
- [ ] เพิ่ม Input Validation
- [ ] ตรวจสอบ File Upload
- [ ] ตั้งค่า CORS
```

---

## One-Command Deployment

```bash
# สำหรับ AI Agent ที่ต้องการ deploy ทันที

# 1. ตรวจสอบ environment
echo "Checking environment..."
npm run build

# 2. Run tests
npm run test

# 3. Database migrations (ถ้ามี)
npm run migration:run

# 4. Restart application
pm2 restart drug-plant-api

# 5. Verify
curl http://localhost:3000/health
```

---

## Tips สำหรับ AI Agent

1. **เริ่มจาก Priority 1 เสมอ** - Token Refresh สำคัญที่สุด
2. **Test ทีละ Fix** - อย่ารวม multiple fixes ใน 1 commit
3. **Backup ก่อนแก้** - git commit ก่อนทำทุกอย่าง
4. **Log everything** - console.log, print ให้เยอะเพื่อ debug
5. **ทดสอบบน Emulator/Device จริง** - อย่าเชื่อแค่ Unit Tests

---

## Emergency Rollback

```bash
# ถ้าแก้แล้วเกิด error
git reset --hard HEAD~1  # ย้อนกลับ 1 commit
git clean -fd  # ลบไฟล์ที่ไม่ได้ track

# หรือ
git stash  # เก็บการเปลี่ยนแปลง
git checkout main  # กลับไป main branch
```

---

**สร้างโดย:** AI Assistant  
**สำหรับ:** AI Agent Execution  
**ประมาณเวลา:** 1-2 ชั่วโมงสำหรับ Priority 1-2
