# Security Checklist: Drug Plant API & Flutter App

## ภาพรวม
เอกสารนี้เป็น Checklist ครอบคลุมด้านความปลอดภัยสำหรับ AI Agent ในการตรวจสอบและแก้ไขช่องโหว่

---

## 1. API Key & Secrets Management

### 1.1 ตรวจสอบ Hardcoded Secrets
```bash
# ค้นหา API Keys ที่อาจถูก hardcode
grep -r "AIzaSy" .
grep -r "sk-" .  # OpenAI key
grep -r "api_key" .
grep -r "apikey" .
grep -r "secret" .
grep -r "token" .
grep -r "password" .
```

**Bad Examples:**
```dart
// NEVER DO THIS
const String apiKey = "AIzaSyBa...xyz";
const String secret = "abc123secret";
final token = "sk-proj-...";
```

**Good Practice:**
```dart
// ใช้ Environment Variables
final apiKey = const String.fromEnvironment('API_KEY');

// เรียกผ่าน Backend
final response = await apiClient.post('/ai/generate', data: prompt);
```

### 1.2 Backend Secrets Storage
```typescript
// ใช้ Environment Variables
const apiKey = process.env.GEMINI_API_KEY;
const dbPassword = process.env.DB_PASSWORD;

// ใช้ Secret Manager (Production)
// AWS Secrets Manager
// Google Cloud Secret Manager
// Azure Key Vault
```

**Checklist:**
- [ ] ไม่มี API Key ใน Source Code
- [ ] ไม่มี API Key ใน Git History (`git log -S "AIzaSy"`)
- [ ] ใช้ `.env` file (และ `.gitignore` ด้วย)
- [ ] มี `.env.example` สำหรับ Template
- [ ] Production ใช้ Secret Manager
- [ ] CI/CD ใช้ Encrypted Variables

---

## 2. Authentication & Authorization

### 2.1 JWT Token Security

**Token Configuration:**
```typescript
// Secure JWT Settings
const accessTokenExpiry = '15m';  // 15 minutes
const refreshTokenExpiry = '7d';  // 7 days
const jwtSecret = process.env.JWT_SECRET; // At least 32 chars
```

**Security Requirements:**
- [ ] JWT Secret >= 32 characters (strong random)
- [ ] Access Token อายุสั้น (≤ 15 นาที)
- [ ] Refresh Token อายุปานกลาง (≤ 30 วัน)
- [ ] มี Token Rotation (issue new refresh token)
- [ ] มี Token Revocation (blacklist)
- [ ] ใช้ HTTPS only
- [ ] Store Tokens ใน Secure Storage (Flutter Secure Storage)

### 2.2 Refresh Token Flow

```dart
// Secure Refresh Implementation
class AuthInterceptor extends Interceptor {
  // 1. ป้องกัน Concurrent Refresh
  Future<Dio?>? _refreshFuture;
  
  // 2. ป้องกัน Infinite Loop
  if (path.contains('/auth/refresh')) {
    await _logout();
    return;
  }
  
  // 3. Lock Refresh
  if (_refreshFuture != null) {
    await _refreshFuture;
    return _retry(err);
  }
  
  // 4. Refresh
  _refreshFuture = _doRefresh();
  try {
    await _refreshFuture;
    return _retry(err);
  } finally {
    _refreshFuture = null;
  }
}
```

**Checklist:**
- [ ] Refresh Endpoint ทำงานได้
- [ ] ป้องกัน Concurrent Refresh
- [ ] ป้องกัน Infinite Loop
- [ ] Handle Network Errors
- [ ] Logout เมื่อ Refresh ล้มเหลว
- [ ] Test Token Expiry Scenarios

### 2.3 Password & PIN Security

```typescript
// Hash Passwords
import * as bcrypt from 'bcrypt';

const saltRounds = 10;
const hashedPassword = await bcrypt.hash(password, saltRounds);

// Verify
const isMatch = await bcrypt.compare(password, hashedPassword);
```

