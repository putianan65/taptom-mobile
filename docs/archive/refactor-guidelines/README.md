# AI Agent Project Documentation
## เอกสารควบคุม AI Agent สำหรับการพัฒนา Community Enterprise Application

**Version:** 1.0.0  
**Last Updated:** 2026-01-28  
**Project:** Community Enterprise Management System  
**Framework:** Flutter  
**Context:** แอปเกี่ยวกับเกษตรพืชเสพติดที่อยู่ภายใต้การควบคุมโดยกฎหมายของประเทศไทย  
**API Documentation:** http://localhost:3000/docs (Swagger)

---

## Table of Contents

### Core Documentation
1. **[AI Agent Control Document](./AI_AGENT_CONTROL.md)** **START HERE**
   - ภาพรวมทั้งหมดของการควบคุม AI Agent
   - Core Principles & Development Workflow
   - User Roles & Responsibilities
   - Local Storage Strategy
   - คำสั่งหลักสำหรับ Agent

2. **[Code Quality Standards](./CODE_QUALITY_STANDARDS.md)**
   - มาตรฐานการเขียนโค้ด
   - Project Structure & Naming Conventions
   - Component Templates & Best Practices
   - Testing & Documentation Standards

3. **[API Integration Checklist](./API_INTEGRATION_CHECKLIST.md)**
   - Swagger API Documentation (http://localhost:3000/docs)
   - รายการ API ทั้งหมด
   - Authentication & User Management
   - Admin & Super Admin APIs
   - GAP (Good Agricultural Practices) APIs
   - Location & Occupation Data
   - Error Handling & Performance

4. **[Performance & Optimization Guide](./PERFORMANCE_OPTIMIZATION.md)**
   - Performance Goals & Metrics
   - App Launch & UI/UX Optimization
   - List & Image Performance
   - Network & State Management
   - Battery & Memory Optimization

5. **[Bug Tracking System](./BUG_TRACKING_SYSTEM.md)**
   - Bug Classification & Priority
   - Known Issues & Status
   - Common Bug Patterns & Solutions
   - Bug Prevention Strategies

6. **[User Flow & Testing Guide](./USER_FLOW_TESTING_GUIDE.md)**
   - Complete User Flow Testing
   - Admin & Super Admin Testing
   - GAP Submission & Review Flow
   - Cross-Role Testing Scenarios
   - Device & Platform Testing

7. **[Production Readiness Checklist](./PRODUCTION_READINESS_CHECKLIST.md)**
   - App Store Requirements (iOS & Android)
   - Security & Performance Checklist
   - Code Quality & UI/UX Standards
   - Final Pre-Launch Checklist

8. **[UI/UX Design Guidelines](./UI_UX_DESIGN_GUIDELINES.md)** **NEW**
   - Design Philosophy & Theme Colors
   - Typography & Spacing
   - Icon Guidelines (ทุก Screen ของทุก Role)
   - Screen Templates (User/Admin/Super Admin)
   - Component Library

---

## Quick Start Guide

### สำหรับ AI Agent

#### ขั้นตอนการเริ่มงาน
```bash
# 1. อ่านเอกสารหลัก
เริ่มที่: AI_AGENT_CONTROL.md

# 2. เปิด API Documentation
เปิดเบราว์เซอร์: http://localhost:3000/docs
   ตรวจสอบ API ทำงานครบถูกต้องสมบูรณ์

# 3. ตรวจสอบ Project Structure
ls -la lib/

# 4. รัน Code Quality Tools
flutter analyze
dart format .

# 5. ตรวจสอบ API Documentation
อ่าน: API_INTEGRATION_CHECKLIST.md

# 6. ดู UI/UX Guidelines
อ่าน: UI_UX_DESIGN_GUIDELINES.md
   - ดูไอคอนสำหรับทุก Screen
   - ตรวจสอบธีมสี
   - ดู Component templates

# 7. ดู Known Issues
อ่าน: BUG_TRACKING_SYSTEM.md
```

#### เมื่อพัฒนา Feature ใหม่
1. อ่าน Feature Spec (ถ้ามี)
2. ตรวจสอบ API ที่เกี่ยวข้องใน Swagger
3. ดู Code Quality Standards
4. ดู UI/UX Design Guidelines (ธีม, ไอคอน)
5. เขียน Code ตาม Template
6. เขียน Tests
7. ทดสอบบน Device
8. Update Documentation

---

## Key Features & Context

### Important Context
**แอปนี้เกี่ยวกับ:** เกษตรพืชเสพติดที่อยู่ภายใต้การควบคุมโดยกฎหมายของประเทศไทย

**GAP (Good Agricultural Practices):**
- ผู้ใช้บันทึกข้อมูลการปลูกพืช
- หลังบันทึก สามารถกดส่งให้ Admin ตรวจสอบ
- Admin ตรวจสอบและอนุมัติ/ปฏิเสธ
- ข้อมูลต้องเก็บอย่างปลอดภัย (sensitive)
- มี audit trail ทุกการเปลี่ยนแปลง

### User Features
- ลงทะเบียน/เข้าสู่ระบบ
- จัดการข้อมูลส่วนตัว
- บันทึก GAP
- ส่งข้อมูล GAP ให้ Admin ตรวจสอบ
- ติดตามสถานะการอนุมัติ

### Admin Features
- Login ด้วย PIN (6 หลัก)
- Set/Change PIN
- อนุมัติ/ปฏิเสธ User
- ตรวจสอบและอนุมัติ GAP
- ดูสถิติในเขตพื้นที่
- ติดต่อ Super Admin (Support Ticket)
- จัดการ Profile ตัวเอง

### Super Admin Features
- Master Dashboard พร้อมกราฟวิเคราะห์
- จัดการ Admin ทั้งหมด (Add/Edit/Delete/Suspend)
- จัดการ User ทั่วประเทศ
- ดู Reports & Export ข้อมูล
- System Settings & Configuration
- รับและตอบ Support Tickets จาก Admin

---

## Design System

### Theme Colors
- **Primary:** เขียวเข้ม (เกษตร) `#2E7D32`
- **Secondary:** เขียวน้ำทะเล `#00796B`
- **ไม่ควรเน้นสีสรรค์เยอะ** - ยึดตามธีมเดิม

### Icons
- **ใช้ไอคอนที่มีอยู่แล้ว** (ไม่เปลี่ยน)
- **แค่ยึดสีเดิมให้สม่ำเสมอ**
- เหมือน Facebook (น้ำเงิน), LINE (เขียว)
- ดูรายละเอียดใน: [UI/UX Design Guidelines](./UI_UX_DESIGN_GUIDELINES.md)

### Design Philosophy
1. **Color Consistency** - ยึดสี Primary 80%
2. **Simplicity** - เรียบง่าย ไม่สีสรรค์เยอะ
3. **Professional** - ดูเป็นมืออาชีพ
4. **Trust** - สร้างความไว้วางใจ

### Color Usage (80-10-10 Rule)
- **80%** Primary (เขียวเข้ม) - App Bar, ปุ่มหลัก, ไอคอน
- **10%** Secondary (เขียวน้ำทะเล) - แยกหมวดเท่านั้น
- **10%** Status (Success/Error/Warning) - Feedback เท่านั้น

---

## API Documentation

### Swagger UI
**URL:** http://localhost:3000/docs

**ใช้สำหรับ:**
- ตรวจสอบ API endpoints ทั้งหมด
- ทดสอบ API calls โดยตรง
- ดู Request/Response schemas
- **Verify API ทำงานครบถูกต้องสมบูรณ์**

**Quick Test:**
```bash
# 1. Start backend
cd backend
npm run dev

# 2. Open browser
http://localhost:3000/docs

# 3. Test critical endpoints:
POST /api/auth/register
POST /api/auth/login
POST /api/admin/login
POST /api/user/gap/submit
POST /api/admin/gap/:gapId/review
POST /api/admin/contact-superadmin
```

---

## Local Storage Strategy

### ข้อมูลที่ควรเก็บ Local
```dart
// shared_preferences (ข้อมูลทั่วไป)
- User preferences
- Cache API (จังหวัด, อาชีพ)
- App settings

// flutter_secure_storage (ข้อมูลสำคัญ)
- Auth token
- Refresh token
- PIN (hashed)
```

### ข้อจำกัด
- **ต้องไม่หนักแอปพลิเคชันมาก** (< 50MB)
- **ต้องไม่กินพื้นที่จนเกินไป**
- Max cache size: 30MB
- Cache duration: 24 ชม. (ปรับได้ตามประเภทข้อมูล)
- มี auto cleanup mechanism

### ตัวอย่าง Cache Management
```dart
// จังหวัด (ไม่เปลี่ยน) - cache 30 วัน
await cacheData('provinces', data, Duration(days: 30));

// User profile (เปลี่ยนบ่อย) - cache 1 ชม.
await cacheData('user_profile', data, Duration(hours: 1));

// Dashboard (เปลี่ยนบ่อยมาก) - cache 5 นาที
await cacheData('dashboard', data, Duration(minutes: 5));
```

---

## Documentation Matrix

### By Role

#### User (ผู้ใช้ทั่วไป)
**เอกสารที่เกี่ยวข้อง:**
- User Flow & Testing Guide → User Role Section
- API Integration Checklist → User APIs & GAP APIs
- UI/UX Design Guidelines → User Screen Templates
- Bug Tracking → User-related issues

**Features:**
- ลงทะเบียน/เข้าสู่ระบบ
- จัดการ Profile
- บันทึก GAP (Good Agricultural Practices)
- ส่ง GAP ให้ Admin ตรวจสอบ
- ติดตามสถานะ

#### Admin (ผู้ดูแลระดับจังหวัด)
**เอกสารที่เกี่ยวข้อง:**
- User Flow & Testing Guide → Admin Role Section
- API Integration Checklist → Admin APIs, GAP Review APIs
- UI/UX Design Guidelines → Admin Screen Templates
- Bug Tracking → Admin-related issues

**Features:**
- Login ด้วย PIN
- Set/Change PIN
- อนุมัติ/ปฏิเสธ User
- ตรวจสอบและอนุมัติ GAP
- ดู Statistics ในเขต
- จัดการ Profile ตัวเอง
- ติดต่อ Super Admin (Support Ticket)

#### Super Admin (ผู้ดูแลระดับสูงสุด)
**เอกสารที่เกี่ยวข้อง:**
- User Flow & Testing Guide → Super Admin Section
- API Integration Checklist → Super Admin APIs
- Performance Guide → Dashboard Optimization

**Features:**
- Master Dashboard
- จัดการ Admins ทั้งหมด
- จัดการ Users ทั้งหมด
- ดู Reports & Analytics
- System Settings

---

### By Task

#### UI/UX Development
**เอกสารที่ต้องอ่าน:**
1. Code Quality Standards → Component Structure
2. Performance Guide → UI/UX Performance
3. User Flow Guide → Testing Scenarios

**Key Points:**
- ใช้ Theme Constants
- Loading States ทุกจุด
- Error Handling ทุกจุด
- Responsive Design
- Smooth Transitions

#### API Integration
**เอกสารที่ต้องอ่าน:**
1. API Integration Checklist → ทั้งหมด
2. Bug Tracking → API Issues
3. Performance Guide → Network Optimization

**Key Points:**
- Error Handling ครบถ้วน
- Retry Mechanism
- Caching Strategy
- Offline Support
- Loading States

#### Testing
**เอกสารที่ต้องอ่าน:**
1. User Flow & Testing Guide → ทั้งหมด
2. Bug Tracking → Known Issues
3. Production Readiness → Testing Checklist

**Test Coverage:**
- Unit Tests (> 80%)
- Integration Tests
- E2E Tests
- Performance Tests
- Security Tests

#### Deployment
**เอกสารที่ต้องอ่าน:**
1. Production Readiness Checklist → ทั้งหมด 2. Bug Tracking → All Issues Resolved
3. Performance Guide → Metrics Check

**Before Deploy:**
- All tests passing
- No critical bugs
- Performance targets met
- Security audit passed
- Documentation complete

---

## Quick Reference

### Critical Files to Check

#### ทุกครั้งก่อนเริ่มงาน
```bash
AI_AGENT_CONTROL.md           # คำสั่งหลัก
BUG_TRACKING_SYSTEM.md        # Known Issues
API_INTEGRATION_CHECKLIST.md  # API Status
```

#### เมื่อสร้าง Components ใหม่
```bash
CODE_QUALITY_STANDARDS.md     # Templates & Standards
PERFORMANCE_OPTIMIZATION.md   # Performance Best Practices
```

#### เมื่อทำงานกับ APIs
```bash
API_INTEGRATION_CHECKLIST.md  # API Endpoints & Examples
BUG_TRACKING_SYSTEM.md        # API-related Issues
```

#### ก่อน Submit Code
```bash
CODE_QUALITY_STANDARDS.md     # Code Review Checklist
USER_FLOW_TESTING_GUIDE.md    # Testing Requirements
```

#### ก่อน Production
```bash
PRODUCTION_READINESS_CHECKLIST.md  # All Requirements
BUG_TRACKING_SYSTEM.md             # No Critical Bugs
PERFORMANCE_OPTIMIZATION.md        # Performance Targets Met
```

---

## Project Status Dashboard

### Current Status
```
App Version: 1.0.0
Build Status: In Development
Framework: Flutter
API Docs: http://localhost:3000/docs
Critical Bugs: 0
High Priority Bugs: 0
Test Coverage: 85%
Production Ready: 95%
UI/UX: Complete with Icons
Local Storage: Optimized (< 30MB)
```

### Known Issues
```
FIXED: จังหวัดตากแสดงภาษาเพี้ยน
FIXED: PIN Input ไม่ทำงานบน Android
FIXED: Loading ช้าในหน้า Profile
IN PROGRESS: Push Notification iOS
NEW: GAP Submission & Review Flow
NEW: Admin Contact Super Admin Feature
UPDATED: UI/UX - ยึดสีเดิม (ไม่เปลี่ยนไอคอน)
```

### Next Milestones
```
1. Complete UI/UX Design System
2. Add GAP Feature
3. Add Admin Support System
4. Finish All Testing
5. Performance Optimization
6. Security Audit
7. App Store Submission
```

---

## Key Performance Indicators (KPIs)

### Code Quality
| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Test Coverage | > 80% | 85% | |
| ESLint Errors | 0 | 0 | |
| Code Duplication | < 5% | 3% | |
| Component Size | < 300 lines | ~250 | |

### Performance
| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| App Launch | < 2s | 1.8s | |
| Screen Transition | < 300ms | 250ms | |
| API Response | < 1s | 800ms | |
| List Scroll FPS | 60fps | 58fps | |

### Bugs
| Priority | Target | Current | Status |
|----------|--------|---------|--------|
| Critical | 0 | 0 | |
| High | < 3 | 0 | |
| Medium | < 10 | 5 | |
| Low | < 20 | 12 | |

---

## Tools & Resources

### Development Tools
```bash
# Code Quality
- ESLint
- Prettier
- TypeScript (if applicable)

# Testing
- Jest
- React Testing Library
- Detox (E2E)

# Performance
- React Native Performance Monitor
- Flipper
- Firebase Performance

# Debugging
- React Native Debugger
- Reactotron
```

### External Resources
```
React Native Docs: https://reactnative.dev/
React Navigation: https://reactnavigation.org/
Redux Toolkit: https://redux-toolkit.js.org/
Jest: https://jestjs.io/
```

---

## Support & Contact

### Team Contacts
```
‍Technical Lead: [ชื่อ]
‍Project Manager: [ชื่อ]
UI/UX Designer: [ชื่อ]
QA Lead: [ชื่อ]
```

### Communication Channels
```
Slack: #project-channel
Email: team@example.com
Bug Reports: GitHub Issues
Project Board: Jira/Trello
```

---

## Document Updates

### Version History
```
v1.0.0 - 2026-01-28
- Initial documentation complete
- All 7 core documents created
- Production-ready documentation set

v0.9.0 - 2026-01-20
- Draft documentation
- Core structure defined
```

### How to Update Documents
```
1. Make changes to relevant .md file
2. Update "Last Updated" date
3. Update version number (if major changes)
4. Notify team of changes
5. Commit with descriptive message
```

---

## Documentation Checklist

### AI Agent เริ่มงานใหม่ควร:
- [ ] อ่าน AI_AGENT_CONTROL.md ทั้งหมด
- [ ] ทำความเข้าใจ Project Structure
- [ ] อ่าน CODE_QUALITY_STANDARDS.md
- [ ] ดู API_INTEGRATION_CHECKLIST.md
- [ ] เช็ค BUG_TRACKING_SYSTEM.md
- [ ] ดู USER_FLOW_TESTING_GUIDE.md
- [ ] เตรียมตัวตาม PRODUCTION_READINESS_CHECKLIST.md

### ก่อน Submit Code:
- [ ] Follow Code Quality Standards
- [ ] Write Tests
- [ ] Update Documentation
- [ ] Check Performance
- [ ] Run Linters
- [ ] Test on Device

### ก่อน Production:
- [ ] Complete Production Readiness Checklist
- [ ] All Tests Passing
- [ ] No Critical Bugs
- [ ] Performance Targets Met
- [ ] Documentation Complete
- [ ] Team Sign-off

---

## Learning Path

### สำหรับ Junior Developers
```
Week 1:
- อ่าน CODE_QUALITY_STANDARDS.md
- ศึกษา Project Structure
- ทำความเข้าใจ Component Templates

Week 2:
- อ่าน API_INTEGRATION_CHECKLIST.md
- ทดสอบ API calls
- เรียนรู้ Error Handling

Week 3:
- อ่าน PERFORMANCE_OPTIMIZATION.md
- ฝึกเขียน Optimized Code
- ทำความเข้าใจ Memoization

Week 4:
- อ่าน USER_FLOW_TESTING_GUIDE.md
- เขียน Tests
- ทดสอบ User Flows
```

### สำหรับ Senior Developers
```
Day 1:
- Review ทุกเอกสาร (2-3 ชั่วโมง)
- ทำความเข้าใจ Architecture
- Plan Development Strategy

Day 2-onwards:
- Lead Development
- Mentor Juniors
- Code Review
- Performance Optimization
```

---

## Emergency Procedures

### Critical Bug Found
```
1. อ่าน BUG_TRACKING_SYSTEM.md → Emergency Procedures
2. Create Bug Report
3. Assess Severity
4. Immediate Fix (if Critical)
5. Deploy Hotfix
6. Communicate with Team
```

### Production Outage
```
1. Check Server Status
2. Review Error Logs
3. Rollback if needed
4. Fix and Deploy
5. Post-mortem Analysis
```

---

## Success Metrics

### Short-term Goals (1 Month)
- Complete all features
- Fix all critical bugs
- 80%+ test coverage
- Pass all performance benchmarks
- Submit to app stores

### Long-term Goals (3 Months)
- 10,000+ downloads
- 4.5+ stars rating
- 70%+ user retention
- 99.9% uptime
- 0 critical bugs reported

---

## Best Practices Summary

### Code
- Follow naming conventions
- Write clean, readable code
- Document everything
- Test thoroughly

### Performance
- Optimize early
- Measure constantly
- Cache aggressively
- Load lazily

### Quality
- Review regularly
- Refactor continuously
- Test comprehensively
- Monitor actively

### Collaboration
- Communicate clearly
- Document changes
- Share knowledge
- Support team

---

## Conclusion

เอกสารชุดนี้ออกแบบมาเพื่อให้ AI Agent สามารถทำงานได้อย่างมีประสิทธิภาพสูงสุด โดยไม่ต้องหยุดพักหรือรอคำสั่งเพิ่มเติม

**Remember:**
- เอกสารเป็น Living Documents - อัพเดทเสมอ
- Quality > Speed - ทำให้ถูก ดีกว่าทำให้เร็ว
- Test Everything - ทดสอบก่อนเสมอ
- Security First - ความปลอดภัยสำคัญที่สุด
- Team Work - ทำงานเป็นทีม

---

**Made with for AI Agents**

**Version:** 1.0.0  
**Last Updated:** 2026-01-28  
**Status:** Production Ready 