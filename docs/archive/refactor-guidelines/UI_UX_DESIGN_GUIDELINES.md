# UI/UX Design Guidelines
## แนวทางการออกแบบ UI/UX สำหรับทุก Role (Flutter Edition)

**Version:** 1.0.1 (Flutter Edition)
**Last Updated:** 2026-01-29
**Framework:** Flutter (Material Design 3)

---

## Design Philosophy

### หลักการออกแบบ
1. **Consistency** - ความสม่ำเสมอในการใช้ Widgets และ Theme
2. **Simplicity** - เรียบง่าย ใช้งานง่ายตามหลัก Material Design
3. **Professional** - ดูเป็นมืออาชีพ น่าเชื่อถือ
4. **Color Consistency** - ยึดคอนเซปต์สีเดิม (80-10-10 Rule)

### หลักการใช้สี (80-10-10 Rule)

- **80% สีหลัก (Primary)**: เขียวเข้ม (`AppColors.primary`)
- **10% สีเสริม (Secondary)**: เขียวน้ำทะเล (`AppColors.secondary`)
- **10% สี Function (Status)**: Success/Warning/Error

```dart
// lib/core/constants/app_colors.dart
class AppColors {
  static const Color primary = Color(0xFF2E7D32); // เขียวเข้ม
  static const Color secondary = Color(0xFF00796B); // เขียวน้ำทะเล
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
}
```

---

## Spacing & Layout

ใช้ Constants แทนการ Hardcode ตัวเลข

```dart
// lib/core/constants/app_dimens.dart
class AppDimens {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
}
```

---

## Typography

ใช้ `GoogleFonts` หรือ `ThemeData` ที่กำหนดไว้

```dart
// lib/core/theme/app_theme.dart
Text(
  'หัวข้อหลัก',
  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  ),
);
```

---

## Icon Guidelines

- **Source**: ใช้ `HeroIcons` (ตามที่โปรเจกต์ใช้อยู่) หรือ `MaterialIcons` อย่างสม่ำเสมอ
- **Color**: ใช้สี `primary` สำหรับ Active state และ `textSecondary` สำหรับ Inactive
- **Size**: มาตรฐาน 24.0 (Small), 32.0 (Medium)

```dart
HeroIcon(
  HeroIcons.home,
  color: AppColors.primary,
  size: 24.0,
)
```

---

## Screen Templates

### 1. Standard Scaffold
```dart
Scaffold(
  appBar: AppBar(
    title: Text('ชื่อหน้า'),
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),
  body: SafeArea(
    child: SingleChildScrollView( // ป้องกัน Overflow
      padding: EdgeInsets.all(AppDimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Content
        ],
      ),
    ),
  ),
)
```

### 2. Form Layout
```dart
FormBuilder(
  key: _formKey,
  child: Column(
    children: [
      FormBuilderTextField(
        name: 'phone',
        decoration: InputDecoration(
          labelText: 'เบอร์โทรศัพท์',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
        ),
      ),
      const SizedBox(height: AppDimens.md),
      ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.all(AppDimens.md),
        ),
        child: const Text('บันทึก'),
      ),
    ],
  ),
)
```

---

## Component Library (Common Widgets)

### 1. Custom Button
ควรสร้าง `CustomButton` หรือ `AppButton` เพื่อใช้ซ้ำ

```dart
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppButton({
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
        ),
        child: isLoading 
          ? const CircularProgressIndicator.adaptive()
          : Text(text),
      ),
    );
  }
}
```

### 2. Loading State
```dart
// Overlay Loading
Stack(
  children: [
    content,
    if (isLoading)
      Container(
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator()),
      ),
  ],
)
```

---

## Common UX Mistakes to Avoid

1.  **RenderFlex Overflow**: ต้อง Wrap Content ที่ยาวด้วย `SingleChildScrollView` หรือ `ListView` เสมอ
2.  **Unresponsive Keyboard**: ใช้ `GestureDetector(onTap: FocusScope.of(context).unfocus)` ที่ Root Widget เพื่อให้แตะพื้นหลังแล้วคีย์บอร์ดหุบ
3.  **No Loading Feedback**: ห้ามปล่อยให้ User รอโดยไม่แสดง Loading indicator
4.  **Hardcoded Strings**: ควรเตรียมพร้อมสำหรับ Localization (ใช้ `AppLocalizations` หรือ constant strings)

---

## Design Checklist ก่อนส่งงาน
- [ ] สีถูกต้องตาม 80-10-10 Rule
- [ ] Font size/weight อ่านง่าย สม่ำเสมอ
- [ ] ไม่มี Overflow ในหน้าจอขนาดเล็ก (iPhone SE/Android Small)
- [ ] Loading state แสดงชัดเจน
- [ ] Error state (สีแดง) สื่อความหมายชัดเจน
- [ ] Padding/Margin ใช้ค่าจาก `AppDimens`