**PIN Requirements:**
```typescript
// Secure PIN
- Length: 4-6 digits
- Hashed (bcrypt)
- Rate Limited (5 attempts / 15 min)
- Auto-lock after failures
- Optional Biometric
```

**Checklist:**
- [ ] Passwords Hashed (bcrypt/argon2)
- [ ] Salt Rounds >= 10
- [ ] PINs Hashed
- [ ] Rate Limiting on Login
- [ ] Account Lockout after 5 failures
- [ ] Password Strength Requirements
- [ ] No Plain-text Passwords in Logs

---

## 3. API Security

### 3.1 Rate Limiting

```typescript
// Implementation
import { ThrottlerModule } from '@nestjs/throttler';

ThrottlerModule.forRoot({
  ttl: 60,        // Time window (seconds)
  limit: 100,     // Max requests
  ignoreUserAgents: [/bot/i], // Optional
})
```

**Rate Limits by Endpoint:**
```typescript
@Post('auth/signin')
@Throttle(5, 900)  // 5 attempts per 15 minutes
async signIn() { }

@Get('api/data')
@Throttle(100, 3600)  // 100 requests per hour
async getData() { }

@Post('upload')
@Throttle(10, 3600)  // 10 uploads per hour
async upload() { }
```

**Checklist:**
- [ ] Global Rate Limiting
- [ ] Per-Endpoint Rate Limiting
- [ ] Per-User Rate Limiting
- [ ] IP-based Rate Limiting
- [ ] Return 429 with Retry-After
- [ ] Log Rate Limit Hits

### 3.2 Input Validation

```typescript
// Validate Everything
import { IsString, IsEmail, IsPhoneNumber, IsEnum, 
         Length, Min, Max, IsOptional } from 'class-validator';

export class CreateUserDto {
  @IsPhoneNumber('TH')
  phone: string;
  
  @IsString()
  @Length(1, 50)
  firstName: string;
  
  @IsEnum(UserRole)
  role: UserRole;
  
  @IsOptional()
  @IsString()
  @MaxLength(500)
  address?: string;
}
```

**Validation Rules:**
```typescript
Phone: 10 digits, starts with 0
Name: 1-50 chars, no special chars
Email: Valid email format
Date: Valid ISO 8601 format
Enum: Must be in allowed list
Number: Min/Max bounds
String: Length limits
```

**Checklist:**
- [ ] Validate All Inputs
- [ ] Whitelist (not Blacklist)
- [ ] Type Checking
- [ ] Length Limits
- [ ] Format Validation
- [ ] Sanitize HTML/Scripts
- [ ] Return 400 with Clear Errors

### 3.3 SQL Injection Prevention

```typescript
// VULNERABLE
const query = `SELECT * FROM users WHERE phone = '${phone}'`;
db.query(query);

// SAFE - Use ORM
const user = await prisma.user.findUnique({
  where: { phone }
});

// SAFE - Parameterized Query
const query = 'SELECT * FROM users WHERE phone = ?';
db.query(query, [phone]);
```

**Checklist:**
- [ ] ใช้ ORM (Prisma, TypeORM)
- [ ] NO Raw SQL Queries
- [ ] Parameterized Queries only
- [ ] Escape Special Characters
- [ ] Validate User Input
- [ ] Use Prepared Statements

### 3.4 CORS Configuration

```typescript
// TOO PERMISSIVE
app.enableCors({ origin: '*' });

// SECURE
app.enableCors({
  origin: [
    'https://yourdomain.com',
    'https://admin.yourdomain.com',
  ],
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 3600,
});
```

**Checklist:**
- [ ] Origin Whitelist (ไม่ใช้ `*`)
- [ ] Methods Whitelist
- [ ] Headers Whitelist
- [ ] Credentials: true (ถ้าต้องการ)
- [ ] No Wildcard in Production

---

## 4. File Upload Security

### 4.1 File Type Validation

