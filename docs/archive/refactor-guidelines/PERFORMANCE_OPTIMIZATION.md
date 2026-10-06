# Performance & Optimization Guide
## คู่มือการเพิ่มประสิทธิภาพแอป (Flutter Edition)

**Version:** 1.0.1 (Flutter Edition)
**Last Updated:** 2026-01-29

---

## Performance Goals
- **App Launch**: < 2 วินาที
- **List Scroll**: 60 FPS (ไม่กระตุก)
- **Image Load**: รวดเร็วและมี Cache

---

## Optimization Techniques

### 1. Use `const` Widgets
ใช้ `const` หน้า Constructor ของ Widget ที่ไม่มีการเปลี่ยนแปลงค่า เพื่อให้ Flutter รู้ว่าไม่ต้อง Rebuild Widget นี้ใหม่

```dart
// ดี
const Text('สวัสดี', style: TextStyle(fontSize: 20));

// ไม่ดี (ถ้าทำเป็น const ได้)
Text('สวัสดี', style: TextStyle(fontSize: 20));
```

### 2. ListView.builder
สำหรับรายการที่มีจำนวนมาก ให้ใช้ `ListView.builder` เสมอ เพื่อ render เฉพาะสิ่งที่เห็นบนหน้าจอ

```dart
// ดี
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// ไม่ดี (สำหรับ List ยาวๆ)
ListView(
  children: items.map((e) => ItemWidget(e)).toList(),
)
```

### 3. Image Caching (`cached_network_image`)
ใช้ package `cached_network_image` แทน `Image.network` เพื่อลดการโหลดซ้ำ

```dart
CachedNetworkImage(
  imageUrl: "https://example.com/image.jpg",
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### 4. Heavy Computation in Isolate
การคำนวณที่หนักหน่วง (เช่น Parse JSON ก้อนใหญ่มากๆ, Process รูปภาพ) ให้ทำใน Background Isolate (ใช้ `compute`)

```dart
// ตัวอย่างการ Parse JSON ใน background
Future<List<User>> fetchUsers() async {
  final response = await http.get(...);
  // ใช้ compute เพื่อย้ายงานไป thread อื่น
  return compute(parseUsers, response.body);
}

List<User> parseUsers(String responseBody) {
  // ... decoding logic
}
```

### 5. Don't block the UI Thread
หลีกเลี่ยงการทำ logic หนักๆ ใน `build` method หรือใน Event handler โดยตรงถ้าเป็นไปได้

---

## Monitoring
ใช้ **Flutter DevTools** เพื่อตรวจสอบ:
- **Flutter Inspector**: ดู Widget Tree ที่ซ้อนกันเกินจำเป็น
- **Performance View**: ดู Frame Rendering Time (ต้องไม่เกิน 16ms ต่อเฟรม)
- **Memory View**: ตรวจสอบ Memory Leak

---

## Checklist ก่อน Deploy
- [ ] รัน `flutter build appbundle --release` แล้วลองเทส (Release mode เร็วกว่า Debug mode มาก)
- [ ] เอา `print()` ออกทั้งหมด
- [ ] รูปภาพขนาดใหญ่ถูก Resize/Compress แล้ว
