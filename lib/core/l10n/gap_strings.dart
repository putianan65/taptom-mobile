// GAP-BUG-013: Extracted Thai strings from GAP forms for future i18n support
// This file serves as a central location for all GAP-related UI strings.
// To implement full i18n, integrate with flutter_localizations package.

/// GAP Form strings in Thai
class GapStrings {
  GapStrings._();

  // Common
  static const String save = 'บันทึกข้อมูล';
  static const String saveDraft = 'บันทึกร่าง';
  static const String cancel = 'ยกเลิก';
  static const String confirm = 'ตกลง';
  static const String back = 'กลับ';
  static const String exit = 'ออก';
  static const String retry = 'ลองใหม่';
  static const String selectDate = 'เลือกวันที่';
  static const String saveSuccess = 'บันทึกสำเร็จ';
  static const String editSuccess = 'แก้ไขสำเร็จ';
  static const String draftSaved = 'บันทึกร่างเรียบร้อย';
  static const String addSuccess = 'เพิ่มข้อมูลสำเร็จ';
  static const String loadError = 'ไม่สามารถโหลดข้อมูลได้ กรุณาลองใหม่';

  // Exit confirmation
  static const String exitFormTitle = 'ออกจากฟอร์ม?';
  static const String exitFormMessage =
      'ข้อมูลที่ยังไม่ได้บันทึกจะสูญหาย\nคุณต้องการออกหรือไม่?';

  // Incomplete fields dialog
  static const String incompleteFieldsTitle = 'ข้อมูลไม่ครบถ้วน';
  static const String goBackToEdit = 'กลับไปแก้ไข';

  // GAP Category names
  static const String category1 = 'ข้อมูลทั่วไป';
  static const String category2 = 'ปัจจัยการผลิต';
  static const String category3 = 'การจัดการแปลง';
  static const String category4 = 'การเก็บเกี่ยว';
  static const String category5 = 'หลังเก็บเกี่ยว';
  static const String category6 = 'ความปลอดภัย';
  static const String category7 = 'ตรวจติดตาม';

  // General Form (Category 1)
  static const String farmerName = 'ชื่อเกษตรกร';
  static const String farmerNameHint = 'กรอกชื่อ-นามสกุล';
  static const String farmerNameRequired = 'กรุณากรอกชื่อเกษตรกร';
  static const String startDate = 'วันเริ่มการเพาะปลูก';
  static const String endDate = 'วันสิ้นสุดฤดูกาล';
  static const String season = 'ฤดูกาล / รุ่นการผลิต';
  static const String cropVariety = 'สายพันธุ์ที่ปลูก';
  static const String farmingSystem = 'ระบบการผลิต';
  static const String waterSource = 'แหล่งน้ำ';
  static const String irrigationSystem = 'ระบบการให้น้ำ';

  // Harvest Form (Category 4)
  static const String harvestDate = 'วันที่เก็บเกี่ยว';
  static const String harvestDateRequired = 'กรุณาเลือกวันที่เก็บเกี่ยว';
  static const String yieldAmount = 'ปริมาณผลผลิต';
  static const String yieldAmountRequired = 'กรุณาระบุปริมาณผลผลิต';
  static const String lotNumber = 'รหัสล็อต';

  // Post-Harvest Form (Category 5)
  static const String processDate = 'วันที่ดำเนินการ';
  static const String processDateRequired = 'กรุณาเลือกวันที่ดำเนินการ';
  static const String noHarvestsMessage = 'ยังไม่มีข้อมูลการเก็บเกี่ยว';
  static const String goBackToHarvest =
      'กรุณาบันทึกข้อมูลการเก็บเกี่ยวในหมวด 4 ก่อน';
  static const String selectHarvestFirst = 'กรุณาเลือกข้อมูลการเก็บเกี่ยวก่อน';

  // Safety Form (Category 6)
  static const String trainingDate = 'วันที่อบรม';
  static const String trainingDateRequired = 'กรุณาเลือกวันที่อบรม';
  static const String trainingTopic = 'หัวข้อการอบรม';
  static const String trainingTopicRequired = 'กรุณาระบุหัวข้อการอบรม';

  // Traceability Form (Category 7)
  static const String searchLot = 'ค้นหาที่มาผลผลิต';
  static const String enterLotId = 'กรุณากรอกรหัสล็อต';
  static const String lotNotFound = 'ไม่พบข้อมูลล็อต';
  static const String partialMatchWarning =
      'พบผลลัพธ์แบบบางส่วน - ตรวจสอบความถูกต้อง';
  static const String lotFound = 'พบข้อมูลล็อต!';

  // Inputs Form (Category 2)
  static const String nameRequired = 'กรุณากรอกชื่อ/ชนิด';
  static const String invalidNumber = 'กรุณาใส่ตัวเลข';
  static const String amount = 'ปริมาณ';
  static const String unit = 'หน่วย';

  // Management Form (Category 3)
  static const String activityDate = 'วันที่ทำกิจกรรม';
  static const String activityDateRequired = 'กรุณาเลือกวันที่ทำกิจกรรม';
}