```typescript
const ALLOWED_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp'
];

const ALLOWED_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.webp'];

@Post('upload')
@UseInterceptors(FileInterceptor('file', {
  fileFilter: (req, file, callback) => {
    // 1. Check MIME type
    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      return callback(new Error('Invalid file type'), false);
    }
    
    // 2. Check extension
    const ext = extname(file.originalname).toLowerCase();
    if (!ALLOWED_EXTENSIONS.includes(ext)) {
      return callback(new Error('Invalid extension'), false);
    }
    
    callback(null, true);
  },
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
    files: 1
  }
}))
async uploadFile(@UploadedFile() file: Express.Multer.File) {
  // 3. Validate file content (magic numbers)
  const isValid = await this.validateFileContent(file.path);
  if (!isValid) {
    fs.unlinkSync(file.path);
    throw new BadRequestException('Invalid file content');
  }
  
  return { url: `/uploads/${file.filename}` };
}
```

### 4.2 Magic Number Validation

```typescript
// Validate file content (not just extension)
import * as fileType from 'file-type';

async validateFileContent(filePath: string): Promise<boolean> {
  const type = await fileType.fromFile(filePath);
  
  if (!type) return false;
  
  const allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
  return allowedMimes.includes(type.mime);
}
```

**File Signatures (Magic Numbers):**
```
JPEG: FF D8 FF
PNG:  89 50 4E 47
WebP: 52 49 46 46
PDF:  25 50 44 46
```

**Checklist:**
- [ ] Validate MIME Type
- [ ] Validate Extension
- [ ] Validate Magic Numbers
- [ ] File Size Limit (≤ 10MB)
- [ ] Sanitize Filename
- [ ] Store Outside Webroot
- [ ] Scan for Malware (optional)
- [ ] No Executable Files (.exe, .php, .js)

---

## 5. Data Protection

### 5.1 Sensitive Data Handling

```typescript
// ซ่อนข้อมูลสำคัญใน Response
class UserEntity {
  id: string;
  phone: string;
  firstName: string;
  
  @Exclude()  // ไม่ส่งใน Response
  password: string;
  
  @Exclude()
  refreshToken: string;
  
  @Exclude()
  pin: string;
}
```

**Sensitive Fields:**
```typescript
Never expose:
- password
- pin
- refreshToken
- creditCardNumber
- bankAccount
- socialSecurityNumber

Mask when displaying:
- phone: 062-xxx-x901
- email: j***@example.com
```

**Checklist:**
- [ ] Passwords Never in Response
- [ ] Tokens Never in Logs
- [ ] PII Masked in Logs
- [ ] Encrypt Sensitive Fields in DB
- [ ] HTTPS Only
- [ ] No Sensitive Data in URLs
- [ ] No Sensitive Data in Error Messages

### 5.2 Database Security

```sql
-- Encryption at Rest
ALTER TABLE users 
  ADD COLUMN email_encrypted VARBINARY(255);

-- Use utf8mb4 for Thai
ALTER DATABASE drug_plant_db 
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_unicode_ci;

-- Index for Performance
CREATE INDEX idx_phone ON users(phone);
CREATE INDEX idx_created_at ON plots(created_at);
```

**Checklist:**
- [ ] Database Encryption at Rest
- [ ] Secure Connection (SSL/TLS)
- [ ] Strong DB Password
- [ ] Least Privilege Access
- [ ] Regular Backups
- [ ] Backup Encryption
- [ ] utf8mb4 for Unicode

---

## 6. Flutter App Security

### 6.1 Secure Storage

```dart
// ใช้ FlutterSecureStorage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

// Save
await storage.write(key: 'accessToken', value: token);

// Read
final token = await storage.read(key: 'accessToken');

// Delete
await storage.delete(key: 'accessToken');
```

**Never Use:**
```dart
// SharedPreferences - not encrypted!
final prefs = await SharedPreferences.getInstance();
prefs.setString('accessToken', token);  // INSECURE
```

**Checklist:**
- [ ] Tokens ใน FlutterSecureStorage
- [ ] ไม่ใช้ SharedPreferences สำหรับ Tokens
- [ ] Clear Storage on Logout
- [ ] Enable Android Keystore
- [ ] Enable iOS Keychain

### 6.2 Network Security

```dart
// Certificate Pinning (Optional)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = 
        (X509Certificate cert, String host, int port) => false;
  }
}

// SSL/TLS Only
final dio = Dio()
  ..options.baseUrl = 'https://api.example.com'  // HTTPS only
  ..options.validateStatus = (status) => status! < 500;
```

**Checklist:**
- [ ] HTTPS Only (no HTTP)
- [ ] Certificate Validation
- [ ] Certificate Pinning (High Security)
- [ ] Timeout Configuration
- [ ] Retry Logic with Backoff

### 6.3 Code Obfuscation

```bash
# Build with Obfuscation
flutter build apk --obfuscate --split-debug-info=build/debug-info
flutter build appbundle --obfuscate --split-debug-info=build/debug-info
```

**Checklist:**
- [ ] Enable Obfuscation
- [ ] Split Debug Info
- [ ] ProGuard Rules (Android)
- [ ] Strip Debug Symbols
- [ ] Minify Code

### 6.4 Prevent Screenshots (Sensitive Screens)

```dart
// Disable Screenshots on Login/PIN screens
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class SecureScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    // Disable screenshots
    FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }
  
  @override
  void dispose() {
    // Re-enable screenshots
    FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    super.dispose();
  }
}
```

**Checklist:**
- [ ] Disable Screenshots (Login/PIN)
- [ ] Blur App on Background
- [ ] Session Timeout
- [ ] Auto-logout on Inactivity

---

## 7. Monitoring & Logging

### 7.1 Security Logging

```typescript
// Log Security Events
@Injectable()
export class SecurityLogger {
  async log(event: SecurityEvent) {
    await this.prisma.securityLog.create({
      data: {
        eventType: event.type,
        userId: event.userId,
        ipAddress: event.ip,
        userAgent: event.userAgent,
        success: event.success,
        timestamp: new Date()
      }
    });
    
    // Alert on suspicious activity
    if (event.suspicious) {
      await this.sendAlert(event);
    }
  }
}
```

**Events to Log:**
```typescript
Login attempts (success/fail)
Logout
Token refresh
Password changes
Permission changes
File uploads
API errors
Rate limit hits
Suspicious activity
```

**Checklist:**
- [ ] Log All Auth Events
- [ ] Log API Errors
- [ ] Log Rate Limit Hits
- [ ] Never Log Passwords/Tokens
- [ ] Alert on Suspicious Activity
- [ ] Retention Policy (90 days)

### 7.2 Error Handling

```typescript
// DON'T expose internals
throw new Error('Query failed: SELECT * FROM users WHERE id = 123');

// DO return generic errors
throw new BadRequestException('Invalid request');

// Log details internally
this.logger.error('Query failed', {
  query: 'SELECT * FROM users WHERE id = ?',
  params: [123],
  error: err.message
});
```

**Checklist:**
- [ ] Generic Error Messages to Users
- [ ] Detailed Logs Internally
- [ ] No Stack Traces in Response
- [ ] No SQL Queries in Response
- [ ] No File Paths in Response

---

## 8. Deployment Security

### 8.1 Environment Configuration

```bash
# Production .env
NODE_ENV=production
JWT_SECRET=<64-char-random-string>
JWT_REFRESH_SECRET=<64-char-random-string>
GEMINI_API_KEY=<actual-key>
DB_PASSWORD=<strong-password>
```

**Checklist:**
- [ ] Different Secrets per Environment
- [ ] Strong Random Secrets (>= 32 chars)
- [ ] Rotate Secrets Regularly
- [ ] Use Secret Manager (AWS/GCP/Azure)
- [ ] No Secrets in Code
- [ ] No Secrets in Git

### 8.2 HTTPS Configuration

```typescript
// Force HTTPS
app.use((req, res, next) => {
  if (req.protocol !== 'https') {
    return res.redirect('https://' + req.headers.host + req.url);
  }
  next();
});

// Security Headers
import helmet from 'helmet';
app.use(helmet());
```

**Security Headers:**
```
Strict-Transport-Security: max-age=31536000
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: ...
```

**Checklist:**
- [ ] SSL Certificate Installed
- [ ] Force HTTPS Redirect
- [ ] HSTS Header
- [ ] Security Headers (helmet)
- [ ] No Mixed Content

---

## 9. Security Testing

### 9.1 Automated Tests

```typescript
// Security Test Cases
describe('Security', () => {
  it('should reject expired tokens', async () => {
    const expiredToken = generateExpiredToken();
    await request(app)
      .get('/users/me')
      .set('Authorization', `Bearer ${expiredToken}`)
      .expect(401);
  });
  
  it('should prevent SQL injection', async () => {
    await request(app)
      .post('/auth/signin')
      .send({ phone: "0812345678' OR '1'='1" })
      .expect(400);
  });
  
  it('should enforce rate limiting', async () => {
    for (let i = 0; i < 6; i++) {
      const response = await request(app)
        .post('/auth/signin')
        .send({ phone: '0812345678', birthday: '01/01/1990' });
      
      if (i < 5) expect(response.status).not.toBe(429);
      else expect(response.status).toBe(429);
    }
  });
});
```

### 9.2 Manual Testing

```bash
# 1. Test SQL Injection
curl -X POST /auth/signin \
  -d "phone=0812345678' OR '1'='1&birthday=01/01/1990"

# 2. Test XSS
curl -X POST /plots \
  -d "name=<script>alert('XSS')</script>"

# 3. Test Rate Limiting
for i in {1..10}; do
  curl -X POST /auth/signin -d "phone=0812345678&birthday=01/01/1990"
done

# 4. Test File Upload
curl -X POST /upload \
  -F "file=@malicious.php"
```

### 9.3 Security Tools

```bash
# Static Analysis
npm audit  # Check npm vulnerabilities
snyk test  # Snyk security scan

# Dynamic Analysis
OWASP ZAP  # Web app security testing
Burp Suite # API security testing

# Dependency Check
npm outdated
npm audit fix
```

**Checklist:**
- [ ] Run `npm audit` Weekly
- [ ] OWASP ZAP Scan Monthly
- [ ] Penetration Test Quarterly
- [ ] Update Dependencies Monthly
- [ ] Security Code Review

---

## 10. Security Checklist Summary

### Critical (Must Fix Now)
- [ ] ไม่มี API Key ใน Frontend Code
- [ ] Token Refresh ทำงานได้
- [ ] Passwords Hashed (bcrypt)
- [ ] Input Validation ทุก Endpoint
- [ ] HTTPS Only
- [ ] Rate Limiting

### High Priority (Fix This Week)
- [ ] Certificate Pinning
- [ ] File Upload Validation
- [ ] CORS Configuration
- [ ] Security Headers
- [ ] Monitoring & Logging
- [ ] Error Handling

### Medium Priority (Fix This Month)
- [ ] Code Obfuscation
- [ ] Database Encryption
- [ ] Backup Strategy
- [ ] Incident Response Plan
- [ ] Security Training

### Low Priority (Nice to Have)
- [ ] WAF (Web Application Firewall)
- [ ] DDoS Protection
- [ ] Intrusion Detection
- [ ] Bug Bounty Program

---

## Quick Win Actions (Do First)

```bash
# 1. Check for Secrets (5 min)
grep -r "AIzaSy" .
grep -r "sk-" .
grep -r "secret" .

# 2. Add .gitignore (1 min)
echo ".env" >> .gitignore
echo ".env.local" >> .gitignore

# 3. Install Security Packages (5 min)
npm install helmet bcrypt rate-limiter-flexible
npm install --save-dev @types/bcrypt

# 4. Enable HTTPS (if not already)
# Get SSL Certificate (Let's Encrypt)

# 5. Run Security Audit (2 min)
npm audit
npm audit fix
```

---

**จัดทำโดย:** AI Assistant  
**อัปเดตล่าสุด:** February 2, 2024  
**สถานะ:** Ready for AI Agent Execution
